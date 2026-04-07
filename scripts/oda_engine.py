#!/usr/bin/env python3
"""ODA 规约生成引擎（LLM 驱动）。

读取 context_slice.json，调用 LLM 输出 JSON 规约，然后生成 oda_stubs.c。
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import requests

PROMPT = """# Role
你是一个资深的程序分析专家，精通 C/C++ 语言、Windows 内部 API 语义以及 KLEE 符号执行技术。你的任务是为函数 `{{TargetFunctionName}}` 生成 ODA（On-Demand Abstraction）打桩代码（Stubs）。

# Context
我们正在进行 Wine 与真实 Windows API 的差异化测试（Differential Testing）。KLEE 生成的测试用例最终将在真实 Windows 上运行。因此，Stub 代码必须兼顾“路径探索效率”与“逻辑真实性”。

# Classification & Strategy (核心逻辑)
请分析 {{TargetFunctionName}} 中的每一个外部依赖函数，并将其归类为以下四种抽象策略之一：

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

# Output Format
请以 JSON 格式输出规约，结构如下：
{
  "target_function": "函数名",
  "dependencies": [
     {
        "function": "被调用函数名",
        "strategy": "上述四类之一",
        "reasoning": "为什么要选这个策略，它在目标函数中起什么作用",
        "stub_code": "完整的 C 语言打桩代码实现"
     }
  ]
}

只输出 JSON，不要有任何开场白或解释文字。

# Dependencies to stub:
{Deps}
"""


def call_llm(prompt: str) -> str:
    api_key = os.environ.get("ODA_LLM_API_KEY") or os.environ.get("OPENAI_API_KEY")
    api_base = os.environ.get("ODA_LLM_BASE_URL") or os.environ.get("OPENAI_API_BASE", "https://api.openai.com/v1")
    model = os.environ.get("ODA_LLM_MODEL") or os.environ.get("OPENAI_MODEL", "gpt-4o")
    if not api_key:
        return "[]"

    resp = requests.post(
        f"{api_base}/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": model,
            "messages": [
                {"role": "system", "content": "You are a precise program analysis assistant."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.1,
        },
        timeout=60,
    )
    return resp.json().get("choices", [{}])[0].get("message", {}).get("content", "")


def main() -> None:
    slice_path = Path("context_slice.json")
    if not slice_path.exists():
        raise SystemExit("context_slice.json not found")

    data = json.loads(slice_path.read_text(encoding="utf-8"))
    deps_text = json.dumps(data.get("dependencies", {}), indent=2, ensure_ascii=False)
    prompt = PROMPT.replace("{{TargetFunctionName}}", data["target_function"]).replace("{Deps}", deps_text)

    response = call_llm(prompt)
    cleaned = response.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    payload = match.group(0) if match else cleaned
    spec = json.loads(payload) if payload else {}

    Path("oda_spec.json").write_text(json.dumps(spec, indent=2, ensure_ascii=False), encoding="utf-8")
    dependencies = spec.get("dependencies", []) if isinstance(spec, dict) else []
    with open("oda_stubs.c", "w", encoding="utf-8") as f:
        f.write("#include <klee/klee.h>\n#include <stddef.h>\n\n")
        for item in dependencies:
            f.write(f"// {item.get('function')} | {item.get('strategy')}\n")
            f.write(f"{item.get('stub_code')}\n\n")

    print("[oda_engine] wrote oda_stubs.c and oda_spec.json")


if __name__ == "__main__":
    main()
