#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# 解码凭据（Base64 字符串写死，避免依赖外部文件）
ODA_LLM_API_KEY_B64="c2stcHJvai1tU0h1R1VZRXhyTHJ4VVlrOGlKNE4zeFN3ck1ELWs1RGxadTdYcWxwb1k4Ul9HZUFFd2ZoSU1MWlpvYzBJZWZqOU1ROE5BOUFrWVQzQmxia0ZKd2VBbk1WbXFZOXplbUp6YTRDLUV5Q1p1TmxxUWg2RmdMb2x2QUF1U2hLYU1NSHA2M0VvdHhGWnhFVDkyTzJETjZzamFLVkhrTUE="
ODA_LLM_MODEL_B64="Z3B0LTRvLW1pbmk="
HTTP_PROXY_B64="aHR0cDovLzEyNy4wLjAuMTo3ODkw"
HTTPS_PROXY_B64="aHR0cDovLzEyNy4wLjAuMTo3ODkw"
ALL_PROXY_B64="c29ja3M1Oi8vMTI3LjAuMC4xOjc4OTA="

export ODA_LLM_API_KEY="$(printf "%s" "$ODA_LLM_API_KEY_B64" | base64 -d)"
export ODA_LLM_MODEL="$(printf "%s" "$ODA_LLM_MODEL_B64" | base64 -d)"
export HTTP_PROXY="$(printf "%s" "$HTTP_PROXY_B64" | base64 -d)"
export HTTPS_PROXY="$(printf "%s" "$HTTPS_PROXY_B64" | base64 -d)"
export ALL_PROXY="$(printf "%s" "$ALL_PROXY_B64" | base64 -d)"
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export all_proxy="$ALL_PROXY"

export ODA_FORCE_NEW_RUN=1

./scripts/ubuntu_run_pipeline.sh --api PathCombineW --wine-root /home/guren/wine --stub-mode llm --target-dll kernelbase --target-file path.c
