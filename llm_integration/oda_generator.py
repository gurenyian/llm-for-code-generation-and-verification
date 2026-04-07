#!/usr/bin/env python3
"""
ODA 规约生成器：使用 LLM 自动生成 stub 规约

用法:
    from oda_generator import ODAGenerator
    
    generator = ODAGenerator(llm_client)
  spec = generator.generate("PathCombineW", dependencies, predicates)  # 生成 ODA 规约
"""

import json
from typing import List, Dict, Any


def _group_predicates_by_dependency(predicates: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
  """将结构化谓词按 depends_on 分组，便于生成针对性的 stub 约束。

  兼容旧格式 predicates（可能只有 condition/description/line/type 等字段）。
  """
  grouped: Dict[str, List[Dict[str, Any]]] = {}
  for p in predicates or []:
    dep = p.get("depends_on")
    if not dep:
      continue
    grouped.setdefault(str(dep), []).append(p)
  return grouped


def _render_predicate_hint(p: Dict[str, Any]) -> str:
    """把单条结构化谓词渲染成 LLM 更容易消费的要点。"""
    kind = p.get("kind") or p.get("type") or "unknown"
    cond = p.get("condition", "")
    line = p.get("line")

    # 提取结构化信息（如果存在）
    variable = p.get("variable")
    op = p.get("op")
    rhs = p.get("rhs")
    polarity = p.get("polarity")

    bits = [f"kind={kind}"]
    if variable:
        bits.append(f"var={variable}")
    if op and rhs is not None:
        bits.append(f"cmp={op} {rhs}")
    if polarity is not None:
        bits.append(f"polarity={polarity}")
    if line is not None:
        bits.append(f"line={line}")
    meta = ", ".join(bits)

    if cond:
        return f"- {cond}  ({meta})"
    return f"- ({meta})"


class ODAGenerator:
    """ODA 规约生成器"""
    
    def __init__(self, llm_client):
        """
        初始化
        
        Args:
            llm_client: LLM 客户端（需要实现 generate 方法）
        """
        self.llm = llm_client
    
    def generate(self, target_func: str, dependencies: List[Dict], 
                predicates: List[Dict]) -> Dict:
        """
        生成 ODA 规约
        
        Args:
            target_func: 目标函数名
            dependencies: 依赖函数列表（来自 DependencyAnalyzer）
            predicates: 谓词条件列表（来自 DependencyAnalyzer）
        
        Returns:
            ODA 规约（JSON 格式）
        """
        print(f"为 {target_func} 生成 ODA 规约...")
        
        # 1. 构建 prompt
        prompt = self._build_prompt(target_func, dependencies, predicates)
        
        # 2. 调用 LLM
        print("  调用 LLM...")
        response = self.llm.generate(prompt)
        
        # 3. 清理响应（移除 markdown 代码块）
        response = response.strip()
        if response.startswith("```json"):
            response = response[7:]  # 移除 ```json
        elif response.startswith("```"):
            response = response[3:]  # 移除 ```
        if response.endswith("```"):
            response = response[:-3]  # 移除 ```
        response = response.strip()
        
        # 4. 解析响应
        try:
            spec = json.loads(response)
            print(f"  ✓ 生成了 {len(spec.get('dependencies', []))} 个 stub")
            return spec
        except json.JSONDecodeError as e:
            print(f"  ✗ JSON 解析失败: {e}")
            print(f"  响应: {response[:500]}...")
            raise
    
    def _build_prompt(self, target_func: str, dependencies: List[Dict], 
                     predicates: List[Dict]) -> str:
        """构建 LLM prompt"""

        # 把结构化 ψ 信息聚合成“依赖→分支覆盖要点”，让 LLM 更容易生成接近最小的约束。
        pred_by_dep = _group_predicates_by_dependency(predicates)
        dep_coverage_hints: Dict[str, Any] = {}
        for dep_name, ps in pred_by_dep.items():
            dep_coverage_hints[dep_name] = {
                "predicate_count": len(ps),
                "hints": [_render_predicate_hint(p) for p in ps[:20]],
            }
        dep_coverage_hints_json = json.dumps(dep_coverage_hints, indent=2, ensure_ascii=False)
        
        prompt = f"""# Role
你是一个资深的程序分析专家，精通 C/C++ 语言、Windows 内部 API 语义以及 KLEE 符号执行技术。你的任务是为函数 `{{{{TargetFunctionName}}}}` 生成 ODA（On-Demand Abstraction）打桩代码（Stubs）。

# Context
我们正在进行 Wine 与真实 Windows API 的差异化测试（Differential Testing）。KLEE 生成的测试用例最终将在真实 Windows 上运行。因此，Stub 代码必须兼顾“路径探索效率”与“逻辑真实性”。

# Classification & Strategy (核心逻辑)
请分析 {{{{TargetFunctionName}}}} 中的每一个外部依赖函数，并将其归类为以下四种抽象策略之一：

1. **Semantic_Binding (控制流决策点)**
   - **适用条件**：函数返回值直接进入 `if/else`、`switch` 或循环判定。
   - **实现方法**：符号化返回值 + 强制语义绑定。
   - **关键要求**：必须根据文档逻辑，使用 `klee_assume` 将输入参数的状态与返回值强行绑定。
   - **示例**：`PathIsUNCW(p)` 返回 1 时，必须 `klee_assume(p[0]=='\\' && p[1]=='\\')`。

2. **Bounded_Concrete (内存操作搬运工)**
   - **适用条件**：基础字符串操作（strlen, strcpy, strcat, memcmp 等）。
   - **实现方法**：手写极简的 C 逻辑，严禁使用符号化返回值。
   - **关键要求**：必须带上硬编码的长度上限（建议 Max 64），防止路径爆炸；必须真实修改内存，确保数据流连通。

3. **Symbolic_Output (数据提供者)**
   - **适用条件**：通过指针参数返回复杂结构体或数据的函数。
   - **实现方法**：对输出指针指向的内存进行 `klee_make_symbolic`，并根据文档约束其字段的合法取值范围。

4. **No-op (环境噪音)**
   - **适用条件**：TRACE, WARN, FIXME, 性能统计等不影响程序逻辑的函数。
   - **实现方法**：直接返回固定值或空操作。

# Strict Rules (铁律)
1. **防范假阳性**：严禁生成在真实 Windows 上永远不可能发生的输入组合。如果 `ret` 为假，必须约束输入参数不满足该函数的成功条件。
2. **防范路径爆炸**：Stub 内部禁止调用其他非基础函数。所有循环必须有 `i < 64` 这种硬性跳出约束。
3. **符号命名**：`klee_make_symbolic` 的名称必须唯一且使用双引号字面量，例如 `"oda_PathIsRelativeW_ret"`。
4. **编译兼容性**：所有 Stub 必须包含正确的返回类型，即使是 `noop` 也应返回合理的默认值（如 NULL 或 TRUE），避免编译警告。
5. **语义绑定模板**：凡是 Semantic_Binding，必须显式写出 `ret` 与输入条件的双向绑定（ret=1/0 分支都要有 klee_assume）。
6. **数据流优先**：若依赖项包含 `mutability.has_mutable_pointer=true` 或 `data_flow_notes` 提示该函数写入参数且后续被使用，则禁止 No-op，必须用 **Bounded_Concrete** 或 **Symbolic_Output** 建模写入效果。

# Semantic_Binding Template
若某函数语义为“返回真当且仅当满足条件 C”，必须按以下模板生成：
```c
BOOL WINAPI Func(T1 a, ...) {{
  int ret = klee_make_symbolic_int("oda_Func_ret");
  klee_assume(ret == 0 || ret == 1);
  // 必要的非空/边界约束
  if (ret) {{
    // ret==1 => 条件成立
    klee_assume(C);
  }} else {{
    // ret==0 => 条件不成立
    klee_assume(!(C));
  }}
  return ret;
}}
```

# Output Format
必须覆盖所有依赖函数（依赖列表中的每个函数都要输出），不允许遗漏。
如果依赖项不是函数（例如宏/内联 helper，如 ARRAY_SIZE），也必须输出一个条目，
在 stub_code 中给出等价的 #define 或 inline 实现，以确保编译通过。
依赖名称必须与列表中的 name 完全一致。
请以 JSON 格式输出规约，结构如下：
{{
  "target_function": "函数名",
  "dependencies": [
    {{
      "function": "被调用函数名",
      "strategy": "上述四类之一",
      "reasoning": "为什么要选这个策略，它在目标函数中起什么作用",
      "stub_code": "完整的 C 语言打桩代码实现"
    }}
  ]
}}

只输出 JSON，不要有任何开场白或解释文字。

# Target Function
{target_func}

# Required dependency names (must all appear in output)
{json.dumps([d.get("name") for d in dependencies if d.get("name")], indent=2, ensure_ascii=False)}

# Dependencies to stub (full metadata)
{json.dumps(dependencies, indent=2, ensure_ascii=False)}

# Predicates
{json.dumps(predicates, indent=2, ensure_ascii=False)}
"""
        
        return prompt
    
    def optimize_for_timeout(self, spec: Dict) -> Dict:
        """KLEE 超时时，收紧约束"""
        
        prompt = f"""KLEE 执行超时，当前 stub 的约束可能太宽松，导致状态空间爆炸。

当前规约：
```json
{json.dumps(spec, indent=2, ensure_ascii=False)}
```

请收紧约束，方法：
1. 减小范围：`len <= 260` → `len <= 32`
2. 限制字符：允许所有 Unicode → 只允许 ASCII（`< 128`）
3. 添加更多假设：例如限制字符串只包含字母和数字

输出修改后的完整 JSON（只输出 JSON，不要其他文字）。
"""
        
        response = self.llm.generate(prompt)
        return json.loads(response)
    
    def optimize_for_few_cases(self, spec: Dict, case_count: int) -> Dict:
        """测试用例太少时，放宽约束"""
        
        prompt = f"""KLEE 只生成了 {case_count} 个测试用例，当前 stub 的约束可能太严格。

当前规约：
```json
{json.dumps(spec, indent=2, ensure_ascii=False)}
```

请放宽约束，方法：
1. 扩大范围：`len <= 10` → `len <= 100`
2. 移除不必要的假设
3. 允许更多的边界情况

输出修改后的完整 JSON（只输出 JSON，不要其他文字）。
"""
        
        response = self.llm.generate(prompt)
        return json.loads(response)


class MockLLM:
    """模拟 LLM（用于测试）"""
    
    def generate(self, prompt: str) -> str:
        """返回预定义的响应"""
        
        # 检查是否是 lstrcatW（从 prompt 中判断）
        if "lstrcatW" in prompt or "lstrcat" in prompt:
            return self._generate_lstrcatw_spec()
        elif "PathCombineW" in prompt:
            return self._generate_pathcombinew_spec()
        else:
            # 默认返回通用的响应
            return self._generate_lstrcatw_spec()
    
    def _generate_lstrcatw_spec(self) -> str:
        """生成 lstrcatW 的规约"""
        return """{
  "target_function": "lstrcatW",
  "description": "Appends one string to another",
  "dependencies": [
    {
      "name": "lstrlenW",
      "signature": "int lstrlenW(LPCWSTR str)",
      "description": "Returns the length of a wide string",
      "abstraction": {
        "type": "symbolic_return",
        "reason": "返回值用于确定追加位置，影响控制流",
        "constraints": [
          "if (str == NULL) return 0;",
          "",
          "int len;",
          "klee_make_symbolic(&len, sizeof(len), \\"lstrlenW_ret\\");",
          "klee_assume(len >= 0 && len <= 32);",
          "if (len > 0) klee_assume(str[0] != 0);",
          "",
          "return len;"
        ]
      }
    }
  ],
  "target_predicates": [
    {
      "description": "Destination is NULL",
      "condition": "dest == NULL"
    },
    {
      "description": "Source is NULL",
      "condition": "src == NULL"
    },
    {
      "description": "Destination length is greater than 0",
      "condition": "lstrlenW(dest) > 0"
    }
  ]
}"""
    
    def _generate_pathcombinew_spec(self) -> str:
        """生成 PathCombineW 的规约"""
        return """{
  "target_function": "PathCombineW",
  "description": "Combines two path strings into one",
  "dependencies": [
    {
      "name": "PathIsRelativeW",
      "signature": "BOOL PathIsRelativeW(LPCWSTR path)",
      "description": "Determines if a path is relative",
      "abstraction": {
        "type": "symbolic_return",
        "reason": "返回值直接用于 if 条件判断，影响控制流",
        "constraints": [
          "if (path == NULL) return TRUE;",
          "BOOL ret;",
          "klee_make_symbolic(&ret, sizeof(ret), \\"PathIsRelativeW_ret\\");",
          "return ret;"
        ]
      }
    },
    {
      "name": "lstrlenW",
      "signature": "int lstrlenW(LPCWSTR str)",
      "description": "Returns the length of a wide string",
      "abstraction": {
        "type": "symbolic_return",
        "reason": "返回值用于长度检查和内存分配",
        "constraints": [
          "if (str == NULL) return 0;",
          "int len;",
          "klee_make_symbolic(&len, sizeof(len), \\"lstrlenW_ret\\");",
          "klee_assume(len >= 0 && len <= 260);",
          "if (len > 0) klee_assume(str[0] != 0);",
          "return len;"
        ]
      }
    },
    {
      "name": "lstrcpyW",
      "signature": "LPWSTR lstrcpyW(LPWSTR dest, LPCWSTR src)",
      "description": "Copies a wide string",
      "abstraction": {
        "type": "noop",
        "reason": "返回值通常不用于条件判断，可以简化",
        "constraints": [
          "if (dest == NULL || src == NULL) return dest;",
          "return dest;"
        ]
      }
    }
  ],
  "target_predicates": [
    {
      "description": "File path is relative",
      "condition": "PathIsRelativeW(file) == TRUE"
    },
    {
      "description": "File path is absolute",
      "condition": "PathIsRelativeW(file) == FALSE"
    },
    {
      "description": "Directory path is not empty",
      "condition": "lstrlenW(dir) > 0"
    }
  ]
}"""


def demo():
    """演示用法"""
    
    # 模拟依赖和谓词
    dependencies = [
        {
            "name": "PathIsRelativeW",
            "signature": "BOOL PathIsRelativeW(LPCWSTR path)",
            "summary": "Determines if a path string is relative",
            "dll": "shlwapi",
            "file": "path.c",
            "call_count": 1
        },
        {
            "name": "lstrlenW",
            "signature": "int lstrlenW(LPCWSTR str)",
            "summary": "Returns the length of a wide string",
            "dll": "kernel32",
            "file": "string.c",
            "call_count": 2
        }
    ]
    
    predicates = [
        {
            "condition": "PathIsRelativeW(file)",
            "depends_on": "PathIsRelativeW",
            "type": "function_call",
            "line": 10
        },
        {
            "condition": "len > 0",
            "type": "variable",
            "line": 15
        }
    ]
    
    # 使用模拟 LLM
    llm = MockLLM()
    generator = ODAGenerator(llm)
    
    # 生成规约
    spec = generator.generate("PathCombineW", dependencies, predicates)
    
    # 输出
    print(json.dumps(spec, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    demo()
