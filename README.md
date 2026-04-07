# Wine API 自动化测试生成与验证系统

## 🎯 项目目标
使用 KLEE 符号执行 + LLM 辅助，为 Wine 项目自动生成高覆盖率的 Windows API 测试用例，并通过跨平台对比验证代码正确性。

## ⭐ 核心创新点
1. **Hierarchical RAG**：分层索引 Wine 源码（DLL → File → Function）
2. **LLM 自动生成 stub**：分析依赖 → 生成 ODA 规约 → 生成 C 代码 🆕
3. **On-Demand Abstraction (ODA)**：为复杂依赖函数生成 stub
4. **KLEE 符号执行**：自动生成全路径覆盖的测试输入
5. **跨平台 Oracle**：Windows 录制 + Wine 回放，自动发现行为差异

## 🚀 快速体验（5 分钟）

```bash
# 运行简单示例（lstrcpyW）
cd oda_demo/examples/simple_demo
chmod +x run_demo.sh
./run_demo.sh

# 预期输出：生成 6+ 个测试用例，覆盖所有分支
```

## 📁 项目结构

```
oda_demo/
├── 📖 文档（8 个）
│   ├── START_HERE.md           ← 从这里开始（3 分钟）
│   ├── COMPLETE_GUIDE.md       ← 完整教程（30 分钟）
│   ├── QUICK_REFERENCE.md      ← 速查表
│   ├── PROJECT_SUMMARY.md      ← 技术总结
│   ├── TROUBLESHOOTING.md      ← 故障排除
│   └── ...
│
├── 🔍 模块 1: RAG（代码索引）
│   ├── build_index.py          # 扫描 Wine 源码
│   ├── query.py                # 分层查询
│   └── index.json              # 生成的索引
│
├── 🤖 模块 2: LLM 集成（自动生成 stub）🆕
│   ├── dependency_analyzer.py  # 分析函数依赖
│   ├── oda_generator.py        # LLM 生成 ODA 规约
│   ├── example_pathcombinew.py # 完整示例
│   └── ANSWER_TO_QUESTIONS.md  # 常见问题
│
├── 🎯 模块 3: ODA 规约
│   ├── pathisrelativew.json    # 示例规约
│   └── gen_oda_stub.py         # JSON → C 代码
│
├── ⚡ 模块 4: KLEE（符号执行）
│   ├── harness_*.c             # 测试驱动
│   ├── run_klee.sh             # 运行 KLEE
│   └── ktest_to_cases.py       # 转换测试用例
│
├── ✅ 模块 5: Runner（跨平台验证）
│   ├── wine_test.h             # 测试框架
│   ├── test_runner.c           # 测试程序
│   └── run_tests.py            # SSH 控制
│
├── 💡 示例（可立即运行）🆕
│   └── simple_demo/            # lstrcpyW 完整示例
│       ├── run_demo.sh         # 一键运行
│       ├── lstrcpyw_spec.json  # ODA 规约
│       └── harness_lstrcpyw.c  # KLEE harness
│
└── 🛠️ 工具脚本
    ├── run_full_pipeline.sh    # 完整流程
    └── check_klee_installation.sh  # 环境检查

新增脚本：`scripts/iterate_bcov_loop.py`
- 自动迭代生成 stub → 运行 KLEE → 统计 BCov → 反馈到下一轮 LLM 提示词
```

## 🔄 完整流程

```
┌─────────────────────────────────────────────────────────────┐
│  阶段 1: 代码生成（你已有的部分）                              │
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

## 🆕 新增功能：LLM 自动生成 stub

### 问题
之前需要手工编写 ODA 规约（JSON），指定每个依赖函数的约束。

### 解决方案
现在可以使用 LLM 自动生成！

```python
from llm_integration.dependency_analyzer import DependencyAnalyzer
from llm_integration.oda_generator import ODAGenerator

# 1. 分析依赖
analyzer = DependencyAnalyzer("rag/index.json", "../wine")
deps = analyzer.analyze("shlwapi", "path.c", "PathCombineW")
# 输出: ["PathIsRelativeW", "lstrlenW", "lstrcpyW"]

# 2. 分析谓词
predicates = analyzer.analyze_predicates("shlwapi", "path.c", "PathCombineW")
# 输出: [{"condition": "len > 0", ...}, ...]

# 3. LLM 生成 ODA 规约
generator = ODAGenerator(llm_client)
spec = generator.generate("PathCombineW", deps, predicates)
# 输出: 完整的 JSON 规约，包含所有 stub 的约束

# 4. 生成 C 代码
python gen_oda_stub.py pathcombinew.json -o oda_stubs.c
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

详见：[llm_integration/README.md](llm_integration/README.md)

## 🧩 通用流水线脚本（已集成到 oda_demo/scripts）

为匹配“Hierarchical RAG + ODA + KLEE + SSH 差分测试”的完整流程，新增以下脚本：

- `scripts/wine_indexer.py`：Tree-sitter 扫描 `dlls/` 并生成 `wine_kb.json`
- `scripts/dependency_analyzer.py`：提取目标函数依赖并生成 `context_slice.json`
- `scripts/oda_engine.py`：基于指定 Prompt 生成 `oda_spec.json` 和 `oda_stubs.c`
- `scripts/run_klee.sh`：编译 harness 并运行 KLEE，产出 `test_cases.bin`
- `scripts/remote_diff_tester.py`：通过 SSH 在 Windows 录制 oracle 并本地校验

### 运行示例（Ubuntu）

```bash
python3 -m pip install -r requirements.txt
python3 scripts/wine_indexer.py --dir ~/wine-source/dlls --out wine_kb.json
python3 scripts/dependency_analyzer.py --target-func PathCombineW --target-file ~/wine-source/dlls/shlwapi/path.c
python3 scripts/oda_engine.py
bash scripts/run_klee.sh klee/harness_pathcombinew.c
python3 scripts/remote_diff_tester.py --runner runner/test_runner.c --libs "shlwapi.lib kernel32.lib"
```

## 📚 文档导航

### 🎓 新手入门
1. **[START_HERE.md](START_HERE.md)** - 3 分钟快速理解
2. **[COMPLETE_GUIDE.md](COMPLETE_GUIDE.md)** - 完整教程（小白友好）
3. **[examples/simple_demo/](examples/simple_demo/)** - 可运行的示例

### 💻 日常使用
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 命令速查表
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 故障排除

### 🔬 深入研究
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 技术架构
- **[llm_integration/ANSWER_TO_QUESTIONS.md](llm_integration/ANSWER_TO_QUESTIONS.md)** - LLM 集成详解
- 各模块的 README.md

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

## ✨ 核心优势

- ✅ **完全自动化**：从依赖分析到测试生成
- ✅ **高覆盖率**：KLEE 自动探索所有路径
- ✅ **可靠验证**：基于真实 Windows 行为
- ✅ **LLM 友好**：可与任何 LLM 无缝集成
- ✅ **易于扩展**：模块化设计，容易添加新功能
- ✅ **文档完善**：8 个文档，从入门到精通

## 🚀 立即开始

### 方式 1: 运行简单示例（推荐）

```bash
cd oda_demo/examples/simple_demo
./run_demo.sh
```

### 方式 2: 运行完整流程

```bash
cd oda_demo
./run_full_pipeline.sh PathIsRelativeW ../wine
```

### 方式 3: 使用 LLM 自动生成

```bash
cd oda_demo/llm_integration
python3 example_pathcombinew.py
```

## 📊 项目统计

- **文档**: 8 个（从入门到精通）
- **模块**: 5 个（RAG, LLM, ODA, KLEE, Runner）
- **示例**: 2 个（PathIsRelativeW, lstrcpyW）
- **代码文件**: 29 个
- **总行数**: 5000+ 行

## 🤝 贡献

欢迎贡献！可以：
- 添加新的示例函数
- 改进 LLM prompt
- 优化 KLEE 性能
- 完善文档

## 📝 许可证

MIT License

---

**需要帮助？**
- 📖 阅读 [START_HERE.md](START_HERE.md)
- 📋 查看 [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- 🔧 参考 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 💬 查看 [llm_integration/ANSWER_TO_QUESTIONS.md](llm_integration/ANSWER_TO_QUESTIONS.md)
