/*
 * KLEE test harness for PathCombineW
 *
 * 目标：构造带外部依赖的调用场景，驱动 KLEE 生成覆盖不同分支的测试用例。
 * 依赖函数由 LLM 生成的 `oda_stubs.c` 提供（已在 pipeline 中拷贝到 klee/）。
 */

#include <klee/klee.h>

// Windows types (minimal subset for this harness)
typedef unsigned short WCHAR;
typedef const WCHAR *LPCWSTR;
typedef WCHAR *LPWSTR;
typedef int BOOL;
typedef int INT;
#ifndef WINAPI
#define WINAPI
#endif
#define TRUE 1
#define FALSE 0
#define NULL ((void*)0)

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

static inline int klee_make_symbolic_int(const char *name)
{
    int x = 0;
    klee_make_symbolic(&x, sizeof(x), name);
    return x;
}

// 引入生成的依赖桩
#include "oda_stubs.c"

/*
 * 原始逻辑风格的 PathCombineW：
 * - 保留 Win32 分支结构
 * - 由 stub 决定底层依赖函数的行为
 * - 便于 KLEE 对“可行路径”做穷举
 */
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

int main()
{
    WCHAR dir[MAX_PATH] = {0};
    WCHAR file[MAX_PATH] = {0};
    WCHAR dst[MAX_PATH] = {0};

    klee_make_symbolic(dir, sizeof(dir), "dir");
    klee_make_symbolic(file, sizeof(file), "file");

    klee_assume(dir[MAX_PATH-1] == 0);
    klee_assume(file[MAX_PATH-1] == 0);

    /*
     * 适度缩小搜索空间：允许空串、相对路径、UNC、绝对路径、\开头路径。
     * 这类约束不会直接剥夺关键分支，但能显著提高 KLEE 可完成性。
     */
    klee_assume(dir[0] == 0 || dir[0] == '\\' || dir[1] == ':' || dir[0] >= 'A');
    klee_assume(file[0] == 0 || file[0] == '\\' || file[1] == ':' || file[0] >= 'A');

    // 调用目标函数
    LPWSTR out = PathCombineW(dst, dir, file);

    // 让 KLEE 保存结果可视化
    klee_print_expr("PathCombineW_out0", out ? out[0] : 0);

    return 0;
}