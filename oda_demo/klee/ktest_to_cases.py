import glob
import os
import re
import struct
import subprocess
import sys

N = 32  # must match harness


def extract_path_bytes(ktest_path: str) -> bytes:
    out = subprocess.check_output(["ktest-tool", ktest_path], text=True, errors="ignore")
    blocks = out.split("object ")
    for b in blocks:
        if "name: 'path'" in b or 'name: "path"' in b:
            m = re.search(r"data:\s*(.*)", b)
            if not m:
                continue
            data_text = m.group(1).strip()
            hex_bytes = []
            i = 0
            while i < len(data_text):
                if data_text[i:i+2] == r"\x":
                    hex_bytes.append(int(data_text[i + 2:i + 4], 16))
                    i += 4
                else:
                    i += 1
            raw = bytes(hex_bytes)
            if len(raw) != N * 2:
                raise ValueError(f"Unexpected path size {len(raw)} in {ktest_path}")
            return raw
    raise RuntimeError(f"Could not find path object in {ktest_path}")


def main(klee_dir: str, out_cases: str) -> None:
    ktests = sorted(glob.glob(os.path.join(klee_dir, "*.ktest")))
    if not ktests:
        raise SystemExit(f"No .ktest found in {klee_dir}")

    cases = []
    seen = set()
    for k in ktests:
        raw = extract_path_bytes(k)
        if raw in seen:
            continue
        seen.add(raw)
        cases.append(raw)

    with open(out_cases, "wb") as f:
        f.write(struct.pack("<I", len(cases)))
        for raw in cases:
            f.write(raw)

    print(f"Wrote {len(cases)} cases to {out_cases}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 ktest_to_cases.py klee-last out_cases.bin")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

