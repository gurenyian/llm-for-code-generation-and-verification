import json
import sys


TEMPLATE = r"""
#include <stdint.h>
#include <klee/klee.h>

#define ODA_IMPLIES(a,b) klee_assume(!(a) || (b))

{stubs}
"""


STUB_TEMPLATE = r"""
// ODA stub for {fn}
int {fn}(const uint16_t* path)
{{
    uint8_t ret;
    klee_make_symbolic(&ret, sizeof(ret), "{fn}__ret");
    klee_assume(ret == 0 || ret == 1);

{implications}

    return (int)ret;
}}
"""


def main(spec_path: str, out_c_path: str) -> None:
    with open(spec_path, "r", encoding="utf-8") as f:
        spec = json.load(f)

    fn = spec["function"]
    summaries = spec["summaries"]

    impl_lines = []
    for s in summaries:
        when = s["when"].strip()  # e.g. "ret == 0"
        expr = s["assume_c_expr"].strip()
        if when not in ("ret == 0", "ret == 1"):
            raise ValueError(f"Unsupported when: {when}")
        v = when.split("==")[1].strip()
        impl_lines.append(f"    ODA_IMPLIES(ret == {v}, ({expr}));")

    stub_c = STUB_TEMPLATE.format(fn=fn, implications="\n".join(impl_lines))
    out = TEMPLATE.format(stubs=stub_c)

    with open(out_c_path, "w", encoding="utf-8") as f:
        f.write(out)

    print(f"generated {out_c_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python gen_oda_stub.py spec.json oda_stubs.c")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

