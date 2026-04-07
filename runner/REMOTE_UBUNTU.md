# 远程在 Ubuntu VM 跑 KLEE/Wine（Windows 发起）

你的环境：
- **Windows 本机/主机**：用于编辑代码、生成 spec/stub、以及（可选）作为 Windows oracle 录制端
- **Ubuntu 虚拟机**：安装了 **KLEE + clang + wine/winegcc**，用于跑符号执行与 Wine 回放

本文把 `oda_demo` 现有 bash 流水线包装成“Windows 一键触发”。

## 1. 你提供的路径配置（示例）

- Windows SSH（用于 oracle 录制脚本 `runner/win_record.ps1`）：
  - `WIN_USER = Administrator`
  - `WIN_IP   = 192.168.154.1`
  - `WIN_KEY  = ~/.ssh/id_rsa`
  - `WIN_DEST_DIR = C:/Temp/WineTest/`

- Ubuntu Wine/KLEE：
  - `WINE_SRC_ROOT   = /home/guren/wine`
  - `WINE_BUILD_ROOT = /home/guren/wine/build64`（暂预留）

## 2. Ubuntu VM 前置依赖

Ubuntu VM 需要能运行：
- `python3`
- `clang`
- `klee`
- `ktest-tool`（通常随 KLEE 安装）

如果遇到 `klee/klee.h` 找不到：
- 参考 `oda_demo/TROUBLESHOOTING.md` 的“问题 1”
- 或在 Ubuntu 上运行：
  - `cd oda_demo; ./check_klee_installation.sh`

## 3. Windows 一键触发 Ubuntu pipeline

我们新增了：
- `oda_demo/scripts/ubuntu_run_pipeline.sh`（Ubuntu VM 上执行）
- `oda_demo/runner/ubuntu_run_pipeline.ps1`（Windows 上执行，负责 ssh/scp）

在 Windows PowerShell 里运行（把 Ubuntu 连接信息改成你自己的）：

```powershell
cd d:\wine\wine-master\oda_demo\runner

.\ubuntu_run_pipeline.ps1 `
  -UbuntuUser guren `
  -UbuntuHost <UBUNTU_IP> `
  -UbuntuKey $env:USERPROFILE\.ssh\id_rsa `
  -WineSrcRoot /home/guren/wine `
  -WineBuildRoot /home/guren/wine/build64 `
  -UbuntuWorkDir /home/guren/oda_work `
  -ApiName PathIsRelativeW
```

产物会被拉回到：
- `oda_demo/runner/_ubuntu_out/<api>/`
  - `oda_stubs.c`
  - `test_cases.bin`
  - `klee-out-0/*.ktest`

## 4. 下一步：接 Windows oracle + Wine check

当你想跑“Windows oracle 录制 → Ubuntu Wine check”闭环时：
1) 先用本远程脚本在 Ubuntu 上生成 `test_cases.bin`
2) 把 `test_cases.bin` 拿去 Windows oracle 录制 `oracle.bin`（用 `runner/win_record.ps1`）
3) 再把 `oracle.bin` 传回 Ubuntu，在 Wine 下执行 `runner/test_runner.c --check`

我可以继续把第 2/3 步也包装成同一个 `ps1` 一键任务（包含 scp 往返与日志汇总）。
