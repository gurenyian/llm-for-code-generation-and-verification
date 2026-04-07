#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <shlwapi.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma comment(lib, "Shlwapi.lib")

#define N 32

static int read_cases(const char* path, uint32_t* out_count, uint16_t** out_buf)
{
    FILE* f = fopen(path, "rb");
    if (!f) return 0;

    uint32_t count;
    if (fread(&count, sizeof(count), 1, f) != 1) { fclose(f); return 0; }

    size_t total = (size_t)count * N;
    uint16_t* buf = (uint16_t*)malloc(total * sizeof(uint16_t));
    if (!buf) { fclose(f); return 0; }

    if (fread(buf, sizeof(uint16_t), total, f) != total)
    {
        free(buf);
        fclose(f);
        return 0;
    }

    fclose(f);
    *out_count = count;
    *out_buf = buf;
    return 1;
}

static void write_hex_utf16le(FILE* out, const uint16_t* s)
{
    for (int i = 0; i < N; i++)
    {
        uint16_t w = s[i];
        uint8_t lo = (uint8_t)(w & 0xff);
        uint8_t hi = (uint8_t)((w >> 8) & 0xff);
        fprintf(out, "%02x%02x", lo, hi);
    }
}

static int record_oracle(const char* cases_path, const char* oracle_path)
{
    uint32_t count = 0;
    uint16_t* buf = NULL;
    if (!read_cases(cases_path, &count, &buf)) return 0;

    FILE* out = fopen(oracle_path, "wb");
    if (!out) { free(buf); return 0; }

    for (uint32_t id = 0; id < count; id++)
    {
        const uint16_t* path16 = buf + (size_t)id * N;
        const WCHAR* wpath = (const WCHAR*)path16;
        BOOL ret = PathIsRelativeW(wpath);

        fprintf(out, "%u\t", id);
        write_hex_utf16le(out, path16);
        fprintf(out, "\t%d\n", ret ? 1 : 0);
    }

    fclose(out);
    free(buf);
    return 1;
}

static int check_oracle(const char* cases_path, const char* oracle_path)
{
    uint32_t count = 0;
    uint16_t* buf = NULL;
    if (!read_cases(cases_path, &count, &buf)) return 0;

    FILE* in = fopen(oracle_path, "rb");
    if (!in) { free(buf); return 0; }

    char line[4096];
    uint32_t seen = 0;
    while (fgets(line, sizeof(line), in))
    {
        char* p1 = strchr(line, '\t'); if (!p1) continue;
        char* p2 = strchr(p1 + 1, '\t'); if (!p2) continue;
        *p1 = 0; *p2 = 0;

        uint32_t id = (uint32_t)strtoul(line, NULL, 10);
        int expected = atoi(p2 + 1);
        if (id >= count)
        {
            printf("oracle id out of range: %u >= %u\n", id, count);
            fclose(in); free(buf);
            return 0;
        }

        const uint16_t* path16 = buf + (size_t)id * N;
        const WCHAR* wpath = (const WCHAR*)path16;
        int got = PathIsRelativeW(wpath) ? 1 : 0;

        if (got != expected)
        {
            printf("MISMATCH id=%u expected=%d got=%d\n", id, expected, got);
            printf("path(hex_utf16le)=%s\n", p1 + 1);
            fclose(in); free(buf);
            return 0;
        }

        seen++;
    }

    fclose(in);
    free(buf);
    printf("OK: checked %u oracle rows\n", seen);
    return 1;
}

int main(int argc, char** argv)
{
    if (argc != 4)
    {
        printf("Usage:\n");
        printf("  %s --record cases.bin oracle.tsv\n", argv[0]);
        printf("  %s --check  cases.bin oracle.tsv\n", argv[0]);
        return 2;
    }

    const char* mode = argv[1];
    const char* cases_path = argv[2];
    const char* oracle_path = argv[3];

    if (strcmp(mode, "--record") == 0)
    {
        if (!record_oracle(cases_path, oracle_path)) return 1;
        printf("Recorded oracle to %s\n", oracle_path);
        return 0;
    }

    if (strcmp(mode, "--check") == 0)
    {
        if (!check_oracle(cases_path, oracle_path)) return 1;
        return 0;
    }

    printf("Unknown mode: %s\n", mode);
    return 2;
}

