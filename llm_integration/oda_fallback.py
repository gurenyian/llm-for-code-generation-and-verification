#!/usr/bin/env python3
"""基于结构化 ψ 的 ODA spec fallback 生成器。

动机：
- 在没有真实 LLM，或 LLM 返回 JSON 不可解析时，仍然能生成“足够合理”的 ODA 规约，
  让 `specs/gen_oda_stub.py` 可以产出可编译的 stub。

设计目标（最小可跑）：
- 只依赖 `dependencies`（函数名/签名/summary）和 `predicates`（结构化 ψ，尤其 `depends_on`）。
- 对出现在 ψ 的依赖函数给出 `symbolic_return`，并尽量覆盖比较边界（例如 >= MAX_PATH）。
- 对未出现在 ψ 的依赖函数默认 `noop`。

注意：这里的 fallback 不是“最优约束”，而是一个可自动收紧/放宽的 baseline。
"""

from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class CompareHint:
    op: str
    rhs: str
    polarity: Optional[bool] = None


def _extract_compare_hints(predicates: List[Dict[str, Any]], dep_name: str) -> List[CompareHint]:
    hints: List[CompareHint] = []
    for p in predicates or []:
        if str(p.get("depends_on")) != dep_name:
            continue
        op = p.get("op")
        rhs = p.get("rhs")
        if not op or rhs is None:
            continue
        hints.append(CompareHint(op=str(op), rhs=str(rhs), polarity=p.get("polarity")))
    return hints


def _default_int_range_for_rhs(rhs: str) -> Tuple[int, int]:
    # 尽量别太宽，先用一个保守范围。
    if rhs in {"MAX_PATH", "PATH_MAX"}:
        return 0, 260
    return 0, 32


def _boundary_values_from_hint(h: CompareHint, default_lo: int, default_hi: int) -> List[int]:
    # 用于覆盖比较边界两侧值。仅适用于 rhs 是常量宏/整数（宏我们仍用默认范围）。
    lo, hi = default_lo, default_hi
    # 对宏 rhs（如 MAX_PATH）我们无法在 Python 侧求出数值；仍用默认 (0..260)
    # 但会尝试提供“0/1/hi-1/hi” 这样的边界值。
    if hi - lo >= 2:
        base = [lo, lo + 1, hi - 1, hi]
    else:
        base = [lo, hi]
    # 去重并限制在区间
    out: List[int] = []
    for v in base:
        if v < lo or v > hi:
            continue
        if v not in out:
            out.append(v)
    return out


def _classify_dependency(name: str, signature_raw: str) -> str:
    sig = (signature_raw or "").strip()
    if name and name.isupper():
        return "macro"
    if "ARRAY_SIZE" in name or "ARRAY_SIZE" in sig:
        return "macro"
    if sig.startswith("for ") or sig.startswith("for("):
        return "macro"
    return "function"


def _sanitize_signature(signature_raw: str, name: str, dep_kind: str) -> str:
    sig = signature_raw or ""
    sig = re.sub(r"/\*.*?\*/", "", sig, flags=re.S)
    sig = re.sub(r"\s+", " ", sig).strip()
    if dep_kind == "macro":
        return f"{name}(arr)" if name else sig
    if name:
        m = re.search(rf"[A-Za-z_][\w\s\*]*\b{re.escape(name)}\s*\([^)]*\)", sig)
        if m:
            return m.group(0).strip()
    if "(" in sig and ")" in sig and "..." not in sig:
        return sig
    lname = (name or "").lower()
    if "lstrlen" in lname:
        return f"int {name}(const WCHAR *str)"
    if "lstrcpyn" in lname:
        return f"LPWSTR {name}(LPWSTR dst, LPCWSTR src, INT n)"
    if "lstrcat" in lname:
        return f"LPWSTR {name}(LPWSTR dst, LPCWSTR src)"
    if "pathaddbackslashw" == lname:
        return f"LPWSTR {name}(WCHAR *path)"
    if "pathcanonicalizew" == lname:
        return f"BOOL {name}(WCHAR *buffer, const WCHAR *path)"
    if "pathstriptorootw" == lname:
        return f"BOOL {name}(WCHAR *path)"
    if "pathisrelativew" == lname or "pathisuncw" == lname:
        return f"BOOL {name}(const WCHAR *path)"
    return f"int {name}(void)" if name else sig


def _signature_returns_void(signature: str) -> bool:
    sig = (signature or "").strip()
    return bool(re.match(r"^void\b", sig))


def generate_fallback_spec(
    target_func: str,
    dependencies: List[Dict[str, Any]],
    predicates: List[Dict[str, Any]],
    description: str = "",
) -> Dict[str, Any]:
    pred_deps = {str(p.get("depends_on")) for p in (predicates or []) if p.get("depends_on")}

    spec: Dict[str, Any] = {
        "target_function": target_func,
        "description": description or f"Auto fallback spec for {target_func}",
        "dependencies": [],
        "target_predicates": [],
    }

    # target_predicates：尽量保持人类可读
    for p in predicates or []:
        cond = p.get("condition")
        if not cond:
            continue
        spec["target_predicates"].append(
            {
                "description": p.get("description") or p.get("kind") or "predicate",
                "condition": cond,
            }
        )

    for dep in dependencies or []:
        name = str(dep.get("name", ""))
        signature_raw = dep.get("signature") or dep.get("signature_raw") or ""
        dep_kind = dep.get("kind") or _classify_dependency(name, signature_raw)
        sig = _sanitize_signature(signature_raw, name, dep_kind) or f"void {name}()"
        dep_desc = dep.get("summary") or dep.get("description") or ""
        dep_desc = dep_desc.replace("/*", "").replace("*/", "")

        if not name:
            continue

        if dep_kind == "macro":
            spec["dependencies"].append(
                {
                    "name": name,
                    "signature": sig,
                    "description": dep_desc,
                    "kind": dep_kind,
                    "abstraction": {
                        "type": "macro",
                        "reason": "Fallback: treat dependency as macro/inline helper.",
                        "constraints": [],
                    },
                }
            )
            continue

        if name in pred_deps:
            # 目前只做最常见的 int/BOOL 返回值约束（让 gen_oda_stub.py 去解析返回类型）。
            hints = _extract_compare_hints(predicates, name)

            lo, hi = 0, 32
            # 如果 ψ 里比较用了 MAX_PATH，扩大范围
            if any(h.rhs in {"MAX_PATH", "PATH_MAX"} for h in hints):
                lo, hi = _default_int_range_for_rhs("MAX_PATH")

            constraints: List[str] = []

            # 常见的 NULL 输入短路（如果 signature 里有 LPCWSTR/LPWSTR/void* 等）
            if "LPCWSTR" in sig or "LPWSTR" in sig or "*" in sig:
                # 只加一个最通用的检查（不保证参数名存在，但 C 里未定义会编译失败）
                # 因此这里不引用参数名，只做返回值的符号化。
                pass

            constraints.extend(
                [
                    "int ret;",
                    f'klee_make_symbolic(&ret, sizeof(ret), "{name}_ret");',
                    f"klee_assume(ret >= {lo} && ret <= {hi});",
                ]
            )

            # 为了引导 KLEE 覆盖边界：增加一个偏向边界值的选择（非必须，但通常有帮助）
            # 用 if 链增加路径分支（可后续被 timeout optimizer 收紧）。
            boundary_vals: List[int] = []
            for h in hints:
                boundary_vals.extend(_boundary_values_from_hint(h, lo, hi))
            # 去重
            b_unique: List[int] = []
            for v in boundary_vals:
                if v not in b_unique:
                    b_unique.append(v)
            if b_unique:
                # 通过 klee_assume(ret == v) 这种硬约束会过强；我们用分支+assume 做可选枚举。
                # 这里生成一个 selector，避免 ret 额外被收紧到单值。
                constraints.append("unsigned char sel;")
                constraints.append(f'klee_make_symbolic(&sel, sizeof(sel), "{name}_sel");')
                constraints.append(f"klee_assume(sel < {min(len(b_unique), 8)});")
                for i, v in enumerate(b_unique[:8]):
                    constraints.append(f"if (sel == {i}) ret = {v};")

            constraints.append("return ret;")

            spec["dependencies"].append(
                {
                    "name": name,
                    "signature": sig,
                    "description": dep_desc,
                    "kind": dep_kind,
                    "abstraction": {
                        "type": "symbolic_return",
                        "reason": "Fallback: function appears in structured predicates (depends_on), so its return impacts control-flow.",
                        "constraints": constraints,
                    },
                }
            )
        else:
            constraints = ["// noop stub"]
            if _signature_returns_void(sig):
                constraints.append("return")
            else:
                constraints.append("return 0")
            spec["dependencies"].append(
                {
                    "name": name,
                    "signature": sig,
                    "description": dep_desc,
                    "kind": dep_kind,
                    "abstraction": {
                        "type": "noop",
                        "reason": "Fallback: dependency not referenced by predicates; use a minimal stub.",
                        "constraints": constraints,
                    },
                }
            )

    return spec
