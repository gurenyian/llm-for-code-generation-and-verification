import struct
from pathlib import Path


def main() -> int:
    outdir = Path(__file__).resolve().parent / "_ubuntu_out" / "pathisrelativew"
    cases = outdir / "test_cases.bin"
    oracle = outdir / "oracle.bin"

    if not cases.exists():
        raise SystemExit(f"missing: {cases}")
    if not oracle.exists():
        raise SystemExit(f"missing: {oracle}")

    data = oracle.read_bytes()
    if len(data) < 12:
        raise SystemExit("oracle.bin too small")

    magic, ver, n = struct.unpack_from("<III", data, 0)
    if magic != 0x4C43524F or ver != 1:
        raise SystemExit(f"unexpected oracle header: magic=0x{magic:08x} ver={ver}")

    bool_size = 4  # Windows BOOL
    expected_len = 12 + n * bool_size
    if len(data) < expected_len:
        raise SystemExit(f"oracle.bin truncated: have={len(data)} need>={expected_len}")

    # Flip first result to force mismatch
    first = struct.unpack_from("<I", data, 12)[0]
    flipped = 0 if first else 1
    patched = bytearray(data)
    struct.pack_into("<I", patched, 12, flipped)

    out = outdir / "oracle_mismatch.bin"
    out.write_bytes(patched)
    print(f"wrote: {out} (flipped first BOOL {first} -> {flipped})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
