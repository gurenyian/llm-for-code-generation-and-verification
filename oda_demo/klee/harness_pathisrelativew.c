#include <stdint.h>
#include <klee/klee.h>

// 固定宽字符串长度（UTF-16 code unit 个数）
#define N 32

// 由 ODA stub 提供（同名链接替换）
int PathIsRelativeW(const uint16_t* path);

static void constrain_wstring(uint16_t *s)
{
    // 1) 限制字符集合（非常关键：减少 solver 空间，避免爆炸）
    for (int i = 0; i < N; i++)
    {
        uint16_t c = s[i];
        klee_assume(
            c == 0 ||
            c == (uint16_t)'\\' ||
            c == (uint16_t)':'  ||
            c == (uint16_t)'.'  ||
            (c >= 0x20 && c <= 0x7e)
        );
    }

    // 2) 强制存在 NUL 终止符，并把后面清零（减少等价状态数）
    uint8_t len;
    klee_make_symbolic(&len, sizeof(len), "path_len");
    klee_assume(len < N);

    s[len] = 0;
    for (int i = (int)len + 1; i < N; i++) s[i] = 0;
}

int main(void)
{
    uint16_t path[N];
    klee_make_symbolic(path, sizeof(path), "path");
    constrain_wstring(path);

    int ret = PathIsRelativeW(path);

    // 目标：覆盖 ret==0 分支（非相对路径）
    if (ret == 0)
    {
        klee_assert(0 && "Reached ret==0 branch (non-relative path)");
    }

    return 0;
}

