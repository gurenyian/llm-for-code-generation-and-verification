#!/bin/bash
#
# Ubuntu VM 侧：在装有 KLEE + Wine 的环境里跑最小流水线。
#
# 目标：让 Windows 侧只需 ssh 触发该脚本，然后 scp 拉回产物。
#
# 做的事（对应 run_full_pipeline.sh 的前半段）：
#  1) （可选）确保 rag/index.json 存在
#  2) 生成/使用 ODA stub（klee/oda_stubs.c）
#  3) 编译 harness 为 bitcode 并运行 KLEE
#  4) 转换 .ktest → test_cases.bin
#
# 用法：
#   ./scripts/ubuntu_run_pipeline.sh --api PathIsRelativeW --wine-root /home/guren/wine
#

set -euo pipefail

# 允许强制创建新 run 目录（避免 last_run.txt 持续指向旧目录导致拉回陈旧工件）
# runner 若设置 ODA_FORCE_NEW_RUN=1，将在每次 llm 运行都生成新 run_<timestamp>_<pid>。
FORCE_NEW_RUN="${ODA_FORCE_NEW_RUN:-0}"

API_NAME="PathIsRelativeW"
WINE_ROOT=""
WORKDIR=""
OUTDIR=""
MAX_TIME="60s"
MAX_MEMORY="2048"
DUMP_KTEST_TOOL=""
STUB_MODE="spec"
TARGET_DLL=""
TARGET_FILE=""

usage() {
  cat <<EOF
Usage:
  $0 --api <API_NAME> --wine-root <WINE_ROOT> [--workdir <DIR>] [--outdir <DIR>]

Options:
  --api            Target API name (default: PathIsRelativeW)
  --wine-root      Wine source root (must contain dlls/)
  --workdir        Working directory (default: current oda_demo dir)
  --outdir         Output directory to collect artifacts (default: <workdir>/out/<api>)
  --max-time       KLEE max time (default: 60s)
  --max-memory     KLEE max memory MB (default: 2048)
  --dump-ktest-tool Dump `ktest-tool <file.ktest>` stdout/stderr into a dir (default: disabled)
  --stub-mode      spec|llm|none (default: spec)
                  spec: use specs/<api>.json -> gen_oda_stub.py -> klee/oda_stubs.c
                  llm : call real LLM to generate spec+stub and write llm_* artifacts into <outdir>/
                  none: use an empty oda_stubs.c (no external dependencies)
  --target-dll     Required when --stub-mode llm (e.g. shlwapi)
  --target-file    Required when --stub-mode llm (e.g. path.c)

Environment:
  ODA_DUMP_KTEST_TOOL=1   Same as --dump-ktest-tool (dumps into <outdir>/ktest_tool_dump)

LLM Environment (required when --stub-mode llm):
  ODA_LLM_API_KEY / OPENAI_API_KEY
  ODA_LLM_MODEL
  ODA_LLM_BASE_URL (optional)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api) API_NAME="$2"; shift 2;;
    --wine-root) WINE_ROOT="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    --outdir) OUTDIR="$2"; shift 2;;
    --max-time) MAX_TIME="$2"; shift 2;;
    --max-memory) MAX_MEMORY="$2"; shift 2;;
    --dump-ktest-tool) DUMP_KTEST_TOOL="$2"; shift 2;;
    --stub-mode) STUB_MODE="$2"; shift 2;;
    --target-dll) TARGET_DLL="$2"; shift 2;;
    --target-file) TARGET_FILE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$(pwd)"
fi

if [[ -z "$WINE_ROOT" ]]; then
  echo "ERROR: --wine-root is required" >&2
  exit 2
fi

if [[ -z "$OUTDIR" ]]; then
  OUTDIR="$WORKDIR/out/${API_NAME,,}"
fi

# 注意：run_<timestamp> 子目录的创建需要在解析完 --stub-mode 后才能可靠判断。
# 这里先保留 OUTDIR 作为 base outdir，真正的 run outdir 在 llm case 内创建。

# env shortcut
if [[ -z "$DUMP_KTEST_TOOL" && "${ODA_DUMP_KTEST_TOOL:-}" == "1" ]]; then
  DUMP_KTEST_TOOL="$OUTDIR/ktest_tool_dump"
fi

mkdir -p "$OUTDIR"

log() { echo "[ubuntu_run_pipeline] $*"; }

log "API_NAME=$API_NAME"
log "API_NAME_LOWER=${API_NAME,,}"
log "WINE_ROOT=$WINE_ROOT"
log "WORKDIR=$WORKDIR"
log "OUTDIR=$OUTDIR"
if [[ -n "$DUMP_KTEST_TOOL" ]]; then
  log "DUMP_KTEST_TOOL=$DUMP_KTEST_TOOL"
fi
log "STUB_MODE=$STUB_MODE"
if [[ -n "$TARGET_DLL" ]]; then log "TARGET_DLL=$TARGET_DLL"; fi
if [[ -n "$TARGET_FILE" ]]; then log "TARGET_FILE=$TARGET_FILE"; fi

cd "$WORKDIR"

# --- 依赖检查 ---
command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
command -v clang >/dev/null || { echo "clang not found"; exit 1; }
command -v klee >/dev/null || { echo "klee not found"; exit 1; }

# --- 1) index（可选） ---
if [[ ! -f "rag/index.json" ]]; then
  log "rag/index.json missing; building index (this can take a while)"
  (cd rag && python3 build_index.py "$WINE_ROOT/dlls" -o index.json)
else
  log "rag/index.json exists; skip"
fi
# --- 2) stub ---
case "$STUB_MODE" in
  spec)
    SPEC_FILE="specs/${API_NAME,,}.json"
    if [[ -f "$SPEC_FILE" ]]; then
      log "Using spec: $SPEC_FILE"
      (cd specs && python3 gen_oda_stub.py "$(basename "$SPEC_FILE")" -o ../klee/oda_stubs.c)
    else
      log "Spec not found ($SPEC_FILE); leaving existing klee/oda_stubs.c if any"
      if [[ ! -f "klee/oda_stubs.c" ]]; then
        echo "// No external dependencies" > klee/oda_stubs.c
      fi
    fi
    ;;
  llm)
    # 为了可复现/可观测且避免旧工件覆盖：LLM 模式下默认写入带时间戳的 run 子目录。
    # 同时写入 last_run.txt 指向最新 run 目录，供 Windows 侧拉取脚本使用。
    BASE_OUTDIR="$OUTDIR"
    mkdir -p "$BASE_OUTDIR"
    # include pid to avoid collisions when multiple runs start within the same second
    RUN_ID="$(date +%Y%m%d_%H%M%S)_$$"

    # 极端情况下（例如旧 last_run.txt 没更新、秒级重复、或多人并发），强制加随机后缀确保 run 目录唯一。
    if [[ "$FORCE_NEW_RUN" != "0" ]]; then
      RUN_ID="${RUN_ID}_$RANDOM"
    fi
  OUTDIR="$BASE_OUTDIR/run_$RUN_ID"
    mkdir -p "$OUTDIR"
    echo "$OUTDIR" > "$BASE_OUTDIR/last_run.txt"
  # 额外打印：确认 FORCE_NEW_RUN 与最终 OUTDIR（用于 Windows runner 抓日志判断是否真正刷新）
  log "FORCE_NEW_RUN=$FORCE_NEW_RUN RUN_ID=$RUN_ID"
    log "LLM_RUN_OUTDIR=$OUTDIR"
    log "Wrote last_run.txt: $BASE_OUTDIR/last_run.txt -> $(cat "$BASE_OUTDIR/last_run.txt" 2>/dev/null || true)"
    if [[ ! -f "$BASE_OUTDIR/last_run.txt" ]]; then
      echo "ERROR: failed to create last_run.txt: $BASE_OUTDIR/last_run.txt" >&2
      exit 3
    fi

    if [[ -z "$TARGET_DLL" || -z "$TARGET_FILE" ]]; then
      echo "ERROR: --stub-mode llm requires --target-dll and --target-file" >&2
      exit 2
    fi
    log "Generating ODA stub with REAL LLM (artifacts -> $OUTDIR)"
    # Sanity check: make sure the function exists in the RAG index under the given dll/file.
    # If not, fail early with a clear message so users don't think LLM was called.
    python3 - "$TARGET_DLL" "$TARGET_FILE" "$API_NAME" << 'PY'
import json
import sys
idx_path='rag/index.json'
dll=sys.argv[1]
file=sys.argv[2]
func=sys.argv[3]
with open(idx_path,'r',encoding='utf-8') as f:
  idx=json.load(f)
try:
  file_info=idx['dlls'][dll]['files'][file]
except Exception:
  print(f"[ubuntu_run_pipeline][llm] ERROR: {dll}/{file} not found in {idx_path}")
  sys.exit(3)
funcs=file_info.get('functions',[])
names=[]
if isinstance(funcs,list):
  for fi in funcs:
    if isinstance(fi,dict) and 'name' in fi:
      names.append(fi['name'])
else:
  names=list(funcs.keys())
if func not in names:
  print(f"[ubuntu_run_pipeline][llm] ERROR: Function '{func}' not found in index under {dll}/{file}.")
  print("[ubuntu_run_pipeline][llm] Hint: check --target-dll/--target-file, or rebuild the index against the correct Wine tree.")
  sys.exit(3)
print(f"[ubuntu_run_pipeline][llm] OK: found {func} in index")
PY
    # 生成 spec + stub 到 outdir，再拷贝到 klee/oda_stubs.c 供 harness include
    python3 scripts/generate_oda_with_llm.py \
      --index rag/index.json \
      --wine-root "$WINE_ROOT" \
      --dll "$TARGET_DLL" \
      --file "$TARGET_FILE" \
      --func "$API_NAME" \
      --outdir "$OUTDIR" \
      --allow-fallback
    cp -f "$OUTDIR/oda_stubs.c" klee/oda_stubs.c
    ;;
  none)
    log "STUB_MODE=none: use empty oda_stubs.c"
    echo "// No external dependencies" > klee/oda_stubs.c
    ;;
  *)
    echo "ERROR: invalid --stub-mode: $STUB_MODE (expected spec|llm|none)" >&2
    exit 2
    ;;
esac

# --- 3) KLEE ---
HARNESS_FILE="klee/harness_${API_NAME,,}.c"
if [[ ! -f "$HARNESS_FILE" ]]; then
  echo "ERROR: harness not found: $HARNESS_FILE" >&2
  exit 1
fi

log "Running KLEE with harness: $HARNESS_FILE"
(
  cd klee

  # 查找 KLEE include 根目录（期望存在 <root>/klee/klee.h）
  KLEE_INCLUDE=""
  for path in /usr/include /usr/local/include /usr/include/klee /usr/local/include/klee; do
    if [[ -f "$path/klee/klee.h" ]]; then
      KLEE_INCLUDE="$path"; break
    fi
  done
  if [[ -z "$KLEE_INCLUDE" ]]; then
    KLEE_H=$(find /usr -name "klee.h" 2>/dev/null | grep "klee/klee.h" | head -1 || true)
    if [[ -n "$KLEE_H" ]]; then
      KLEE_INCLUDE=$(dirname "$(dirname "$KLEE_H")")
    fi
  fi
  if [[ -z "$KLEE_INCLUDE" ]]; then
    echo "ERROR: klee/klee.h not found; run ./check_klee_installation.sh" >&2
    exit 1
  fi

  log "KLEE include root: $KLEE_INCLUDE"

  rm -rf klee-out-0 harness.bc

  clang -I"$KLEE_INCLUDE" \
    -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone \
    "$(basename "$HARNESS_FILE")" \
    -o harness.bc

  klee \
    --optimize \
    --max-time="$MAX_TIME" \
    --max-memory="$MAX_MEMORY" \
    --output-dir=klee-out-0 \
    --write-test-info \
    --write-paths \
    --write-sym-paths \
    harness.bc

  if [[ -n "$DUMP_KTEST_TOOL" ]]; then
    mkdir -p "$DUMP_KTEST_TOOL"
    python3 ktest_to_cases.py klee-out-0/ -o test_cases.bin --dump-ktest-tool "$DUMP_KTEST_TOOL"
  else
    python3 ktest_to_cases.py klee-out-0/ -o test_cases.bin
  fi
)

# --- 4) 收集产物到 outdir ---
log "Collect artifacts to $OUTDIR"
cp -f "klee/oda_stubs.c" "$OUTDIR/oda_stubs.c"
cp -f "klee/test_cases.bin" "$OUTDIR/test_cases.bin"
cp -f "$HARNESS_FILE" "$OUTDIR/$(basename "$HARNESS_FILE")"

# 复制 KLEE 输出（可能较大）
rm -rf "$OUTDIR/klee-out-0"
cp -R "klee/klee-out-0" "$OUTDIR/klee-out-0"

if [[ -n "$DUMP_KTEST_TOOL" ]]; then
  # DUMP_KTEST_TOOL 可能在 outdir 内，也可能在别处；尽量确保 outdir 下有一份可拉回
  if [[ "$DUMP_KTEST_TOOL" != "$OUTDIR/ktest_tool_dump" ]]; then
    rm -rf "$OUTDIR/ktest_tool_dump"
    cp -R "$DUMP_KTEST_TOOL" "$OUTDIR/ktest_tool_dump" || true
  fi
fi

log "DONE"
log "Artifacts:"
log "  $OUTDIR/oda_stubs.c"
log "  $OUTDIR/test_cases.bin"
log "  $OUTDIR/klee-out-0/*.ktest"
