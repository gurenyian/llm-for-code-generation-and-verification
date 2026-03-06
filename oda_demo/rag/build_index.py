import argparse
import json
import os
import re
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Tuple


SIG_RE = re.compile(
    r"""
    ^(?P<prefix>\s*)
    (?P<ret>[\w\*\s]+?)\s+
    (?P<name>[A-Za-z_]\w*)\s*
    \(\s*(?P<args>[^;]*?)\s*\)\s*
    $""",
    re.VERBOSE,
)

COMMENT_RE = re.compile(r"^\s*(/\*\*?|\*|//)")


def is_c_file(path: str) -> bool:
    return path.endswith(".c") or path.endswith(".h")


def read_text(path: str) -> str:
    with open(path, "rb") as f:
        data = f.read()
    # Wine 源码基本是 utf-8 / ascii，这里用宽容解码
    return data.decode("utf-8", errors="ignore")


def extract_leading_comment(lines: List[str], start_line_idx: int, max_lines: int = 40) -> str:
    """
    从函数开始行的上方提取紧邻注释块（最多 max_lines），用于轻量摘要输入。
    """
    out: List[str] = []
    i = start_line_idx - 1
    scanned = 0
    while i >= 0 and scanned < max_lines:
        line = lines[i].rstrip("\n")
        if not line.strip():
            if out:
                break
            i -= 1
            scanned += 1
            continue
        if COMMENT_RE.match(line):
            out.append(line)
            i -= 1
            scanned += 1
            continue
        break
    out.reverse()
    return "\n".join(out).strip()


def extract_functions_from_c(path: str) -> List[Dict]:
    """
    极简 C 函数抽取：识别形如 `TYPE name(args) {` 的定义。
    这不是完整 C 解析器，但对“RAG 导航”足够。
    """
    text = read_text(path)
    lines = text.splitlines(keepends=True)

    functions: List[Dict] = []

    def next_code_line(start: int) -> int:
        j = start
        while j < len(lines):
            s = lines[j].strip()
            if not s:
                j += 1
                continue
            # 跳过纯注释行（避免把注释中的 '{' 误当成函数体开始）
            if COMMENT_RE.match(lines[j]):
                j += 1
                continue
            return j
        return -1

    for idx, line in enumerate(lines):
        stripped = line.lstrip()
        if stripped.startswith(("if", "else", "for", "while", "switch", "return")):
            continue
        # 快速跳过明显不是函数签名的行
        if "(" not in line or ")" not in line:
            continue
        if ";" in line:
            continue

        m = SIG_RE.match(line.rstrip("\n"))
        if not m:
            continue

        # 允许 '{' 在下一行（Wine 大量函数采用这种风格）
        j = next_code_line(idx + 1)
        if j == -1:
            continue
        if lines[j].lstrip().startswith("{") is False:
            continue

        name = m.group("name")
        ret = " ".join(m.group("ret").split())
        args = " ".join(m.group("args").split())
        comment = extract_leading_comment(lines, idx)

        functions.append(
            {
                "name": name,
                "ret": ret,
                "args": args,
                "signature": f"{ret} {name}({args})",
                "file": path.replace("\\", "/"),
                "line": idx + 1,
                "leading_comment": comment,
            }
        )

    return functions


def dll_name_from_path(dlls_root: str, file_path: str) -> str:
    rel = os.path.relpath(file_path, dlls_root)
    parts = rel.replace("\\", "/").split("/")
    return parts[0] if parts else ""


def file_base_name(file_path: str) -> str:
    return os.path.basename(file_path)


def build_index(dlls_root: str) -> Dict:
    index: Dict[str, Dict] = {"dlls_root": dlls_root.replace("\\", "/"), "dlls": {}}
    for root, _, files in os.walk(dlls_root):
        for fn in files:
            full = os.path.join(root, fn)
            if not is_c_file(full):
                continue
            dll = dll_name_from_path(dlls_root, full)
            if not dll:
                continue
            funcs = extract_functions_from_c(full)
            if not funcs:
                continue

            dll_entry = index["dlls"].setdefault(dll, {"files": {}})
            rel_file = os.path.relpath(full, os.path.join(dlls_root, dll)).replace("\\", "/")
            file_entry = dll_entry["files"].setdefault(rel_file, {"functions": []})
            file_entry["functions"].extend(funcs)
    return index


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="Path to dlls/ directory (e.g. .\\dlls)")
    ap.add_argument("--out", required=True, help="Output index.json")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    out = os.path.abspath(args.out)

    index = build_index(root)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    print(f"Wrote index to {out}")


if __name__ == "__main__":
    main()

