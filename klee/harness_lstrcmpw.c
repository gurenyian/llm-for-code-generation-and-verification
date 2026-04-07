/*
 * KLEE test harness for lstrcmpW
 *
 * Goal: generate diverse UTF-16LE string pairs for differential testing:
 *   - Windows: record ground-truth results into oracle.bin
 *   - Wine: replay and compare
 *
 * Notes:
 * - In this harness we include a small, deterministic implementation of
 *   lstrcmpW semantics (lexicographic compare on WCHAR, stop at NUL).
 *   This keeps KLEE self-contained and avoids huge external dependencies.
 * - The runner will call the real lstrcmpW on Windows/Wine.
 */

#include <klee/klee.h>

typedef unsigned short WCHAR;
typedef const WCHAR *LPCWSTR;

static int harness_lstrcmpW(LPCWSTR a, LPCWSTR b)
{
    /* Minimal semantics: compare WCHAR code units until difference or NUL. */
    while (*a && *b && *a == *b) { a++; b++; }
    if (*a == *b) return 0;
    return (*a < *b) ? -1 : 1;
}

int main(void)
{
    /* Keep small to control path explosion. */
    WCHAR a[16];
    WCHAR b[16];

    for (int i = 0; i < 16; i++) { a[i] = 0; b[i] = 0; }
    klee_make_symbolic(a, sizeof(a), "a");
    klee_make_symbolic(b, sizeof(b), "b");
    klee_assume(a[15] == 0);
    klee_assume(b[15] == 0);

    /* Light constraints for readability + branch diversity. */
    WCHAR a0 = a[0], b0 = b[0];
    klee_assume(a0 == 0 || (a0 >= 'a' && a0 <= 'z') || (a0 >= 'A' && a0 <= 'Z') || (a0 >= '0' && a0 <= '9'));
    klee_assume(b0 == 0 || (b0 >= 'a' && b0 <= 'z') || (b0 >= 'A' && b0 <= 'Z') || (b0 >= '0' && b0 <= '9'));

    /* Encourage KLEE to hit equal / less / greater. */
    int r = harness_lstrcmpW(a, b);
    if (r < 0) { /* a < b */ }
    else if (r == 0) { /* a == b */ }
    else { /* a > b */ }

    klee_print_expr("lstrcmpW(norm)", r);
    return 0;
}
