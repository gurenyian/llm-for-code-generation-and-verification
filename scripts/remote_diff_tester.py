#!/usr/bin/env python3
"""SSH 远程差分测试 (Ubuntu -> Windows)。

用法:
  python3 scripts/remote_diff_tester.py --cases test_cases.bin --runner test_runner.c --libs "shlwapi.lib"
"""

import argparse
import os
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
    ap.add_argument("--win-build", default=os.environ.get("WIN_BUILD", "local-gcc"))
    args = ap.parse_args()

    remote_dir = "C:\\oda_diff_test"

    print(f"Connecting to {args.win_host}...")
    if not args.win_key and not args.win_pass:
        raise SystemExit("Missing credentials: provide --win-key or --win-pass (or WIN_KEY/WIN_PASS).")

    ssh_base = [args.ssh_bin]
    scp_base = [args.scp_bin]
    if args.win_key:
        key_path = os.path.expanduser(args.win_key)
        ssh_base += ["-i", key_path]
        scp_base += ["-i", key_path]
    ssh_base += [f"{args.win_user}@{args.win_host}"]

    cmd_exe = "C:\\Windows\\System32\\cmd.exe"
    ssh_exec(ssh_base, f"{cmd_exe} /c \"mkdir {remote_dir} 2>nul || exit 0\"")
    run_cmd(scp_base + [args.cases, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_cases.bin"], check=True)

    win_exe = "test_runner_win.exe"
    if args.win_build == "local-gcc":
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
        run_cmd(scp_base + [win_exe, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_runner.exe"], check=True)
    else:
        run_cmd(scp_base + [args.runner, f"{args.win_user}@{args.win_host}:{remote_dir}\\test_runner.c"], check=True)
        ssh_exec(ssh_base, f"{cmd_exe} /c \"cd /d {remote_dir} && cl.exe /nologo test_runner.c {args.libs}\"")

    ssh_exec(ssh_base, f"{cmd_exe} /c \"cd /d {remote_dir} && test_runner.exe --record test_cases.bin oracle.bin\"")

    run_cmd(scp_base + [f"{args.win_user}@{args.win_host}:{remote_dir}\\oracle.bin", "oracle_win.bin"], check=True)

    subprocess.run(["gcc", "-I.", args.runner, "-o", "test_runner_bin", "-lshlwapi"], check=False)
    res = subprocess.run(
        ["./test_runner_bin", "--check", args.cases, "oracle_win.bin"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if res.stdout:
        print(res.stdout)
    if res.stderr:
        print("[local error]", res.stderr)

    if res.returncode != 0 or "Mismatch" in res.stdout:
        print("[diff] mismatches detected")


if __name__ == "__main__":
    main()
