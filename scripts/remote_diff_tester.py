#!/usr/bin/env python3
"""SSH 远程差分测试 (Ubuntu -> Windows)。

用法:
  python3 scripts/remote_diff_tester.py --cases test_cases.bin --runner test_runner.c --libs "shlwapi.lib"
"""

import argparse
import os
import shutil
import subprocess


def run_cmd(args: list[str], *, check: bool = False) -> int:
    result = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.stdout:
        print(result.stdout.strip())
    if result.stderr:
        print(f"[remote error] {result.stderr.strip()}")
    if check and result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.returncode


def ssh_exec(base_args: list[str], cmd: str) -> int:
    return run_cmd(base_args + [cmd])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cases", default="test_cases.bin")
    ap.add_argument("--runner", required=True)
    ap.add_argument("--libs", default="shlwapi.lib")
    ap.add_argument("--win-host", default=os.environ.get("WIN_HOST", "192.168.154.129"))
    ap.add_argument("--win-user", default=os.environ.get("WIN_USER", "Administrator"))
    ap.add_argument("--win-pass", default=os.environ.get("WIN_PASS"))
    ap.add_argument("--win-key", default=os.environ.get("WIN_KEY"))
    ap.add_argument("--ssh-bin", default=os.environ.get("SSH_BIN", "ssh"))
    ap.add_argument("--scp-bin", default=os.environ.get("SCP_BIN", "scp"))
    ap.add_argument("--sshpass-bin", default=os.environ.get("SSHPASS_BIN", "sshpass"))
    ap.add_argument("--win-build", default=os.environ.get("WIN_BUILD", "local-gcc"))
    ap.add_argument("--win-cmd", default=os.environ.get("WIN_CMD", "C:\\Windows\\System32\\cmd.exe"))
    ap.add_argument("--win-shell", default=os.environ.get("WIN_SHELL", "cmd"))
    ap.add_argument("--win-runner", default=os.environ.get("WIN_RUNNER", ""))
    ap.add_argument("--wine-include", default=os.environ.get("WINE_INCLUDE", ""))
    ap.add_argument("--wine-src", default=os.environ.get("WINE_SRC_ROOT", ""))
    ap.add_argument("--wine-bin", default=os.environ.get("WINE_BIN", "wine"))
    ap.add_argument("--wine-runner", default=os.environ.get("WINE_RUNNER", "/home/guren/oda_work/oda_demo/runner/test_runner_wine.exe"))
    ap.add_argument("--local-runner", default=os.environ.get("LOCAL_RUNNER", "native"))
    ap.add_argument("--save-dir", default=os.environ.get("DIFF_SAVE_DIR", ""))
    args = ap.parse_args()

    remote_dir = "C:\\oda_diff_test"

    print(f"Connecting to {args.win_host}...")
    if not args.win_key and not args.win_pass:
        raise SystemExit("Missing credentials: provide --win-key or --win-pass (or WIN_KEY/WIN_PASS).")

    ssh_base = [args.ssh_bin]
    scp_base = [args.scp_bin]
    use_paramiko = False

    if args.win_pass and not args.win_key:
        if shutil.which(args.sshpass_bin):
            ssh_base = [args.sshpass_bin, "-p", args.win_pass] + ssh_base
            scp_base = [args.sshpass_bin, "-p", args.win_pass] + scp_base
        else:
            try:
                import paramiko
                use_paramiko = True
            except Exception as exc:
                raise SystemExit("sshpass not found and paramiko unavailable; cannot use password auth.") from exc

    if args.win_key:
        key_path = os.path.expanduser(args.win_key)
        ssh_base += ["-i", key_path]
        scp_base += ["-i", key_path]

    if not use_paramiko:
        ssh_base += [f"{args.win_user}@{args.win_host}"]

    cmd_exe = args.win_cmd

    def wrap_win_cmd(cmd: str) -> str:
        if args.win_shell.lower() == "powershell":
            escaped = cmd.replace("'", "''")
            return f"powershell -NoProfile -Command \"& '{cmd_exe}' /c '{escaped}'\""
        return f"{cmd_exe} /c \"{cmd}\""

    if use_paramiko:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(args.win_host, username=args.win_user, password=args.win_pass, timeout=10)
        sftp = client.open_sftp()

        def ssh_exec_pm(cmd: str) -> None:
            stdin, stdout, stderr = client.exec_command(cmd)
            out = stdout.read().decode("utf-8", errors="replace").strip()
            err = stderr.read().decode("utf-8", errors="replace").strip()
            if out:
                print(out)
            if err:
                print(f"[remote error] {err}")

        ssh_exec_pm(wrap_win_cmd(f"mkdir {remote_dir}"))
        sftp.put(args.cases, f"{remote_dir}\\test_cases.bin")
    else:
        ssh_exec(ssh_base, wrap_win_cmd(f"mkdir {remote_dir}"))
        run_cmd(scp_base + [args.cases, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_cases.bin"], check=True)

    win_exe = "test_runner_win.exe"
    if args.win_runner:
        if use_paramiko:
            sftp.put(args.win_runner, f"{remote_dir}\\test_runner.exe")
        else:
            run_cmd(scp_base + [args.win_runner, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_runner.exe"], check=True)
    elif args.win_build == "local-gcc":
        build = subprocess.run(
            ["gcc", "-I.", args.runner, "-o", win_exe, "-lshlwapi"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if build.returncode != 0:
            print(build.stdout)
            print(build.stderr)
            raise SystemExit("Failed to build Windows runner with local gcc.")
        if use_paramiko:
            sftp.put(win_exe, f"{remote_dir}\\test_runner.exe")
        else:
            run_cmd(scp_base + [win_exe, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_runner.exe"], check=True)
    else:
        if use_paramiko:
            sftp.put(args.runner, f"{remote_dir}\\test_runner.c")
            ssh_exec_pm(wrap_win_cmd(f"cd /d {remote_dir} && cl.exe /nologo test_runner.c {args.libs}"))
        else:
            run_cmd(scp_base + [args.runner, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_runner.c"], check=True)
            ssh_exec(ssh_base, wrap_win_cmd(f"cd /d {remote_dir} && cl.exe /nologo test_runner.c {args.libs}"))

    if use_paramiko:
        ssh_exec_pm(wrap_win_cmd(f"cd /d {remote_dir} && test_runner.exe --record test_cases.bin oracle.bin"))
    else:
        ssh_exec(ssh_base, wrap_win_cmd(f"cd /d {remote_dir} && test_runner.exe --record test_cases.bin oracle.bin"))

    if use_paramiko:
        sftp.get(f"{remote_dir}\\oracle.bin", "oracle_win.bin")
        sftp.close()
        client.close()
    else:
        run_cmd(scp_base + [f"{args.win_user}@{args.win_host}:{remote_dir}\\oracle.bin", "oracle_win.bin"], check=True)

    include_dirs = ["."]
    if args.wine_include:
        include_dirs.extend([p for p in args.wine_include.split(os.pathsep) if p])
    if os.path.isdir("/usr/include/wine"):
        include_dirs.append("/usr/include/wine")
    if args.wine_src:
        wine_inc = os.path.join(args.wine_src, "include")
        if os.path.isdir(wine_inc):
            include_dirs.append(wine_inc)
    if os.path.isdir("/home/guren/wine/include"):
        include_dirs.append("/home/guren/wine/include")
    runner_wine_inc = "/home/guren/oda_work/oda_demo/runner/wine"
    if os.path.isdir(runner_wine_inc):
        include_dirs.append(runner_wine_inc)
    runner_root = "/home/guren/oda_work/oda_demo/runner"
    if os.path.isdir(runner_root):
        include_dirs.append(runner_root)

    res = None
    if args.local_runner.lower() != "wine":
        gcc_cmd = ["gcc"]
        for inc in include_dirs:
            gcc_cmd.append(f"-I{inc}")
        gcc_cmd += [args.runner, "-o", "test_runner_bin", "-lshlwapi"]

        subprocess.run(gcc_cmd, check=False)
        if os.path.isfile("./test_runner_bin"):
            res = subprocess.run(
                ["./test_runner_bin", "--check", args.cases, "oracle_win.bin"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )

    if res is None:
        wine_bin = args.wine_bin
        if wine_bin == "wine" and shutil.which("wine64"):
            wine_bin = "wine64"
        if os.path.isfile(args.wine_runner):
            res = subprocess.run(
                [wine_bin, args.wine_runner, "--check", args.cases, "oracle_win.bin"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        else:
            raise SystemExit("Failed to build local runner and no wine runner available.")
    if res.stdout:
        print(res.stdout)
    if res.stderr:
        print("[local error]", res.stderr)

    save_dir = args.save_dir
    if save_dir:
        os.makedirs(save_dir, exist_ok=True)
        with open(os.path.join(save_dir, "diff_stdout.txt"), "w", encoding="utf-8") as f:
            f.write(res.stdout or "")
        with open(os.path.join(save_dir, "diff_stderr.txt"), "w", encoding="utf-8") as f:
            f.write(res.stderr or "")
        summary = "PASS"
        if res.returncode != 0 or "Mismatch" in (res.stdout or ""):
            summary = "FAIL"
        with open(os.path.join(save_dir, "diff_summary.txt"), "w", encoding="utf-8") as f:
            f.write(summary + "\n")

    if res.returncode != 0 or "Mismatch" in (res.stdout or ""):
        print("[diff] mismatches detected")


if __name__ == "__main__":
    main()
