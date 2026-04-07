#!/usr/bin/env python3
"""Generate a function-specific spec/harness from reusable templates.

This script copies the reusable PathCombineW template style and stamps
out a target-specific spec/harness pair.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate reusable ODA artifacts")
    parser.add_argument("--spec", required=True, help="Path to function spec json")
    parser.add_argument("--harness-template", required=True, help="Reusable harness template")
    parser.add_argument("--out-spec", required=True, help="Output spec path")
    parser.add_argument("--out-harness", required=True, help="Output harness path")
    args = parser.parse_args()

    spec_path = Path(args.spec)
    harness_template = Path(args.harness_template).read_text(encoding="utf-8")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))

    Path(args.out_spec).write_text(json.dumps(spec, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    Path(args.out_harness).write_text(harness_template, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
