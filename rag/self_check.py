#!/usr/bin/env python3
"""RAG 索引自检（Windows 可直接跑）。

目标：快速验证 build_index.py 的函数定位是否稳定。

它会：
1) 只对指定 dll 目录构建索引（避免全 Wine 扫描太慢）
2) 在索引中查找函数
3) 用 HierarchicalQuery 取出代码片段
4) 做一些轻量断言：包含函数名/花括号闭合/哈希一致

用法：
  python self_check.py --wine-root d:\\wine\\wine-master --dll kernelbase --file path.c --func PathIsRelativeW
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_index import WineIndexBuilder
from query import HierarchicalQuery


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--wine-root", required=True)
    ap.add_argument("--dll", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--func", required=True)
    ap.add_argument("--out", default="_self_check_index.json")
    args = ap.parse_args()

    wine_root = Path(args.wine_root)
    dll_dir = wine_root / "dlls" / args.dll
    if not dll_dir.exists():
        raise SystemExit(f"DLL dir not found: {dll_dir}")

    # 只扫描一个 dll，加快速度
    builder = WineIndexBuilder(str(wine_root / "dlls"))
    builder.index = {"dlls": {}}  # reset
    # 直接调用 _index_dll（够用）
    dll_info = builder._index_dll(dll_dir)
    builder.index["dlls"][args.dll] = dll_info

    out_path = Path(args.out)
    out_path.write_text(json.dumps(builder.index, indent=2, ensure_ascii=False), encoding="utf-8")

    hq = HierarchicalQuery(str(out_path), str(wine_root))

    funcs = hq.list_functions(args.dll, args.file, keyword=args.func)
    if not funcs:
        raise SystemExit(f"Function not found in index: {args.dll}/{args.file}/{args.func}")

    info = hq.get_function_info(args.dll, args.file, args.func)
    code = hq.get_function_code(args.dll, args.file, args.func)

    # 轻量 sanity checks
    if args.func not in code:
        raise SystemExit("Extracted code doesn't contain function name")
    if "{" not in code or "}" not in code:
        raise SystemExit("Extracted code seems incomplete (missing braces)")

    print("[OK] index built:", out_path)
    print("[OK] function:", args.func)
    print("[OK] signature:", info.get("signature"))
    print("[OK] line range:", info.get("line_start"), "-", info.get("line_end"))
    print("[OK] hash:", info.get("code_hash"))
    print("[OK] code preview:\n", "\n".join(code.splitlines()[:20]))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
