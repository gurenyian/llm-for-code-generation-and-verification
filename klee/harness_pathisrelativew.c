/*
 * KLEE test harness for PathIsRelativeW
 * 
 * This program creates symbolic inputs and calls PathIsRelativeW
 * to explore all possible execution paths.
 * 
 * Compile:
 *   clang -I/usr/include/klee -emit-llvm -c -g -O0 harness_pathisrelativew.c -o harness.bc
 * 
 * Run KLEE:
 *   klee --optimize --max-time=60s harness.bc
 */

#include <klee/klee.h>

// Windows types for KLEE environment
typedef unsigned short WCHAR;
typedef const WCHAR *LPCWSTR;
typedef int BOOL;
#define TRUE 1
#define FALSE 0
#define NULL ((void*)0)

// Include ODA stubs (generated from specs)
// Uncomment if you have external dependencies
// #include "oda_stubs.c"

/*
 * PathIsRelativeW implementation (copied from Wine source)
 * 
 * In real scenario, you would:
 * 1. Copy the actual Wine implementation here, OR
 * 2. Link against Wine's compiled object files
 * 
 * For this demo, we use a simplified version.
 */
BOOL PathIsRelativeW(LPCWSTR lpszPath)
{
    // Handle NULL pointer
    if (!lpszPath)
        return TRUE;
    
    // Handle empty string
    if (!*lpszPath)
        return TRUE;
    
    // Check for absolute path indicators
    // 1. Starts with backslash (e.g., "\Windows")
    if (lpszPath[0] == '\\')
        return FALSE;
    
    // 2. Has drive letter (e.g., "C:\Windows")
    if (lpszPath[0] && lpszPath[1] == ':')
        return FALSE;
    
    // Otherwise, it's relative
    return TRUE;
}

int main()
{
    // Create symbolic path string
    // Use smaller size (32 WCHARs = 64 bytes) for faster KLEE execution
    WCHAR path[32];
    /*
     * 约束字符串 NUL 终止：不要用 "在 C 循环里累积一个 flag" 的方式，然后
     * `klee_assume(flag)` —— KLEE 往往无法把这种控制流归约成可满足条件，
     * 最终会把 assume 判成 provably false 并忽略。
     *
     * 这里采用一个对 KLEE 友好的约束：
     *   - 先把数组清零，避免无意义的未约束字节
     *   - 再把整个数组设为 symbolic
     *   - 强制最后一个 WCHAR 为 0，保证一定能 NUL 终止
     */
    for (int i = 0; i < 32; i++) path[i] = 0;
    klee_make_symbolic(path, sizeof(path), "path");
    klee_assume(path[31] == 0);

    /*
     * 重要：当前 demo 里的 PathIsRelativeW 实现非常短，默认情况下 KLEE 可能很快
     * 找到一个满足约束的路径就结束（尤其在 --optimize 下）。
     *
     * 为了稳定地产生更多 .ktest，我们对关键分支位做“轻约束枚举”：
     *   - path[0] 允许是 '\\'（绝对路径分支）
     *   - 或者是 [A-Z]（盘符分支候选）
     *   - 或者是普通字符（相对路径分支）
     *
     * 同时只在盘符分支时允许 ':'，避免把状态空间炸到完全无意义。
     */
    WCHAR p0 = path[0];
    WCHAR p1 = path[1];
    klee_assume(p0 == '\\' || (p0 >= 'A' && p0 <= 'Z') || (p0 >= 'a' && p0 <= 'z') || (p0 >= '0' && p0 <= '9'));

    /*
     * 如果选择了“盘符候选”（字母开头），则让第二个字符在 ':' 或其他之间保持符号性。
     * 这里不强制 ':'，否则依然只会生成一个极短路径集合。
     */
    if ((p0 >= 'A' && p0 <= 'Z') || (p0 >= 'a' && p0 <= 'z'))
    {
        klee_assume(p1 == ':' || p1 == 0 || (p1 >= '0' && p1 <= '9') || p1 == '\\' || p1 == '/');
    }
    
    // Optional: constrain to printable characters for readability
    // Uncomment to reduce state space
    /*
    for (int i = 0; i < 32 && path[i] != 0; i++) {
        klee_assume(path[i] >= 32 && path[i] < 127);
    }
    */
    
    // Call target function
    BOOL result = PathIsRelativeW(path);
    
    // Guide KLEE to explore both branches
    // This ensures we get test cases for both TRUE and FALSE returns
    if (result == TRUE) {
        // Relative path branch
        // KLEE will generate inputs that make this true
    } else {
        // Absolute path branch
        // KLEE will generate inputs that make this false
    }

    /* 让约束与输出更“可见”，有助于 KLEE 保留分支相关的状态 */
    klee_print_expr("PathIsRelativeW(result)", result);
    
    return 0;
}
