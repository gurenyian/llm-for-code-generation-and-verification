import argparse
import json
import os
from typing import Any, Dict, List


def load_index(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def norm(s: str) -> str:
    return (s or "").lower()


def match(q: str, s: str) -> bool:
    if not q:
        return True
    return norm(q) in norm(s)


def list_dlls(index: Dict[str, Any], q: str) -> List[str]:
    return sorted([d for d in index["dlls"].keys() if match(q, d)])


def list_files(index: Dict[str, Any], dll: str, q: str) -> List[str]:
    files = index["dlls"].get(dll, {}).get("files", {})
    return sorted([f for f in files.keys() if match(q, f) or match(q, os.path.basename(f))])


def list_funcs(index: Dict[str, Any], dll: str, file: str, q: str) -> List[Dict[str, Any]]:
    files = index["dlls"].get(dll, {}).get("files", {})
    fentry = files.get(file)
    if not fentry:
        return []
    out = []
    for fn in fentry.get("functions", []):
        if match(q, fn.get("name", "")) or match(q, fn.get("signature", "")):
            out.append(fn)
    out.sort(key=lambda x: (x.get("name", ""), x.get("line", 0)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--level", required=True, choices=["dll", "file", "func"])
    ap.add_argument("--query", default="")
    ap.add_argument("--dll", default="")
    ap.add_argument("--file", default="")
    args = ap.parse_args()

    index = load_index(args.index)

    if args.level == "dll":
        for d in list_dlls(index, args.query):
            print(d)
        return

    if args.level == "file":
        if not args.dll:
            raise SystemExit("--dll is required for level=file")
        for f in list_files(index, args.dll, args.query):
            print(f)
        return

    if args.level == "func":
        if not args.dll or not args.file:
            raise SystemExit("--dll and --file are required for level=func")
        funcs = list_funcs(index, args.dll, args.file, args.query)
        for fn in funcs:
            # 只打印“当前层级”的必要信息：signature + location + 简短 comment（最多 3 行）
            comment = (fn.get("leading_comment") or "").splitlines()
            comment3 = "\n".join(comment[:3]).strip()
            print(f"- {fn.get('signature')}  @ {fn.get('file')}:{fn.get('line')}")
            if comment3:
                print(f"  {comment3.replace(chr(9), ' ')}")
        return


if __name__ == "__main__":
    main()

