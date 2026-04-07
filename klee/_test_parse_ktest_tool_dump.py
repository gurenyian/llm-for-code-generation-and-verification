#!/usr/bin/env python3
"""本机小测试：验证 ktest_to_cases 的 fallback 解析能吃掉 `ktest-tool file.ktest` 的默认输出。

用法：
  python _test_parse_ktest_tool_dump.py <path/to/test000001.ktest.stdout.txt>

预期：
  - 能解析到对象 'path'
  - len(path)==64
"""

from __future__ import annotations

import sys
from pathlib import Path

from ktest_to_cases import KTestParser


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python _test_parse_ktest_tool_dump.py <ktest-tool-stdout.txt>")
        return 2

    p = Path(sys.argv[1])
    out = p.read_text(encoding="utf-8", errors="replace")

    parser = KTestParser("DUMMY.ktest")
    objs = parser._parse_default_output(out)  # noqa: SLF001 (intentional for test)

    if "path" not in objs:
        raise SystemExit(f"missing 'path' in objects: {list(objs.keys())}")

    b = objs["path"]
    print("parsed objects:", list(objs.keys()))
    print("len(path) =", len(b))
    print("first 16 bytes =", b[:16].hex())

    assert len(b) == 64, f"expected 64 bytes, got {len(b)}"
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
