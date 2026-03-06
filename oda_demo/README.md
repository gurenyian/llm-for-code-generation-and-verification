## 你将得到什么（可运行的最小闭环）

这个 `oda_demo/` 目录提供一条**可执行**的端到端链路，用来理解并跑通：

- **Hierarchical RAG（dll / file / function）索引与定位**
- **函数摘要缓存**（优先用静态抽取 + 可选接入 LLM；不会每次都“重写 prompt”）
- **On-demand Abstraction（ODA）**：把 `(外部函数 f, 目标谓词 ψ)` 变成可注入 KLEE 的约束
- **KLEE 生成高覆盖输入用例**（输出 `cases.bin`）
- **Windows 录制 oracle**（`--record` 不断言）
- **Wine 回放对比**（`--check` 断言不一致）

本 demo 选用 Windows/Wine 都存在且行为稳定的真实 API：`PathIsRelativeW`（来自 `shlwapi`）。
KLEE 侧通过 ODA stub 对 `PathIsRelativeW` 建模（不分析其实现），只注入“充分条件”约束来引导探索。

> 为什么要选 `PathIsRelativeW`：
> - 真实存在于 Windows 与 Wine，可做 record/check
> - 返回值布尔，容易做目标谓词 `ret==0/1`
> - 便于你先把框架跑通；跑通后可按同样方式扩展到更复杂的 Path 系列（`PathCanonicalizeW` 等）

---

## 目录结构

- `rag/`
  - `build_index.py`：扫描 `dlls/`，按 dll→file→function 建索引（JSON）
  - `query.py`：按层级查询索引（只暴露当前层级的结果）
- `specs/`
  - `pathisrelativew.json`：ODA spec（演示用；也可由 LLM 自动生成）
  - `gen_oda_stub.py`：把 spec.json 生成 `oda_stubs.c`（KLEE 用）
- `klee/`
  - `harness_pathisrelativew.c`：KLEE harness（符号化 `WCHAR[32]`，覆盖目标分支）
  - `ktest_to_cases.py`：把 KLEE `.ktest` 转成 `cases.bin`
- `runner/`
  - `pathrel_runner.c`：同一份程序支持 Windows `--record` 与 Wine `--check`

---

## 第 1 部分：构建 Hierarchical RAG 索引（在 Windows 上运行）

在 `d:\wine\wine-master` 根目录打开 PowerShell：

```powershell
python .\\oda_demo\\rag\\build_index.py --root .\\dlls --out .\\oda_demo\\rag\\index.json
```

解释：
- 这一步只做**结构化索引**（dll / file / function），不做 LLM。
- 后续你做“每个函数摘要”时，会从该索引取到：函数名、文件路径、近邻函数等信息。

查询示例（逐级）：

```powershell
python .\\oda_demo\\rag\\query.py --index .\\oda_demo\\rag\\index.json --level dll --query path
python .\\oda_demo\\rag\\query.py --index .\\oda_demo\\rag\\index.json --level file --dll shlwapi --query path.c
python .\\oda_demo\\rag\\query.py --index .\\oda_demo\\rag\\index.json --level func --dll shlwapi --file path.c --query PathIsRelativeW
```

---

## 第 2 部分：KLEE 用 ODA 生成输入用例（在 Ubuntu VM 上本机安装 KLEE）

### 2.1 安装本机 KLEE（Ubuntu 22.04，从源码构建）

Ubuntu 22.04 的官方 apt 源没有 `klee` / `klee-dev` 包，我们改为**在家目录源码构建一个本地 KLEE**。下面步骤假设你在 Ubuntu 虚拟机里使用一个普通用户（例如 `guren`），并且网络至少可以访问 GitHub。

#### 2.1.1 安装依赖

```bash
sudo apt update

# 基本构建工具
sudo apt install -y build-essential cmake git python3 python3-pip \
                    clang-11 llvm-11 llvm-11-dev llvm-11-tools

# SMT 求解器（本 demo 只用 Z3 即可）
sudo apt install -y z3 libz3-dev

# 其它常见依赖（用于最小 KLEE 构建；先不启用 POSIX runtime）
sudo apt install -y libncurses5-dev libtcmalloc-minimal4 libgoogle-perftools-dev \
                    libsqlite3-dev
```

> 说明：
> - 我们绑定使用 `clang-11` / `llvm-11`，因为 KLEE 对高版本 LLVM 支持常常滞后一截；
> - 只构建“核心 KLEE + uclibc/Qt 相关关闭”的最小版本，足够跑本 demo。

#### 2.1.2 拉取 KLEE 源码并构建

在你的家目录下：

```bash
cd ~
git clone https://github.com/klee/klee.git
cd klee

mkdir build
cd build

cmake \
  -DENABLE_UNIT_TESTS=OFF \
  -DENABLE_SYSTEM_TESTS=OFF \
  -DENABLE_POSIX_RUNTIME=OFF \
  -DENABLE_SOLVER_STP=OFF \
  -DENABLE_SOLVER_Z3=ON \
  -DLLVM_CONFIG_BINARY=/usr/bin/llvm-config-11 \
  -DLLVMCC=/usr/bin/clang-11 \
  -DLLVMCXX=/usr/bin/clang++-11 \
  ..

make -j$(nproc)
```

构建完成后，你会在 `~/klee/build/bin/` 下看到 `klee` 可执行文件，在 `~/klee/include/` 下看到 `klee/klee.h` 头文件。

为了使用方便，可以把 KLEE 加到 PATH：

```bash
echo 'export KLEE_DIR=$HOME/klee' >> ~/.bashrc
echo 'export PATH=$KLEE_DIR/build/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

验证：

```bash
klee --version
```

如果能看到版本信息，就说明本地 KLEE 安装成功。

#### 2.1.3 准备 demo 目录

把你在 Windows 上的 `oda_demo/` 同步到 Ubuntu，例如放在：

```bash
cd ~
ls oda_demo   # 确认能看到 specs/ klee/ runner/ rag/ 等子目录
```

### 2.2 生成 stub、编译 bitcode、运行 KLEE（使用本地 KLEE）

在 `~/oda_demo` 下执行：

```bash
cd ~/oda_demo

# 1. 根据 ODA spec 生成 stub 源码
python3 specs/gen_oda_stub.py specs/pathisrelativew.json klee/oda_stubs.c

# 2. 使用 clang-11 编译 C 源码为 LLVM bitcode
clang-11 -I "$KLEE_DIR/include" -emit-llvm -c -g -O0 klee/harness_pathisrelativew.c -o klee/harness.bc
clang-11 -I "$KLEE_DIR/include" -emit-llvm -c -g -O0 klee/oda_stubs.c -o klee/oda_stubs.bc

# 3. 链接成一个整体 bitcode（使用 llvm-link-11）
llvm-link-11 klee/harness.bc klee/oda_stubs.bc -o klee/merged.bc

# 4. 运行 KLEE，做约束求解与路径探索（使用你刚编译的 klee）
klee --search=bfs --max-time=30s klee/merged.bc

# 5. 把 KLEE 生成的 .ktest 用例转成跨平台的 cases.bin
python3 klee/ktest_to_cases.py klee-last cases.bin
```

说明：

- `-I "$KLEE_DIR/include"`：让 clang 找到 `klee/klee.h` 头文件；
- `clang-11` / `llvm-link-11`：与前面使用的 LLVM 版本保持一致；
- `klee-last/` 目录会存放本次运行的所有 `.ktest` 文件，`ktest_to_cases.py` 会从中提取符号变量 `path` 的具体取值，转换为 `cases.bin`。

完成上述步骤后，你会得到 `cases.bin`（跨平台输入集），后续可在 Windows / Wine 上复用。

---

## 第 3 部分：Windows 录制 oracle（真实 Windows 行为）

在 Windows 上用 MSVC 编译（或用 mingw 也行，见下）：

```powershell
cl /O2 /W3 /EHsc .\\oda_demo\\runner\\pathrel_runner.c Shlwapi.lib /Fe:pathrel.exe
```

录制：

```powershell
.\pathrel.exe --record .\cases.bin .\oracle.tsv
```

解释：
- Windows 上**永远不做断言**，只记录真实输出。

---

## 第 4 部分：Wine 回放对比（断言差异）

在 Ubuntu：

```bash
sudo apt install -y wine
wine ./pathrel.exe --check ./cases.bin ./oracle.tsv
```

若输出 `OK: checked ...` 表示 Wine 与 Windows 在这些输入上行为一致。
如果有 `MISMATCH`，你就得到了一个**可复现反例**，可回灌到 LLM 修复 Wine/生成代码。

---

## 如何扩展到“更复杂函数 + 系统调用爆炸”的真实场景

跑通本 demo 后，你要做的升级点是：

- 目标不再是 `PathIsRelativeW`，而是你 LLM 生成的新 API/包装函数 `P`；
- `P` 内部调用很多复杂函数/系统调用（例如 `GetFileAttributesW`、`CreateFileW`、`PathCanonicalizeW` 等）；
- 你将这些外部调用写成 ODA stub，并按需生成 `(f, ψ) -> assume_c_expr`；
- KLEE 只探索 P 的逻辑，外部调用靠 ODA 约束引导。

本 demo 的 stub 生成器与层级索引就是为这个扩展准备的最小骨架。

