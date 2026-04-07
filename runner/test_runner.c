/*
 * test_runner.c - Cross-platform record/check runner for Wine API differential testing
 *
 * This program consumes test cases generated from KLEE (klee/test_cases.bin),
 * records ground-truth outputs on real Windows (oracle.bin), then replays on
 * Wine (Linux) and asserts that behavior matches the oracle.
 *
 * Modes:
 *   --record <test_cases.bin> <oracle.bin>
 *   --check  <test_cases.bin> <oracle.bin>
 *
 * Notes:
 * - The input format is produced by oda_demo/klee/ktest_to_cases.py.
 * - This runner focuses on PathIsRelativeW first (minimal viable example).
 *   You can extend it to other APIs by changing the 'invoke_target()' section.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <ctype.h>

#if !defined(_WIN32)
#  include <strings.h>
#  define _stricmp strcasecmp
#  include <wine/windows.h>
#  include <wine/shlwapi.h>
#endif

#include "wine_test.h"

#if defined(_WIN32)
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#  include <shlwapi.h>
#  pragma comment(lib, "Shlwapi.lib")
#endif

/* ------------------------ test_cases.bin reader ------------------------ */

typedef struct BinObject {
    char *name;
    uint32_t len;
    uint8_t *data;
} BinObject;

typedef struct TestCase {
    uint32_t object_count;
    BinObject *objects;
} TestCase;

static int read_u32_le(FILE *f, uint32_t *out)
{
    uint8_t b[4];
    if (fread(b, 1, 4, f) != 4) return 0;
    *out = (uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24);
    return 1;
}

static void free_test_cases(uint32_t count, TestCase *cases)
{
    if (!cases) return;
    for (uint32_t i = 0; i < count; i++)
    {
        for (uint32_t j = 0; j < cases[i].object_count; j++)
        {
            free(cases[i].objects[j].name);
            free(cases[i].objects[j].data);
        }
        free(cases[i].objects);
    }
    free(cases);
}

static int load_test_cases_bin(const char *path, uint32_t *out_count, TestCase **out_cases)
{
    FILE *f = fopen(path, "rb");
    if (!f)
    {
        fprintf(stderr, "无法打开用例文件: %s\n", path);
        return 0;
    }

    uint32_t case_count = 0;
    if (!read_u32_le(f, &case_count))
    {
        fprintf(stderr, "用例文件格式错误(读 case_count 失败): %s\n", path);
        fclose(f);
        return 0;
    }

    TestCase *cases = (TestCase *)calloc(case_count, sizeof(TestCase));
    if (!cases)
    {
        fprintf(stderr, "内存不足\n");
        fclose(f);
        return 0;
    }

    for (uint32_t i = 0; i < case_count; i++)
    {
        uint32_t obj_count = 0;
        if (!read_u32_le(f, &obj_count))
        {
            fprintf(stderr, "用例文件格式错误(读 obj_count 失败)，case=%u\n", i);
            free_test_cases(i, cases);
            fclose(f);
            return 0;
        }
        cases[i].object_count = obj_count;
        cases[i].objects = (BinObject *)calloc(obj_count, sizeof(BinObject));
        if (!cases[i].objects)
        {
            fprintf(stderr, "内存不足\n");
            free_test_cases(i, cases);
            fclose(f);
            return 0;
        }

        for (uint32_t j = 0; j < obj_count; j++)
        {
            uint32_t name_len = 0;
            if (!read_u32_le(f, &name_len) || name_len == 0 || name_len > 4096)
            {
                fprintf(stderr, "用例文件格式错误(name_len)，case=%u obj=%u\n", i, j);
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }
            char *name = (char *)malloc((size_t)name_len + 1);
            if (!name)
            {
                fprintf(stderr, "内存不足\n");
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }
            if (fread(name, 1, name_len, f) != name_len)
            {
                fprintf(stderr, "用例文件格式错误(读 name 失败)，case=%u obj=%u\n", i, j);
                free(name);
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }
            name[name_len] = 0;

            uint32_t data_len = 0;
            if (!read_u32_le(f, &data_len) || data_len > (1024 * 1024))
            {
                fprintf(stderr, "用例文件格式错误(data_len)，case=%u obj=%u\n", i, j);
                free(name);
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }
            uint8_t *data = (uint8_t *)malloc(data_len ? data_len : 1);
            if (!data)
            {
                fprintf(stderr, "内存不足\n");
                free(name);
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }
            if (data_len && fread(data, 1, data_len, f) != data_len)
            {
                fprintf(stderr, "用例文件格式错误(读 data 失败)，case=%u obj=%u\n", i, j);
                free(name);
                free(data);
                free_test_cases(i + 1, cases);
                fclose(f);
                return 0;
            }

            cases[i].objects[j].name = name;
            cases[i].objects[j].len = data_len;
            cases[i].objects[j].data = data;
        }
    }

    fclose(f);
    *out_count = case_count;
    *out_cases = cases;
    return 1;
}

static const BinObject *find_obj(const TestCase *tc, const char *name)
{
    for (uint32_t i = 0; i < tc->object_count; i++)
        if (strcmp(tc->objects[i].name, name) == 0)
            return &tc->objects[i];
    return NULL;
}

/* ------------------------ diagnostics helpers ------------------------ */

static void dump_hex_preview(FILE *out, const uint8_t *data, uint32_t len, uint32_t max_bytes)
{
    uint32_t n = (len < max_bytes) ? len : max_bytes;
    for (uint32_t i = 0; i < n; i++)
    {
        fprintf(out, "%02x", (unsigned)data[i]);
        if ((i + 1) % 2 == 0) fputc(' ', out);
    }
    if (len > n) fprintf(out, "...(+%u bytes)", (unsigned)(len - n));
}

static void dump_utf16le_preview(FILE *out, const uint8_t *data, uint32_t len, uint32_t max_wchars)
{
    uint32_t wchar_bytes = max_wchars * 2;
    uint32_t n = (len < wchar_bytes) ? len : wchar_bytes;
    uint32_t pairs = n / 2;
    fputc('"', out);
    for (uint32_t i = 0; i < pairs; i++)
    {
        uint16_t wc = (uint16_t)data[i * 2] | ((uint16_t)data[i * 2 + 1] << 8);
        if (wc == 0) break;
        if (wc < 0x80 && isprint((int)wc))
            fputc((char)wc, out);
        else
            fputc('.', out);
    }
    fputc('"', out);
    if (len > n) fputs("...", out);
}

static void export_bytes_if_possible(const char *filename, const uint8_t *data, uint32_t len)
{
    FILE *f = fopen(filename, "wb");
    if (!f) return;
    if (len) fwrite(data, 1, len, f);
    fclose(f);
}

static void export_mismatch_txt_if_possible(const char *filename, uint32_t case_id, BOOL got, BOOL exp, const BinObject *path)
{
    FILE *f = fopen(filename, "wb");
    if (!f) return;
    fprintf(f, "case=%u got=%d exp=%d\n", (unsigned)case_id, (int)got, (int)exp);
    if (!path)
    {
        fprintf(f, "input.path: <missing>\n");
        fclose(f);
        return;
    }
    fprintf(f, "input.path: len=%u bytes\n", (unsigned)path->len);
    fprintf(f, "utf16 preview: ");
    dump_utf16le_preview(f, path->data, path->len, 64);
    fputc('\n', f);
    fprintf(f, "utf16 hex: ");
    dump_hex_preview(f, path->data, path->len, 128);
    fputc('\n', f);
    fclose(f);
}

/* ------------------------ target invocation ------------------------ */

typedef enum TargetKind {
    TARGET_PATHISRELATIVEW = 1,
    TARGET_LSTRCMPW = 2,
    TARGET_PATHCOMBINEW = 3,
} TargetKind;

static TargetKind parse_target(const char *name)
{
    if (!name) return TARGET_PATHISRELATIVEW;
    if (_stricmp(name, "PathIsRelativeW") == 0) return TARGET_PATHISRELATIVEW;
    if (_stricmp(name, "lstrcmpW") == 0) return TARGET_LSTRCMPW;
    if (_stricmp(name, "PathCombineW") == 0) return TARGET_PATHCOMBINEW;
    return (TargetKind)0;
}

static const char *target_name(TargetKind t)
{
    switch (t)
    {
    case TARGET_PATHISRELATIVEW: return "PathIsRelativeW";
    case TARGET_LSTRCMPW: return "lstrcmpW";
    case TARGET_PATHCOMBINEW: return "PathCombineW";
    default: return "<unknown>";
    }
}

static BOOL invoke_target_PathIsRelativeW(const TestCase *tc)
{
#if defined(_WIN32)
    /* Delay-load from shlwapi.dll so builds that don't link -lshlwapi can still
       succeed (e.g., lstrcmpW-only build links just -lkernel32). */
    typedef BOOL (WINAPI *PFN_PathIsRelativeW)(LPCWSTR);
    static PFN_PathIsRelativeW pPathIsRelativeW = NULL;
    static int resolved = 0;
    if (!resolved)
    {
        HMODULE h = LoadLibraryA("shlwapi.dll");
        if (h) pPathIsRelativeW = (PFN_PathIsRelativeW)GetProcAddress(h, "PathIsRelativeW");
        resolved = 1;
    }
#endif

    const BinObject *obj = find_obj(tc, "path");
    if (!obj || obj->len == 0)
    {
#if defined(_WIN32)
        if (!pPathIsRelativeW) return FALSE;
        return pPathIsRelativeW(NULL);
#else
        return 0;
#endif
    }

    /* 'path' is a serialized byte array from KLEE. Treat it as UTF-16LE buffer. */
    const WCHAR *pathW = (const WCHAR *)obj->data;
#if defined(_WIN32)
    if (!pPathIsRelativeW) return FALSE;
    return pPathIsRelativeW(pathW);
#else
    return 0;
#endif
}

static int normalize_cmp(int r)
{
    if (r < 0) return -1;
    if (r > 0) return 1;
    return 0;
}

static int invoke_target_lstrcmpW(const TestCase *tc)
{
    const BinObject *a = find_obj(tc, "a");
    const BinObject *b = find_obj(tc, "b");
    const WCHAR *aw = (a && a->len) ? (const WCHAR *)a->data : NULL;
    const WCHAR *bw = (b && b->len) ? (const WCHAR *)b->data : NULL;
    return normalize_cmp(lstrcmpW(aw, bw));
}

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

typedef struct PathCombineResult {
    int32_t ret;             /* 0 = NULL, 1 = success */
    uint16_t dst[MAX_PATH];  /* UTF-16LE buffer */
} PathCombineResult;

static PathCombineResult invoke_target_PathCombineW(const TestCase *tc)
{
    PathCombineResult r;
    r.ret = 0;
    memset(r.dst, 0, sizeof(r.dst));

    const BinObject *dir = find_obj(tc, "dir");
    const BinObject *file = find_obj(tc, "file");

    const WCHAR *dirW = (dir && dir->len) ? (const WCHAR *)dir->data : NULL;
    const WCHAR *fileW = (file && file->len) ? (const WCHAR *)file->data : NULL;

    WCHAR dst[MAX_PATH];
    memset(dst, 0, sizeof(dst));

    LPWSTR ret = PathCombineW(dst, dirW, fileW);
    if (ret)
    {
        r.ret = 1;
        memcpy(r.dst, dst, sizeof(dst));
    }
    return r;
}

/* ------------------------ oracle format ------------------------ */

typedef struct OracleHeader {
    uint32_t magic;      /* 'ORCL' little-endian */
    uint32_t version;    /* 1: BOOL results; 2: int32 results */
    uint32_t case_count;
} OracleHeader;

#define ORACLE_MAGIC 0x4c43524fU /* 'ORCL' */
#define ORACLE_VER_BOOL   1
#define ORACLE_VER_I32    2
#define ORACLE_VER_PATHCOMBINE 3

static int write_oracle_v1_bool(const char *path, uint32_t case_count, const BOOL *results)
{
    FILE *f = fopen(path, "wb");
    if (!f) return 0;
    OracleHeader h;
    h.magic = ORACLE_MAGIC;
    h.version = ORACLE_VER_BOOL;
    h.case_count = case_count;
    if (fwrite(&h, sizeof(h), 1, f) != 1) { fclose(f); return 0; }
    if (case_count && fwrite(results, sizeof(BOOL), case_count, f) != case_count) { fclose(f); return 0; }
    fclose(f);
    return 1;
}

static int write_oracle_v2_i32(const char *path, uint32_t case_count, const int32_t *results)
{
    FILE *f = fopen(path, "wb");
    if (!f) return 0;
    OracleHeader h;
    h.magic = ORACLE_MAGIC;
    h.version = ORACLE_VER_I32;
    h.case_count = case_count;
    if (fwrite(&h, sizeof(h), 1, f) != 1) { fclose(f); return 0; }
    if (case_count && fwrite(results, sizeof(int32_t), case_count, f) != case_count) { fclose(f); return 0; }
    fclose(f);
    return 1;
}

static int read_oracle_v1_bool(const char *path, uint32_t *out_case_count, BOOL **out_results)
{
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    OracleHeader h;
    if (fread(&h, sizeof(h), 1, f) != 1) { fclose(f); return 0; }
    if (h.magic != ORACLE_MAGIC || h.version != ORACLE_VER_BOOL) { fclose(f); return 0; }
    BOOL *results = (BOOL *)calloc(h.case_count ? h.case_count : 1, sizeof(BOOL));
    if (!results) { fclose(f); return 0; }
    if (h.case_count && fread(results, sizeof(BOOL), h.case_count, f) != h.case_count)
    {
        free(results);
        fclose(f);
        return 0;
    }
    fclose(f);
    *out_case_count = h.case_count;
    *out_results = results;
    return 1;
}

static int read_oracle_v2_i32(const char *path, uint32_t *out_case_count, int32_t **out_results)
{
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    OracleHeader h;
    if (fread(&h, sizeof(h), 1, f) != 1) { fclose(f); return 0; }
    if (h.magic != ORACLE_MAGIC || h.version != ORACLE_VER_I32) { fclose(f); return 0; }
    int32_t *results = (int32_t *)calloc(h.case_count ? h.case_count : 1, sizeof(int32_t));
    if (!results) { fclose(f); return 0; }
    if (h.case_count && fread(results, sizeof(int32_t), h.case_count, f) != h.case_count)
    {
        free(results);
        fclose(f);
        return 0;
    }
    fclose(f);
    *out_case_count = h.case_count;
    *out_results = results;
    return 1;
}

/* ------------------------ main ------------------------ */

static void usage(const char *argv0)
{
    printf("用法:\n");
    printf("  %s --record <test_cases.bin> <oracle.bin> [--target <name>] [--case <id>]\n", argv0);
    printf("  %s --check  <test_cases.bin> <oracle.bin> [--target <name>] [--case <id>]\n", argv0);
    printf("\n");
    printf("选项:\n");
    printf("  --target <name>  目标函数名: PathIsRelativeW | lstrcmpW | PathCombineW (default: PathIsRelativeW)\n");
    printf("  --case <id>   仅运行指定用例(0-based)。用于快速复现 mismatch。\n");
}

int main(int argc, char **argv)
{
    if (argc != 4 && argc != 6 && argc != 8)
    {
        usage(argv[0]);
        return 2;
    }

    const char *mode = argv[1];
    const char *cases_path = argv[2];
    const char *oracle_path = argv[3];

    const char *target_str = "PathIsRelativeW";
    int have_case_filter = 0;
    uint32_t only_case = 0;

    /* parse optional args: [--target <name>] [--case <id>] in any order */
    for (int i = 4; i + 1 < argc; i += 2)
    {
        if (strcmp(argv[i], "--case") == 0)
        {
            only_case = (uint32_t)strtoul(argv[i + 1], NULL, 10);
            have_case_filter = 1;
        }
        else if (strcmp(argv[i], "--target") == 0)
        {
            target_str = argv[i + 1];
        }
        else
        {
            usage(argv[0]);
            return 2;
        }
    }

    TargetKind target = parse_target(target_str);
    if (!target)
    {
        fprintf(stderr, "未知 target: %s\n", target_str);
        usage(argv[0]);
        return 2;
    }

    uint32_t case_count = 0;
    TestCase *cases = NULL;
    if (!load_test_cases_bin(cases_path, &case_count, &cases))
        return 1;

    if (strcmp(mode, "--record") == 0)
    {
        if (target == TARGET_PATHISRELATIVEW)
        {
            BOOL *results = (BOOL *)calloc(case_count ? case_count : 1, sizeof(BOOL));
            if (!results) { free_test_cases(case_count, cases); return 1; }

            uint32_t start = 0, end = case_count;
            if (have_case_filter)
            {
                if (only_case >= case_count)
                {
                    fprintf(stderr, "--case %u 超出范围 (case_count=%u)\n", only_case, case_count);
                    free(results);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                results[i] = invoke_target_PathIsRelativeW(&cases[i]);
            }

            if (!write_oracle_v1_bool(oracle_path, case_count, results))
            {
                fprintf(stderr, "写入 oracle 失败: %s\n", oracle_path);
                free(results);
                free_test_cases(case_count, cases);
                return 1;
            }

            if (have_case_filter)
                printf("[OK] Windows oracle 已写入: %s (target=%s case=%u/%u)\n", oracle_path, target_name(target), only_case, case_count);
            else
                printf("[OK] Windows oracle 已写入: %s (target=%s cases=%u)\n", oracle_path, target_name(target), case_count);
            free(results);
            free_test_cases(case_count, cases);
            return 0;
        }
    else if (target == TARGET_LSTRCMPW)
        {
            int32_t *results = (int32_t *)calloc(case_count ? case_count : 1, sizeof(int32_t));
            if (!results) { free_test_cases(case_count, cases); return 1; }

            uint32_t start = 0, end = case_count;
            if (have_case_filter)
            {
                if (only_case >= case_count)
                {
                    fprintf(stderr, "--case %u 超出范围 (case_count=%u)\n", only_case, case_count);
                    free(results);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                results[i] = (int32_t)invoke_target_lstrcmpW(&cases[i]);
            }

            if (!write_oracle_v2_i32(oracle_path, case_count, results))
            {
                fprintf(stderr, "写入 oracle 失败: %s\n", oracle_path);
                free(results);
                free_test_cases(case_count, cases);
                return 1;
            }

            if (have_case_filter)
                printf("[OK] Windows oracle 已写入: %s (target=%s case=%u/%u)\n", oracle_path, target_name(target), only_case, case_count);
            else
                printf("[OK] Windows oracle 已写入: %s (target=%s cases=%u)\n", oracle_path, target_name(target), case_count);
            free(results);
            free_test_cases(case_count, cases);
            return 0;
        }
        else /* TARGET_PATHCOMBINEW */
        {
            PathCombineResult *results = (PathCombineResult *)calloc(case_count ? case_count : 1, sizeof(PathCombineResult));
            if (!results) { free_test_cases(case_count, cases); return 1; }

            uint32_t start = 0, end = case_count;
            if (have_case_filter)
            {
                if (only_case >= case_count)
                {
                    fprintf(stderr, "--case %u 超出范围 (case_count=%u)\n", only_case, case_count);
                    free(results);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                results[i] = invoke_target_PathCombineW(&cases[i]);
            }

            FILE *f = fopen(oracle_path, "wb");
            if (!f)
            {
                fprintf(stderr, "写入 oracle 失败(打开文件): %s\n", oracle_path);
                free(results);
                free_test_cases(case_count, cases);
                return 1;
            }
            OracleHeader h;
            h.magic = ORACLE_MAGIC;
            h.version = ORACLE_VER_PATHCOMBINE;
            h.case_count = case_count;
            if (fwrite(&h, sizeof(h), 1, f) != 1) { fclose(f); free(results); free_test_cases(case_count, cases); return 1; }
            for (uint32_t i = 0; i < case_count; i++)
            {
                if (fwrite(&results[i].ret, sizeof(results[i].ret), 1, f) != 1 ||
                    fwrite(results[i].dst, sizeof(uint16_t), MAX_PATH, f) != MAX_PATH)
                {
                    fclose(f);
                    free(results);
                    free_test_cases(case_count, cases);
                    return 1;
                }
            }
            fclose(f);

            if (have_case_filter)
                printf("[OK] Windows oracle 已写入: %s (target=%s case=%u/%u)\n", oracle_path, target_name(target), only_case, case_count);
            else
                printf("[OK] Windows oracle 已写入: %s (target=%s cases=%u)\n", oracle_path, target_name(target), case_count);
            free(results);
            free_test_cases(case_count, cases);
            return 0;
        }
    }

    if (strcmp(mode, "--check") == 0)
    {
        if (target == TARGET_PATHISRELATIVEW)
        {
            uint32_t oracle_count = 0;
            BOOL *oracle_results = NULL;
            if (!read_oracle_v1_bool(oracle_path, &oracle_count, &oracle_results))
            {
                fprintf(stderr, "读取 oracle 失败(期望 v1/BOOL): %s\n", oracle_path);
                free_test_cases(case_count, cases);
                return 1;
            }

            uint32_t n = (case_count < oracle_count) ? case_count : oracle_count;
            if (case_count != oracle_count)
                printf("[WARN] oracle 用例数(%u)与输入(%u)不一致，将对比前 %u 个\n", oracle_count, case_count, n);

            uint32_t start = 0, end = n;
            if (have_case_filter)
            {
                if (only_case >= n)
                {
                    fprintf(stderr, "--case %u 超出范围 (n=%u)\n", only_case, n);
                    free(oracle_results);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                BOOL got = invoke_target_PathIsRelativeW(&cases[i]);
                BOOL exp = oracle_results[i];
                int ok = (got == exp);
                wine_ok(ok, "case %u: PathIsRelativeW(...) got=%d exp=%d", i, (int)got, (int)exp);

                if (!ok)
                {
                    const BinObject *path = find_obj(&cases[i], "path");
                    fprintf(stderr, "[MISMATCH] target=%s case=%u got=%d exp=%d\n", target_name(target), i, (int)got, (int)exp);
                    if (!path)
                    {
                        fprintf(stderr, "  input.path: <missing>\n");
                    }
                    else
                    {
                        fprintf(stderr, "  input.path: len=%u bytes\n", (unsigned)path->len);
                        fprintf(stderr, "  input.path utf16 preview: ");
                        dump_utf16le_preview(stderr, path->data, path->len, 64);
                        fputc('\n', stderr);
                        fprintf(stderr, "  input.path utf16 hex: ");
                        dump_hex_preview(stderr, path->data, path->len, 128);
                        fputc('\n', stderr);

                        char fn[128];
                        snprintf(fn, sizeof(fn), "fail_case_%05u_path.bin", (unsigned)i);
                        export_bytes_if_possible(fn, path->data, path->len);
                        fprintf(stderr, "  exported: %s\n", fn);

                        char fn_txt[128];
                        snprintf(fn_txt, sizeof(fn_txt), "fail_case_%05u.txt", (unsigned)i);
                        export_mismatch_txt_if_possible(fn_txt, i, got, exp, path);
                        fprintf(stderr, "  exported: %s\n", fn_txt);
                    }
                }
            }

            wine_test_summary();
            free(oracle_results);
            free_test_cases(case_count, cases);
            return wine_get_fail_count() ? 1 : 0;
        }
    else if (target == TARGET_LSTRCMPW)
        {
            uint32_t oracle_count = 0;
            int32_t *oracle_results = NULL;
            if (!read_oracle_v2_i32(oracle_path, &oracle_count, &oracle_results))
            {
                fprintf(stderr, "读取 oracle 失败(期望 v2/int32): %s\n", oracle_path);
                free_test_cases(case_count, cases);
                return 1;
            }

            uint32_t n = (case_count < oracle_count) ? case_count : oracle_count;
            if (case_count != oracle_count)
                printf("[WARN] oracle 用例数(%u)与输入(%u)不一致，将对比前 %u 个\n", oracle_count, case_count, n);

            uint32_t start = 0, end = n;
            if (have_case_filter)
            {
                if (only_case >= n)
                {
                    fprintf(stderr, "--case %u 超出范围 (n=%u)\n", only_case, n);
                    free(oracle_results);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                int got = invoke_target_lstrcmpW(&cases[i]);
                int exp = (int)oracle_results[i];
                int ok = (got == exp);
                wine_ok(ok, "case %u: lstrcmpW(...) got=%d exp=%d", i, got, exp);
                if (!ok)
                {
                    const BinObject *a = find_obj(&cases[i], "a");
                    const BinObject *b = find_obj(&cases[i], "b");
                    fprintf(stderr, "[MISMATCH] target=%s case=%u got=%d exp=%d\n", target_name(target), i, got, exp);
                    if (a)
                    {
                        fprintf(stderr, "  input.a len=%u utf16 preview: ", (unsigned)a->len);
                        dump_utf16le_preview(stderr, a->data, a->len, 64);
                        fputc('\n', stderr);
                    }
                    if (b)
                    {
                        fprintf(stderr, "  input.b len=%u utf16 preview: ", (unsigned)b->len);
                        dump_utf16le_preview(stderr, b->data, b->len, 64);
                        fputc('\n', stderr);
                    }
                }
            }

            wine_test_summary();
            free(oracle_results);
            free_test_cases(case_count, cases);
            return wine_get_fail_count() ? 1 : 0;
        }
        else /* TARGET_PATHCOMBINEW */
        {
            FILE *f = fopen(oracle_path, "rb");
            if (!f)
            {
                fprintf(stderr, "读取 oracle 失败: %s\n", oracle_path);
                free_test_cases(case_count, cases);
                return 1;
            }
            OracleHeader h;
            if (fread(&h, sizeof(h), 1, f) != 1 || h.magic != ORACLE_MAGIC || h.version != ORACLE_VER_PATHCOMBINE)
            {
                fclose(f);
                fprintf(stderr, "读取 oracle 失败(期望 v3/PathCombineW): %s\n", oracle_path);
                free_test_cases(case_count, cases);
                return 1;
            }
            PathCombineResult *oracle = (PathCombineResult *)calloc(h.case_count ? h.case_count : 1, sizeof(PathCombineResult));
            if (!oracle)
            {
                fclose(f);
                free_test_cases(case_count, cases);
                return 1;
            }
            for (uint32_t i = 0; i < h.case_count; i++)
            {
                if (fread(&oracle[i].ret, sizeof(oracle[i].ret), 1, f) != 1 ||
                    fread(oracle[i].dst, sizeof(uint16_t), MAX_PATH, f) != MAX_PATH)
                {
                    fclose(f);
                    free(oracle);
                    free_test_cases(case_count, cases);
                    fprintf(stderr, "读取 oracle 内容失败 (case=%u)\n", i);
                    return 1;
                }
            }
            fclose(f);

            uint32_t n = (case_count < h.case_count) ? case_count : h.case_count;
            if (case_count != h.case_count)
                printf("[WARN] oracle 用例数(%u)与输入(%u)不一致，将对比前 %u 个\n", h.case_count, case_count, n);

            uint32_t start = 0, end = n;
            if (have_case_filter)
            {
                if (only_case >= n)
                {
                    fprintf(stderr, "--case %u 超出范围 (n=%u)\n", only_case, n);
                    free(oracle);
                    free_test_cases(case_count, cases);
                    return 2;
                }
                start = only_case;
                end = only_case + 1;
            }

            for (uint32_t i = start; i < end; i++)
            {
                PathCombineResult got = invoke_target_PathCombineW(&cases[i]);
                int ok = (got.ret == oracle[i].ret) &&
                         (memcmp(got.dst, oracle[i].dst, sizeof(got.dst)) == 0);
                wine_ok(ok, "case %u: PathCombineW(...) ret=%d exp=%d", i, got.ret, oracle[i].ret);
                if (!ok)
                {
                    const BinObject *dir = find_obj(&cases[i], "dir");
                    const BinObject *file = find_obj(&cases[i], "file");
                    fprintf(stderr, "[MISMATCH] target=%s case=%u ret=%d exp=%d\n", target_name(target), i, got.ret, oracle[i].ret);
                    if (dir)
                    {
                        fprintf(stderr, "  input.dir len=%u utf16 preview: ", (unsigned)dir->len);
                        dump_utf16le_preview(stderr, dir->data, dir->len, 64);
                        fputc('\n', stderr);
                    }
                    if (file)
                    {
                        fprintf(stderr, "  input.file len=%u utf16 preview: ", (unsigned)file->len);
                        dump_utf16le_preview(stderr, file->data, file->len, 64);
                        fputc('\n', stderr);
                    }
                    fprintf(stderr, "  got.dst utf16 preview: ");
                    dump_utf16le_preview(stderr, (const uint8_t *)got.dst, sizeof(got.dst), 64);
                    fputc('\n', stderr);
                    fprintf(stderr, "  exp.dst utf16 preview: ");
                    dump_utf16le_preview(stderr, (const uint8_t *)oracle[i].dst, sizeof(oracle[i].dst), 64);
                    fputc('\n', stderr);
                }
            }

            wine_test_summary();
            free(oracle);
            free_test_cases(case_count, cases);
            return wine_get_fail_count() ? 1 : 0;
        }
    }

    usage(argv[0]);
    free_test_cases(case_count, cases);
    return 2;
}
