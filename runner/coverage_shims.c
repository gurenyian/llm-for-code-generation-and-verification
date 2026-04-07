#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <wctype.h>
#include <stdint.h>
#include <errno.h>
#include <setjmp.h>

#if !defined(_WIN32)
#  include <wine/windows.h>
#  include <wine/debug.h>
#endif

#ifndef CSTR_LESS_THAN
#  define CSTR_LESS_THAN 1
#  define CSTR_EQUAL 2
#  define CSTR_GREATER_THAN 3
#endif

#ifndef _UNICODE_STRING_DEFINED
#define _UNICODE_STRING_DEFINED
typedef struct _UNICODE_STRING {
    USHORT Length;
    USHORT MaximumLength;
    PWSTR Buffer;
} UNICODE_STRING, *PUNICODE_STRING;
#endif

static size_t wcsnlen_safe(const WCHAR *s, size_t max_len)
{
    size_t i = 0;
    if (!s) return 0;
    for (; i < max_len && s[i]; ++i) {}
    return i;
}

int WINAPI lstrcmpW(LPCWSTR a, LPCWSTR b)
{
    if (!a) a = L"";
    if (!b) b = L"";
    return wcscmp(a, b);
}

int WINAPI lstrcmpA(LPCSTR a, LPCSTR b)
{
    if (!a) a = "";
    if (!b) b = "";
    return strcmp(a, b);
}

int WINAPI wcsnicmp(const WCHAR *a, const WCHAR *b, size_t count)
{
    if (!a) a = L"";
    if (!b) b = L"";
    for (size_t i = 0; i < count; ++i)
    {
        WCHAR ca = (WCHAR)towlower(a[i]);
        WCHAR cb = (WCHAR)towlower(b[i]);
        if (!ca || !cb)
            return (int)(ca - cb);
        if (ca != cb)
            return (int)(ca - cb);
    }
    return 0;
}

LPWSTR WINAPI StrCpyNW(LPWSTR dst, LPCWSTR src, int count)
{
    if (!dst || count <= 0) return dst;
    if (!src) src = L"";
    size_t len = wcsnlen_safe(src, (size_t)count - 1);
    if (len > 0)
        memcpy(dst, src, len * sizeof(WCHAR));
    dst[len] = 0;
    return dst;
}

LPWSTR WINAPI StrDupW(LPCWSTR src)
{
    if (!src) return NULL;
    size_t len = wcslen(src);
    LPWSTR out = (LPWSTR)malloc((len + 1) * sizeof(WCHAR));
    if (!out) return NULL;
    memcpy(out, src, (len + 1) * sizeof(WCHAR));
    return out;
}

LPWSTR WINAPI StrRChrW(LPCWSTR start, LPCWSTR end, WCHAR ch)
{
    LPCWSTR s = start;
    if (!s) return NULL;
    if (!end) end = start + wcslen(start);
    const WCHAR *last = NULL;
    for (; s < end && *s; ++s)
        if (*s == ch) last = s;
    return (LPWSTR)last;
}

LPSTR WINAPI StrRChrA(LPCSTR start, LPCSTR end, char ch)
{
    LPCSTR s = start;
    if (!s) return NULL;
    if (!end) end = start + strlen(start);
    const char *last = NULL;
    for (; s < end && *s; ++s)
        if (*s == ch) last = s;
    return (LPSTR)last;
}

LPWSTR WINAPI StrChrW(LPCWSTR str, WCHAR ch)
{
    if (!str) return NULL;
    return (LPWSTR)wcschr(str, ch);
}

LPSTR WINAPI StrChrA(LPCSTR str, char ch)
{
    if (!str) return NULL;
    return (LPSTR)strchr(str, ch);
}

INT WINAPI StrToIntW(LPCWSTR str)
{
    if (!str) return 0;
    return (INT)wcstol(str, NULL, 10);
}

INT WINAPI StrToIntA(LPCSTR str)
{
    if (!str) return 0;
    return (INT)strtol(str, NULL, 10);
}

BOOL WINAPI StrToIntExW(LPCWSTR str, DWORD flags, INT *out)
{
    (void)flags;
    if (!out) return FALSE;
    *out = StrToIntW(str);
    return TRUE;
}

WCHAR WINAPI ChrCmpIW(WCHAR a, WCHAR b)
{
    WCHAR la = (WCHAR)towlower(a);
    WCHAR lb = (WCHAR)towlower(b);
    if (la == lb) return 0;
    return (la < lb) ? -1 : 1;
}

LPSTR WINAPI CharNextA(LPCSTR str)
{
    if (!str || !*str) return (LPSTR)str;
    return (LPSTR)(str + 1);
}

LPSTR WINAPI CharPrevA(LPCSTR start, LPCSTR current)
{
    if (!start || !current || current <= start) return (LPSTR)start;
    return (LPSTR)(current - 1);
}

BOOL WINAPI IsDBCSLeadByte(BYTE ch)
{
    (void)ch;
    return FALSE;
}

int WINAPI MultiByteToWideChar(UINT cp, DWORD flags, LPCSTR src, int src_len, LPWSTR dst, int dst_len)
{
    (void)cp;
    (void)flags;
    if (!src) return 0;
    if (src_len < 0) src_len = (int)strlen(src);
    if (!dst) return src_len + 1;
    int count = (dst_len < src_len + 1) ? dst_len : src_len + 1;
    for (int i = 0; i < count - 1; ++i) dst[i] = (WCHAR)(unsigned char)src[i];
    dst[count - 1] = 0;
    return count;
}

int WINAPI WideCharToMultiByte(UINT cp, DWORD flags, LPCWSTR src, int src_len, LPSTR dst, int dst_len, LPCSTR def_char, LPBOOL used_default)
{
    (void)cp;
    (void)flags;
    (void)def_char;
    if (used_default) *used_default = FALSE;
    if (!src) return 0;
    if (src_len < 0) src_len = (int)wcslen(src);
    if (!dst) return src_len + 1;
    int count = (dst_len < src_len + 1) ? dst_len : src_len + 1;
    for (int i = 0; i < count - 1; ++i) dst[i] = (char)(src[i] & 0x7f);
    dst[count - 1] = 0;
    return count;
}

DWORD WINAPI GetFullPathNameA(LPCSTR path, DWORD size, LPSTR out, LPSTR *file_part)
{
    if (!path) return 0;
    size_t len = strlen(path);
    if (file_part) *file_part = (LPSTR)path;
    if (!out) return (DWORD)(len + 1);
    if (size == 0) return 0;
    size_t copy = (len + 1 < size) ? len + 1 : size;
    memcpy(out, path, copy - 1);
    out[copy - 1] = 0;
    return (DWORD)strlen(out);
}

DWORD WINAPI GetFullPathNameW(LPCWSTR path, DWORD size, LPWSTR out, LPWSTR *file_part)
{
    if (!path) return 0;
    size_t len = wcslen(path);
    if (file_part) *file_part = (LPWSTR)path;
    if (!out) return (DWORD)(len + 1);
    if (size == 0) return 0;
    size_t copy = (len + 1 < size) ? len + 1 : size;
    if (copy > 1)
        memcpy(out, path, (copy - 1) * sizeof(WCHAR));
    out[copy - 1] = 0;
    return (DWORD)wcslen(out);
}

DWORD WINAPI SearchPathA(LPCSTR path, LPCSTR file, LPCSTR ext, DWORD size, LPSTR out, LPSTR *file_part)
{
    (void)path;
    (void)ext;
    return GetFullPathNameA(file, size, out, file_part);
}

DWORD WINAPI SearchPathW(LPCWSTR path, LPCWSTR file, LPCWSTR ext, DWORD size, LPWSTR out, LPWSTR *file_part)
{
    (void)path;
    (void)ext;
    return GetFullPathNameW(file, size, out, file_part);
}

DWORD WINAPI GetFileAttributesA(LPCSTR path)
{
    (void)path;
    return 0xFFFFFFFF;
}

DWORD WINAPI GetFileAttributesW(LPCWSTR path)
{
    (void)path;
    return 0xFFFFFFFF;
}

UINT WINAPI SetErrorMode(UINT mode)
{
    return mode;
}

LONG WINAPI RegOpenKeyExW(HKEY key, LPCWSTR subkey, DWORD options, REGSAM sam, HKEY *result)
{
    (void)key;
    (void)subkey;
    (void)options;
    (void)sam;
    if (result) *result = NULL;
    return ERROR_FILE_NOT_FOUND;
}

LONG WINAPI RegEnumValueW(HKEY key, DWORD index, LPWSTR value_name, LPDWORD value_len, LPDWORD reserved, LPDWORD type, LPBYTE data, LPDWORD data_len)
{
    (void)key;
    (void)index;
    (void)value_name;
    (void)value_len;
    (void)reserved;
    (void)type;
    (void)data;
    (void)data_len;
    return ERROR_NO_MORE_ITEMS;
}

LONG WINAPI RegQueryValueExW(HKEY key, LPCWSTR value, LPDWORD reserved, LPDWORD type, LPBYTE data, LPDWORD data_len)
{
    (void)key;
    (void)value;
    (void)reserved;
    (void)type;
    (void)data;
    (void)data_len;
    return ERROR_FILE_NOT_FOUND;
}

LONG WINAPI RegCloseKey(HKEY key)
{
    (void)key;
    return ERROR_SUCCESS;
}

int WINAPI CompareStringOrdinal(LPCWSTR str1, int len1, LPCWSTR str2, int len2, BOOL ignore_case)
{
    (void)ignore_case;
    if (!str1) str1 = L"";
    if (!str2) str2 = L"";
    if (len1 < 0) len1 = (int)wcslen(str1);
    if (len2 < 0) len2 = (int)wcslen(str2);
    int cmp = wcsncmp(str1, str2, (size_t)((len1 < len2) ? len1 : len2));
    if (cmp == 0 && len1 != len2) cmp = (len1 < len2) ? -1 : 1;
    if (cmp < 0) return CSTR_LESS_THAN;
    if (cmp > 0) return CSTR_GREATER_THAN;
    return CSTR_EQUAL;
}

int WINAPI CompareStringA(LCID locale, DWORD flags, LPCSTR s1, int len1, LPCSTR s2, int len2)
{
    (void)locale;
    (void)flags;
    if (!s1) s1 = "";
    if (!s2) s2 = "";
    if (len1 < 0) len1 = (int)strlen(s1);
    if (len2 < 0) len2 = (int)strlen(s2);
    int cmp = strncmp(s1, s2, (size_t)((len1 < len2) ? len1 : len2));
    if (cmp == 0 && len1 != len2) cmp = (len1 < len2) ? -1 : 1;
    if (cmp < 0) return CSTR_LESS_THAN;
    if (cmp > 0) return CSTR_GREATER_THAN;
    return CSTR_EQUAL;
}

DWORD WINAPI ExpandEnvironmentStringsW(LPCWSTR src, LPWSTR dst, DWORD size)
{
    if (!src) return 0;
    size_t len = wcslen(src) + 1;
    if (!dst) return (DWORD)len;
    if (size == 0) return 0;
    size_t copy = (len < size) ? len : size;
    if (copy > 1)
        memcpy(dst, src, (copy - 1) * sizeof(WCHAR));
    dst[copy - 1] = 0;
    return (DWORD)wcslen(dst);
}

LPVOID WINAPI LocalAlloc(UINT flags, SIZE_T bytes)
{
    (void)flags;
    return malloc((size_t)bytes);
}

HLOCAL WINAPI LocalFree(HLOCAL handle)
{
    free(handle);
    return NULL;
}

PVOID WINAPI RtlAllocateHeap(PVOID heap, ULONG flags, SIZE_T size)
{
    (void)heap;
    (void)flags;
    return malloc((size_t)size);
}

BOOLEAN WINAPI RtlFreeHeap(PVOID heap, ULONG flags, PVOID ptr)
{
    (void)heap;
    (void)flags;
    free(ptr);
    return TRUE;
}

PVOID WINAPI RtlReAllocateHeap(PVOID heap, ULONG flags, PVOID ptr, SIZE_T size)
{
    (void)heap;
    (void)flags;
    return realloc(ptr, (size_t)size);
}

BOOLEAN WINAPI RtlCreateUnicodeStringFromAsciiz(PUNICODE_STRING dst, LPCSTR src)
{
    if (!dst) return FALSE;
    if (!src) {
        dst->Buffer = NULL;
        dst->Length = 0;
        dst->MaximumLength = 0;
        return TRUE;
    }
    size_t len = strlen(src);
    dst->Buffer = (PWSTR)malloc((len + 1) * sizeof(WCHAR));
    if (!dst->Buffer) return FALSE;
    for (size_t i = 0; i < len; ++i) dst->Buffer[i] = (WCHAR)(unsigned char)src[i];
    dst->Buffer[len] = 0;
    dst->Length = (USHORT)(len * sizeof(WCHAR));
    dst->MaximumLength = (USHORT)((len + 1) * sizeof(WCHAR));
    return TRUE;
}

VOID WINAPI RtlFreeUnicodeString(PUNICODE_STRING dst)
{
    if (!dst) return;
    free(dst->Buffer);
    dst->Buffer = NULL;
    dst->Length = 0;
    dst->MaximumLength = 0;
}

ULONG WINAPI RtlUnicodeToMultiByteSize(PULONG bytes, PCWSTR src, ULONG len)
{
    if (!src || !bytes) return 0;
    ULONG chars = len / sizeof(WCHAR);
    *bytes = chars;
    return 0;
}

ULONG WINAPI RtlUnicodeToMultiByteN(PCHAR dst, ULONG dst_len, PULONG out_len, PCWSTR src, ULONG src_len)
{
    if (!src || !dst) return 0;
    ULONG chars = src_len / sizeof(WCHAR);
    ULONG count = (dst_len < chars) ? dst_len : chars;
    for (ULONG i = 0; i < count; ++i) dst[i] = (char)(src[i] & 0x7f);
    if (out_len) *out_len = count;
    return 0;
}

WCHAR WINAPI RtlDowncaseUnicodeChar(WCHAR ch)
{
    return (WCHAR)towlower(ch);
}

BOOL WINAPI IsBadStringPtrA(LPCSTR str, UINT_PTR len)
{
    (void)str;
    (void)len;
    return FALSE;
}

BOOL WINAPI IsBadStringPtrW(LPCWSTR str, UINT_PTR len)
{
    (void)str;
    (void)len;
    return FALSE;
}

int WINAPI __wine_dbg_write(const char *str, unsigned int len)
{
    (void)len;
    if (str) fputs(str, stderr);
    return 0;
}

unsigned char __cdecl __wine_dbg_get_channel_flags(struct __wine_debug_channel *channel)
{
    (void)channel;
    return 0;
}

const char * __cdecl __wine_dbg_strdup(const char *str)
{
    return str ? str : "";
}

int __cdecl __wine_dbg_output(const char *str)
{
    if (str) fputs(str, stderr);
    return 0;
}

int __cdecl __wine_dbg_header(enum __wine_debug_class cls, struct __wine_debug_channel *channel, const char *function)
{
    (void)cls;
    (void)channel;
    (void)function;
    return -1;
}

LONG WINAPI __wine_exception_handler_page_fault(EXCEPTION_POINTERS *ptrs)
{
    (void)ptrs;
    return EXCEPTION_EXECUTE_HANDLER;
}

LONG WINAPI __wine_exception_handler(EXCEPTION_POINTERS *ptrs)
{
    (void)ptrs;
    return EXCEPTION_EXECUTE_HANDLER;
}

int __wine_setjmpex(jmp_buf *buf)
{
    if (!buf) return 0;
    return setjmp(*buf);
}
