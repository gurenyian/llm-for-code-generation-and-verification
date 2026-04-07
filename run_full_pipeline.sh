#!/bin/bash
#
# Wine API 测试生成完整流程
#
# 用法:
#   ./run_full_pipeline.sh [API_NAME] [WINE_ROOT]
#
# 示例:
#   ./run_full_pipeline.sh PathIsRelativeW ../wine
#

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
API_NAME=${1:-PathIsRelativeW}
WINE_ROOT=${2:-../../}
WINDOWS_HOST=${WINDOWS_HOST:-192.168.1.100}
WINDOWS_USER=${WINDOWS_USER:-Administrator}
WINDOWS_PASSWORD=${WINDOWS_PASSWORD:-}
SKIP_WINE_CHECK=${SKIP_WINE_CHECK:-0}

# 打印带颜色的消息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 未安装"
        return 1
    fi
    return 0
}

# 主流程
main() {
    print_header "Wine API 测试生成完整流程"
    
    info "目标 API: $API_NAME"
    info "Wine 根目录: $WINE_ROOT"
    echo ""
    
    # 检查依赖
    info "检查依赖..."
    check_command python3 || exit 1
    check_command clang || exit 1
    check_command klee || exit 1
    success "所有依赖已安装"
    echo ""
    
    # 步骤 1: 构建索引
    print_header "[1/7] 构建索引"
    
    if [ ! -f "rag/index.json" ]; then
        info "扫描 Wine 源码..."
        cd rag
        python3 build_index.py "$WINE_ROOT/dlls" -o index.json
        cd ..
        success "索引构建完成"
    else
        warning "索引已存在，跳过构建"
    fi
    echo ""
    
    # 步骤 2: 生成 ODA stub
    print_header "[2/7] 生成 ODA stub"
    
    SPEC_FILE="specs/${API_NAME,,}.json"  # 转小写
    
    if [ -f "$SPEC_FILE" ]; then
        info "使用规约: $SPEC_FILE"
        cd specs
        python3 gen_oda_stub.py "$(basename $SPEC_FILE)" -o ../klee/oda_stubs.c
        cd ..
        success "ODA stub 生成完成"
    else
        warning "未找到 ODA 规约: $SPEC_FILE"
        warning "假设 $API_NAME 无外部依赖"
        echo "// No external dependencies" > klee/oda_stubs.c
    fi
    echo ""
    
    # 步骤 3: 运行 KLEE
    print_header "[3/7] 运行 KLEE"
    
    HARNESS_FILE="klee/harness_${API_NAME,,}.c"
    
    if [ ! -f "$HARNESS_FILE" ]; then
        error "未找到 harness: $HARNESS_FILE"
        error "请先创建 KLEE harness 文件"
        exit 1
    fi
    
    info "使用 harness: $HARNESS_FILE"
    cd klee
    
    # 查找 KLEE 头文件路径
    info "查找 KLEE 头文件..."
    KLEE_INCLUDE=""
    
    # 尝试常见路径
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
        error "未找到 klee/klee.h"
        error "请运行: ./check_klee_installation.sh"
        exit 1
    fi
    
    success "找到 KLEE 头文件: $KLEE_INCLUDE/klee/klee.h"
    
    # 编译为 LLVM bitcode
    info "编译为 LLVM bitcode..."
    clang -I"$KLEE_INCLUDE" \
        -emit-llvm \
        -c \
        -g \
        -O0 \
        -Xclang -disable-O0-optnone \
        "$(basename $HARNESS_FILE)" \
        -o harness.bc
    
    # 运行 KLEE
    info "运行 KLEE 符号执行..."
    rm -rf klee-out-0  # 清理旧输出
    
    klee \
        --optimize \
        --max-time=60s \
        --max-memory=2048 \
        --output-dir=klee-out-0 \
        --write-test-info \
        harness.bc
    
    KTEST_COUNT=$(ls -1 klee-out-0/*.ktest 2>/dev/null | wc -l)
    success "KLEE 完成，生成 $KTEST_COUNT 个测试用例"
    cd ..
    echo ""
    
    # 步骤 4: 转换测试用例
    print_header "[4/7] 转换测试用例"
    
    cd klee
    python3 ktest_to_cases.py klee-out-0/ -o test_cases.bin
    success "测试用例已转换为 test_cases.bin"
    cd ..
    echo ""
    
    # 步骤 5: Windows 录制
    print_header "[5/7] Windows 录制"
    
    if [ -z "$WINDOWS_PASSWORD" ]; then
        warning "未设置 WINDOWS_PASSWORD 环境变量"
        warning "跳过 Windows 录制（使用模拟 oracle）"
        
        # 创建模拟 oracle（用于演示）
        info "创建模拟 oracle..."
        cd runner
        # 这里应该调用 Windows，但为了演示，我们创建一个空文件
        touch oracle.bin
        warning "这是模拟 oracle，实际使用时需要真实 Windows"
        cd ..
    else
        info "连接到 Windows: $WINDOWS_HOST"
        cd runner
        
        # 检查是否有 test_runner.c
        if [ ! -f "test_runner.c" ]; then
            error "未找到 test_runner.c"
            exit 1
        fi
        
        # 使用 SSH 上传并运行
        info "上传测试用例..."
        scp ../klee/test_cases.bin "$WINDOWS_USER@$WINDOWS_HOST:C:/temp/"
        
        info "在 Windows 上运行录制..."
        ssh "$WINDOWS_USER@$WINDOWS_HOST" \
            "C:/path/to/test_runner_win.exe --record C:/temp/test_cases.bin C:/temp/oracle.bin"
        
        info "下载 oracle..."
        scp "$WINDOWS_USER@$WINDOWS_HOST:C:/temp/oracle.bin" .
        
        success "Windows 录制完成"
        cd ..
    fi
    echo ""
    
    # 步骤 6: 编译 Wine 版本
    print_header "[6/7] 编译 Wine 版本"

    if [ "$SKIP_WINE_CHECK" = "1" ]; then
        warning "SKIP_WINE_CHECK=1，跳过 Wine 编译与检查"
        RESULT=0
        print_header "完成"
        warning "已跳过 Wine 校验步骤（未进行差分检查）"
        return 0
    fi
    
    cd runner
    
    if [ ! -f "test_runner.c" ]; then
        error "未找到 test_runner.c"
        exit 1
    fi
    
    info "使用 winegcc 编译..."
    
    if command -v ldconfig >/dev/null 2>&1; then
        if ! ldconfig -p | grep -q "libshlwapi"; then
            warning "系统缺少 Wine 开发库（libshlwapi 等），跳过 Wine 校验"
            return 0
        fi
    fi

    if check_command winegcc; then
        WINE_ARCH_FLAG=""
        if [ -n "${WINE_ARCH:-}" ]; then
            if [ "$WINE_ARCH" = "32" ] || [ "$WINE_ARCH" = "x86" ]; then
                WINE_ARCH_FLAG="-m32"
            elif [ "$WINE_ARCH" = "64" ] || [ "$WINE_ARCH" = "x86_64" ]; then
                WINE_ARCH_FLAG="-m64"
            fi
        else
            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
                WINE_ARCH_FLAG="-m64"
            else
                WINE_ARCH_FLAG="-m32"
            fi
        fi
        winegcc $WINE_ARCH_FLAG -o test_runner_wine test_runner.c -lshlwapi
        success "编译完成: test_runner_wine"
    else
        error "winegcc 未安装"
        error "请安装: sudo apt-get install wine-dev"
        exit 1
    fi
    
    cd ..
    echo ""
    
    # 步骤 7: Wine 检查
    print_header "[7/7] Wine 检查"
    
    cd runner
    
    if [ ! -f "oracle.bin" ]; then
        error "未找到 oracle.bin"
        error "请先运行 Windows 录制"
        exit 1
    fi
    
    info "运行 Wine 测试..."
    
    # 运行测试并捕获输出
    if ./test_runner_wine --check ../klee/test_cases.bin oracle.bin; then
        success "所有测试通过！"
        RESULT=0
    else
        error "有测试失败"
        RESULT=1
    fi
    
    cd ..
    echo ""
    
    # 总结
    print_header "完成"
    
    if [ $RESULT -eq 0 ]; then
        success "✓ $API_NAME 的所有测试通过"
        success "生成的文件:"
        success "  - rag/index.json (索引)"
        success "  - klee/test_cases.bin (测试用例)"
        success "  - runner/oracle.bin (Windows oracle)"
        success "  - runner/test_runner_wine (Wine 测试程序)"
    else
        error "✗ $API_NAME 有测试失败"
        warning "请查看上面的错误信息"
        warning "可以将失败信息反馈给 LLM 进行修正"
    fi
    
    echo ""
    return $RESULT
}

# 运行主流程
main "$@"
