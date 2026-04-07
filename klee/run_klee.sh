#!/bin/bash
#
# Run KLEE on PathIsRelativeW harness
#
# Usage:
#   ./run_klee.sh [harness_file.c]
#

set -e

# Default harness file
HARNESS=${1:-harness_pathisrelativew.c}
OUTPUT_DIR="klee-out-0"

echo "=== KLEE 测试用例生成 ==="
echo "Harness: $HARNESS"
echo ""

# Step 1: Compile to LLVM bitcode
echo "[1/3] 编译为 LLVM bitcode..."

# 查找 KLEE 头文件路径
KLEE_INCLUDE=""
for path in /usr/include /usr/local/include /usr/include/klee /usr/local/include/klee; do
    if [ -f "$path/klee/klee.h" ]; then
        KLEE_INCLUDE="$path"
        break
    fi
done

# 如果还没找到，尝试搜索
if [ -z "$KLEE_INCLUDE" ]; then
    KLEE_H=$(find /usr -name "klee.h" 2>/dev/null | grep "klee/klee.h" | head -1)
    if [ -n "$KLEE_H" ]; then
        KLEE_INCLUDE=$(dirname $(dirname "$KLEE_H"))
    fi
fi

if [ -z "$KLEE_INCLUDE" ]; then
    echo "错误: 未找到 klee/klee.h"
    echo "请运行: ../check_klee_installation.sh"
    exit 1
fi

echo "  使用 KLEE 头文件: $KLEE_INCLUDE/klee/klee.h"

clang -I"$KLEE_INCLUDE" \
    -emit-llvm \
    -c \
    -g \
    -O0 \
    -Xclang -disable-O0-optnone \
    "$HARNESS" \
    -o harness.bc

if [ $? -ne 0 ]; then
    echo "错误: 编译失败"
    exit 1
fi

echo "  ✓ 生成 harness.bc"
echo ""

# Step 2: Run KLEE
echo "[2/3] 运行 KLEE 符号执行..."
echo "  参数:"
echo "    - 最大时间: 60 秒"
echo "    - 最大内存: 2048 MB"
echo "    - 输出目录: $OUTPUT_DIR"
echo ""

# Remove old output directory
if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi

klee \
    --optimize \
    --max-time=60s \
    --max-memory=2048 \
    --output-dir="$OUTPUT_DIR" \
    --write-test-info \
    --write-paths \
    --write-sym-paths \
    harness.bc

if [ $? -ne 0 ]; then
    echo "错误: KLEE 执行失败"
    exit 1
fi

echo ""
echo "  ✓ KLEE 执行完成"
echo ""

# Step 3: Show results
echo "[3/3] 生成的测试用例:"
echo ""

KTEST_COUNT=$(ls -1 "$OUTPUT_DIR"/*.ktest 2>/dev/null | wc -l)

if [ $KTEST_COUNT -eq 0 ]; then
    echo "  警告: 没有生成测试用例"
    exit 1
fi

echo "  总计: $KTEST_COUNT 个测试用例"
echo ""

# Show first few test cases
for ktest in $(ls "$OUTPUT_DIR"/*.ktest | head -5); do
    echo "  - $(basename $ktest)"
    
    # Try to show the input (if ktest-tool is available)
    if command -v ktest-tool &> /dev/null; then
        echo "    输入:"
        ktest-tool --write-ints "$ktest" 2>/dev/null | grep -A 3 "object 0:" | tail -3 | sed 's/^/      /'
    fi
    echo ""
done

if [ $KTEST_COUNT -gt 5 ]; then
    echo "  ... 还有 $((KTEST_COUNT - 5)) 个测试用例"
    echo ""
fi

# Show statistics
echo "=== KLEE 统计信息 ==="
if [ -f "$OUTPUT_DIR/info" ]; then
    cat "$OUTPUT_DIR/info"
else
    echo "  (统计信息不可用)"
fi

echo ""
echo "=== 完成 ==="
echo "下一步: 运行 'python ktest_to_cases.py $OUTPUT_DIR -o test_cases.bin'"
