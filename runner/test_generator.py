#!/usr/bin/env python3
"""
自动生成跨平台测试代码

直接解析 KLEE 的 .ktest 二进制文件（不依赖 ktest-tool），
然后生成完整的跨平台测试程序。

用法:
    python3 test_generator.py \
        --function lstrcatW \
        --klee-output output/klee-out \
        --output test_lstrcatW.c
"""

import argparse
import struct
import os
from pathlib import Path
from typing import List, Dict, Any


def parse_ktest(path: str) -> Dict[str, bytes]:
    """
    直接解析 .ktest 二进制文件，不依赖 ktest-tool。

    .ktest 格式 (所有整数均为大端序 big-endian):
      magic:       b"KTEST" (5 bytes)
      version:     uint32
      num_args:    uint32
      args:        [len uint32, data bytes] * num_args
      symArgvs:    uint32  (version >= 2 才有)
      symArgvLen:  uint32  (version >= 2 才有)
      num_objects: uint32
      objects:     [name_len uint32, name bytes, data_len uint32, data bytes] * num_objects
    """
    objects = {}
    try:
        with open(path, 'rb') as f:
            def read_uint32():
                return struct.unpack('>I', f.read(4))[0]

            # magic (5 bytes)
            magic = f.read(5)
            if magic not in (b'KTEST', b'BOUT\n'):
                print(f"  警告: {path} 不是有效的 ktest 文件 (magic={magic})")
                return {}

            version = read_uint32()

            # args
            num_args = read_uint32()
            for _ in range(num_args):
                arg_len = read_uint32()
                f.read(arg_len)

            # symArgvs / symArgvLen (version >= 2)
            if version >= 2:
                read_uint32()  # symArgvs
                read_uint32()  # symArgvLen

            # objects
            num_objects = read_uint32()
            for _ in range(num_objects):
                name_len = read_uint32()
                name = f.read(name_len).decode('utf-8', errors='replace').rstrip('\x00')
                data_len = read_uint32()
                data = f.read(data_len)
                objects[name] = data

    except Exception as e:
        print(f"  警告: 解析 {path} 失败: {e}")
    return objects


def bytes_to_wchar_array(data: bytes, max_chars: int = 32) -> str:
    """将字节数据转换为 WCHAR 数组初始化器"""
    # 每2字节一个 WCHAR (UTF-16LE)
    chars = []
    for i in range(0, min(len(data), max_chars * 2), 2):
        if i + 1 < len(data):
            val = data[i] | (data[i+1] << 8)
        else:
            val = data[i]
        chars.append(f"0x{val:04x}")
    if not chars:
        chars = ["0x0000"]
    # 确保以 null 结尾
    if chars[-1] != "0x0000":
        chars.append("0x0000")
    return ", ".join(chars)


def bytes_to_int(data: bytes) -> int:
    """将字节数据转换为整数（小端序）"""
    if not data:
        return 0
    try:
        # KLEE 的 int 对象是小端序
        return struct.unpack_from('<I', data[:4])[0]
    except:
        return data[0] if data else 0


def generate_test_c(function_name: str, test_cases: List[Dict[str, bytes]]) -> str:
    """生成完整的跨平台测试 C 代码"""

    # 生成测试用例数组
    tc_structs = []
    for i, tc in enumerate(test_cases):
        dest_data = tc.get('dest', b'\x00\x00')
        src_data  = tc.get('src',  b'\x00\x00')
        dest_null = bytes_to_int(tc.get('dest_is_null', b'\x00'))
        src_null  = bytes_to_int(tc.get('src_is_null',  b'\x00'))

        dest_arr = bytes_to_wchar_array(dest_data)
        src_arr  = bytes_to_wchar_array(src_data)

        tc_structs.append(
            f"    /* test {i+1:03d} */\n"
            f"    {{ {{{dest_arr}}}, {{{src_arr}}}, {dest_null}, {src_null} }}"
        )

    tc_array = ",\n".join(tc_structs) if tc_structs else "    /* no test cases */"
    num_cases = len(test_cases)

    return f"""\
/*
 * 自动生成的跨平台测试程序：{function_name}
 *
 * 从 KLEE 输出自动生成（共 {num_cases} 个测试用例）
 *
 * 用法:
 *   Windows: {function_name}_test.exe --record oracle.bin
 *   Linux:   ./{function_name}_test --check oracle.bin
 *
 * 生成工具: test_generator.py
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#  include <windows.h>
#else
/* Linux: WCHAR = uint16_t，避免与 wchar_t(32bit) 冲突 */
#  include <stdint.h>
typedef uint16_t     WCHAR;
typedef WCHAR*       LPWSTR;
typedef const WCHAR* LPCWSTR;
extern LPWSTR {function_name}(LPWSTR dest, LPCWSTR src);
#endif

/* 比较两个 WCHAR 字符串（不依赖 wcscmp） */
static int wchar_eq(const WCHAR* a, const WCHAR* b) {{
    while (*a && *b) {{ if (*a != *b) return 0; a++; b++; }}
    return *a == *b;
}}

/* ---- 测试用例数据 ---- */

typedef struct {{
    WCHAR dest[64];
    WCHAR src[64];
    int   dest_is_null;
    int   src_is_null;
}} TestCase;

static int num_test_cases = {num_cases};

static TestCase test_cases[] = {{
{tc_array}
}};

/* ---- Oracle ---- */

typedef struct {{
    LPWSTR result_offset; /* 相对于 dest 的偏移，NULL 表示返回 NULL */
    WCHAR  dest_after[64];
    int    returned_null;
}} Oracle;

static Oracle* oracles = NULL;

/* ---- 测试统计 ---- */

static int passed = 0, failed = 0;

/* ---- 运行单个测试 ---- */

static void run_test(int idx, int record_mode) {{
    TestCase* tc = &test_cases[idx];

    WCHAR dest_copy[64];
    memcpy(dest_copy, tc->dest, sizeof(dest_copy));

    LPWSTR  dest_ptr = tc->dest_is_null ? NULL : dest_copy;
    LPCWSTR src_ptr  = tc->src_is_null  ? NULL : tc->src;

    printf("  [%03d] dest=%s src=%s  ->  ",
           idx + 1,
           tc->dest_is_null ? "NULL" : "(str)",
           tc->src_is_null  ? "NULL" : "(str)");

    LPWSTR result = {function_name}(dest_ptr, src_ptr);

    if (record_mode) {{
        oracles[idx].returned_null = (result == NULL);
        if (dest_ptr)
            memcpy(oracles[idx].dest_after, dest_ptr, sizeof(dest_copy));
        printf("recorded\\n");
    }} else {{
        Oracle* o = &oracles[idx];
        int ok = 1;

        if ((result == NULL) != o->returned_null) {{
            printf("FAIL (return NULL mismatch)\\n");
            ok = 0;
        }} else if (dest_ptr && !wchar_eq(dest_ptr, o->dest_after)) {{
            printf("FAIL (dest content mismatch)\\n");
            ok = 0;
        }}

        if (ok) {{ printf("PASS\\n"); passed++; }}
        else     {{ failed++; }}
    }}
}}

/* ---- main ---- */

int main(int argc, char* argv[]) {{
    if (argc < 3) {{
        printf("用法: %s --record|--check oracle.bin\\n", argv[0]);
        return 1;
    }}

    int         record_mode = (strcmp(argv[1], "--record") == 0);
    const char* oracle_file = argv[2];

    oracles = (Oracle*)calloc(num_test_cases, sizeof(Oracle));
    if (!oracles) {{ perror("calloc"); return 1; }}

    if (record_mode) {{
        printf("=== Windows 录制模式 (%d 个测试用例) ===\\n", num_test_cases);
        for (int i = 0; i < num_test_cases; i++)
            run_test(i, 1);

        FILE* f = fopen(oracle_file, "wb");
        if (!f) {{ perror("fopen"); free(oracles); return 1; }}
        fwrite(&num_test_cases, sizeof(int), 1, f);
        fwrite(oracles, sizeof(Oracle), num_test_cases, f);
        fclose(f);
        printf("\\n[OK] Oracle 已保存到 %s\\n", oracle_file);

    }} else {{
        printf("=== Linux/Wine 检查模式 (%d 个测试用例) ===\\n", num_test_cases);

        FILE* f = fopen(oracle_file, "rb");
        if (!f) {{ perror("fopen"); free(oracles); return 1; }}
        int saved;
        fread(&saved, sizeof(int), 1, f);
        if (saved != num_test_cases)
            printf("警告: oracle 有 %d 个用例，程序有 %d 个\\n", saved, num_test_cases);
        fread(oracles, sizeof(Oracle), num_test_cases, f);
        fclose(f);

        for (int i = 0; i < num_test_cases; i++)
            run_test(i, 0);

        printf("\\n=== 结果: %d 通过 / %d 失败 / %d 总计 ===\\n",
               passed, failed, passed + failed);
        free(oracles);
        return (failed > 0) ? 1 : 0;
    }}

    free(oracles);
    return 0;
}}
"""


def main():
    parser = argparse.ArgumentParser(description='自动生成跨平台测试代码')
    parser.add_argument('--function',    required=True, help='函数名，如 lstrcatW')
    parser.add_argument('--klee-output', required=True, help='KLEE 输出目录')
    parser.add_argument('--output',      required=True, help='输出 .c 文件路径')
    args = parser.parse_args()

    klee_dir = Path(args.klee_output)
    ktest_files = sorted(klee_dir.glob("*.ktest"))

    print(f"找到 {len(ktest_files)} 个 .ktest 文件，开始解析...")

    test_cases = []
    for kf in ktest_files:
        objs = parse_ktest(str(kf))
        if objs is not None:   # 即使是空字典也加入，保证数量对应
            test_cases.append(objs)

    print(f"成功解析 {len(test_cases)} 个测试用例")

    code = generate_test_c(args.function, test_cases)

    os.makedirs(os.path.dirname(args.output) if os.path.dirname(args.output) else '.', exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(code)

    print(f"[OK] 测试代码已生成: {args.output}")
    print()
    print("下一步:")
    print(f"  Linux 编译:   gcc -o test_{args.function} {args.output}")
    print(f"  Windows 编译: cl {args.output}")
    print(f"  录制 oracle:  test_{args.function}.exe --record oracle.bin")
    print(f"  运行测试:     ./test_{args.function} --check oracle.bin")


if __name__ == "__main__":
    main()
