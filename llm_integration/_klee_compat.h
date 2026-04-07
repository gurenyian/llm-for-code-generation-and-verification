#pragma once
// Minimal KLEE API shim for syntax-only compilation.
static inline void klee_make_symbolic(void *addr, unsigned long nbytes, const char *name) { (void)addr; (void)nbytes; (void)name; }
static inline void klee_assume(int cond) { (void)cond; }
static inline void klee_assert(int cond) { (void)cond; }
