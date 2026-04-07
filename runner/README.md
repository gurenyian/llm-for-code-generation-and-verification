# Runner 模块：跨平台测试验证

## 核心思想

我们需要验证 LLM 生成的 Wine API 实现是否与真实 Windows 行为一致。

### 两阶段验证流程

```
阶段 1: Windows 录制 (Record)
┌─────────────┐
│ Windows VM  │
│             │
│ 运行测试    │ → 记录每个输入的输出 → oracle.bin
│ (不断言)    │   (真实 Windows 行为)
└─────────────┘

阶段 2: Wine 回放 (Check)
┌─────────────┐
│ Linux VM    │
│             │
│ 运行测试    │ → 对比 oracle.bin → 报告差异
│ (断言)      │   (Wine 实现)
└─────────────┘
```

### 为什么要分两阶段？

**问题**：如果直接在 Wine 上运行测试，我们怎么知道"正确答案"是什么？

**解决方案**：
1. 先在真实 Windows 上运行，记录所有输出（oracle）
2. 再在 Wine 上运行，对比输出是否一致
3. 任何不一致都说明 Wine 实现有 bug

## 文件说明

### wine_test.h

模拟 Wine 测试框架的断言宏：

```c
#ifndef WINE_TEST_H
#define WINE_TEST_H

#include <stdio.h>
#include <stdlib.h>

// 全局计数器
static int test_count = 0;
static int fail_count = 0;

// wine_ok: 类似 Wine 的 ok() 宏
#define wine_ok(condition, ...) \
    do { \
        test_count++; \
        if (!(condition)) { \
            fail_count++; \
            fprintf(stderr, "FAIL (line %d): ", __LINE__); \
            fprintf(stderr, __VA_ARGS__); \
            fprintf(stderr, "\n"); \
        } \
    } while (0)

// 显示测试结果
static void wine_test_summary() {
    printf("\n=== 测试结果 ===\n");
    printf("总计: %d 个测试\n", test_count);
    printf("通过: %d 个\n", test_count - fail_count);
    printf("失败: %d 个\n", fail_count);
    
    if (fail_count == 0) {
        printf("✓ 所有测试通过\n");
    } else {
        printf("✗ 有 %d 个测试失败\n", fail_count);
    }
}

#endif // WINE_TEST_H
```

**为什么要模拟 Wine 测试框架？**
- Wine 的测试代码使用 `ok()` 宏进行断言
- 我们的测试程序需要在 Windows 和 Wine 上都能编译
- Windows 没有 Wine 的测试框架，所以需要自己实现

### test_runner.c

统一的测试执行程序，支持两种模式：

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "wine_test.h"

// Windows API (在 Windows 上链接系统库，在 Wine 上链接 Wine 实现)
#ifdef _WIN32
#include <windows.h>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")
#else
// Wine 环境
#include <wine/windows.h>
#include <wine/shlwapi.h>
#endif

// 测试用例结构
typedef struct {
    WCHAR path[260];
    BOOL expected;  // 仅在 check 模式使用
} TestCase;

// 从二进制文件加载测试用例
int load_test_cases(const char *filename, TestCase **cases) {
    FILE *f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "无法打开: %s\n", filename);
        return 0;
    }
    
    // 读取用例数量
    uint32_t count;
    fread(&count, sizeof(count), 1, f);
    
    *cases = malloc(count * sizeof(TestCase));
    
    // 读取每个用例
    for (uint32_t i = 0; i < count; i++) {
        // 读取对象数量
        uint32_t obj_count;
        fread(&obj_count, sizeof(obj_count), 1, f);
        
        for (uint32_t j = 0; j < obj_count; j++) {
            // 读取对象名
            uint32_t name_len;
            fread(&name_len, sizeof(name_len), 1, f);
            char *name = malloc(name_len + 1);
            fread(name, 1, name_len, f);
            name[name_len] = '\0';
            
            // 读取数据
            uint32_t data_len;
            fread(&data_len, sizeof(data_len), 1, f);
            
            if (strcmp(name, "path") == 0) {
                // 复制路径数据
                fread((*cases)[i].path, 1, 
                      data_len < sizeof((*cases)[i].path) ? data_len : sizeof((*cases)[i].path), 
                      f);
            } else {
                // 跳过未知对象
                fseek(f, data_len, SEEK_CUR);
            }
            
            free(name);
        }
    }
    
    fclose(f);
    return count;
}

// 录制模式：运行测试并保存结果
void record_mode(const char *input_file, const char *output_file) {
    printf("=== 录制模式 (Windows) ===\n");
    
    TestCase *cases;
    int count = load_test_cases(input_file, &cases);
    
    printf("加载了 %d 个测试用例\n", count);
    
    // 打开输出文件
    FILE *f = fopen(output_file, "wb");
    fwrite(&count, sizeof(count), 1, f);
    
    // 运行每个测试用例
    for (int i = 0; i < count; i++) {
        BOOL result = PathIsRelativeW(cases[i].path);
        
        // 保存结果
        fwrite(&result, sizeof(result), 1, f);
        
        // 显示进度
        if ((i + 1) % 10 == 0 || i == count - 1) {
            printf("  进度: %d/%d\r", i + 1, count);
            fflush(stdout);
        }
    }
    
    fclose(f);
    free(cases);
    
    printf("\n录制完成: %s\n", output_file);
}

// 检查模式：运行测试并对比 oracle
void check_mode(const char *input_file, const char *oracle_file) {
    printf("=== 检查模式 (Wine) ===\n");
    
    TestCase *cases;
    int count = load_test_cases(input_file, &cases);
    
    printf("加载了 %d 个测试用例\n", count);
    
    // 加载 oracle
    FILE *f = fopen(oracle_file, "rb");
    if (!f) {
        fprintf(stderr, "无法打开 oracle: %s\n", oracle_file);
        return;
    }
    
    uint32_t oracle_count;
    fread(&oracle_count, sizeof(oracle_count), 1, f);
    
    if (oracle_count != count) {
        fprintf(stderr, "警告: oracle 用例数 (%d) 与输入不匹配 (%d)\n", 
                oracle_count, count);
    }
    
    // 运行每个测试用例并对比
    for (int i = 0; i < count && i < oracle_count; i++) {
        BOOL expected;
        fread(&expected, sizeof(expected), 1, f);
        
        BOOL actual = PathIsRelativeW(cases[i].path);
        
        // 断言结果一致
        wine_ok(actual == expected, 
                "测试 %d: PathIsRelativeW(\"%ls\") = %d, 期望 %d",
                i, cases[i].path, actual, expected);
    }
    
    fclose(f);
    free(cases);
    
    wine_test_summary();
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("用法:\n");
        printf("  录制: %s --record <input.bin> <oracle.bin>\n", argv[0]);
        printf("  检查: %s --check <input.bin> <oracle.bin>\n", argv[0]);
        return 1;
    }
    
    if (strcmp(argv[1], "--record") == 0) {
        record_mode(argv[2], argv[3]);
    } else if (strcmp(argv[1], "--check") == 0) {
        check_mode(argv[2], argv[3]);
    } else {
        fprintf(stderr, "未知模式: %s\n", argv[1]);
        return 1;
    }
    
    return 0;
}
```

### build_windows.bat

Windows 编译脚本：

```batch
@echo off
REM 编译 Windows 版本的测试程序

echo === 编译 Windows 测试程序 ===

cl /nologo /W3 /O2 ^
    test_runner.c ^
    /Fe:test_runner_win.exe ^
    /link shlwapi.lib

if %ERRORLEVEL% NEQ 0 (
    echo 编译失败
    exit /b 1
)

echo 编译成功: test_runner_win.exe
```

### build_wine.sh

Wine 编译脚本：

```bash
#!/bin/bash
# 编译 Wine 版本的测试程序

echo "=== 编译 Wine 测试程序 ==="

# 使用 winegcc (Wine 的交叉编译器)
winegcc -o test_runner_wine test_runner.c -lshlwapi

if [ $? -ne 0 ]; then
    echo "编译失败"
    exit 1
fi

echo "编译成功: test_runner_wine"
```

### run_tests.py

SSH 控制脚本，自动化跨平台测试：

```python
#!/usr/bin/env python3
"""
跨平台测试控制脚本

用法:
    # Windows 录制
    python run_tests.py --platform windows --mode record \\
        --input test_cases.bin --output oracle.bin
    
    # Wine 检查
    python run_tests.py --platform wine --mode check \\
        --input test_cases.bin --oracle oracle.bin
"""

import argparse
import paramiko
import os
from pathlib import Path


class RemoteRunner:
    """远程执行器（通过 SSH）"""
    
    def __init__(self, host, username, password=None, key_file=None):
        self.host = host
        self.username = username
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        if key_file:
            self.ssh.connect(host, username=username, key_filename=key_file)
        else:
            self.ssh.connect(host, username=username, password=password)
    
    def upload_file(self, local_path, remote_path):
        """上传文件"""
        sftp = self.ssh.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()
        print(f"  上传: {local_path} → {remote_path}")
    
    def download_file(self, remote_path, local_path):
        """下载文件"""
        sftp = self.ssh.open_sftp()
        sftp.get(remote_path, local_path)
        sftp.close()
        print(f"  下载: {remote_path} → {local_path}")
    
    def execute(self, command):
        """执行命令"""
        stdin, stdout, stderr = self.ssh.exec_command(command)
        return stdout.read().decode(), stderr.read().decode()
    
    def close(self):
        self.ssh.close()


def run_windows_record(args):
    """在 Windows 上录制 oracle"""
    print("=== Windows 录制模式 ===")
    
    runner = RemoteRunner(
        args.windows_host,
        args.windows_user,
        password=args.windows_password,
        key_file=args.windows_key
    )
    
    # 上传测试用例
    runner.upload_file(args.input, "C:\\temp\\test_cases.bin")
    
    # 运行测试
    print("  运行测试...")
    stdout, stderr = runner.execute(
        "C:\\path\\to\\test_runner_win.exe --record C:\\temp\\test_cases.bin C:\\temp\\oracle.bin"
    )
    print(stdout)
    if stderr:
        print("错误:", stderr)
    
    # 下载 oracle
    runner.download_file("C:\\temp\\oracle.bin", args.output)
    
    runner.close()
    print("✓ 录制完成")


def run_wine_check(args):
    """在 Wine 上检查"""
    print("=== Wine 检查模式 ===")
    
    # 本地运行（假设在 Linux 上）
    import subprocess
    
    result = subprocess.run(
        ["./test_runner_wine", "--check", args.input, args.oracle],
        capture_output=True,
        text=True
    )
    
    print(result.stdout)
    if result.stderr:
        print("错误:", result.stderr)
    
    if result.returncode == 0:
        print("✓ 所有测试通过")
    else:
        print("✗ 有测试失败")
        return 1
    
    return 0


def main():
    parser = argparse.ArgumentParser(description="跨平台测试控制")
    parser.add_argument("--platform", choices=["windows", "wine"], required=True)
    parser.add_argument("--mode", choices=["record", "check"], required=True)
    parser.add_argument("--input", required=True, help="测试用例文件")
    parser.add_argument("--output", help="输出文件 (record 模式)")
    parser.add_argument("--oracle", help="Oracle 文件 (check 模式)")
    
    # Windows SSH 配置
    parser.add_argument("--windows-host", default="192.168.1.100")
    parser.add_argument("--windows-user", default="Administrator")
    parser.add_argument("--windows-password")
    parser.add_argument("--windows-key")
    
    args = parser.parse_args()
    
    if args.platform == "windows" and args.mode == "record":
        run_windows_record(args)
    elif args.platform == "wine" and args.mode == "check":
        run_wine_check(args)
    else:
        print(f"不支持的组合: {args.platform} + {args.mode}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
```

## 完整流程示例

### 步骤 1: 生成测试用例（KLEE）

```bash
cd ../klee
./run_klee.sh
python ktest_to_cases.py klee-out-0/ -o test_cases.bin
```

### 步骤 2: Windows 录制

```bash
cd ../runner

# 编译 Windows 版本（在 Windows 上）
build_windows.bat

# 运行录制（通过 SSH）
python run_tests.py \
    --platform windows \
    --mode record \
    --input ../klee/test_cases.bin \
    --output oracle.bin \
    --windows-host 192.168.1.100 \
    --windows-user Administrator \
    --windows-password YourPassword
```

### 步骤 3: Wine 检查

```bash
# 编译 Wine 版本（在 Linux 上）
./build_wine.sh

# 运行检查
python run_tests.py \
    --platform wine \
    --mode check \
    --input ../klee/test_cases.bin \
    --oracle oracle.bin
```

### 预期输出

如果 Wine 实现正确：
```
=== 检查模式 (Wine) ===
加载了 8 个测试用例

=== 测试结果 ===
总计: 8 个测试
通过: 8 个
失败: 0 个
✓ 所有测试通过
```

如果有 bug：
```
=== 检查模式 (Wine) ===
加载了 8 个测试用例
FAIL (line 123): 测试 3: PathIsRelativeW("C:\") = 1, 期望 0

=== 测试结果 ===
总计: 8 个测试
通过: 7 个
失败: 1 个
✗ 有 1 个测试失败
```

## 与 LLM 集成

当 LLM 生成的代码测试失败时，可以提供反馈：

```python
def provide_feedback_to_llm(failed_tests):
    feedback = "以下测试用例失败:\n"
    
    for test in failed_tests:
        feedback += f"- 输入: {test.input}\n"
        feedback += f"  期望: {test.expected}\n"
        feedback += f"  实际: {test.actual}\n"
        feedback += f"  Windows 行为: {test.windows_behavior}\n\n"
    
    prompt = f"""
    你生成的 PathIsRelativeW 实现有以下问题:
    
    {feedback}
    
    请分析原因并修正代码。
    """
    
    return llm.generate(prompt)
```

## 下一步

完整示例见 [examples/pathisrelativew/](../examples/pathisrelativew/)
