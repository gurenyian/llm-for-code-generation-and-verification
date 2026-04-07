# PathCombineW Windows/Linux 测试差异

- **生成方式**：LLM 模式（`stub_validation_report.json` 中可见，`llm_diag.json` status=success）。
- **Stub 来源**：`out/pathcombinew/run_20260319_134128_96558_25194/oda_stubs.c` 为 LLM 生成，包含 9 个外部依赖桩。

## Linux（KLEE）
- 工具：KLEE
- 跑法：`scripts/ubuntu_run_pipeline.sh --api PathCombineW --stub-mode llm ...`
- 结果：3 个 `.ktest`，`test_cases.bin` 大小约 3.5 KB。
- 日志提示：`./oda_stubs.c:54 invalid klee_assume call (provably false)` 被忽略；clang 有多条 non-void 无返回的 warning（桩函数缺少 return）。

## Windows
- 当前流水线未执行 Windows 本地用例（`wine_test_runner.exe` 等文件不存在）。如需 Windows 对比，需要补充 Windows 测试 runner 并落盘结果。

## 差异结论
- 仅有 Linux/KLEE 符号执行结果，未有 Windows 运行结果，因此无法形成具体用例层面的差异对比。
- 现有 stub 在 Linux 下可跑通 KLEE，但有可改进项：
  - 给所有非 void 桩函数补齐返回值，消除编译警告。
  - 避免生成不可满足的 `klee_assume`（如在添加约束前先检查指针可用或范围合理）。

## 后续建议
1. 复跑流水线以生成新的 LLM 桩（已更新 prompt，要求 return 与可满足假设），观察 warning 是否消失。
2. 若需要 Windows 对比，补充/运行 Windows runner，生成对应测试日志，再与 Linux 结果比对。
