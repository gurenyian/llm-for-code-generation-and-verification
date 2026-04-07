# RAG 模块：分层索引与检索

## 为什么需要分层索引？

Wine 项目有 **728 个 DLL 目录**，每个 DLL 包含多个 `.c` 文件，每个文件有几十个函数。如果一次性把所有函数信息给 LLM：

❌ **问题**：
- Token 消耗巨大（可能超过 100 万 token）
- LLM 难以聚焦关键信息
- 检索效率低

✅ **解决方案**：Hierarchical RAG
- 第一层：只看 DLL 列表（728 个）
- 第二层：选定 DLL 后，看文件列表（~10 个）
- 第三层：选定文件后，看函数摘要（~50 个）
- 第四层：选定函数后，看完整代码

## 索引结构

```json
{
  "schema_version": 2,
  "summary_mode": "static|llm|hybrid",
  "generated_at": "2026-03-18T12:00:00Z",
  "dlls": {
    "shlwapi": {
      "description": "Shell Light-weight Utility Library",
      "files": {
        "path.c": {
          "description": "Path manipulation functions",
          "functions": [
            {
              "name": "PathIsRelativeW",
              "signature": "BOOL PathIsRelativeW(LPCWSTR lpszPath)",
              "summary": "Determines if a path string is relative",
              "line_start": 1234,
              "line_end": 1250,
              "dependencies": ["lstrlenW"],
              "complexity": "low",
              "static_summary": "...",
              "llm_summary": "..."
            }
          ]
        }
      }
    }
  }
}
```

## 使用方法

### 1. 构建索引

```bash
python build_index.py /path/to/wine/dlls -o index.json
```

**LLM 摘要（可选）**：

```bash
python build_index.py /path/to/wine/dlls -o index.json --summary-mode llm --llm-limit 100
```

```bash
python build_index.py /path/to/wine/dlls -o index.json --summary-mode hybrid --prev-index index.json
```

**这一步做什么？**
- 递归扫描 `dlls/` 目录
- 解析每个 `.c` 文件的 AST（抽象语法树）
- 提取函数签名、注释、依赖关系
- 生成三层 JSON 索引

**为什么要这么做？**
- 一次性构建，多次查询（避免重复解析）
- 支持快速的层级导航
- 可以缓存 LLM 生成的摘要（避免重复调用 LLM）

### 2. 查询索引

```python
from query import HierarchicalQuery

hq = HierarchicalQuery("index.json")

# 第一层：列出所有 DLL
dlls = hq.list_dlls()
# 返回: ["shlwapi", "kernel32", "user32", ...]

# 第二层：列出 shlwapi 的文件
files = hq.list_files("shlwapi")
# 返回: ["path.c", "string.c", "reg.c", ...]

# 第三层：列出 path.c 的函数（只返回摘要）
functions = hq.list_functions("shlwapi", "path.c")
# 返回: [
#   {"name": "PathIsRelativeW", "signature": "BOOL PathIsRelativeW(LPCWSTR)", "summary": "..."},
#   ...
# ]

# 第四层：获取完整代码
code = hq.get_function_code("shlwapi", "path.c", "PathIsRelativeW")
# 返回完整的函数实现
```

## 与 LLM 集成

### 场景：LLM 需要实现 `PathCombineW`

**第一轮对话**：
```
User: 帮我实现 PathCombineW
LLM: 让我先找到相关代码...
     [调用] hq.list_dlls() 
     [结果] 找到 shlwapi
```

**第二轮对话**：
```
LLM: [调用] hq.list_files("shlwapi")
     [结果] 找到 path.c
```

**第三轮对话**：
```
LLM: [调用] hq.list_functions("shlwapi", "path.c")
     [结果] 发现 PathCombineW 和相关函数：
     - PathIsRelativeW (判断相对路径)
     - PathCanonicalizeW (规范化路径)
     - PathAddBackslashW (添加反斜杠)
```

**第四轮对话**：
```
LLM: 我需要参考 PathIsRelativeW 的实现
     [调用] hq.get_function_code("shlwapi", "path.c", "PathIsRelativeW")
     [结果] 获取完整代码
```

**优势**：
- 每次只传输必要的信息（节省 token）
- LLM 可以"探索式"学习代码库
- 支持增量式代码生成

## 函数摘要生成

### 静态提取（优先）

从代码中直接提取：
- 函数签名（参数、返回值）
- 注释（Doxygen 风格）
- 调用的外部函数

```c
/**
 * PathIsRelativeW
 * 
 * Determines whether a path string is relative.
 * 
 * @param lpszPath  Pointer to a null-terminated string
 * @return TRUE if relative, FALSE if absolute or NULL
 */
BOOL WINAPI PathIsRelativeW(LPCWSTR lpszPath)
{
    if (!lpszPath || !*lpszPath)
        return TRUE;
    
    if (lpszPath[0] == '\\' || lpszPath[1] == ':')
        return FALSE;
    
    return TRUE;
}
```

**提取结果**：
```json
{
  "signature": "BOOL PathIsRelativeW(LPCWSTR lpszPath)",
  "summary": "Determines whether a path string is relative",
  "params": [
    {"name": "lpszPath", "type": "LPCWSTR", "desc": "Pointer to a null-terminated string"}
  ],
  "returns": "TRUE if relative, FALSE if absolute or NULL",
  "dependencies": []
}
```

### LLM 增强（可选）

如果注释不完整，可以调用 LLM 生成摘要：

```python
def generate_summary(function_code):
    prompt = f"""
    分析以下 C 函数，生成简洁的摘要（不超过 50 字）：
    
    {function_code}
    
    摘要格式：
    - 功能：...
    - 输入：...
    - 输出：...
    - 边界情况：...
    """
    return llm.generate(prompt)
```

**缓存策略**：
- 首次生成后，保存到 `index.json`
- 下次查询直接返回缓存
- 避免重复调用 LLM（节省成本）

## 实现细节

见 `build_index.py` 和 `query.py`
