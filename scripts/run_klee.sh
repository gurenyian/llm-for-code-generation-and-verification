#!/bin/bash
set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <harness_file.c> [--max-time 60s] [--max-memory 2048]"
  exit 1
fi

HARNESS_FILE="$1"
shift || true
MAX_TIME="60s"
MAX_MEMORY="2048"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-time) MAX_TIME="$2"; shift 2;;
    --max-memory) MAX_MEMORY="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

if [[ ! -f "$HARNESS_FILE" ]]; then
  echo "Harness not found: $HARNESS_FILE" >&2
  exit 1
fi

# move into klee dir for build
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ODA_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
KLEE_DIR="$ODA_ROOT/klee"

cd "$KLEE_DIR"

KLEE_INCLUDE=""
for path in /usr/include /usr/local/include /usr/include/klee /usr/local/include/klee; do
  if [[ -f "$path/klee/klee.h" ]]; then KLEE_INCLUDE="$path"; break; fi
done
if [[ -z "$KLEE_INCLUDE" ]]; then
  KLEE_H=$(find /usr -name "klee.h" 2>/dev/null | grep "klee/klee.h" | head -1 || true)
  if [[ -n "$KLEE_H" ]]; then KLEE_INCLUDE=$(dirname "$(dirname "$KLEE_H")"); fi
fi
if [[ -z "$KLEE_INCLUDE" ]]; then
  echo "klee/klee.h not found" >&2
  exit 1
fi

rm -rf klee-out-0 harness.bc

clang -I"$KLEE_INCLUDE" -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone \
  -fprofile-arcs -ftest-coverage \
  "$HARNESS_FILE" -o harness.bc

klee --optimize --max-time="$MAX_TIME" --max-memory="$MAX_MEMORY" --output-dir=klee-out-0 --write-test-info harness.bc

python3 ktest_to_cases.py klee-out-0/ -o test_cases.bin

echo "[run_klee] done. output: klee/klee-out-0 test_cases.bin"
