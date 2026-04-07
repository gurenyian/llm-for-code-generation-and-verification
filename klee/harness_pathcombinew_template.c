
#include <klee/klee.h>

typedef unsigned short WCHAR;
typedef const WCHAR *LPCWSTR;
typedef WCHAR *LPWSTR;
typedef int BOOL;

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef NULL
#define NULL ((void*)0)
#endif

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

#include "oda_stubs.c"

LPWSTR PathCombineW(WCHAR *dst, const WCHAR *dir, const WCHAR *file)
{
    BOOL use_both = FALSE, strip = FALSE;
    WCHAR tmp[MAX_PATH];

    if (!dst)
        return NULL;

    if (!dir && !file)
    {
        dst[0] = 0;
        return NULL;
    }

    if ((!file || !*file) && dir)
    {
        KERNELBASE_lstrcpynW(tmp, dir, MAX_PATH);
    }
    else if (!dir || !*dir || !PathIsRelativeW(file))
    {
        if (!dir || !*dir || *file != '\\' || PathIsUNCW(file))
        {
            KERNELBASE_lstrcpynW(tmp, file, MAX_PATH);
        }
        else
        {
            use_both = TRUE;
            strip = TRUE;
        }
    }
    else
        use_both = TRUE;

    if (use_both)
    {
        KERNELBASE_lstrcpynW(tmp, dir, MAX_PATH);
        if (strip)
        {
            PathStripToRootW(tmp);
            file++; /* Skip '\\' */
        }

        if (!myPathAddBackslashW(tmp) || KERNELBASE_lstrlenW(tmp) + KERNELBASE_lstrlenW(file) >= MAX_PATH)
        {
            dst[0] = 0;
            return NULL;
        }

        lstrcatW(tmp, file);
    }

    PathCanonicalizeW(dst, tmp);
    return dst;
}

int main(void)
{
    WCHAR dir[MAX_PATH] = {0};
    WCHAR file[MAX_PATH] = {0};
    WCHAR dst[MAX_PATH] = {0};

    klee_make_symbolic(dir, sizeof(dir), "dir");
    klee_make_symbolic(file, sizeof(file), "file");

    klee_assume(dir[MAX_PATH-1] == 0);
    klee_assume(file[MAX_PATH-1] == 0);

    klee_assume(dir[0] == 0 || dir[0] == '\\' || dir[1] == ':' || dir[0] >= 'A');
    klee_assume(file[0] == 0 || file[0] == '\\' || file[1] == ':' || file[0] >= 'A');

    LPWSTR out = PathCombineW(dst, dir, file);
    klee_print_expr("PathCombineW_out0", out ? out[0] : 0);
    return 0;
}
