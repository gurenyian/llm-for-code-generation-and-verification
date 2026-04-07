#!/usr/bin/env python3
"""从 RAG 索引 + Wine 源码提取依赖/ψ，并生成 ODA spec + C stub（端到端自检用）。

这个脚本把我们目前完成的几块能力串起来：
- `DependencyAnalyzer`：依赖函数 + 结构化 ψ
- `ODAGenerator`：prompt 生成（这里默认使用 MockLLM；也可接真实 LLM client）
- `oda_fallback.generate_fallback_spec()`：当 LLM 输出不可解析时自动降级
- `specs/gen_oda_stub.py`：把 spec JSON 变成 `oda_stubs.c`

用法示例（当前仓库已验证过的函数）：
- PathAddBackslashW（kernelbase/path.c）

注意：
- 该脚本不会运行 KLEE；目标是先把“ψ→spec→C stub”打通并可编译。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List

import sys

from dependency_analyzer import DependencyAnalyzer
from oda_generator import ODAGenerator, MockLLM
from oda_fallback import generate_fallback_spec


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True, help="RAG index json (e.g. rag/_self_check_index.json)")
    ap.add_argument("--wine-root", required=True, help="Wine repo root (e.g. d:/wine/wine-master)")
    ap.add_argument("--dll", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--func", required=True)
    ap.add_argument("--out-spec", default="", help="Output spec json path")
    ap.add_argument("--out-stub", default="", help="Output stub c path")
    ap.add_argument("--use-mock-llm", action="store_true", help="Use MockLLM (default true)")

    args = ap.parse_args()

    index_path = Path(args.index)
    wine_root = Path(args.wine_root)

    index = json.loads(index_path.read_text(encoding="utf-8"))

    dll_rec = index.get("dlls", {}).get(args.dll)
    if not dll_rec:
        raise SystemExit(f"dll not found in index: {args.dll}")
    file_rec = dll_rec.get("files", {}).get(args.file)
    if not file_rec:
        raise SystemExit(f"file not found in index: {args.dll}/{args.file}")

    func_rec = None
    funcs = file_rec.get("functions", {})
    if isinstance(funcs, dict):
        func_rec = funcs.get(args.func)
    else:
        # 兼容旧格式：functions 是 list[dict]
        for f in funcs or []:
            if isinstance(f, dict) and f.get("name") == args.func:
                func_rec = f
                break
    if not func_rec:
        raise SystemExit(f"function not found: {args.func}")

    analyzer = DependencyAnalyzer(str(index_path), str(wine_root))

    # 复用 analyzer 的索引+源码读取逻辑，保证和 pipeline 一致
    deps = analyzer.analyze(args.dll, args.file, args.func)
    preds = analyzer.analyze_predicates(args.dll, args.file, args.func)

    # 先尝试走 ODAGenerator（主要为了利用 prompt 结构）；当前默认用 MockLLM。
    llm = MockLLM()
    gen = ODAGenerator(llm)

    try:
        spec = gen.generate(args.func, deps, preds)
    except Exception:
        spec = generate_fallback_spec(args.func, deps, preds, description=f"Fallback spec for {args.func}")

    out_spec = Path(args.out_spec) if args.out_spec else (Path(__file__).resolve().parents[1] / "specs" / f"_generated_{args.func}.json")
    out_spec.write_text(json.dumps(spec, indent=2, ensure_ascii=False), encoding="utf-8")

    # 生成 stub C
    if args.out_stub:
        out_stub = Path(args.out_stub)
    else:
        out_stub = Path(__file__).resolve().parents[1] / "klee" / "oda_stubs.c"

    # 直接调用生成器类，避免 subprocess；specs/ 不是 python package，所以手动加到 sys.path
    specs_dir = (Path(__file__).resolve().parents[1] / "specs").resolve()
    if str(specs_dir) not in sys.path:
        sys.path.insert(0, str(specs_dir))
    from gen_oda_stub import ODAStubGenerator  # type: ignore

    stub_code = ODAStubGenerator(str(out_spec)).generate()
    out_stub.write_text(stub_code, encoding="utf-8")

    print(f"Wrote spec: {out_spec}")
    print(f"Wrote stub: {out_stub}")
    print(f"Dependencies: {len(deps)}; predicates: {len(preds)}")

    # 可选：做一个轻量的 C 语法检查。
    # 说明：`oda_stubs.c` 默认会 `#include <klee/klee.h>`，在未安装 KLEE headers 的环境中会失败。
    # 这里做降级：如果找不到 klee 头文件，就用宏把 klee API 替换为空实现，仅做语法检查。
    try:
        import subprocess

        cc = "gcc"

        # 生成一个本地的 `klee/klee.h`（仅用于语法检查），并用 -I 覆盖 include 路径。
        # 这样即使系统没装 KLEE headers，也能通过 `#include <klee/klee.h>`。
        tmp_inc_root = Path(__file__).resolve().parent / "_tmp_include"
        (tmp_inc_root / "klee").mkdir(parents=True, exist_ok=True)
        klee_h = tmp_inc_root / "klee" / "klee.h"
        klee_h.write_text(
            """
#pragma once
// Minimal KLEE API shim for syntax-only compilation.
static inline void klee_make_symbolic(void *addr, unsigned long nbytes, const char *name) { (void)addr; (void)nbytes; (void)name; }
static inline void klee_assume(int cond) { (void)cond; }
static inline void klee_assert(int cond) { (void)cond; }
""".lstrip(),
            encoding="utf-8",
        )

        # 纯语法检查，不产物
        cmd = [
            cc,
            "-fsyntax-only",
            str(out_stub),
            "-I",
            str(tmp_inc_root),
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0:
            print("Stub C syntax check: OK (klee APIs stubbed)")
        else:
            print("Stub C syntax check: FAILED")
            if r.stdout:
                print(r.stdout)
            if r.stderr:
                print(r.stderr)
    except Exception as e:
        print(f"Stub C syntax check: skipped ({e})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
