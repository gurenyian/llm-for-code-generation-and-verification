#!/usr/bin/env python3
"""Iterative BCov-driven stub generation loop.

This script automates:
  1) LLM stub generation (generate_oda_with_llm.py)
  2) Copying oda_stubs.c into oda_demo/klee
  3) Running KLEE (scripts/run_klee.sh)
  4) Collecting BCov/ICov via klee-stats
  5) Feeding coverage feedback into the next LLM prompt

Recommended to run on the Ubuntu host where KLEE is installed.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
import hashlib
from typing import Dict, List, Optional

try:
    from coverage_extractor import extract_uncovered_lines
except Exception:  # pragma: no cover - optional runtime import
    extract_uncovered_lines = None


def run_cmd(args: List[str], cwd: Optional[Path] = None, *, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run(args, cwd=str(cwd) if cwd else None, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout.strip())
    if result.stderr:
        print(result.stderr.strip())
    if check and result.returncode != 0:
        raise SystemExit(result.returncode)
    return result


def _file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_klee_stats(text: str) -> Dict[str, float]:
    # Expect a table with a row like: |klee-out-0|   72578|     1.33|    79.01|    60.94|     324|       62.79|
    for line in text.splitlines():
        if "klee-out-" in line and "|" in line:
            parts = [p.strip() for p in line.strip().strip("|").split("|")]
            if len(parts) >= 5:
                try:
                    return {
                        "icov": float(parts[3]),
                        "bcov": float(parts[4]),
                    }
                except ValueError:
                    continue
    return {"icov": 0.0, "bcov": 0.0}


def _run_lcov_capture(
    *,
    capture_dir: Path,
    output_file: Path,
    base_dir: Optional[Path] = None,
    gcov_tool: Optional[str] = None,
    rc_opts: Optional[List[str]] = None,
) -> bool:
    cmd = ["lcov", "--capture", "--directory", str(capture_dir), "--output-file", str(output_file)]
    if base_dir:
        cmd += ["--base-directory", str(base_dir)]
    if gcov_tool:
        cmd += ["--gcov-tool", gcov_tool]
    if rc_opts:
        for opt in rc_opts:
            cmd += ["--rc", opt]
    try:
        run_cmd(cmd, cwd=base_dir, check=True)
        return output_file.exists()
    except SystemExit:
        return False


def read_case_count(klee_out: Path) -> Optional[int]:
    info_path = klee_out / "info"
    if not info_path.exists():
        return None
    text = info_path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"generated tests\s*=\s*(\d+)", text)
    if not m:
        m = re.search(r"generated tests\s*:\s*(\d+)", text)
    return int(m.group(1)) if m else None


def _extract_error_snippets(text: str, max_lines: int = 40) -> List[str]:
    hits: List[str] = []
    lines = text.splitlines()
    klee_error = re.compile(r"KLEE:\s*ERROR:\s*(.*)")
    file_line = re.compile(r"(?P<file>[^:\s]+\.[ch]):(?P<line>\d+)")
    for idx, line in enumerate(lines):
        l = line.lower()
        match = klee_error.search(line)
        if match:
            detail = match.group(1).strip()
            loc = file_line.search(detail)
            if loc:
                hits.append(f"{detail} (file={loc.group('file')}, line={loc.group('line')})")
            else:
                hits.append(detail)
        elif "invalid klee_assume" in l or "failed external call" in l or "error" in l:
            hits.append(line.strip())
        if len(hits) >= max_lines:
            break
        if match and idx + 1 < len(lines):
            next_line = lines[idx + 1].strip()
            if next_line:
                hits.append(f"context: {next_line}")
                if len(hits) >= max_lines:
                    break
    return hits


def _parse_lcov_uncovered(lcov_path: Path, *, target_file: str, max_lines: int = 12) -> List[int]:
    if not lcov_path.exists():
        return []
    uncovered: List[int] = []
    current_file: Optional[str] = None
    target_norm = target_file.replace("\\", "/")
    with lcov_path.open("r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if line.startswith("SF:"):
                current_file = line[3:]
                if current_file:
                    current_file = current_file.replace("\\", "/")
                continue
            if line.startswith("DA:") and current_file:
                if not (current_file.endswith("/" + target_norm) or current_file.endswith(target_norm)):
                    continue
                parts = line[3:].split(",")
                if len(parts) >= 2:
                    try:
                        ln = int(parts[0])
                        count = int(parts[1])
                    except ValueError:
                        continue
                    if count == 0:
                        uncovered.append(ln)
                        if len(uncovered) >= max_lines:
                            break
    return uncovered


def build_feedback(
    prev: Dict[str, float],
    case_count: Optional[int],
    *,
    error_snips: Optional[List[str]] = None,
    uncovered_lines: Optional[List[int]] = None,
    uncovered_hints: Optional[List[str]] = None,
    degrade: bool = False,
) -> str:
    lines = [
        "目标：显著提高 KLEE 的分支覆盖率（BCov），优先覆盖所有 if/else 与关键返回路径。",
        "核心要求：所有分支条件必须由输入驱动，禁止常量分支与固定返回值。",
        "约束策略：",
        "- 使用 klee_make_symbolic 生成多类输入（长度、内容、路径分隔符、空串/NULL、相对/绝对/UNC）。",
        "- 仅用必要且宽松的 klee_assume，确保多分支可达；避免过窄约束导致路径被剪枝。",
        "语义一致性：stub 的返回值与输出必须与输入关联（如长度、是否包含分隔符、前缀匹配等）。",
        "多样性：输出逻辑至少包含 3 种以上可达分支，并体现不同输入类别的处理差异。",
        "禁止：if(1)/if(0)/恒定 return/单一分支兜底/覆盖所有路径的早返回。",
    ]
    if prev:
        lines.append(f"上轮结果：BCov={prev.get('bcov', 0.0):.2f}%，ICov={prev.get('icov', 0.0):.2f}%。")
    if case_count is not None:
        lines.append(f"上轮生成用例数：{case_count}。")
    if uncovered_lines:
        lines.append("未覆盖行（优先让这些行所在分支可达）：")
        lines.append("- " + ", ".join(str(ln) for ln in uncovered_lines))
    if uncovered_hints:
        lines.append("【关键情报】目标函数中以下代码行从未被执行到：")
        lines.extend([f"- {hint}" for hint in uncovered_hints])
        lines.append("请重点审查这些未覆盖行所在分支的进入条件，修改 stub 的约束以便生成命中这些分支的输入。")
    if error_snips:
        lines.append("上轮编译/执行错误（请修复这些问题，生成可编译的 C stub）：")
        lines.extend([f"- {s}" for s in error_snips])
    if degrade:
        lines.append(
            "这是最后一次尝试：如果无法实现复杂语义绑定，请降级为最安全的有界实现，"
            "确保可编译、不中断，并保留最少量分支（但仍需输入驱动）。"
        )
    return "\n".join(lines)


def rewrite_feedback_with_llm(base_feedback: str) -> Optional[str]:
    try:
        oda_root = Path(__file__).resolve().parents[1]
        if str(oda_root) not in sys.path:
            sys.path.insert(0, str(oda_root))
        from llm_integration.llm_client import OpenAICompatLLM, load_llm_config_from_env

        llm = OpenAICompatLLM(load_llm_config_from_env())
        prompt = (
            "你是 KLEE 覆盖率优化助手。以下是上轮 BCov 低时的错误与约束问题，请将其整理为"
            "更有约束力的提示词指导，用于让 LLM 生成更可编译、更易覆盖分支的 stub。\n\n"
            "要求：仅输出可直接拼接到 prompt 的指导文本，不要解释，不要 JSON。\n\n"
            f"反馈内容:\n{base_feedback}\n"
        )
        response = llm.generate(prompt)
        return response.strip()
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--wine-root", required=True)
    ap.add_argument("--oda-root", help="Path to oda_demo root (defaults to <wine-root>/oda_demo)")
    ap.add_argument("--dll", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--func", required=True)
    ap.add_argument("--harness", required=True, help="Path to KLEE harness .c")
    ap.add_argument("--out-root", default="_iter_bcov")
    ap.add_argument("--iterations", type=int, default=3)
    ap.add_argument("--bcov-target", type=float, default=0.0)
    ap.add_argument("--max-time", default="60s")
    ap.add_argument("--max-memory", default="2048")
    ap.add_argument("--allow-fallback", action="store_true", help="Allow fallback spec when LLM fails")
    ap.add_argument("--seed-stub", help="Fallback stub file if LLM stub fails to compile")
    ap.add_argument("--llm-rewrite-feedback", action="store_true", help="Let LLM rewrite feedback for next prompt")
    ap.add_argument("--fix-retries", type=int, default=1, help="Retry LLM stub fix attempts when build fails")
    ap.add_argument("--require-llm-fix", action="store_true", help="Disable fallback during fix attempts")
    ap.add_argument("--lcov-file", help="Optional lcov.info path to extract uncovered lines")
    ap.add_argument("--lcov-target-file", help="Target source file path (relative to wine root) for lcov lookup")
    ap.add_argument("--degrade-on-last", action="store_true", help="Ask LLM to degrade on the final retry")
    ap.add_argument("--lcov-capture-dir", help="Directory to collect gcda/gcno for lcov capture")
    ap.add_argument("--lcov-output", default="lcov.info", help="Output lcov.info path")
    ap.add_argument("--lcov-base-dir", help="Base directory for lcov capture (optional)")
    ap.add_argument("--lcov-gcov-tool", help="Optional gcov tool path for lcov")
    ap.add_argument("--lcov-rc", action="append", help="Extra lcov --rc options (repeatable)")
    ap.add_argument("--coverage-extract", action="store_true", help="Extract gcov uncovered lines after KLEE")
    ap.add_argument("--coverage-test-runner", help="Path to test_runner.c for coverage replay")
    ap.add_argument("--coverage-test-cases", help="Path to test_cases.bin generated by KLEE")
    ap.add_argument("--coverage-oracle", help="Path to oracle.bin for replay")
    ap.add_argument("--coverage-compiler", default="gcc", help="Compiler to build coverage runner")
    ap.add_argument("--coverage-extra-src", action="append", help="Extra source files to compile with coverage runner")
    ap.add_argument("--coverage-cflag", action="append", help="Extra CFLAGS for coverage build (repeatable)")
    ap.add_argument("--coverage-ldflag", action="append", help="Extra LDFLAGS for coverage build (repeatable)")
    ap.add_argument("--coverage-work-dir", help="Working directory for gcov artifacts")
    args = ap.parse_args()

    oda_root = Path(args.oda_root) if args.oda_root else (Path(args.wine_root) / "oda_demo")
    scripts_dir = oda_root / "scripts"
    klee_dir = oda_root / "klee"

    out_root = Path(args.out_root)
    out_root.mkdir(parents=True, exist_ok=True)

    summary: List[Dict[str, float]] = []
    prev_metrics: Dict[str, float] = {}
    prev_cases: Optional[int] = None
    prev_error_snips: List[str] = []
    prev_uncovered_hints: List[str] = []

    for i in range(1, args.iterations + 1):
        iter_dir = out_root / f"iter_{i:02d}"
        iter_dir.mkdir(parents=True, exist_ok=True)

        low_bcov = bool(prev_metrics) and args.bcov_target and prev_metrics.get("bcov", 0.0) < args.bcov_target
        uncovered_lines: List[int] = []
        if low_bcov and args.lcov_file:
            target_file = args.lcov_target_file or args.file
            uncovered_lines = _parse_lcov_uncovered(Path(args.lcov_file), target_file=target_file)
        feedback = (
            build_feedback(
                prev_metrics,
                prev_cases,
                error_snips=prev_error_snips if low_bcov else None,
                uncovered_lines=uncovered_lines if low_bcov else None,
                uncovered_hints=prev_uncovered_hints if low_bcov else None,
            )
            if i > 1
            else ""
        )
        if feedback and low_bcov and args.llm_rewrite_feedback:
            rewritten = rewrite_feedback_with_llm(feedback)
            if rewritten:
                feedback = rewritten
        feedback_path = iter_dir / "bcov_feedback.txt"
        if feedback:
            feedback_path.write_text(feedback, encoding="utf-8")

        def run_generate(out_dir: Path, extra_feedback: Optional[str], *, allow_fallback: bool) -> None:
            gen_cmd = [
                sys.executable,
                str(scripts_dir / "generate_oda_with_llm.py"),
                "--index",
                args.index,
                "--wine-root",
                args.wine_root,
                "--dll",
                args.dll,
                "--file",
                args.file,
                "--func",
                args.func,
                "--outdir",
                str(out_dir),
            ]
            if allow_fallback and args.allow_fallback:
                gen_cmd.append("--allow-fallback")
            if extra_feedback:
                tmp_path = out_dir / "feedback_prompt.txt"
                tmp_path.write_text(extra_feedback, encoding="utf-8")
                gen_cmd += ["--prompt-extra-file", str(tmp_path)]
            run_cmd(gen_cmd, cwd=oda_root)

        run_generate(iter_dir, feedback, allow_fallback=not args.require_llm_fix)

        stub_src = iter_dir / "oda_stubs.c"
        stub_dst = klee_dir / "oda_stubs.c"
        if not stub_src.exists():
            raise SystemExit(f"stub not found: {stub_src}")
        shutil.copy2(stub_src, stub_dst)

        klee_cmd = [
            str(scripts_dir / "run_klee.sh"),
            args.harness,
            "--max-time",
            args.max_time,
            "--max-memory",
            args.max_memory,
        ]
        result = run_cmd(klee_cmd, cwd=oda_root, check=False)
        klee_log = (result.stdout or "") + "\n" + (result.stderr or "")
        (iter_dir / "klee_log.txt").write_text(klee_log, encoding="utf-8", errors="replace")

        retry = 0
        err_snips = _extract_error_snippets(klee_log)
        while err_snips and retry < args.fix_retries:
            retry += 1
            degrade = args.degrade_on_last and retry >= args.fix_retries
            fix_feedback = build_feedback(
                prev_metrics,
                prev_cases,
                error_snips=err_snips,
                uncovered_lines=uncovered_lines if low_bcov else None,
                uncovered_hints=prev_uncovered_hints if low_bcov else None,
                degrade=degrade,
            )
            fix_feedback += "\n\n必须修复上面的编译/约束错误，并确保生成的 stub 与上一版不同。"
            fix_dir = iter_dir / f"fix_{retry}"
            fix_dir.mkdir(parents=True, exist_ok=True)

            prev_hash = _file_hash(stub_src)
            run_generate(fix_dir, fix_feedback, allow_fallback=not args.require_llm_fix)
            new_stub = fix_dir / "oda_stubs.c"
            if not new_stub.exists():
                break
            new_hash = _file_hash(new_stub)
            if new_hash == prev_hash:
                fix_feedback += "\n你输出的 stub 与上一版完全一致，请更改实现细节（分支/约束/返回逻辑）。"
                run_generate(fix_dir, fix_feedback, allow_fallback=not args.require_llm_fix)
                if new_stub.exists():
                    new_hash = _file_hash(new_stub)

            if new_hash != prev_hash:
                shutil.copy2(new_stub, stub_dst)
            result = run_cmd(klee_cmd, cwd=oda_root, check=False)
            klee_log = (result.stdout or "") + "\n" + (result.stderr or "")
            (iter_dir / "klee_log.txt").write_text(klee_log, encoding="utf-8", errors="replace")
            err_snips = _extract_error_snippets(klee_log)
        if result.returncode != 0 and args.seed_stub:
            seed_path = Path(args.seed_stub)
            if seed_path.exists():
                print("[iter] KLEE compile failed; falling back to seed stub...")
                if seed_path.resolve() != stub_dst.resolve():
                    shutil.copy2(seed_path, stub_dst)
                else:
                    print("[iter] seed stub equals target stub; skipping copy")
                result = run_cmd(klee_cmd, cwd=oda_root, check=True)
                klee_log = (result.stdout or "") + "\n" + (result.stderr or "")
                (iter_dir / "klee_log.txt").write_text(klee_log, encoding="utf-8", errors="replace")
            else:
                raise SystemExit(f"Seed stub not found: {seed_path}")
        elif result.returncode != 0:
            raise SystemExit(result.returncode)

        stats = run_cmd(["klee-stats", "klee-out-0"], cwd=klee_dir, check=False)
        metrics = parse_klee_stats(stats.stdout or "")
        case_count = read_case_count(klee_dir / "klee-out-0")

        prev_uncovered_hints = []
        if args.coverage_extract and extract_uncovered_lines:
            if metrics.get("bcov", 0.0) < 100.0:
                wine_src = Path(args.wine_root) / "dlls" / args.dll / args.file
                test_runner = Path(args.coverage_test_runner) if args.coverage_test_runner else (oda_root / "runner" / "test_runner.c")
                test_cases_bin = Path(args.coverage_test_cases) if args.coverage_test_cases else (klee_dir / "test_cases.bin")
                oracle_bin = Path(args.coverage_oracle) if args.coverage_oracle else (klee_dir / "oracle.bin")
                work_dir = args.coverage_work_dir
                print("[INFO] BCov 未满，正在提取源码级未覆盖行...")
                try:
                    prev_uncovered_hints = extract_uncovered_lines(
                        str(wine_src),
                        str(test_runner),
                        str(test_cases_bin),
                        str(oracle_bin),
                        compiler=args.coverage_compiler,
                        extra_sources=args.coverage_extra_src,
                        extra_cflags=args.coverage_cflag,
                        extra_ldflags=args.coverage_ldflag,
                        work_dir=work_dir,
                    )
                except Exception as exc:
                    print(f"[WARN] 覆盖率提取失败: {exc}")
        elif args.coverage_extract and extract_uncovered_lines is None:
            print("[WARN] coverage_extractor 导入失败，跳过覆盖率提取。")

        if args.lcov_capture_dir:
            capture_dir = Path(args.lcov_capture_dir)
            base_dir = Path(args.lcov_base_dir) if args.lcov_base_dir else None
            output_file = Path(args.lcov_output)
            if not output_file.is_absolute():
                output_file = iter_dir / output_file
            ok = _run_lcov_capture(
                capture_dir=capture_dir,
                output_file=output_file,
                base_dir=base_dir,
                gcov_tool=args.lcov_gcov_tool,
                rc_opts=args.lcov_rc,
            )
            if ok:
                args.lcov_file = str(output_file)

        summary.append({
            "iteration": i,
            "bcov": metrics.get("bcov", 0.0),
            "icov": metrics.get("icov", 0.0),
            "cases": float(case_count or 0),
        })
        (iter_dir / "coverage.json").write_text(json.dumps({
            "iteration": i,
            "bcov": metrics.get("bcov", 0.0),
            "icov": metrics.get("icov", 0.0),
            "cases": case_count,
        }, indent=2), encoding="utf-8")

        print(f"[iter {i}] BCov={metrics.get('bcov', 0.0):.2f} ICov={metrics.get('icov', 0.0):.2f} cases={case_count}")
        prev_metrics = metrics
        prev_cases = case_count
        prev_error_snips = _extract_error_snippets(klee_log)

        if args.bcov_target and metrics.get("bcov", 0.0) >= args.bcov_target:
            print(f"Reached BCov target: {args.bcov_target}")
            break

    (out_root / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
