#include <klee/klee.h>
#include <stddef.h>

/* Stub for ARRAY_SIZE */
/* Abstraction strategy: No-op */
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

/* Stub for PathAddBackslashW */
/* Abstraction strategy: Semantic_Binding */
LPWSTR WINAPI PathAddBackslashW(WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathAddBackslashW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(path != NULL);
  if (ret) {
    klee_assume(path[wcslen(path)] == '\\');
  } else {
    klee_assume(path[wcslen(path)] != '\\');
  }
  return path;
}

/* Stub for PathCanonicalizeW */
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathCanonicalizeW(WCHAR *buffer, const WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathCanonicalizeW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(buffer != NULL);
  klee_assume(path != NULL);
  if (ret) {
    // 假设 buffer 被正确填充
  } else {
    klee_assume(!(path));
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
/* Abstraction strategy: Semantic_Binding */
BOOL WINAPI PathStripToRootW(WCHAR *path) {
  int ret = klee_make_symbolic_int("oda_PathStripToRootW_ret");
  klee_assume(ret == 0 || ret == 1);
  klee_assume(path != NULL);
  if (ret) {
    // 假设 path 被正确修改为根路径
  } else {
    klee_assume(!(path));
  }
  return ret;
}

/* Stub for lstrcatW */
/* Abstraction strategy: Bounded_Concrete */
LPWSTR WINAPI lstrcatW(LPWSTR dst, LPCWSTR src) {
  if (dst == NULL || src == NULL) return NULL;
  int i = 0;
  while (dst[i] != '\0' && i < 64) i++;
  int j = 0;
  while (src[j] != '\0' && j < 64 && i < 64) {
    dst[i++] = src[j++];
  }
  dst[i] = '\0';
  return dst;
}

/* Stub for KERNELBASE_lstrcpynW */
/* Abstraction strategy: Bounded_Concrete */
LPWSTR WINAPI KERNELBASE_lstrcpynW(LPWSTR dst, LPCWSTR src, INT n) {
  if (dst == NULL || src == NULL) return NULL;
  int i = 0;
  while (src[i] != '\0' && i < n && i < 64) {
    dst[i] = src[i];
    i++;
  }
  dst[i] = '\0';
  return dst;
}

/* Stub for lstrlenW */
/* Abstraction strategy: Bounded_Concrete */
int WINAPI lstrlenW(LPCWSTR str) {
  int len = 0;
  while (str[len] != '\0' && len < 64) len++;
  return len;
}
