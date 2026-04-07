# ODA 规约：按需抽象

## 什么是 ODA（On-Demand Abstraction）？

当我们用 KLEE 符号执行一个函数时，如果这个函数调用了其他复杂函数，会遇到两个问题：

### 问题 1：路径爆炸
```c
BOOL PathCombineW(LPWSTR dest, LPCWSTR dir, LPCWSTR file) {
    // 调用 PathIsRelativeW
    if (PathIsRelativeW(file)) {
        // 调用 PathCanonicalizeW
        return PathCanonicalizeW(dest, ...);
    }
    // ... 更多分支
}
```

如果 KLEE 要完整分析 `PathCombineW`，需要：
1. 分析 `PathIsRelativeW` 的所有路径
2. 分析 `PathCanonicalizeW` 的所有路径
3. 组合所有可能的路径

**结果**：状态空间指数级增长，KLEE 跑不完。

### 问题 2：外部依赖
```c
BOOL PathIsRelativeW(LPCWSTR path) {
    int len = lstrlenW(path);  // 调用 Windows API
    // ...
}
```

`lstrlenW` 是 Windows 系统库函数，KLEE 无法链接。

## ODA 的解决方案

**核心思想**：为依赖函数生成"充分条件"的 stub，而不是完整实现。

### 示例：为 `lstrlenW` 生成 stub

**真实实现**（复杂）：
```c
int lstrlenW(LPCWSTR str) {
    int len = 0;
    while (str[len] != 0) len++;
    return len;
}
```

**ODA stub**（简化）：
```c
int lstrlenW_stub(LPCWSTR str) {
    if (str == NULL) {
        return 0;  // 边界情况
    }
    
    // 符号化返回值
    int len;
    klee_make_symbolic(&len, sizeof(len), "lstrlenW_ret");
    
    // 添加约束：长度必须合理
    klee_assume(len >= 0 && len <= 1024);
    
    // 如果长度 > 0，确保字符串至少有一个字符
    if (len > 0) {
        klee_assume(str[0] != 0);
    }
    
    return len;
}
```

**为什么这样做？**
- ✅ KLEE 可以探索所有可能的长度（0, 1, 2, ..., 1024）
- ✅ 不需要实际遍历字符串（避免路径爆炸）
- ✅ 保留了关键约束（NULL 返回 0，非空返回正数）
- ✅ 可以发现边界情况（空字符串、超长字符串）

## ODA 规约格式

我们用 JSON 定义每个函数的抽象规则：

```json
{
  "target_function": "PathIsRelativeW",
  "dependencies": [
    {
      "name": "lstrlenW",
      "signature": "int lstrlenW(LPCWSTR str)",
      "abstraction": {
        "type": "symbolic_return",
        "constraints": [
          "if (str == NULL) return 0",
          "int len; klee_make_symbolic(&len, sizeof(len), \"len\")",
          "klee_assume(len >= 0 && len <= 1024)",
          "if (len > 0) klee_assume(str[0] != 0)",
          "return len"
        ]
      }
    }
  ],
  "target_predicates": [
    "return == TRUE",
    "return == FALSE"
  ]
}
```

### 字段说明

- `target_function`: 我们要测试的目标函数
- `dependencies`: 它依赖的外部函数列表
- `abstraction.type`: 抽象类型
  - `symbolic_return`: 符号化返回值
  - `symbolic_output`: 符号化输出参数
  - `noop`: 空操作（忽略副作用）
- `constraints`: 约束条件（C 代码片段）
- `target_predicates`: 我们想要覆盖的目标条件

## 生成 stub 代码

运行 `gen_oda_stub.py` 将 JSON 规约转换为 C 代码：

```bash
python gen_oda_stub.py pathisrelativew.json -o ../klee/oda_stubs.c
```

**生成的代码**：
```c
// Auto-generated ODA stubs for PathIsRelativeW

#include <klee/klee.h>
#include <windows.h>

// Stub for lstrlenW
int lstrlenW(LPCWSTR str) {
    if (str == NULL) return 0;
    
    int len;
    klee_make_symbolic(&len, sizeof(len), "lstrlenW_ret");
    klee_assume(len >= 0 && len <= 1024);
    
    if (len > 0) klee_assume(str[0] != 0);
    
    return len;
}
```

## 抽象策略

### 1. 字符串函数（lstrlenW, lstrcpyW, ...）

**策略**：符号化长度/结果，添加合理性约束

```json
{
  "name": "lstrlenW",
  "abstraction": {
    "type": "symbolic_return",
    "constraints": [
      "if (str == NULL) return 0",
      "int len; klee_make_symbolic(&len, sizeof(len), \"len\")",
      "klee_assume(len >= 0 && len <= MAX_PATH)",
      "return len"
    ]
  }
}
```

### 2. 内存分配（malloc, HeapAlloc, ...）

**策略**：返回符号化指针或 NULL

```json
{
  "name": "HeapAlloc",
  "abstraction": {
    "type": "symbolic_return",
    "constraints": [
      "if (size == 0) return NULL",
      "int success; klee_make_symbolic(&success, sizeof(success), \"alloc_ok\")",
      "if (success) return malloc(size); else return NULL"
    ]
  }
}
```

### 3. 文件操作（CreateFileW, ReadFile, ...）

**策略**：符号化句柄和返回值

```json
{
  "name": "CreateFileW",
  "abstraction": {
    "type": "symbolic_return",
    "constraints": [
      "HANDLE h; klee_make_symbolic(&h, sizeof(h), \"file_handle\")",
      "int valid; klee_make_symbolic(&valid, sizeof(valid), \"file_valid\")",
      "return valid ? h : INVALID_HANDLE_VALUE"
    ]
  }
}
```

### 4. 无副作用函数（GetLastError, ...）

**策略**：返回符号化值，无约束

```json
{
  "name": "GetLastError",
  "abstraction": {
    "type": "symbolic_return",
    "constraints": [
      "DWORD err; klee_make_symbolic(&err, sizeof(err), \"last_error\")",
      "return err"
    ]
  }
}
```

## 如何编写 ODA 规约？

### 步骤 1：识别依赖函数

使用 RAG 模块查询：
```python
hq = HierarchicalQuery("index.json")
func_info = hq.get_function_info("shlwapi", "path.c", "PathIsRelativeW")
print(func_info["dependencies"])
# 输出: ["lstrlenW", "lstrcpyW"]
```

### 步骤 2：分析每个依赖函数

对于每个依赖函数，问自己：
1. 它的返回值对目标函数的控制流有影响吗？
   - 有 → 需要符号化返回值
   - 无 → 可以用 noop
2. 它有副作用（修改全局状态、输出参数）吗？
   - 有 → 需要符号化输出
   - 无 → 只需符号化返回值
3. 返回值的合理范围是什么？
   - 添加 `klee_assume` 约束

### 步骤 3：编写 JSON 规约

```json
{
  "target_function": "PathIsRelativeW",
  "dependencies": [
    {
      "name": "lstrlenW",
      "signature": "int lstrlenW(LPCWSTR str)",
      "abstraction": {
        "type": "symbolic_return",
        "constraints": [
          "if (str == NULL) return 0",
          "int len; klee_make_symbolic(&len, sizeof(len), \"len\")",
          "klee_assume(len >= 0 && len <= 260)",
          "return len"
        ]
      }
    }
  ]
}
```

### 步骤 4：生成并测试

```bash
python gen_oda_stub.py pathisrelativew.json -o ../klee/oda_stubs.c
cd ../klee
./run_klee.sh harness_pathisrelativew.c
```

## LLM 辅助生成 ODA 规约

可以让 LLM 自动生成规约：

```python
def generate_oda_spec(func_name, dependencies):
    prompt = f"""
    为函数 {func_name} 生成 ODA 规约。
    
    依赖函数: {dependencies}
    
    对于每个依赖函数，生成：
    1. 函数签名
    2. 抽象类型（symbolic_return/symbolic_output/noop）
    3. 约束条件（C 代码）
    
    输出 JSON 格式。
    """
    return llm.generate(prompt)
```

## 示例规约

见 `pathisrelativew.json`
