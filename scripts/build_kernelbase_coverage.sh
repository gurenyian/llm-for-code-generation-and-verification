#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR=/home/guren/wine/build64/dlls/kernelbase
MAKEFILE=/home/guren/wine/build64/Makefile

XFLAGS=$(sed -n 's/^x86_64_EXTRACFLAGS = //p' "$MAKEFILE")
XFLAGS="$XFLAGS --coverage -fprofile-arcs -ftest-coverage -O0"

make -C "$BUILD_DIR" clean
make -C "$BUILD_DIR" x86_64_EXTRACFLAGS="$XFLAGS"
