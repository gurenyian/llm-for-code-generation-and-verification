#!/bin/bash
#
# 检查 KLEE 安装并找到正确的头文件路径
#

echo "=== 检查 KLEE 安装 ==="
echo ""

# 1. 检查 klee 命令
echo "[1/4] 检查 klee 命令..."
if command -v klee &> /dev/null; then
    KLEE_PATH=$(which klee)
    echo "  ✓ 找到 klee: $KLEE_PATH"
    klee --version
else
    echo "  ✗ 未找到 klee 命令"
    echo ""
    echo "请安装 KLEE:"
    echo "  Ubuntu: sudo apt-get install klee"
    echo "  或从源码编译: https://klee.github.io/build-llvm11/"
    exit 1
fi

echo ""

# 2. 查找 klee.h 头文件
echo "[2/4] 查找 klee/klee.h 头文件..."

KLEE_INCLUDE_PATHS=(
    "/usr/include"
    "/usr/local/include"
    "/usr/include/klee"
    "/usr/local/include/klee"
    "$HOME/.local/include"
)

FOUND_PATH=""

for path in "${KLEE_INCLUDE_PATHS[@]}"; do
    if [ -f "$path/klee/klee.h" ]; then
        FOUND_PATH="$path"
        echo "  ✓ 找到 klee.h: $path/klee/klee.h"
        break
    fi
done

if [ -z "$FOUND_PATH" ]; then
    echo "  ✗ 未找到 klee/klee.h"
    echo ""
    echo "尝试搜索整个系统..."
    SEARCH_RESULT=$(find /usr -name "klee.h" 2>/dev/null | head -1)
    
    if [ -n "$SEARCH_RESULT" ]; then
        # 提取目录（去掉 /klee/klee.h）
        FOUND_PATH=$(dirname $(dirname "$SEARCH_RESULT"))
        echo "  ✓ 找到: $SEARCH_RESULT"
        echo "  → 包含路径: $FOUND_PATH"
    else
        echo "  ✗ 系统中没有找到 klee.h"
        echo ""
        echo "可能的原因:"
        echo "  1. KLEE 未正确安装"
        echo "  2. 缺少 KLEE 开发包"
        echo ""
        echo "解决方案:"
        echo "  Ubuntu: sudo apt-get install klee klee-dev"
        exit 1
    fi
fi

echo ""

# 3. 检查 clang
echo "[3/4] 检查 clang..."
if command -v clang &> /dev/null; then
    CLANG_PATH=$(which clang)
    echo "  ✓ 找到 clang: $CLANG_PATH"
    clang --version | head -1
else
    echo "  ✗ 未找到 clang"
    echo "  安装: sudo apt-get install clang"
    exit 1
fi

echo ""

# 4. 测试编译
echo "[4/4] 测试编译..."

TEST_FILE="/tmp/klee_test.c"
cat > "$TEST_FILE" << 'EOF'
#include <klee/klee.h>

int main() {
    int x;
    klee_make_symbolic(&x, sizeof(x), "x");
    return 0;
}
EOF

if clang -I"$FOUND_PATH" -emit-llvm -c -g "$TEST_FILE" -o /tmp/klee_test.bc 2>/dev/null; then
    echo "  ✓ 编译成功"
    rm -f /tmp/klee_test.bc
else
    echo "  ✗ 编译失败"
    echo ""
    echo "尝试使用完整路径:"
    clang -I"$FOUND_PATH" -emit-llvm -c -g "$TEST_FILE" -o /tmp/klee_test.bc
    exit 1
fi

rm -f "$TEST_FILE"

echo ""
echo "=== 检查完成 ==="
echo ""
echo "KLEE 包含路径: $FOUND_PATH"
echo ""
echo "修复方案:"
echo "  1. 编辑 oda_demo/klee/run_klee.sh"
echo "  2. 将 '-I/usr/include/klee' 改为 '-I$FOUND_PATH'"
echo ""
echo "或者运行自动修复:"
echo "  sed -i 's|-I/usr/include/klee|-I$FOUND_PATH|g' oda_demo/klee/run_klee.sh"
echo ""

# 自动修复
read -p "是否自动修复 run_klee.sh? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "klee/run_klee.sh" ]; then
        sed -i "s|-I/usr/include/klee|-I$FOUND_PATH|g" klee/run_klee.sh
        echo "✓ 已修复 klee/run_klee.sh"
    elif [ -f "oda_demo/klee/run_klee.sh" ]; then
        sed -i "s|-I/usr/include/klee|-I$FOUND_PATH|g" oda_demo/klee/run_klee.sh
        echo "✓ 已修复 oda_demo/klee/run_klee.sh"
    else
        echo "✗ 未找到 run_klee.sh"
    fi
    
    # 同时修复 run_full_pipeline.sh
    if [ -f "run_full_pipeline.sh" ]; then
        sed -i "s|-I/usr/include/klee|-I$FOUND_PATH|g" run_full_pipeline.sh
        echo "✓ 已修复 run_full_pipeline.sh"
    elif [ -f "oda_demo/run_full_pipeline.sh" ]; then
        sed -i "s|-I/usr/include/klee|-I$FOUND_PATH|g" oda_demo/run_full_pipeline.sh
        echo "✓ 已修复 oda_demo/run_full_pipeline.sh"
    fi
fi

echo ""
echo "现在可以重新运行:"
echo "  ./run_full_pipeline.sh PathIsRelativeW ../wine"
