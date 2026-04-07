#!/usr/bin/env python3
r"""谓词 ψ 自检脚本（在 Windows 侧也可跑）。

这个脚本用 DependencyAnalyzer 对指定函数提取：
- dependencies（依赖函数）
- predicates（结构化 ψ）

用法：
    python predicate_self_check.py --index ..\rag\_self_check_index.json --wine-root d:\\wine\\wine-master --dll kernelbase --file path.c --func PathRemoveFileSpecW

说明：
- 为了让 Windows 侧也容易跑，你可以直接复用 rag/self_check.py 生成的 _self_check_index.json。
- 真正跑全库时，index.json 建议在 Linux 侧一次性构建。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from dependency_analyzer import DependencyAnalyzer


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--wine-root", required=True)
    ap.add_argument("--dll", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--func", required=True)
    args = ap.parse_args()

    analyzer = DependencyAnalyzer(args.index, args.wine_root)

    deps = analyzer.analyze(args.dll, args.file, args.func)
    preds = analyzer.analyze_predicates(args.dll, args.file, args.func)

    print("=== dependencies ===")
    print(json.dumps(deps, indent=2, ensure_ascii=False))
    print("\n=== predicates (psi) ===")
    print(json.dumps(preds, indent=2, ensure_ascii=False))

    # Quick signal: list which predicates depend on external calls
    ext = [p for p in preds if p.get("depends_on")]
    print(f"\n[OK] total predicates={len(preds)}; with depends_on={len(ext)}")
    if ext:
        print("[OK] depends_on set:", sorted({p["depends_on"] for p in ext}))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
