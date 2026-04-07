#!/bin/bash
#
# Ubuntu VM 侧：在 Wine 环境下回放 test_cases.bin，并与 Windows 侧生成的 oracle.bin 对比。
#
# 输入：
#   - test_cases.bin  (由 KLEE 生成并转成跨平台二进制)
#   - oracle.bin      (在真 Windows 上 --record 得到)
#
# 输出：
#   - <outdir>/wine_check_report.txt
#   - <outdir>/wine_test_runner.exe  (编译产物，方便复现)
#

set -euo pipefail

API_NAME="PathIsRelativeW"
WORKDIR=""
OUTDIR=""
CASES_BIN=""
ORACLE_BIN=""
WINEEXE="wine"
ARCH="win64"
WINEPREFIX=""

usage() {
  cat <<EOF
Usage:
  $0 --api <API_NAME> --cases <test_cases.bin> --oracle <oracle.bin> [--workdir <DIR>] [--outdir <DIR>] [--wine <wine>] [--arch win64|win32] [--wineprefix <dir>]

Options:
  --api      API name (default: PathIsRelativeW)
  --cases    Path to test_cases.bin
  --oracle   Path to oracle.bin
  --workdir  oda_demo directory (default: current dir)
  --outdir   Output directory (default: <workdir>/out/<api>)
  --wine     Wine executable (default: wine)
  --arch     Target arch for winegcc (default: win64)
  --wineprefix Wine prefix to use (default: <outdir>/wineprefix_<arch>)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api) API_NAME="$2"; shift 2;;
    --cases) CASES_BIN="$2"; shift 2;;
    --oracle) ORACLE_BIN="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    --outdir) OUTDIR="$2"; shift 2;;
    --wine) WINEEXE="$2"; shift 2;;
    --arch) ARCH="$2"; shift 2;;
    --wineprefix) WINEPREFIX="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$(pwd)"
fi

if [[ -z "$OUTDIR" ]]; then
  OUTDIR="$WORKDIR/out/${API_NAME,,}"
fi

if [[ -z "$CASES_BIN" || -z "$ORACLE_BIN" ]]; then
  echo "ERROR: --cases and --oracle are required" >&2
  usage
  exit 2
fi

log() { echo "[ubuntu_wine_check] $*"; }

cd "$WORKDIR"
mkdir -p "$OUTDIR"

# 默认给本次检查一个独立 prefix，避免用户 home 下的 ~/.wine 与运行时 wineserver 位数冲突
if [[ -z "$WINEPREFIX" ]]; then
  WINEPREFIX="$OUTDIR/wineprefix_${ARCH}"
fi

case "$ARCH" in
  win64) export WINEARCH=win64;;
  win32) export WINEARCH=win32;;
esac
export WINEPREFIX

if ! command -v winegcc >/dev/null 2>&1; then
  echo "ERROR: winegcc not found. Install Wine build tools (winegcc) on Ubuntu." >&2
  exit 1
fi

if ! command -v "$WINEEXE" >/dev/null 2>&1; then
  echo "ERROR: wine not found: $WINEEXE" >&2
  exit 1
fi

# 如果用户没显式指定 wine64/wine32，则按 arch 自动选一个更匹配的 binary
if [[ "$WINEEXE" == "wine" ]]; then
  if [[ "$ARCH" == "win64" ]] && command -v wine64 >/dev/null 2>&1; then
    WINEEXE="wine64"
  elif [[ "$ARCH" == "win32" ]] && command -v wine32 >/dev/null 2>&1; then
    WINEEXE="wine32"
  fi
fi

# 尽力避免残留 wineserver 位数冲突（不让其失败中止）
if command -v wineserver >/dev/null 2>&1; then
  wineserver -k >/dev/null 2>&1 || true
fi

RUNNER_C="$WORKDIR/runner/test_runner.c"
WINE_TEST_H="$WORKDIR/runner/wine_test.h"

if [[ ! -f "$RUNNER_C" || ! -f "$WINE_TEST_H" ]]; then
  echo "ERROR: runner sources missing under $WORKDIR/runner" >&2
  exit 1
fi

if [[ "$API_NAME" != "PathIsRelativeW" ]]; then
  log "WARN: runner currently hardcodes PathIsRelativeW; api=$API_NAME is accepted but not implemented yet."
fi

copy_if_needed() {
  local src="$1"
  local dst="$2"
  # 允许用户直接把 --cases/--oracle 指到 outdir 下；此时避免 cp 自拷贝触发失败。
  if [[ "$(readlink -f "$src")" == "$(readlink -f "$dst")" ]]; then
    return 0
  fi
  cp -f "$src" "$dst"
}

copy_if_needed "$CASES_BIN" "$OUTDIR/test_cases.bin"
copy_if_needed "$ORACLE_BIN" "$OUTDIR/oracle.bin"

log "Compiling Wine runner via winegcc"
EXE="$OUTDIR/wine_test_runner.exe"
LOG="$OUTDIR/wine_compile_log.txt"

try_mingw() {
  local cc="$1"
  local cflags=()
  case "$ARCH" in
    win64) cflags=(-m64);;
    win32) cflags=(-m32);;
    *) return 2;;
  esac

  local libs=()
  case "${API_NAME,,}" in
    pathisrelativew) libs=(-lshlwapi);;
    lstrcmpw) libs=(-lkernel32);;
    *) libs=(-lshlwapi);;
  esac

  "$cc" "${cflags[@]}" -I"$WORKDIR/runner" "$RUNNER_C" -o "$EXE" "${libs[@]}"
}

set +e
rc_compile=1

if [[ "$ARCH" == "win64" ]] && command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
  log "Using x86_64-w64-mingw32-gcc (preferred)"
  try_mingw x86_64-w64-mingw32-gcc >"$LOG" 2>&1
  rc_compile=$?
elif [[ "$ARCH" == "win32" ]] && command -v i686-w64-mingw32-gcc >/dev/null 2>&1; then
  log "Using i686-w64-mingw32-gcc (preferred)"
  try_mingw i686-w64-mingw32-gcc >"$LOG" 2>&1
  rc_compile=$?
else
  # 回退 winegcc（它会调用 winebuild/ld，某些环境容易出现 32/64 混编问题）
  log "Falling back to winegcc"
  WINEGCC_ARCH=()
  case "$ARCH" in
    win64) WINEGCC_ARCH=(--arch win64 -m64);;
    win32) WINEGCC_ARCH=(--arch win32 -m32);;
    *) echo "ERROR: invalid --arch: $ARCH (use win64 or win32)" >&2; exit 2;;
  esac
  libs=()
  case "${API_NAME,,}" in
    pathisrelativew) libs=(-lshlwapi);;
    lstrcmpw) libs=(-lkernel32);;
    *) libs=(-lshlwapi);;
  esac
  winegcc "${WINEGCC_ARCH[@]}" -I"$WORKDIR/runner" "$RUNNER_C" -o "$EXE" "${libs[@]}" >"$LOG" 2>&1
  rc_compile=$?
fi

set -e
if [[ $rc_compile -ne 0 ]]; then
  {
    echo "[ubuntu_wine_check] ERROR: compile failed rc=$rc_compile"
    echo "[ubuntu_wine_check] arch=$ARCH"
    echo "[ubuntu_wine_check] See: $LOG"
    echo ""
    echo "If you don't have mingw-w64 cross compilers, install them (Ubuntu: mingw-w64)."
    echo "If you rely on winegcc, ensure matching Wine dev toolchain for the target arch."
  } | tee "$OUTDIR/wine_check_report.txt" >/dev/null
  exit $rc_compile
fi

log "Running under Wine: --check"
set +e
RAW_REPORT="$OUTDIR/wine_check_raw.txt"
CLEAN_REPORT="$OUTDIR/wine_check_report.txt"

EXTRA_ARGS=()
EXTRA_ARGS+=("--target" "$API_NAME")
if [[ -n "${ODA_WINE_CASE:-}" ]]; then
  EXTRA_ARGS+=("--case" "${ODA_WINE_CASE}")
  log "Single-case mode: ODA_WINE_CASE=${ODA_WINE_CASE}"
fi

"$WINEEXE" "$OUTDIR/wine_test_runner.exe" --check "$OUTDIR/test_cases.bin" "$OUTDIR/oracle.bin" "${EXTRA_ARGS[@]}" \
  >"$RAW_REPORT" 2>&1
rc=$?
set -e

# 生成“干净版”报告：
#  - 优先保留测试摘要块（从分隔线开始直到文件结束）
#  - 同时保留任何 FAIL 行（支持前面出现的断言信息）
#  - 若摘要块不存在，则退化为输出 raw 尾部（便于排障）
python3 - "$RAW_REPORT" "$CLEAN_REPORT" <<'PY'
import sys
from pathlib import Path
import re

raw_path = Path(sys.argv[1])
clean_path = Path(sys.argv[2])
text = raw_path.read_text(errors="replace").splitlines(True)

sep = "========================================\n"

# 找摘要块起点（第一条分隔线）
start = None
for i, line in enumerate(text):
  if line == sep:
    start = i
    break

fails = [ln for ln in text if "[FAIL]" in ln or "MISMATCH" in ln]

# 过滤噪声行（仍保留 FAIL/MISMATCH 和摘要块）。
# 说明：一些 err 级别也可能是无关噪声（例如无 DISPLAY 的 headless 环境、rpc fault）。
NOISE_PATTERNS = [
  re.compile(r"^\s*[0-9a-fA-F]{4}:(fixme|trace|warn):"),
  re.compile(r"^\s*[0-9a-fA-F]{4}:err:explorer:initialize_display_settings\b"),
  re.compile(r"^\s*[0-9a-fA-F]{4}:err:rpc:I_RpcReceive\b"),
]

def is_noise(line: str) -> bool:
  return any(p.search(line) for p in NOISE_PATTERNS)

out = []
filtered_count = 0

out.append("[Wine check report (filtered)]\n")
out.append(f"raw: {raw_path.name} (see it when debugging)\n")
if fails:
  out.append("[Filtered FAIL lines]\n")
  out.extend(fails)
  if out[-1].endswith("\n") is False:
    out.append("\n")
  out.append("\n")

if start is not None:
  out.append("[Test summary]\n")
  # 先把摘要块原样保留；但在写入前，统计一下摘要块外的噪声过滤数量。
  for ln in text[:start]:
    if ln in fails:
      continue
    if is_noise(ln):
      filtered_count += 1
  out.extend(text[start:])
else:
  # 没摘要：给个尾部窗口
  out.append("[No summary block found; tail of raw output]\n")
  tail = text[-200:]
  cleaned_tail = []
  for ln in tail:
    if ("[FAIL]" in ln) or ("MISMATCH" in ln) or (not is_noise(ln)):
      cleaned_tail.append(ln)
    else:
      filtered_count += 1
  out.extend(cleaned_tail)

# 把过滤计数插到最前面（便于快速知道“为什么看起来很短”）
out.insert(3, f"filtered noise lines: {filtered_count}\n\n")

clean_path.write_text("".join(out), encoding="utf-8")
PY

log "DONE rc=$rc"
log "Report: $OUTDIR/wine_check_report.txt"
log "Raw: $OUTDIR/wine_check_raw.txt"

exit $rc
