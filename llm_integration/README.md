# LLM 集成模块：自动生成 ODA 规约

## 概述

这个模块展示如何使用 LLM 自动化以下任务：
1. **分析依赖函数**：找出待测函数调用的外部函数
2. **生成函数摘要**：为依赖函数生成简洁的描述
3. **生成 ODA 规约**：根据摘要和谓词约束生成 stub
4. **迭代优化**：根据 KLEE 结果调整 stub

## 完整流程

```
┌─────────────────────────────────────────────────────────────┐
│  输入: 待测函数名称（如 PathCombineW）                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 1: 静态分析 - 找到依赖函数                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 读取源码     │ →  │ AST 解析     │ →  │ 提取调用     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│  输出: ["PathIsRelativeW", "lstrlenW", "lstrcpyW"]          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 2: RAG 查询 - 获取依赖函数的摘要                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 查询索引     │ →  │ 读取签名     │ →  │ LLM 生成摘要 │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│  输出: 每个函数的签名、功能描述、参数说明                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 3: 谓词分析 - 找到目标分支条件                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 分析控制流   │ →  │ 提取条件     │ →  │ 识别关键变量 │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│  输出: ["result == TRUE", "result == FALSE"]                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 4: LLM 生成 ODA 规约                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 构建 prompt  │ →  │ LLM 推理     │ →  │ 生成 JSON    │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│  输出: ODA 规约 JSON 文件                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 5: 生成 stub 代码                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 解析 JSON    │ →  │ 生成 C 代码  │ →  │ oda_stubs.c  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  步骤 6: KLEE 测试 + 迭代优化                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ KLEE 执行    │ →  │ 分析结果     │ →  │ 调整 stub    │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 详细说明

### 步骤 1: 静态分析 - 找到依赖函数

**目的**：自动识别待测函数调用了哪些外部函数

**方法**：
1. 使用 RAG 模块读取函数源码
2. 使用 AST 解析器（如 pycparser）提取函数调用
3. 过滤掉标准库函数和内部函数

**示例**：

```python
from rag.query import HierarchicalQuery
import re

def find_dependencies(dll_name, file_name, func_name, wine_root):
    """找到函数的依赖"""
    hq = HierarchicalQuery("rag/index.json", wine_root)
    
    # 方法 1: 从索引中读取（快速）
    func_info = hq.get_function_info(dll_name, file_name, func_name)
    dependencies = func_info.get("dependencies", [])
    
    # 方法 2: 读取源码并解析（更准确）
    code = hq.get_function_code(dll_name, file_name, func_name)
    
    # 简单的正则匹配函数调用
    # 格式: function_name(
    pattern = r'\b([a-zA-Z_]\w+)\s*\('
    calls = re.findall(pattern, code)
    
    # 过滤掉关键字和常见函数
    keywords = {'if', 'while', 'for', 'switch', 'return', 'sizeof'}
    dependencies = [c for c in set(calls) if c not in keywords]
    
    return dependencies

# 使用示例
deps = find_dependencies("shlwapi", "path.c", "PathCombineW", "../wine")
print(deps)
# 输出: ["PathIsRelativeW", "lstrlenW", "lstrcpyW", "PathCanonicalizeW"]
```

**为什么这么做？**
- 自动化：不需要手工查看代码
- 准确：基于实际的函数调用
- 快速：利用已有的索引

### 步骤 2: RAG 查询 - 获取依赖函数的摘要

**目的**：为每个依赖函数获取签名和功能描述

**方法**：
1. 使用 RAG 查询获取函数元数据
2. 如果摘要不存在，使用 LLM 生成

**示例**：

```python
def get_function_summary(dep_func, hq, llm):
    """获取依赖函数的摘要"""
    
    # 1. 尝试在索引中查找
    results = hq.search_functions(dep_func, max_results=1)
    
    if results:
        func = results[0]
        return {
            "name": func["name"],
            "signature": func["signature"],
            "summary": func["summary"],
            "dll": func["dll"],
            "file": func["file"]
        }
    
    # 2. 如果索引中没有摘要，使用 LLM 生成
    # 读取函数代码
    code = hq.get_function_code(func["dll"], func["file"], func["name"])
    
    prompt = f"""
    分析以下 C 函数，生成简洁的摘要（不超过 50 字）：
    
    ```c
    {code}
    ```
    
    输出格式（JSON）：
    {{
        "功能": "...",
        "输入": "...",
        "输出": "...",
        "副作用": "...",
        "边界情况": "..."
    }}
    """
    
    summary = llm.generate(prompt)
    return summary
```

**为什么这么做？**
- 优先使用缓存（索引中的摘要）
- 按需生成（只在需要时调用 LLM）
- 结构化输出（便于后续处理）

### 步骤 3: 谓词分析 - 找到目标分支条件

**目的**：识别待测函数中的关键分支，确定需要覆盖的路径

**方法**：
1. 解析函数的控制流（if, switch, while 等）
2. 提取条件表达式
3. 识别哪些条件依赖于外部函数的返回值

**示例**：

```python
def analyze_predicates(code):
    """分析函数中的谓词条件"""
    
    predicates = []
    
    # 简单的正则匹配 if 条件
    # 格式: if (condition)
    pattern = r'if\s*\(([^)]+)\)'
    conditions = re.findall(pattern, code)
    
    for cond in conditions:
        # 识别函数调用
        if '(' in cond:
            # 例如: if (PathIsRelativeW(file))
            func_call = re.search(r'(\w+)\s*\(', cond)
            if func_call:
                predicates.append({
                    "condition": cond,
                    "depends_on": func_call.group(1),
                    "type": "function_call"
                })
        else:
            # 例如: if (len > 0)
            predicates.append({
                "condition": cond,
                "type": "variable"
            })
    
    return predicates

# 示例
code = """
BOOL PathCombineW(LPWSTR dest, LPCWSTR dir, LPCWSTR file) {
    if (PathIsRelativeW(file)) {
        // 相对路径
        int len = lstrlenW(dir);
        if (len > 0) {
            lstrcpyW(dest, dir);
        }
    }
    return TRUE;
}
"""

predicates = analyze_predicates(code)
print(predicates)
# 输出:
# [
#   {"condition": "PathIsRelativeW(file)", "depends_on": "PathIsRelativeW", "type": "function_call"},
#   {"condition": "len > 0", "type": "variable"}
# ]
```

**为什么这么做？**
- 识别关键路径：知道哪些分支需要覆盖
- 确定依赖关系：知道哪些外部函数影响控制流
- 指导 stub 生成：为关键函数生成更精确的 stub

### 步骤 4: LLM 生成 ODA 规约

**目的**：根据函数摘要和谓词条件，让 LLM 生成 stub 的约束

**方法**：
1. 构建包含上下文的 prompt
2. LLM 推理生成约束
3. 输出 JSON 格式的 ODA 规约

**示例**：

```python
def generate_oda_spec_with_llm(target_func, dependencies, predicates, llm):
    """使用 LLM 生成 ODA 规约"""
    
    # 构建 prompt
    prompt = f"""
你是一个符号执行专家。请为函数 {target_func} 生成 ODA（On-Demand Abstraction）规约。

## 目标函数
{target_func}

## 依赖函数
{json.dumps(dependencies, indent=2, ensure_ascii=False)}

## 关键谓词（需要覆盖的分支）
{json.dumps(predicates, indent=2, ensure_ascii=False)}

## 任务
为每个依赖函数生成 stub，要求：

1. **分析影响**：判断该函数的返回值是否影响目标函数的控制流
   - 如果影响（出现在谓词中）→ 需要符号化返回值
   - 如果不影响 → 可以返回固定值或 noop

2. **生成约束**：
   - 边界情况：NULL 指针、空字符串、0 值等
   - 合理范围：返回值的最小/最大值
   - 充分条件：确保能触发目标谓词的所有分支

3. **输出格式**：JSON，包含：
   - name: 函数名
   - signature: 函数签名
   - abstraction.type: "symbolic_return" | "symbolic_output" | "noop"
   - abstraction.reason: 为什么选择这种抽象
   - abstraction.constraints: C 代码数组（每行一个字符串）

## 示例

对于 lstrlenW：
- 功能：返回宽字符串长度
- 影响：返回值用于 if (len > 0) 判断
- 约束：
  - NULL → 返回 0
  - 非 NULL → 返回符号化的长度（0 到 MAX_PATH）

输出 JSON：
```json
{{
  "target_function": "{target_func}",
  "dependencies": [
    {{
      "name": "lstrlenW",
      "signature": "int lstrlenW(LPCWSTR str)",
      "abstraction": {{
        "type": "symbolic_return",
        "reason": "返回值影响控制流（len > 0）",
        "constraints": [
          "if (str == NULL) return 0;",
          "int len;",
          "klee_make_symbolic(&len, sizeof(len), \\"lstrlenW_ret\\");",
          "klee_assume(len >= 0 && len <= 260);",
          "if (len > 0) klee_assume(str[0] != 0);",
          "return len;"
        ]
      }}
    }}
  ]
}}
```

现在请生成完整的 ODA 规约。
"""
    
    # 调用 LLM
    response = llm.generate(prompt)
    
    # 解析 JSON
    spec = json.loads(response)
    
    return spec
```

**为什么这么做？**
- **上下文丰富**：LLM 能看到完整的信息（函数摘要、谓词、目标）
- **推理能力**：LLM 能理解"哪些函数影响控制流"
- **生成约束**：LLM 能生成合理的 `klee_assume` 约束

### 步骤 5: 生成 stub 代码

这一步已经实现了（`specs/gen_oda_stub.py`），直接使用即可。

### 步骤 6: KLEE 测试 + 迭代优化

**目的**：根据 KLEE 的执行结果，调整 stub

**场景 1：KLEE 超时**
- **原因**：stub 的约束太宽松，状态空间太大
- **解决**：收紧约束

```python
def optimize_stub_for_timeout(spec, llm):
    """KLEE 超时时，收紧约束"""
    
    prompt = f"""
KLEE 执行超时，当前 stub 的约束可能太宽松。

当前约束：
{json.dumps(spec, indent=2)}

请收紧约束，例如：
- 减小范围：len <= 260 → len <= 32
- 限制字符：允许所有 Unicode → 只允许 ASCII
- 添加更多假设

输出修改后的 JSON。
"""
    
    improved_spec = llm.generate(prompt)
    return improved_spec
```

**场景 2：生成的测试用例太少**
- **原因**：stub 的约束太严格
- **解决**：放宽约束

```python
def optimize_stub_for_few_cases(spec, llm):
    """测试用例太少时，放宽约束"""
    
    prompt = f"""
KLEE 只生成了很少的测试用例，当前 stub 的约束可能太严格。

当前约束：
{json.dumps(spec, indent=2)}

请放宽约束，例如：
- 扩大范围：len <= 10 → len <= 100
- 移除不必要的假设

输出修改后的 JSON。
"""
    
    improved_spec = llm.generate(prompt)
    return improved_spec
```

## 完整示例：PathCombineW

让我创建一个完整的示例，展示如何为 `PathCombineW` 生成 ODA 规约。

见 `llm_integration/example_pathcombinew.py`
