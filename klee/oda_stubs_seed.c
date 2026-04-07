/*
 * Bounded, deterministic stubs for PathCombineW dependencies.
 * Seed stub used when LLM-generated stubs fail to compile.
 */

#include <klee/klee.h>
#include <stddef.h>
#include <wchar.h>

#ifndef _WINDOWS_
typedef unsigned short WCHAR;
typedef const WCHAR *LPCWSTR;
typedef WCHAR *LPWSTR;
typedef int BOOL;
typedef unsigned long DWORD;
#define TRUE 1
#define FALSE 0
#define NULL ((void*)0)
#endif

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

static int oda_wcsnlen(const WCHAR *s, int max)
{
    int i = 0;
    if (!s) return 0;
    while (i < max && s[i]) i++;
    return i;
}

static LPWSTR append_backslash_if_needed(LPWSTR path)
{
    if (!path) return NULL;
    int len = oda_wcsnlen(path, MAX_PATH);
    if (len == 0 || len >= MAX_PATH) return NULL;
    if (path[len - 1] != L'\\' && path[len - 1] != L'/')
    {
        if (len + 1 >= MAX_PATH) return NULL;
        path[len] = L'\\';
        path[len + 1] = 0;
    }
    return path + oda_wcsnlen(path, MAX_PATH);
}

LPWSTR PathAddBackslashW(LPWSTR path)
{
    return append_backslash_if_needed(path);
}

static LPWSTR myPathAddBackslashW(LPWSTR lpszPath)
{
    return append_backslash_if_needed(lpszPath);
}

BOOL PathIsRelativeW(const WCHAR *path)
{
    if (!path || !path[0]) return TRUE;
    if (((path[0] >= L'A' && path[0] <= L'Z') || (path[0] >= L'a' && path[0] <= L'z')) && path[1] == L':')
        return FALSE;
    if (path[0] == L'\\' || path[0] == L'/')
        return FALSE;
    return TRUE;
}

BOOL PathIsUNCW(const WCHAR *path)
{
    return path && path[0] == L'\\' && path[1] == L'\\';
}

BOOL PathStripToRootW(WCHAR *path)
{
    if (!path || !path[0]) return FALSE;

    if (PathIsUNCW(path))
    {
        int slash_count = 0;
        int i = 0;
        while (path[i] && slash_count < 3 && i < MAX_PATH)
        {
            if (path[i] == L'\\' || path[i] == L'/') slash_count++;
            i++;
        }
        path[i] = 0;
        return TRUE;
    }

    if (((path[0] >= L'A' && path[0] <= L'Z') || (path[0] >= L'a' && path[0] <= L'z')) && path[1] == L':')
    {
        path[2] = L'\\';
        path[3] = 0;
        return TRUE;
    }

    path[1] = 0;
    return TRUE;
}

BOOL PathCanonicalizeW(WCHAR *buffer, const WCHAR *path)
{
    if (!buffer || !path) return FALSE;
    int len = oda_wcsnlen(path, MAX_PATH);
    if (len >= MAX_PATH) return FALSE;
    for (int i = 0; i <= len; i++)
    {
        WCHAR c = path[i];
        if (c == L'/') c = L'\\';
        buffer[i] = c;
    }
    return TRUE;
}

LPWSTR lstrcatW(LPWSTR dst, LPCWSTR src)
{
    if (!dst || !src) return dst;
    int dst_len = oda_wcsnlen(dst, MAX_PATH);
    int src_len = oda_wcsnlen(src, MAX_PATH - dst_len);
    if (dst_len + src_len >= MAX_PATH)
        src_len = MAX_PATH - dst_len - 1;
    for (int i = 0; i < src_len; i++) dst[dst_len + i] = src[i];
    dst[dst_len + src_len] = 0;
    return dst;
}

LPWSTR KERNELBASE_lstrcpynW(LPWSTR dst, LPCWSTR src, int n)
{
    if (!dst) return NULL;
    if (!src || n <= 0) { dst[0] = 0; return dst; }
    int i = 0;
    for (; i < n - 1 && i < MAX_PATH - 1 && src[i]; i++) dst[i] = src[i];
    dst[i] = 0;
    return dst;
}

int KERNELBASE_lstrlenW(LPCWSTR str)
{
    return oda_wcsnlen(str, MAX_PATH);
}
