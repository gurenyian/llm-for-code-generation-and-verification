/*
 * wine_test.h - 模拟 Wine 测试框架
 * 
 * 这个头文件提供与 Wine 测试框架兼容的断言宏，
 * 使得测试代码可以在 Windows 和 Wine 上都能编译运行。
 */

#ifndef WINE_TEST_H
#define WINE_TEST_H

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* 全局测试计数器 */
static int wine_test_count = 0;
static int wine_fail_count = 0;
static int wine_skip_count = 0;

/* wine_ok: 主要的断言宏 */
#define wine_ok(condition, ...) \
    do { \
        wine_test_count++; \
        if (!(condition)) { \
            wine_fail_count++; \
            fprintf(stderr, "[FAIL] %s:%d: ", __FILE__, __LINE__); \
            fprintf(stderr, __VA_ARGS__); \
            fprintf(stderr, "\n"); \
            fflush(stderr); \
        } \
    } while (0)

/* wine_skip: 跳过测试 */
#define wine_skip(...) \
    do { \
        wine_test_count++; \
        wine_skip_count++; \
        fprintf(stdout, "[SKIP] "); \
        fprintf(stdout, __VA_ARGS__); \
        fprintf(stdout, "\n"); \
        fflush(stdout); \
    } while (0)

/* wine_trace: 调试输出 */
#define wine_trace(...) \
    do { \
        fprintf(stdout, "[TRACE] "); \
        fprintf(stdout, __VA_ARGS__); \
        fprintf(stdout, "\n"); \
        fflush(stdout); \
    } while (0)

/* 显示测试摘要 */
static inline void wine_test_summary(void) {
    printf("\n");
    printf("========================================\n");
    printf("测试摘要\n");
    printf("========================================\n");
    printf("总计: %d 个测试\n", wine_test_count);
    printf("通过: %d 个\n", wine_test_count - wine_fail_count - wine_skip_count);
    printf("失败: %d 个\n", wine_fail_count);
    printf("跳过: %d 个\n", wine_skip_count);
    printf("========================================\n");
    
    if (wine_fail_count == 0) {
        printf("✓ 所有测试通过！\n");
    } else {
        printf("✗ 有 %d 个测试失败\n", wine_fail_count);
    }
    printf("\n");
}

/* 获取失败数量（用于返回值） */
static inline int wine_get_fail_count(void) {
    return wine_fail_count;
}

#endif /* WINE_TEST_H */
