#!/usr/bin/env python3
"""基于 Tree-sitter 的依赖切片生成器。

用法:
  python3 scripts/dependency_analyzer.py \
    --target-func PathCombineW \
    --target-file ~/wine-source/dlls/shlwapi/path.c \
    --kb wine_kb.json --out context_slice.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Iterable, Tuple

import tree_sitter_c as tsc
from tree_sitter import Language, Parser


def _iter_captures(captures: object) -> Iterable[Tuple[str, object]]:
    if isinstance(captures, list):
        for node, name in captures:
            yield name, node
    elif isinstance(captures, dict):
        for name, nodes in captures.items():
            for node in nodes:
                yield name, node


def find_function_node(code: str, func_name: str, parser: Parser):
    tree = parser.parse(bytes(code, "utf8"))
    query = Language(tsc.language()).query(
        "(function_definition declarator: (function_declarator declarator: (identifier) @fname)) @funcdef"
    )
    captures = query.captures(tree.root_node)
    saw_target = False
    for name, node in _iter_captures(captures):
        if name == "fname" and code[node.start_byte:node.end_byte] == func_name:
            saw_target = True
        elif name == "funcdef" and saw_target:
            return node
    return None


def extract_calls(code: str, root_node) -> set[str]:
    calls = set()

    def walk(node):
        if node.type == "call_expression":
            for c in node.children:
                if c.type == "identifier":
                    calls.add(code[c.start_byte:c.end_byte])
        for c in node.children:
            walk(c)

    walk(root_node)
    return calls


def lookup_meta(kb: Dict, func_name: str) -> Dict:
    for _, dll_data in kb.get("dlls", {}).items():
        for _, file_data in dll_data.get("files", {}).items():
            if func_name in file_data.get("functions", {}):
                return file_data["functions"][func_name]
    return {"signature": f"{func_name}(...)", "logic_contract": "Unknown"}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target-func", required=True)
    ap.add_argument("--target-file", required=True)
    ap.add_argument("--kb", default="wine_kb.json")
    ap.add_argument("--out", default="context_slice.json")
    args = ap.parse_args()

    kb = json.loads(Path(args.kb).read_text(encoding="utf-8"))
    code = Path(args.target_file).read_text(encoding="utf-8", errors="ignore")

    parser = Parser(Language(tsc.language()))
    func_node = find_function_node(code, args.target_func, parser)
    if not func_node:
        raise SystemExit(f"Function {args.target_func} not found in {args.target_file}")

    func_code = code[func_node.start_byte:func_node.end_byte]
    called_funcs = extract_calls(func_code, func_node)

    deps = {name: lookup_meta(kb, name) for name in sorted(called_funcs)}
    out = {
        "target_function": args.target_func,
        "source_snippet": func_code,
        "dependencies": deps,
    }
    Path(args.out).write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[dependency_analyzer] wrote {args.out}")


if __name__ == "__main__":
    main()
