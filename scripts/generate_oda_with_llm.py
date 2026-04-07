#!/usr/bin/env python3
"""在 pipeline 里调用真实 LLM 生成 ODA spec + oda_stubs.c。

这个脚本的定位：
- 给 `scripts/ubuntu_run_pipeline.sh` 调用
- 把“依赖+ψ -> LLM -> spec.json -> oda_stubs.c”变成一个稳定、可复现、可观测的步骤

输入：
- --index rag/index.json
- --wine-root <wine repo root>
- --dll/--file/--func: 目标函数定位
- --outdir: 写入 llm_prompt.txt / llm_response.txt / llm_spec.json / oda_stubs.c

LLM 配置见：llm_integration/llm_client.py 的环境变量约定。
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import traceback
from pathlib import Path
from typing import Any, Dict, List


def _tokenize_symbol(s: str) -> List[str]:
    # 把 PathRemoveFileSpecW -> [path, remove, file, spec, w]；也兼容 snake_case。
    parts = []
    for p in s.replace("_", " ").split():
        parts.extend([x for x in ("".join([(" " + c if c.isupper() else c) for c in p]).split()) if x])
    toks = [t.strip().lower() for t in parts if t.strip()]
    return toks or [s.strip().lower()]


def _score_candidate(func_name: str, cand: Dict[str, Any], *, requested_dll: str, requested_file: str) -> float:
    score = 0.0
    # 1) 名称匹配强度
    want = func_name.strip().lower()
    got = str(cand.get("name", "")).strip().lower()
    if got == want:
        score += 10.0
    elif want in got or got in want:
        score += 5.0

    # 2) dll/file proximity
    if cand.get("dll") == requested_dll:
        score += 2.0
    if cand.get("file") == requested_file:
        score += 1.0

    # 3) signature/summary 轻量加成
    if cand.get("signature"):
        score += 0.5
    if cand.get("summary"):
        score += 0.5
    return score


def _dedup_candidates(cands: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen = set()
    out = []
    for c in cands:
        k = (c.get("dll"), c.get("file"), c.get("name"))
        if k in seen:
            continue
        seen.add(k)
        out.append(c)
    return out

# Ensure we can import `llm_integration.*` when this script is executed directly.
# In the repo layout, `llm_integration/` lives next to `scripts/` (under oda_demo/).
_ODA_DEMO_ROOT = Path(__file__).resolve().parents[1]
if str(_ODA_DEMO_ROOT) not in sys.path:
    sys.path.insert(0, str(_ODA_DEMO_ROOT))



def _write_text(path: Path, s: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(s, encoding="utf-8")


def _write_json(path: Path, data: Dict[str, Any]) -> None:
    _write_text(path, json.dumps(data, indent=2, ensure_ascii=False))


def _validate_spec(spec: Dict[str, Any], deps: List[Dict[str, Any]], preds: List[Dict[str, Any]], stub_code: str) -> Dict[str, Any]:
    dep_names = {str(d.get("name")) for d in deps if d.get("name")}
    spec_deps = {str(d.get("name")) for d in spec.get("dependencies", []) if d.get("name")}
    pred_deps = {str(p.get("depends_on")) for p in preds if p.get("depends_on")}

    missing_deps = sorted(dep_names - spec_deps)
    missing_pred_deps = sorted(pred_deps - spec_deps)

    return {
        "dependency_count": len(dep_names),
        "spec_dependency_count": len(spec_deps),
        "missing_dependencies": missing_deps,
        "predicate_dependency_count": len(pred_deps),
        "missing_predicate_dependencies": missing_pred_deps,
        "stub_contains_target": "" if not spec.get("target_function") else (spec["target_function"] in stub_code),
        "ok": not missing_deps,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True, help="RAG index json (rag/index.json)")
    ap.add_argument("--wine-root", required=True, help="Wine repo root (must contain dlls/)")
    ap.add_argument("--dll", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--func", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--allow-fallback", action="store_true", help="If LLM fails, write fallback spec instead of failing")
    ap.add_argument("--prompt-extra-file", help="Append extra text to LLM prompt from file")
    ap.add_argument("--prompt-extra-text", help="Append extra text to LLM prompt (inline)")

    args = ap.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    error_path = outdir / "llm_error.txt"
    if error_path.exists():
        try:
            error_path.unlink()
        except Exception:
            pass

    def write_error(stage: str, exc: BaseException) -> None:
        msg = f"[{stage}] {type(exc).__name__}: {exc}\n\n{traceback.format_exc()}"
        _write_text(error_path, msg)

    try:
        from llm_integration.dependency_analyzer import DependencyAnalyzer
        from llm_integration.oda_generator import ODAGenerator
        from llm_integration.oda_fallback import generate_fallback_spec
        from llm_integration.llm_client import OpenAICompatLLM, load_llm_config_from_env
    except Exception as e:
        write_error("import_failed", e)
        return 2

    target_dll = args.dll
    target_file = args.file
    resolve_debug: Dict[str, Any] = {
        "requested": {"dll": args.dll, "file": args.file, "func": args.func},
        "resolved": None,
        "resolution": "as_requested",
        "candidates": [],
    }
    try:
        analyzer = DependencyAnalyzer(args.index, args.wine_root)
        deps = analyzer.analyze(target_dll, target_file, args.func)
        preds = analyzer.analyze_predicates(target_dll, target_file, args.func)
    except ValueError:
        # 兜底：在索引里全局搜索函数，修正 dll/file 后再分析
        try:
            from rag.query import HierarchicalQuery

            hq = HierarchicalQuery(args.index, args.wine_root)
            matches = hq.search_functions(args.func, max_results=5)
            resolve_debug["candidates"] = matches
            if matches:
                target_dll = matches[0]["dll"]
                target_file = matches[0]["file"]
                resolve_debug["resolved"] = {"dll": target_dll, "file": target_file, "func": args.func}
                resolve_debug["resolution"] = "index_search_functions_fallback"
                deps = analyzer.analyze(target_dll, target_file, args.func)
                preds = analyzer.analyze_predicates(target_dll, target_file, args.func)
            else:
                raise
        except Exception as e:
            write_error("dependency_analysis_failed", e)
            return 3
    except Exception as e:
        write_error("dependency_analysis_failed", e)
        return 3

    retrieval_report: Dict[str, Any] = {
        "target_function": args.func,
        "target_dll": target_dll,
        "target_file": target_file,
        "requested_dll": args.dll,
        "requested_file": args.file,
        "resolution": resolve_debug,
        "resolved_source_path": str((Path(args.wine_root) / "dlls" / target_dll / target_file).resolve()),
        "resolved_source_path_hint": f"dlls/{target_dll}/{target_file}",
        "dependency_count": len(deps),
        "predicate_count": len(preds),
        "dependency_names": [d.get("name") for d in deps if d.get("name")],
        "predicate_depends_on": [p.get("depends_on") for p in preds if p.get("depends_on")],
    }
    # 先落一版基础报告，便于即使后续步骤失败也能看到 resolved target。
    _write_json(outdir / "retrieval_report.json", retrieval_report)

    pred_depends = [p.get("depends_on") for p in preds if p.get("depends_on")]
    predicate_ir: Dict[str, Any] = {
        "schema": "oda.predicate_ir.v2",
        "target": {
            "function": args.func,
            "dll": target_dll,
            "file": target_file,
            "requested": {"dll": args.dll, "file": args.file},
        },
        "summary": {
            "predicate_count": len(preds),
            "dependency_count": len(deps),
            "depends_on": sorted(set(pred_depends)),
        },
        "items": preds,
        "dependencies": [d.get("name") for d in deps if d.get("name")],
    }
    _write_json(outdir / "predicate_ir.json", predicate_ir)

    prompt = ODAGenerator(None)._build_prompt(args.func, deps, preds)  # 仅构造 prompt，不需要 LLM

    prompt_extra_parts: List[str] = []
    if args.prompt_extra_file:
        try:
            prompt_extra_parts.append(Path(args.prompt_extra_file).read_text(encoding="utf-8"))
        except Exception as e:
            write_error("prompt_extra_file_read_failed", e)
    if args.prompt_extra_text:
        prompt_extra_parts.append(args.prompt_extra_text)

    if prompt_extra_parts:
        extra_block = "\n".join([p.strip() for p in prompt_extra_parts if p.strip()])
        if extra_block:
            prompt = f"{prompt}\n\n# Iteration Feedback\n{extra_block}\n"

    # --- RAG 增强：多路召回 + 证据片段 ---
    # 目标：即便 deps/preds 为空或偏弱，也能给 LLM 足够的“源码证据”，减少漏依赖。
    source_snippet_used = False
    snippet_blocks: List[str] = []
    candidate_debug: List[Dict[str, Any]] = []
    try:
        from rag.query import HierarchicalQuery

        hq = HierarchicalQuery(args.index, args.wine_root)

        # 1) 候选召回：精确命中 + 模糊命中（token）
        cands: List[Dict[str, Any]] = []
        cands.extend(hq.search_functions_exact(args.func, max_results=10))
        for t in _tokenize_symbol(args.func):
            if len(t) < 3:
                continue
            cands.extend(hq.search_functions(t, max_results=10))

        cands = _dedup_candidates(cands)
        # 2) 打分重排
        scored: List[Dict[str, Any]] = []
        for c in cands:
            s = _score_candidate(args.func, c, requested_dll=args.dll, requested_file=args.file)
            cc = dict(c)
            cc["score"] = s
            scored.append(cc)
        scored.sort(key=lambda x: float(x.get("score", 0.0)), reverse=True)

        # 3) 选择 Top-K 候选，抽取源码/调用点证据
        topk = scored[:3]
        for c in topk:
            dll = c.get("dll")
            file = c.get("file")
            name = c.get("name")
            if not dll or not file or not name:
                continue

            code = hq.get_function_code(dll, file, name)
            if not code:
                # fallback：DependencyAnalyzer 里的函数体抽取已经更稳，这里不重复造轮子，
                # 直接交给 analyzer 的私有能力会比较脏；因此这里用“尽量短”的文件切片。
                src_path = Path(args.wine_root) / "dlls" / str(dll) / str(file)
                if src_path.exists():
                    lines = src_path.read_text(encoding="utf-8", errors="ignore").splitlines()
                    start = None
                    for idx, line in enumerate(lines):
                        if str(name) in line:
                            start = idx
                            break
                    if start is not None:
                        end = min(start + 180, len(lines) - 1)
                        code = "\n".join(lines[start:end + 1])

            callsites = hq.grep_symbol_in_file(dll, file, name, max_hits=20)
            candidate_debug.append({
                "dll": dll,
                "file": file,
                "name": name,
                "score": c.get("score"),
                "signature": c.get("signature"),
                "summary": c.get("summary"),
                "callsites": callsites[:5],
                "code_included": bool(code),
            })

            if code:
                source_snippet_used = True
                snippet_blocks.append(
                    f"[RAGSnippet score={c.get('score')}] {dll}/{file}::{name}\n"
                    f"```c\n{code}\n```\n"
                )

        if snippet_blocks:
            prompt += (
                "\n\n[RAGEvidence]\n"
                "下面是从索引/源码召回的候选片段（可能包含目标函数或其邻近实现）。"
                "请用它们来补齐依赖与谓词，避免漏 stub：\n\n" + "\n".join(snippet_blocks)
            )

        retrieval_report.update({
            "rag_candidates": candidate_debug,
            "rag_candidate_count": len(scored),
            "rag_topk": [
            {"dll": c.get("dll"), "file": c.get("file"), "name": c.get("name"), "score": c.get("score")}
            for c in scored[:3]
            ],
            "source_snippet_used": bool(source_snippet_used),
        })

        # 覆盖写入增强后的报告
        _write_json(outdir / "retrieval_report.json", retrieval_report)
    except Exception as e:
        write_error("rag_enhance_failed", e)
    _write_text(outdir / "llm_prompt.txt", prompt)

    # Always snapshot environment proxies early for observability.
    # 注意：这里要“无条件写文件”（即使值为空），否则 Windows 侧会误以为脚本没跑到这里。
    try:
        keys = [
            "HTTP_PROXY",
            "HTTPS_PROXY",
            "ALL_PROXY",
            "NO_PROXY",
            "http_proxy",
            "https_proxy",
            "all_proxy",
            "no_proxy",
        ]
        env_proxy = {k: (os.environ.get(k) or "") for k in keys}
        _write_json(outdir / "env_proxy.json", env_proxy)
    except Exception as e:
        write_error("env_proxy_dump_failed", e)

    # 真 LLM
    try:
        cfg = load_llm_config_from_env()
        llm = OpenAICompatLLM(cfg)
        gen = ODAGenerator(llm)
    except Exception as e:
        write_error("llm_config_failed", e)
        if not args.allow_fallback:
            return 4
        spec = generate_fallback_spec(args.func, deps, preds, description=f"Fallback spec for {args.func} (LLM config failed)")
        _write_text(outdir / "llm_response.txt", "<fallback used: llm config failed>\n")
        spec_path = outdir / "llm_spec.json"
        spec_path.write_text(json.dumps(spec, indent=2, ensure_ascii=False), encoding="utf-8")
        # spec -> oda_stubs.c
        specs_dir = (Path(__file__).resolve().parents[1] / "specs").resolve()
        if str(specs_dir) not in os.sys.path:
            os.sys.path.insert(0, str(specs_dir))
        from gen_oda_stub import ODAStubGenerator  # type: ignore
        stub_code = ODAStubGenerator(str(spec_path)).generate()
        _write_text(outdir / "oda_stubs.c", stub_code)
        print(f"[generate_oda_with_llm] wrote fallback spec: {spec_path}")
        return 0

    try:
        # 这里不直接调用 gen.generate()，因为我们要把 raw response 落盘
        print(f"[generate_oda_with_llm] LLM is running for {args.func} ...")
        response = llm.generate(prompt, diag_path=outdir / "llm_diag.json", request_tag=args.func)
        _write_text(outdir / "llm_response.txt", response)

        cleaned = response.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        def _sanitize_json(raw: str) -> str:
            # 修复未转义的反斜杠（常见于 Windows 路径）
            fixed = re.sub(r"\\(?![\\\"/bfnrtu])", r"\\\\", raw)
            # 去掉未转义控制字符（含换行/回车）
            return re.sub(r"[\x00-\x1f]", "", fixed)

        try:
            spec: Dict[str, Any] = json.loads(cleaned)
        except json.JSONDecodeError:
            spec = json.loads(_sanitize_json(cleaned))

        # 兼容 LLM 输出字段：function -> name
        if isinstance(spec, dict) and isinstance(spec.get("dependencies"), list):
            for dep in spec["dependencies"]:
                if isinstance(dep, dict) and "function" in dep and "name" not in dep:
                    dep["name"] = dep.get("function")
    except Exception as e:
        write_error("llm_generate_failed", e)
        if not args.allow_fallback:
            return 5
        spec = generate_fallback_spec(args.func, deps, preds, description=f"Fallback spec for {args.func} (LLM failed)")
        _write_text(outdir / "llm_response.txt", "<fallback used>\n")
    else:
        if error_path.exists():
            try:
                error_path.unlink()
            except Exception:
                pass

    # 必须覆盖所有依赖：若缺失则报错（不自动补全）
    dep_lookup = {d.get("name"): d for d in deps if d.get("name")}
    seen = {d.get("name") for d in (spec.get("dependencies", []) or []) if d.get("name")}
    missing = sorted([name for name in dep_lookup.keys() if name and name not in seen])
    if missing:
        raise RuntimeError(f"LLM spec missing dependencies: {missing}")

    spec_path = outdir / "llm_spec.json"
    spec_path.write_text(json.dumps(spec, indent=2, ensure_ascii=False), encoding="utf-8")

    # spec -> oda_stubs.c
    deps_list = spec.get("dependencies") if isinstance(spec, dict) else None
    if isinstance(deps_list, list) and deps_list and isinstance(deps_list[0], dict) and "stub_code" in deps_list[0]:
        parts = ["#include <klee/klee.h>", "#include <stddef.h>", ""]
        for dep in deps_list:
            fn = dep.get("name") or dep.get("function") or "unknown"
            strat = dep.get("strategy") or dep.get("abstraction", {}).get("type")
            parts.append(f"/* Stub for {fn} */")
            if strat:
                parts.append(f"/* Abstraction strategy: {strat} */")
            parts.append(dep.get("stub_code", ""))
            parts.append("")
        stub_code = "\n".join(parts)
        _write_text(outdir / "oda_stubs.c", stub_code)
        validation = _validate_spec(spec, deps, preds, stub_code)
        _write_json(outdir / "stub_validation_report.json", validation)
    else:
        specs_dir = (Path(__file__).resolve().parents[1] / "specs").resolve()
        if str(specs_dir) not in os.sys.path:
            os.sys.path.insert(0, str(specs_dir))
        from gen_oda_stub import ODAStubGenerator  # type: ignore

        stub_code = ODAStubGenerator(str(spec_path)).generate()
        _write_text(outdir / "oda_stubs.c", stub_code)
        validation = _validate_spec(spec, deps, preds, stub_code)
        _write_json(outdir / "stub_validation_report.json", validation)

    # 顺带打印一点点摘要，给 pipeline 日志用
    print(f"[generate_oda_with_llm] deps={len(deps)} preds={len(preds)}")
    print(f"[generate_oda_with_llm] wrote: {spec_path}")
    print(f"[generate_oda_with_llm] wrote: {outdir / 'oda_stubs.c'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
