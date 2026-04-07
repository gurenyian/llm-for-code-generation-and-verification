#include <klee/klee.h>
#include <stddef.h>

// Windows types (for KLEE environment)
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

/*
 * Lightweight path-combine stubs for KLEE.
 *
 * Goal:
 * - keep the harness executable
 * - expose enough branch structure to drive PathCombineW
 * - avoid impossible klee_assume constraints
 * - return concrete values where the real code needs them
 */

#define MAX_PATH 260

static int wspnlen(const WCHAR *s, int limit)
{
    int i = 0;
    if (!s) return 0;
    while (i < limit && s[i]) i++;
    return i;
}

static int wcontains_backslash(const WCHAR *s)
{
    int i;
    if (!s) return 0;
    for (i = 0; s[i]; ++i)
        if (s[i] == '\\') return 1;
    return 0;
}

static int wis_unc(const WCHAR *s)
{
    return s && s[0] == '\\' && s[1] == '\\';
}

static int wis_relative(const WCHAR *s)
{
    if (!s || !s[0]) return 1;
    return !(s[0] == '\\' || (s[1] == ':' && s[2] == '\\'));
}

static void wcopy(LPWSTR dst, LPCWSTR src, int n)
{
    int i = 0;
    if (!dst || n <= 0) return;
    if (!src) { dst[0] = 0; return; }
    for (; i < n - 1 && src[i]; ++i) dst[i] = src[i];
    dst[i] = 0;
}

static void wcat(LPWSTR dst, LPCWSTR src)
{
    int dlen = wspnlen(dst, MAX_PATH);
    int i = 0;
    if (!dst || !src) return;
    while (dlen < MAX_PATH - 1 && src[i]) dst[dlen++] = src[i++];
    dst[dlen] = 0;
}

/*
 * Stub for myPathAddBackslashW
 * 
 * Adds a backslash to the end of the path if necessary.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
static LPWSTR myPathAddBackslashW(LPWSTR lpszPath) {
    if (lpszPath == NULL) return NULL;
    if (lpszPath[0] == 0) return NULL;
    if (lpszPath[wspnlen(lpszPath, MAX_PATH - 1) - 1] != '\\') {
        int i = wspnlen(lpszPath, MAX_PATH - 1);
        if (i >= MAX_PATH - 1) return NULL;
        lpszPath[i] = '\\';
        lpszPath[i + 1] = 0;
    }
    return lpszPath;
}

/*
 * Stub for PathCanonicalizeW
 * 
 * Canonicalizes a path string.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
BOOL PathCanonicalizeW(WCHAR *buffer, const WCHAR *path) {
    if (buffer == NULL) return FALSE;
    if (path == NULL) { buffer[0] = 0; return FALSE; }
    wcopy(buffer, path, MAX_PATH);
    return TRUE;
}

/*
 * Stub for PathIsRelativeW
 * 
 * Determines if a path is relative.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
BOOL PathIsRelativeW(const WCHAR *path) {
    return wis_relative(path);
}

/*
 * Stub for PathIsUNCW
 * 
 * Checks if a path is a UNC path.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
BOOL PathIsUNCW(const WCHAR *path) {
    return wis_unc(path);
}

/*
 * Stub for PathStripToRootW
 * 
 * Strips the path to its root.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
BOOL PathStripToRootW(WCHAR *path) {
    int i;
    if (path == NULL || path[0] == 0) return FALSE;
    if (wis_unc(path)) {
        int slashes = 0;
        for (i = 0; path[i]; ++i) {
            if (path[i] == '\\') {
                slashes++;
                if (slashes == 4) {
                    path[i] = 0;
                    return TRUE;
                }
            }
        }
        return TRUE;
    }
    if (path[1] == ':' && path[2] == '\\') {
        path[3] = 0;
        return TRUE;
    }
    for (i = 0; path[i]; ++i) {
        if (path[i] == '\\') {
            path[i + 1] = 0;
            return TRUE;
        }
    }
    return TRUE;
}

/*
 * Stub for lstrcatW
 * 
 * Concatenates two strings.
 * 
 * Abstraction strategy: noop
 * Reason: The return value does not affect control flow.
 */
LPWSTR lstrcatW(LPWSTR dst, LPCWSTR src) {
    if (!dst || !src) return dst;
    wcat(dst, src);
    return dst;
}

/*
 * Stub for KERNELBASE_lstrcpynW
 * 
 * Copies a specified number of characters from one string to another.
 * 
 * Abstraction strategy: noop
 * Reason: The return value does not affect control flow.
 */
LPWSTR KERNELBASE_lstrcpynW(LPWSTR dst, LPCWSTR src, int n) {
    wcopy(dst, src, n);
    return dst;
}

/*
 * Stub for KERNELBASE_lstrlenW
 * 
 * Returns the length of a string.
 * 
 * Abstraction strategy: symbolic_return
 * Reason: The return value affects control flow in the function.
 */
int KERNELBASE_lstrlenW(LPCWSTR str) {
    return wspnlen(str, MAX_PATH);
}