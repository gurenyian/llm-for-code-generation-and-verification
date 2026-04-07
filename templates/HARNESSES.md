# 可复用 harness 设计

这个目录保存两类模板：

1. `harness_template.c`：通用 KLEE harness
2. `function_spec_template.json`：每个 API 的函数级配置

## 复用原则

- **harness 只保留通用逻辑**：KLEE 初始化、符号输入、调用目标函数、打印结果。
- **函数差异放在 JSON**：目标函数名、参数、边界输入、依赖、关键谓词。
- **stub 由 LLM 自动生成**：只需要读取 JSON，不手写每个函数的 stub。

## 新函数接入流程

1. 复制 `function_spec_template.json`，填入新函数信息。
2. 用分析工具生成 `predicate_ir.json` 和依赖列表。
3. 让 LLM 基于 spec 生成 `oda_stubs.c`。
4. 用模板生成对应 `harness_<func>.c`。
5. 跑 KLEE，检查：`missing_predicate_dependencies`、`Icov/I`、`Iuncov`、`Completed paths`。
6. 覆盖不足则把反馈回灌给 LLM 重新生成 stub。

## 建议的目录约定

- `templates/`：稳定模板
- `specs/`：每个函数的 JSON 配置
- `klee/`：每个函数的 harness 和 stub 输出目录
- `runner/_ubuntu_out/<api>/`：运行结果、统计、测试用例和差异报告
