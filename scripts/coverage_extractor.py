#!/usr/bin/env python3
"""Coverage extraction helper for KLEE-generated test cases.

Compiles a coverage-instrumented runner + Wine source file, replays test cases,
then parses gcov output to list uncovered source lines.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Iterable, List, Optional


def _run(cmd: List[str], *, cwd: Optional[Path] = None, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=check)


def _cleanup_cov_files(directory: Path) -> None:
    for pattern in ("*.gcda", "*.gcno", "*.gcov"):
        for path in directory.glob(pattern):
            try:
                path.unlink()
            except FileNotFoundError:
                continue


def _find_gcov_output(work_dir: Path, source_path: Path) -> Optional[Path]:
    exact = work_dir / f"{source_path.name}.gcov"
    if exact.exists():
        return exact
    # gcov may emit with mangled path components; fallback to any matching basename
    matches = sorted(work_dir.glob("*.gcov"))
    for candidate in matches:
        if candidate.name.endswith(f"{source_path.name}.gcov") or candidate.stem.endswith(source_path.name):
            return candidate
    return None


def extract_uncovered_lines(
    wine_src_file: str,
    test_runner_src: str,
    test_cases_bin: str,
    oracle_bin: str,
    *,
    compiler: str = "gcc",
    extra_sources: Optional[Iterable[str]] = None,
    extra_cflags: Optional[Iterable[str]] = None,
    extra_ldflags: Optional[Iterable[str]] = None,
    work_dir: Optional[str] = None,
) -> List[str]:
    """Compile instrumented runner, run cases, and parse gcov for uncovered lines.

    Returns a list like "Line 46: strip = TRUE;".
    """

    src_path = Path(wine_src_file).resolve()
    runner_path = Path(test_runner_src).resolve()
    cases_path = Path(test_cases_bin).resolve()
    oracle_path = Path(oracle_bin).resolve()

    cov_work_dir = Path(work_dir).resolve() if work_dir else src_path.parent
    cov_work_dir.mkdir(parents=True, exist_ok=True)

    _cleanup_cov_files(cov_work_dir)

    cov_exe = cov_work_dir / "test_runner_cov"
    compile_cmd = [
        compiler,
        "-O0",
        "-g",
        "-fprofile-arcs",
        "-ftest-coverage",
        str(runner_path),
        str(src_path),
        "-o",
        str(cov_exe),
    ]
    if extra_sources:
        compile_cmd.extend([str(Path(src).resolve()) for src in extra_sources])
    if extra_cflags:
        compile_cmd.extend(list(extra_cflags))
    if extra_ldflags:
        compile_cmd.extend(list(extra_ldflags))

    _run(compile_cmd, cwd=cov_work_dir, check=True)

    if not cases_path.exists() or not oracle_path.exists():
        return []

    run_cmd = [str(cov_exe), "--check", str(cases_path), str(oracle_path)]
    _run(run_cmd, cwd=cov_work_dir, check=False)

    gcov_cmd = ["gcov", str(src_path)]
    _run(gcov_cmd, cwd=cov_work_dir, check=True)

    gcov_path = _find_gcov_output(cov_work_dir, src_path)
    if not gcov_path or not gcov_path.exists():
        return []

    uncovered: List[str] = []
    with gcov_path.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            parts = line.split(":", 2)
            if len(parts) < 3:
                continue
            execution_count = parts[0].strip()
            line_number = parts[1].strip()
            source_code = parts[2].rstrip()
            if execution_count == "#####":
                try:
                    ln = int(line_number)
                except ValueError:
                    continue
                if source_code.strip() not in {"", "{", "}"}:
                    uncovered.append(f"Line {ln}: {source_code.strip()}")

    return uncovered
