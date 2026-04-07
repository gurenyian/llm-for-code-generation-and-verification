#include <klee/klee.h>
#include <stddef.h>

/* Stub for ARRAY_SIZE */
/* Abstraction strategy: No-op */
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

/* Stub for PathAddBackslashW */
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathAddBackslashW(WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathAddBackslashW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(path != NULL);
  if (ret) {
    klee_assume(path[wcslen(path)] == '\\');
  } else {
    klee_assume(path[wcslen(path)] != '\\');
  }
  return ret;
}

/* Stub for PathCanonicalizeW */
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathCanonicalizeW(WCHAR *buffer, const WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathCanonicalizeW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(buffer != NULL);
  klee_assume(path != NULL);
  if (ret) {
    klee_assume(wcslen(path) < MAX_PATH);
  } else {
    klee_assume(wcslen(path) >= MAX_PATH);
  }
  return ret;
}

/* Stub for PathIsRelativeW */
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathIsRelativeW(const WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathIsRelativeW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(path != NULL);
  if (ret) {
    klee_assume(path[0] != '\\');
  } else {
    klee_assume(path[0] == '\\');
  }
  return ret;
}

/* Stub for PathIsUNCW */
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathIsUNCW(const WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathIsUNCW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(path != NULL);
  if (ret) {
    klee_assume(path[0] == '\\' && path[1] == '\\');
  } else {
    klee_assume(!(path[0] == '\\' && path[1] == '\\'));
  }
  return ret;
}

/* Stub for PathStripToRootW */
/* Abstraction strategy: No-op */
BOOL WINAPI PathStripToRootW(WCHAR *path) {
  if (path) {
    path[0] = 0;
  }
  return TRUE;
}

/* Stub for lstrcatW */
/* Abstraction strategy: Bounded_Concrete */
LPWSTR WINAPI lstrcatW(LPWSTR dst, LPCWSTR src) {
  if (dst && src) {
    for (int i = 0; i < 64 && *src; i++) {
      dst[i] = *src;
      src++;
    }
    dst[64 - 1] = '\0';
  }
  return dst;
}

/* Stub for KERNELBASE_lstrcpynW */
/* Abstraction strategy: Bounded_Concrete */
LPWSTR WINAPI KERNELBASE_lstrcpynW(LPWSTR dst, LPCWSTR src, INT n) {
  if (dst && src) {
    for (int i = 0; i < n && *src; i++) {
      dst[i] = *src;
      src++;
    }
    dst[n - 1] = '\0';
  }
  return dst;
}

/* Stub for lstrlenW */
/* Abstraction strategy: Bounded_Concrete */
int WINAPI lstrlenW(LPCWSTR str) {
  int len = 0;
  if (str) {
    while (len < 64 && str[len]) {
      len++;
    }
  }
  return len;
}
