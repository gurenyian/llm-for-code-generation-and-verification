# Wine API 自动化测试生成与验证系统

## 🎯 项目目标
使用 KLEE 符号执行 + LLM 辅助，为 Wine 项目自动生成高覆盖率的 Windows API 测试用例，并通过跨平台对比验证代码正确性。

## ⭐ 核心创新点
1. **Hierarchical RAG**：分层索引 Wine 源码（DLL → File → Function）
2. **LLM 自动生成 stub**：分析依赖 → 生成 ODA 规约 → 生成 C 代码 🆕
3. **On-Demand Abstraction (ODA)**：为复杂依赖函数生成 stub
4. **KLEE 符号执行**：自动生成全路径覆盖的测试输入


## 🔄 完整流程

```
┌─────────────────────────────────────────────────────────────┐
│  阶段 1: 代码生成                          │
│  Hierarchical RAG → LongCodeZip → LLM → Wine API 实现        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  阶段 2: 测试生成（本系统核心）🆕                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 1. 分析依赖  │ →  │ 2. LLM 生成  │ →  │ 3. KLEE 执行 │  │
│  │   (自动)     │    │   stub 规约  │    │   (符号执行) │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         ↓                    ↓                    ↓          │
│  依赖函数列表          ODA 规约 JSON         test_cases.bin  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  阶段 3: 跨平台验证                                           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ Windows 录制 │ →  │ Wine 回放    │ →  │ 差异分析     │  │
│  │ (--record)   │    │ (--check)    │    │ (报告 bug)   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         ↓                    ↓                    ↓          │
│   oracle.bin          断言失败列表         修正建议          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  阶段 4: 迭代优化（LLM 辅助）                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 失败反馈     │ →  │ LLM 修正代码 │ →  │ 重新测试     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```


## ♻️ 迭代提升 BCov（自动化）

建议在 **Ubuntu/KLEE 主机** 上运行：

```bash
python3 scripts/iterate_bcov_loop.py \
    --index rag/index.json \
    --wine-root /home/<user>/wine-master \
    --dll shlwapi \
    --file path.c \
    --func PathCombineW \
    --harness /home/<user>/wine-master/oda_demo/klee/harness_pathcombinew.c \
    --iterations 3 \
    --bcov-target 70
```

输出目录默认在 `_iter_bcov/iter_XX/`，每轮会写入：
- `oda_stubs.c`（LLM 生成）
- `coverage.json`（BCov/ICov/用例数）
- `bcov_feedback.txt`（下一轮提示词反馈）
- `summary.json`（总览）



### 运行示例（Ubuntu）

```bash
python3 -m pip install -r requirements.txt
python3 scripts/wine_indexer.py --dir ~/wine-source/dlls --out wine_kb.json
python3 scripts/dependency_analyzer.py --target-func PathCombineW --target-file ~/wine-source/dlls/shlwapi/path.c
python3 scripts/oda_engine.py
bash scripts/run_klee.sh klee/harness_pathcombinew.c
python3 scripts/remote_diff_tester.py --runner runner/test_runner.c --libs "shlwapi.lib kernel32.lib"
```



## 🎯 使用场景

### 场景 1: 验证 LLM 生成的代码

```python
# 1. LLM 生成代码
generated_code = llm.generate("实现 PathCombineW")

# 2. 自动生成测试
./run_full_pipeline.sh PathCombineW

# 3. 如果失败，反馈给 LLM
if test_failed:
    feedback = generate_feedback(test_results)
    improved_code = llm.generate(f"修正代码:\n{feedback}")
```

### 场景 2: 发现 Wine 的 bug

```bash
# 为现有 Wine API 生成测试
./run_full_pipeline.sh PathCanonicalizeW

# 如果发现不一致，提交 bug 报告
```

### 场景 3: 回归测试

```bash
# 每次修改 Wine 代码后
./run_full_pipeline.sh PathIsRelativeW

# 确保没有破坏现有功能
```


