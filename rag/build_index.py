#!/usr/bin/env python3
"""
构建 Wine 源码的分层索引

用法:
    python build_index.py /path/to/wine/dlls -o index.json
"""

import os
import json
import re
import argparse
import hashlib
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

class WineIndexBuilder:
    """Wine 源码索引构建器（分层 RAG v2）"""

    def __init__(
        self,
        dlls_root: str,
        summary_mode: str = "static",
        llm_limit: Optional[int] = None,
        prev_index: Optional[Path] = None,
    ):
        self.dlls_root = Path(dlls_root)
        self.summary_mode = summary_mode
        self.llm_limit = llm_limit
        self._llm_used = 0
        self._llm_total_candidates = 0
        self._llm_progress_step = 20
        self._func_progress_step = 50
        self._func_seen = 0
        self._tmp_path: Optional[Path] = None
        self._prev_summary_map: Dict[str, str] = {}
        if prev_index and prev_index.exists():
            try:
                with open(prev_index, "r", encoding="utf-8") as f:
                    prev = json.load(f)
                self._prev_summary_map = self._flatten_llm_summaries(prev)
            except Exception as e:
                print(f"[WARN] failed to load prev index: {e}")

        self.index = {
            "schema_version": 2,
            "summary_mode": summary_mode,
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "dlls": {},
        }
        self._llm = None
    
    def build(self) -> Dict:
        """构建完整索引"""
        print(f"扫描目录: {self.dlls_root}")
        if self.summary_mode in {"llm", "hybrid"}:
            print(f"[summary] mode={self.summary_mode} llm_limit={self.llm_limit}")

        if self._tmp_path:
            self._write_tmp()
        
        # 遍历所有 DLL 目录
        for dll_dir in sorted(self.dlls_root.iterdir()):
            if not dll_dir.is_dir():
                continue
            
            dll_name = dll_dir.name
            print(f"  处理 DLL: {dll_name}")
            
            dll_info = self._index_dll(dll_dir)
            if dll_info["files"]:  # 只保留有代码的 DLL
                self.index["dlls"][dll_name] = dll_info

            if self._tmp_path:
                self._write_tmp()

        print(f"\n索引完成: {len(self.index['dlls'])} 个 DLL")
        return self.index

    def _write_tmp(self) -> None:
        if not self._tmp_path:
            return
        try:
            self._tmp_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self._tmp_path, 'w', encoding='utf-8') as f:
                json.dump(self.index, f, indent=2, ensure_ascii=False)
            print(f"[tmp] wrote {self._tmp_path}")
        except Exception as e:
            print(f"[WARN] tmp write failed: {e}")
    
    def _index_dll(self, dll_dir: Path) -> Dict:
        """索引单个 DLL"""
        dll_info = {
            "description": self._extract_dll_description(dll_dir),
            "files": {}
        }
        
        # 遍历所有 .c 文件（不包括 tests 目录）
        for c_file in dll_dir.rglob("*.c"):
            if "tests" in c_file.parts:
                continue
            
            rel_path = c_file.relative_to(dll_dir)
            file_info = self._index_file(c_file, dll_dir.name, str(rel_path))
            
            if file_info["functions"]:  # 只保留有函数的文件
                dll_info["files"][str(rel_path)] = file_info
        
        return dll_info
    
    def _index_file(self, file_path: Path, dll_name: str, rel_path: str) -> Dict:
        """索引单个 C 文件"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception as e:
            print(f"    警告: 无法读取 {file_path}: {e}")
            return {"description": "", "functions": {}}
        
        file_info = {
            "description": self._extract_file_description(content),
            "functions": []
        }
        
        print(f"    [file] {dll_name}/{rel_path}")
        # 提取所有函数
        functions = self._extract_functions(content)
        for func in functions:
            self._func_seen += 1
            if self._func_seen % self._func_progress_step == 0:
                print(f"[progress] functions_seen={self._func_seen}")
            func["_dll_name"] = dll_name
            func["_file_name"] = rel_path
            func = self._maybe_attach_llm_summary(func)
            func.pop("_dll_name", None)
            func.pop("_file_name", None)
            file_info["functions"].append(func)
        
        return file_info
    
    def _extract_dll_description(self, dll_dir: Path) -> str:
        """从 README 或注释中提取 DLL 描述"""
        # 尝试读取 README
        readme = dll_dir / "README"
        if readme.exists():
            try:
                with open(readme, 'r', encoding='utf-8', errors='ignore') as f:
                    return f.readline().strip()
            except:
                pass
        
        # 尝试从第一个 .c 文件的头部注释提取
        for c_file in dll_dir.glob("*.c"):
            try:
                with open(c_file, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()[:20]  # 只看前 20 行
                    for line in lines:
                        if "/*" in line or "*" in line:
                            desc = line.strip().strip("/*").strip("*").strip()
                            if len(desc) > 10:
                                return desc
            except:
                pass
        
        return ""
    
    def _extract_file_description(self, content: str) -> str:
        """从文件头部注释提取描述"""
        lines = content.split('\n')[:30]  # 只看前 30 行
        
        for i, line in enumerate(lines):
            if "/*" in line or "*" in line:
                desc = line.strip().strip("/*").strip("*").strip()
                if len(desc) > 10 and not desc.startswith("Copyright"):
                    return desc
        
        return ""
    
    def _extract_functions(self, content: str) -> List[Dict]:
        """提取文件中的所有函数（增强版，支持多行签名，尽量避免误判原型/typedef/宏）。"""

        lines = content.split('\n')
        functions: List[Dict] = []

        i = 0
        n = len(lines)
        while i < n:
            # 快速跳过空行和预处理行
            line = lines[i]
            s = line.strip()
            if not s or s.startswith('#'):
                i += 1
                continue

            # 聚合可能的“函数头”多行文本，直到遇到 { 或 ; 或 行数上限。
            # 目标：捕捉如下情况：
            #   BOOL WINAPI PathIsRelativeW(
            #       const WCHAR *path)
            #   {
            header_start = i
            header_lines = []
            header_text = ""
            saw_paren = False
            max_header_lines = 12

            j = i
            while j < n and (j - header_start) < max_header_lines:
                raw = lines[j]
                stripped = raw.strip()
                if not stripped:
                    j += 1
                    continue
                if stripped.startswith('#'):
                    break
                header_lines.append(raw)
                header_text += raw + "\n"
                if '(' in raw:
                    saw_paren = True
                # 终止条件：遇到 { 或 ;
                if '{' in raw or ';' in raw:
                    break
                j += 1

            if not saw_paren:
                i += 1
                continue

            # 必须是“定义”而不是“声明/typedef”：需要在 header 末端附近找到 '{'（允许下一行是 '{'）。
            def_line = j
            has_open_brace = '{' in lines[def_line] if def_line < n else False
            if not has_open_brace and (def_line + 1) < n and lines[def_line].strip().endswith(')'):
                # 处理这类：")" + 下一行 "{"。
                if lines[def_line + 1].strip().startswith('{'):
                    def_line += 1
                    has_open_brace = True

            # 排除 typedef / struct / enum / union / static inline 原型等（无函数体）。
            if not has_open_brace:
                i += 1
                continue
            if any(k in header_text for k in ("typedef ", "struct ", "enum ", "union ")):
                i += 1
                continue

            # 解析函数名/签名：
            # 用一个“松但可控”的正则：
            #   [return-and-modifiers] name ( params )
            # 允许: static/inline/const/extern/WINAPI/CDECL/NTAPI 等。
            header_flat = " ".join(l.strip() for l in header_lines)
            header_flat = re.sub(r'\s+', ' ', header_flat).strip()
            # 去掉 '{' 之后的部分
            header_flat = header_flat.split('{', 1)[0].strip()

            # 排除宏形如：#define FOO(x) ...（上面已跳过 #）
            if header_flat.startswith("#"):
                i += 1
                continue

            m = re.search(
                r'^(?P<ret>.+?)\s+(?P<name>[A-Za-z_]\w*)\s*\((?P<params>.*)\)\s*$',
                header_flat,
            )
            if not m:
                i += 1
                continue

            func_name = m.group('name')
            if func_name in {'if', 'while', 'for', 'switch', 'return', 'sizeof'}:
                i += 1
                continue

            ret_part = m.group('ret').strip()
            params_part = m.group('params').strip()

            # 找到函数体结束位置（更稳：忽略字符串/注释中的括号）
            func_end = self._find_function_end_robust(lines, def_line)
            func_body = '\n'.join(lines[header_start:func_end + 1])

            dependencies = self._extract_dependencies(func_body)
            comment = self._extract_comment(lines, header_start)
            fallback_summary = self._fallback_summary(func_name, f"{ret_part} {func_name}({params_part})")
            snippet_lines = lines[header_start: min(func_end + 1, header_start + 120)]
            code_snippet = "\n".join(snippet_lines)[:4000]

            # 用 body + signature 做 hash，便于发现索引漂移/缓存摘要
            code_hash = hashlib.sha256(func_body.encode('utf-8', errors='ignore')).hexdigest()[:16]

            functions.append({
                "name": func_name,
                "signature": f"{ret_part} {func_name}({params_part})",
                "summary": comment or fallback_summary,
                "line_start": header_start + 1,
                "line_end": func_end + 1,
                "signature_line_start": header_start + 1,
                "signature_line_end": def_line + 1,
                "code_hash": code_hash,
                "dependencies": dependencies,
                "complexity": self._estimate_complexity(func_body),
                "static_summary": comment or None,
                "llm_summary": None,
                "code_snippet": code_snippet,
            })

            # 跳过整个函数体，避免重复匹配内层语句
            i = func_end + 1
            continue

        return functions

    def _fallback_summary(self, func_name: str, signature: str) -> str:
        """统一的兜底摘要：不做特殊函数处理。"""
        return f"Function {func_name} described by signature: {signature}."
    
    def _find_function_end_robust(self, lines: List[str], start_line: int) -> int:
        """找到函数结束位置（增强版）：匹配大括号，尽量忽略注释与字符串。"""
        brace_count = 0
        in_function = False
        in_block_comment = False
        in_string = False
        in_char = False
        escape = False

        for i in range(start_line, len(lines)):
            line = lines[i]
            k = 0
            while k < len(line):
                ch = line[k]
                nxt = line[k + 1] if (k + 1) < len(line) else ''

                if in_block_comment:
                    if ch == '*' and nxt == '/':
                        in_block_comment = False
                        k += 2
                        continue
                    k += 1
                    continue

                if in_string:
                    if escape:
                        escape = False
                    elif ch == '\\':
                        escape = True
                    elif ch == '"':
                        in_string = False
                    k += 1
                    continue

                if in_char:
                    if escape:
                        escape = False
                    elif ch == '\\':
                        escape = True
                    elif ch == "'":
                        in_char = False
                    k += 1
                    continue

                # line comment
                if ch == '/' and nxt == '/':
                    break
                # block comment start
                if ch == '/' and nxt == '*':
                    in_block_comment = True
                    k += 2
                    continue
                if ch == '"':
                    in_string = True
                    k += 1
                    continue
                if ch == "'":
                    in_char = True
                    k += 1
                    continue

                if ch == '{':
                    in_function = True
                    brace_count += 1
                elif ch == '}':
                    brace_count -= 1

                k += 1

            if in_function and brace_count == 0:
                return i

        # fallback
        return min(start_line + 200, len(lines) - 1)
    
    def _extract_comment(self, lines: List[str], func_line: int) -> str:
        """提取函数前的注释"""
        comment_lines = []
        
        # 向上查找注释（最多 10 行）
        for i in range(max(0, func_line - 10), func_line):
            line = lines[i].strip()
            
            if line.startswith('/*') or line.startswith('*') or line.startswith('//'):
                comment_lines.append(line.strip('/*').strip('*').strip('/').strip())
            elif comment_lines:  # 遇到非注释行且已有注释，停止
                break
        
        return ' '.join(comment_lines) if comment_lines else ""
    
    def _extract_dependencies(self, func_body: str) -> List[str]:
        """提取函数调用的外部函数"""
        # 先移除注释与字符串，降低误报（例如 TRACE("foo(")）
        code = self._strip_comments_and_strings(func_body)

        # 匹配函数调用模式: name(
        pattern = r'\b([A-Za-z_]\w*)\s*\('
        matches = re.findall(pattern, code)

        # 过滤关键字、常见宏、类型名等等（宁可少报，后续依赖分析器还能补）
        blacklist = {
            # C keywords
            'if', 'while', 'for', 'switch', 'case', 'return', 'sizeof',
            'do', 'goto', 'break', 'continue',
            # common macros / tracing
            'TRACE', 'WARN', 'FIXME', 'ERR', 'MESSAGE', 'assert',
            # allocation / libc (usually no stub needed)
            'malloc', 'free', 'calloc', 'realloc', 'memcpy', 'memset', 'memcmp',
        }
        deps = [m for m in set(matches) if m not in blacklist]
        return sorted(deps)[:30]

    def _strip_comments_and_strings(self, code: str) -> str:
        """移除 C/C++ 风格注释与字符串常量（用于依赖提取降噪）。"""
        out = []
        i = 0
        n = len(code)
        in_block = False
        in_line = False
        in_str = False
        in_chr = False
        escape = False
        while i < n:
            ch = code[i]
            nxt = code[i + 1] if i + 1 < n else ''

            if in_line:
                if ch == '\n':
                    in_line = False
                    out.append(ch)
                i += 1
                continue
            if in_block:
                if ch == '*' and nxt == '/':
                    in_block = False
                    i += 2
                    continue
                i += 1
                continue
            if in_str:
                if escape:
                    escape = False
                elif ch == '\\':
                    escape = True
                elif ch == '"':
                    in_str = False
                i += 1
                continue
            if in_chr:
                if escape:
                    escape = False
                elif ch == '\\':
                    escape = True
                elif ch == "'":
                    in_chr = False
                i += 1
                continue

            if ch == '/' and nxt == '/':
                in_line = True
                i += 2
                continue
            if ch == '/' and nxt == '*':
                in_block = True
                i += 2
                continue
            if ch == '"':
                in_str = True
                i += 1
                continue
            if ch == "'":
                in_chr = True
                i += 1
                continue

            out.append(ch)
            i += 1

        return ''.join(out)
    
    def _estimate_complexity(self, func_body: str) -> str:
        """估算函数复杂度"""
        lines = len(func_body.split('\n'))
        
        if lines < 20:
            return "low"
        elif lines < 50:
            return "medium"
        else:
            return "high"

    def _flatten_llm_summaries(self, idx: Dict) -> Dict[str, str]:
        summaries: Dict[str, str] = {}
        for dll_name, dll in idx.get("dlls", {}).items():
            for file_name, file_info in dll.get("files", {}).items():
                funcs = file_info.get("functions", [])
                if isinstance(funcs, dict):
                    func_iter = funcs.values()
                else:
                    func_iter = funcs
                for func in func_iter:
                    if not isinstance(func, dict):
                        continue
                    key = f"{dll_name}/{file_name}:{func.get('name')}/{func.get('code_hash') or ''}"
                    summary = func.get("llm_summary") or func.get("summary")
                    if summary:
                        summaries[key] = summary
        return summaries

    def _maybe_attach_llm_summary(self, func: Dict) -> Dict:
        if self.summary_mode == "static":
            return func

        key = f"{func.get('name')}/{func.get('code_hash') or ''}"
        dll_name = func.get("_dll_name")
        file_name = func.get("_file_name")
        if dll_name and file_name:
            key = f"{dll_name}/{file_name}:{func.get('name')}/{func.get('code_hash') or ''}"

        if key in self._prev_summary_map:
            func["llm_summary"] = self._prev_summary_map[key]
            func["summary"] = func["llm_summary"]
            return func

        if self.summary_mode in {"llm", "hybrid"}:
            if self.summary_mode == "hybrid" and func.get("static_summary"):
                func["summary"] = func.get("static_summary")
                return func

            self._llm_total_candidates += 1
            if self._llm_total_candidates % self._llm_progress_step == 0:
                print(
                    f"[summary] progress: seen={self._llm_total_candidates} llm_used={self._llm_used}"
                )

            if self.llm_limit is not None and self._llm_used >= self.llm_limit:
                return func

            try:
                llm = self._get_llm()
                prompt = (
                    "请根据以下 C 函数签名、注释与代码片段生成简洁摘要（40字以内）。\n"
                    "只描述功能、输入/输出，不展开实现细节。\n\n"
                    f"函数名: {func.get('name')}\n"
                    f"签名: {func.get('signature')}\n"
                    f"注释: {func.get('static_summary') or ''}\n"
                    f"代码片段: \n{func.get('code_snippet') or ''}\n"
                )
                resp = llm.generate(prompt)
                summary = resp.strip()
                func["llm_summary"] = summary
                func["summary"] = summary
                self._llm_used += 1
                if self._llm_used % self._llm_progress_step == 0:
                    print(f"[summary] llm_used={self._llm_used}")
            except Exception as e:
                print(f"[WARN] llm summary failed for {func.get('name')}: {e}")
        return func

    def _get_llm(self):
        if self._llm is not None:
            return self._llm
        # 延迟导入，避免构建索引时强制依赖 LLM
        root = Path(__file__).resolve().parents[1]
        if str(root) not in sys.path:
            sys.path.insert(0, str(root))
        from llm_integration.llm_client import OpenAICompatLLM, load_llm_config_from_env
        cfg = load_llm_config_from_env()
        self._llm = OpenAICompatLLM(cfg)
        return self._llm
    
    def save(self, output_path: str):
        """保存索引到文件"""
        output = Path(output_path)
        tmp_path = output.with_suffix(output.suffix + ".tmp")
        output.parent.mkdir(parents=True, exist_ok=True)
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, indent=2, ensure_ascii=False)
        with open(tmp_path, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, indent=2, ensure_ascii=False)
        print(f"索引已保存到: {output}")
        print(f"索引临时文件保留: {tmp_path}")
        if self.summary_mode in {"llm", "hybrid"}:
            print(
                f"[summary] total_candidates={self._llm_total_candidates} llm_used={self._llm_used}"
            )


def main():
    parser = argparse.ArgumentParser(description="构建 Wine 源码索引")
    parser.add_argument("dlls_root", help="Wine dlls 目录路径")
    parser.add_argument("-o", "--output", default="index.json", help="输出文件路径")
    parser.add_argument(
        "--summary-mode",
        choices=["static", "llm", "hybrid"],
        default="static",
        help="摘要生成模式：static(仅注释) | llm(全量LLM) | hybrid(有注释用注释，无注释用LLM)",
    )
    parser.add_argument(
        "--llm-limit",
        type=int,
        default=None,
        help="限制 LLM 摘要调用次数（避免全量成本过高）",
    )
    parser.add_argument(
        "--prev-index",
        default=None,
        help="上一版索引，用于复用已有 llm_summary",
    )
    
    args = parser.parse_args()
    
    prev_index = Path(args.prev_index) if args.prev_index else None
    builder = WineIndexBuilder(
        args.dlls_root,
        summary_mode=args.summary_mode,
        llm_limit=args.llm_limit,
        prev_index=prev_index,
    )
    builder._tmp_path = Path(args.output).with_suffix(Path(args.output).suffix + ".tmp")
    builder.build()
    builder.save(args.output)


if __name__ == "__main__":
    main()
