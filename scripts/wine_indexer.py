#!/usr/bin/env python3
"""通用 Hierarchical Indexer (Tree-sitter 版)

用法:
  python3 scripts/wine_indexer.py --dir ~/wine-source/dlls --out wine_kb.json

输出格式:
  {"dlls": {"shlwapi": {"files": {"path.c": {"functions": {"PathCombineW": {"signature": "...", "logic_contract": "..."}}}}}}}
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import requests
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


def call_llm(system_prompt: str, user_prompt: str) -> str:
    api_key = os.environ.get("ODA_LLM_API_KEY") or os.environ.get("OPENAI_API_KEY")
    api_base = os.environ.get("ODA_LLM_BASE_URL") or os.environ.get("OPENAI_API_BASE", "https://api.openai.com/v1")
    model = os.environ.get("ODA_LLM_MODEL") or os.environ.get("OPENAI_MODEL", "gpt-4o")
    if not api_key:
        return "[Mock] Return 1 when semantic condition holds."

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": 0.1,
    }
    try:
        resp = requests.post(f"{api_base}/chat/completions", headers=headers, json=payload, timeout=60)
        return resp.json().get("choices", [{}])[0].get("message", {}).get("content", "").strip()
    except Exception:
        return "[Mock] Contract generation failed."


def extract_functions(code: str, parser: Parser) -> List[Dict[str, str]]:
    tree = parser.parse(bytes(code, "utf8"))
    query = Language(tsc.language()).query(
        "(function_definition declarator: (function_declarator declarator: (identifier) @fname)) @funcdef"
    )
    captures = query.captures(tree.root_node)

    funcs: List[Dict[str, str]] = []
    current_name = None
    for name, node in _iter_captures(captures):
        if name == "fname":
            current_name = code[node.start_byte:node.end_byte]
        elif name == "funcdef" and current_name:
            for child in node.children:
                if child.type == "compound_statement":
                    sig = code[node.start_byte:child.start_byte].strip()
                    funcs.append({"name": current_name, "signature": sig})
                    break
            current_name = None
    return funcs


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True, help="Wine dlls/ directory")
    ap.add_argument("--out", default="wine_kb.json")
    args = ap.parse_args()

    parser = Parser(Language(tsc.language()))
    kb: Dict[str, Dict] = {"dlls": {}}

    for root, _, files in os.walk(args.dir):
        c_files = [f for f in files if f.endswith(".c")]
        if not c_files:
            continue
        dll_name = Path(root).name
        if dll_name not in kb["dlls"]:
            kb["dlls"][dll_name] = {"files": {}}

        for cfile in c_files:
            src_path = Path(root) / cfile
            try:
                code = src_path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            funcs = extract_functions(code, parser)
            if not funcs:
                continue

            kb["dlls"][dll_name]["files"][cfile] = {"functions": {}}
            for f in funcs:
                sys_prompt = "You are a C/Win32 API expert."
                usr_prompt = (
                    "Provide a brief logic contract for this function."
                    " Mention the concrete condition for returning TRUE if applicable."
                    f"\nSignature:\n{f['signature']}"
                )
                kb["dlls"][dll_name]["files"][cfile]["functions"][f["name"]] = {
                    "signature": f["signature"],
                    "logic_contract": call_llm(sys_prompt, usr_prompt),
                }

    Path(args.out).write_text(json.dumps(kb, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[wine_indexer] wrote {args.out}")


if __name__ == "__main__":
    main()
