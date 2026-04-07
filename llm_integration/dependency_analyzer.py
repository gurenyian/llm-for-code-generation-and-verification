#!/usr/bin/env python3
"""
依赖分析器：自动找到函数的外部依赖

用法:
    from dependency_analyzer import DependencyAnalyzer
    
    analyzer = DependencyAnalyzer("../rag/index.json", "../wine")
    deps = analyzer.analyze("shlwapi", "path.c", "PathCombineW")
"""

import re
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from rag.query import HierarchicalQuery
from typing import List, Dict, Set, Optional, Tuple


class DependencyAnalyzer:
    """依赖分析器"""
    
    def __init__(self, index_path: str, wine_root: str):
        self.hq = HierarchicalQuery(index_path, wine_root)
        
        # 标准库函数和关键字（不需要 stub）
        self.blacklist = {
            # C 关键字
            'if', 'else', 'while', 'for', 'switch', 'case', 'return',
            'break', 'continue', 'goto', 'sizeof', 'typeof',
            
            # 标准库函数
            'malloc', 'free', 'calloc', 'realloc',
            'memcpy', 'memset', 'memmove', 'memcmp',
            'strcpy', 'strcat', 'strcmp', 'strlen',
            'printf', 'sprintf', 'fprintf', 'snprintf',
            
            # KLEE 函数
            'klee_make_symbolic', 'klee_assume', 'klee_assert',

            # Wine/WIN32 常见调试宏与辅助（不应 stub）
            'TRACE', 'WARN', 'FIXME', 'ERR', 'MESSAGE', 'debugstr_w', 'debugstr_a',
            'wine_dbgstr_w', 'wine_dbgstr_a', 'wine_dbgstr_guid',
        }
    
    def analyze(self, dll_name: str, file_name: str, func_name: str) -> List[Dict]:
        """
        分析函数的依赖
        
        Returns:
            [
                {
                    "name": "lstrlenW",
                    "signature": "int lstrlenW(LPCWSTR str)",
                    "summary": "Returns the length of a string",
                    "dll": "kernel32",
                    "file": "string.c",
                    "call_count": 2  # 在目标函数中被调用的次数
                },
                ...
            ]
        """
        print(f"分析 {dll_name}/{file_name}/{func_name} 的依赖...")
        
        # 1. 从索引中快速获取依赖列表
        func_info = self.hq.get_function_info(dll_name, file_name, func_name)
        indexed_deps = set(func_info.get("dependencies", []))
        if func_name in indexed_deps:
            indexed_deps.discard(func_name)
        
        # 2. 读取源码，进行更精确的分析
        code = self.hq.get_function_code(dll_name, file_name, func_name)
        if not code:
            code = self._extract_function_body_from_file(dll_name, file_name, func_name)
        lines = code.splitlines()
        code_deps = self._extract_calls_from_code(code)
        if func_name in code_deps:
            code_deps.discard(func_name)
        
        # 3. 合并两种方法的结果
        all_deps = indexed_deps | code_deps
        
        # 4. 过滤掉黑名单中的函数
        all_deps = all_deps - self.blacklist
        
        # 5. 预提取条件语句（用于数据流启发式）
        cond_lines: List[Tuple[int, str]] = []
        for idx, raw in enumerate(lines, start=1):
            kind, cond = self._extract_condition(raw.strip())
            if cond and kind in ("if", "while"):
                cond_lines.append((idx, cond))

        # 6. 为每个依赖函数获取详细信息
        dependencies = []
        for dep_name in sorted(all_deps):
            dep_info = self._get_dependency_info(dep_name, code, cond_lines=cond_lines)
            if dep_info:
                dependencies.append(dep_info)
        
        print(f"  找到 {len(dependencies)} 个依赖函数")
        return dependencies
    
    def _extract_calls_from_code(self, code: str) -> Set[str]:
        """从代码中提取函数调用"""
        # 正则匹配函数调用：function_name(
        pattern = r'\b([a-zA-Z_]\w+)\s*\('
        calls = re.findall(pattern, code)
        return set(calls)
    
    def _get_dependency_info(
        self,
        dep_name: str,
        target_code: str,
        *,
        cond_lines: Optional[List[Tuple[int, str]]] = None,
    ) -> Dict:
        """获取依赖函数的详细信息"""
        # 1. 在索引中搜索
        results = self.hq.search_functions(dep_name, max_results=5)
        
        if not results:
            print(f"    警告: 未找到函数 {dep_name}")
            return None
        
        # 2. 选择最匹配的结果（通常是第一个）
        func = results[0]
        
        # 3. 统计调用次数
        call_count = target_code.count(dep_name + '(')

        signature_raw = str(func.get("signature", ""))
        dep_kind = self._classify_dependency(dep_name, signature_raw)
        signature = self._sanitize_signature(signature_raw, dep_name, dep_kind)
        mutability = self._signature_mutability(signature) if dep_kind == "function" else {
            "has_pointer": False,
            "has_mutable_pointer": False,
            "mutable_args": [],
        }
        data_flow_notes = self._infer_data_flow_notes(dep_name, target_code, cond_lines or [], mutability)
        
        return {
            "name": func["name"],
            "signature": signature,
            "signature_raw": signature_raw,
            "summary": func.get("summary", ""),
            "dll": func["dll"],
            "file": func["file"],
            "call_count": call_count,
            "kind": dep_kind,
            "mutability": mutability,
            "data_flow_notes": data_flow_notes,
        }

    def _classify_dependency(self, name: str, signature_raw: str) -> str:
        """粗略判断依赖是否为宏/内联 helper。"""
        sig = (signature_raw or "").strip()
        if name.isupper():
            return "macro"
        if sig.startswith("for ") or sig.startswith("for("):
            return "macro"
        if "ARRAY_SIZE" in name or "ARRAY_SIZE" in sig:
            return "macro"
        return "function"

    def _sanitize_signature(self, signature_raw: str, name: str, dep_kind: str) -> str:
        """清理签名文本，避免把注释/代码片段带入 prompt。"""
        sig = signature_raw or ""
        # 去掉块注释
        sig = re.sub(r"/\*.*?\*/", "", sig, flags=re.S)
        # 压缩空白
        sig = re.sub(r"\s+", " ", sig).strip()
        if dep_kind == "macro":
            return f"{name}(arr)" if name else sig
        # 尝试提取带函数名的原型
        if name:
            m = re.search(rf"[A-Za-z_][\w\s\*]*\b{re.escape(name)}\s*\([^)]*\)", sig)
            if m:
                return m.group(0).strip()
        # 兜底：保留括号部分
        if "(" in sig and ")" in sig:
            return sig
        # 常见函数签名推断（避免 ... 造成编译错误）
        lname = (name or "").lower()
        if "lstrlen" in lname:
            return f"int {name}(const WCHAR *str)"
        if "lstrcpyn" in lname:
            return f"LPWSTR {name}(LPWSTR dst, LPCWSTR src, INT n)"
        if "lstrcat" in lname:
            return f"LPWSTR {name}(LPWSTR dst, LPCWSTR src)"
        if "pathaddbackslashw" == lname:
            return f"LPWSTR {name}(WCHAR *path)"
        if "pathcanonicalizew" == lname:
            return f"BOOL {name}(WCHAR *buffer, const WCHAR *path)"
        if "pathstriptorootw" == lname:
            return f"BOOL {name}(WCHAR *path)"
        if "pathisrelativew" == lname or "pathisuncw" == lname:
            return f"BOOL {name}(const WCHAR *path)"
        return f"int {name}(void)" if name else sig

    def _signature_mutability(self, signature: str) -> Dict[str, object]:
        """基于签名做轻量可写指针判断（启发式）。"""
        sig = signature or ""
        args = sig[sig.find("(") + 1:sig.rfind(")")] if "(" in sig and ")" in sig else sig
        args = args.strip()
        if not args or args.lower() == "void":
            return {"has_pointer": False, "has_mutable_pointer": False, "mutable_args": []}

        mutable_args: List[str] = []
        for raw in args.split(","):
            part = raw.strip()
            if not part:
                continue
            # 有 * 或者常见指针类型
            is_ptr = "*" in part or "LP" in part or "PTR" in part or "PVOID" in part
            if not is_ptr:
                continue
            if "const" in part:
                continue
            mutable_args.append(part)

        return {
            "has_pointer": bool(mutable_args),
            "has_mutable_pointer": bool(mutable_args),
            "mutable_args": mutable_args,
        }

    def _infer_data_flow_notes(
        self,
        dep_name: str,
        target_code: str,
        cond_lines: List[Tuple[int, str]],
        mutability: Dict[str, object],
    ) -> List[str]:
        """检测“可写指针 + 后续被条件使用”的简单数据流提示。"""
        if not target_code:
            return []

        notes: List[str] = []
        if not mutability.get("has_mutable_pointer"):
            return notes

        # 识别调用点与参数：foo(x, y)
        call_pat = re.compile(rf"\b{re.escape(dep_name)}\s*\(([^)]*)\)")
        lines = target_code.splitlines()
        for idx, raw in enumerate(lines, start=1):
            m = call_pat.search(raw)
            if not m:
                continue
            arg_text = m.group(1)
            args = [a.strip() for a in arg_text.split(",") if a.strip()]
            # 只关心简单标识符变量
            arg_vars = [a for a in args if re.fullmatch(r"[A-Za-z_]\w*", a or "")]
            if not arg_vars:
                continue

            for var in arg_vars:
                for cond_idx, cond in cond_lines:
                    if cond_idx <= idx:
                        continue
                    if re.search(rf"\b{re.escape(var)}\b", cond):
                        notes.append(
                            f"可能写入参数 '{var}'（非 const 指针），该变量在后续条件(line {cond_idx})中被使用：{cond.strip()}"
                        )
                        break

        if not notes and mutability.get("has_mutable_pointer"):
            notes.append("包含非 const 指针参数，可能写入输入缓冲区（未发现直接条件使用）。")
        return notes
    
    def analyze_predicates(self, dll_name: str, file_name: str, func_name: str) -> List[Dict]:
        """
        分析函数中的谓词条件
        
        Returns:
            [
                {
                    "condition": "PathIsRelativeW(file)",
                    "depends_on": "PathIsRelativeW",
                    "type": "function_call",
                    "line": 123
                },
                {
                    "condition": "len > 0",
                    "type": "variable",
                    "line": 125
                }
            ]
        """
        code = self.hq.get_function_code(dll_name, file_name, func_name)
        if not code:
            code = self._extract_function_body_from_file(dll_name, file_name, func_name)
        lines = code.split('\n')

        # 赋值追踪：var -> (callee, call_expr, line)
        assigns: Dict[str, Tuple[str, str, int]] = {}

        predicates: List[Dict] = []

        # 多行条件聚合：遇到 if( / while( 开始后，如果本行括号未闭合，持续拼接后续行。
        i = 0
        while i < len(lines):
            idx = i + 1
            raw = lines[i]
            line = raw.strip()
            i += 1
            if not line:
                continue

            # 1) 识别赋值：x = f(...);
            #    仅做轻量模式匹配，足以覆盖大量 API 代码。
            asg = self._parse_assignment_call(line)
            if asg:
                var, callee, call_expr = asg
                assigns[var] = (callee, call_expr, idx)

            # 2) 识别 if/while 条件（支持多行）
            stmt_kind, cond, next_i = self._extract_condition_multiline(line, lines, i)
            if cond and stmt_kind in ("if", "while"):
                i = next_i
            if not cond:
                continue

            # 兼容旧字段
            entry: Dict = {
                "condition": cond,
                "type": "loop" if stmt_kind == "while" else "if",
                "line": idx,
            }

            entry["normalized_condition"] = self._normalize_condition(cond)
            entry["symbols"] = sorted(self._extract_symbols(cond))

            # 结构化 IR（尽量可机读、可扩展；失败时不阻塞）
            try:
                entry["ir"] = self._parse_condition_ir(entry["normalized_condition"])
            except Exception:
                entry["ir"] = {"kind": "raw", "text": entry["normalized_condition"]}

            psi = self._build_minimal_psi(cond, assigns)
            if psi:
                entry.update(psi)

                # 旧版 ODAGenerator 会看 depends_on/type=function_call
                if entry.get("depends_on"):
                    entry.setdefault("type", "function_call")

            predicates.append(entry)

        return predicates

    # --------------------------
    # Predicate IR (AST-lite)
    # --------------------------
    def _parse_condition_ir(self, cond: str) -> Dict:
        """把条件表达式解析成轻量 IR。

        目标：覆盖 Wine C 代码里最常见的条件结构：
          - a && b / a || b / !a
          - x OP y
          - f(...) / !f(...)
          - x / !x

        这不是完整 C parser，只做够用的结构化，失败时退回 raw。
        """
        s = cond.strip()
        s = self._strip_outer_parens(s)

        # 顶层按 || 分割（最低优先级）
        parts = self._split_top_level(s, '||')
        if len(parts) > 1:
            return {"kind": "or", "items": [self._parse_condition_ir(p) for p in parts]}

        parts = self._split_top_level(s, '&&')
        if len(parts) > 1:
            return {"kind": "and", "items": [self._parse_condition_ir(p) for p in parts]}

        # not
        if s.startswith('!'):
            inner = s[1:].strip()
            inner = self._strip_outer_parens(inner)
            return {"kind": "not", "item": self._parse_condition_ir(inner)}

        # compare
        cmp_ops = ['==', '!=', '>=', '<=', '>', '<']
        for op in cmp_ops:
            lr = self._split_top_level_first(s, op)
            if lr:
                l, r = lr
                return {"kind": "compare", "op": op, "left": l.strip(), "right": r.strip()}

        # call truthy
        m = re.match(r'^(?P<callee>[A-Za-z_]\w*)\s*\((?P<args>.*)\)\s*$', s)
        if m:
            return {"kind": "call", "callee": m.group('callee'), "args": m.group('args').strip()}

        # var/expr truthy
        return {"kind": "expr", "text": s}

    def _strip_outer_parens(self, s: str) -> str:
        ss = s.strip()
        while ss.startswith('(') and ss.endswith(')'):
            inner = ss[1:-1].strip()
            if self._paren_balance(inner) == 0:
                ss = inner
                continue
            break
        return ss

    def _split_top_level(self, s: str, sep: str) -> List[str]:
        out: List[str] = []
        buf: List[str] = []
        i = 0
        depth = 0
        while i < len(s):
            ch = s[i]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth = max(0, depth - 1)

            if depth == 0 and s.startswith(sep, i):
                out.append(''.join(buf).strip())
                buf = []
                i += len(sep)
                continue
            buf.append(ch)
            i += 1
        tail = ''.join(buf).strip()
        if tail:
            out.append(tail)
        return out

    def _split_top_level_first(self, s: str, sep: str) -> Optional[Tuple[str, str]]:
        i = 0
        depth = 0
        while i < len(s):
            ch = s[i]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth = max(0, depth - 1)

            if depth == 0 and s.startswith(sep, i):
                return s[:i], s[i + len(sep):]
            i += 1
        return None

    def _extract_condition_multiline(self, line: str, lines: List[str], next_i: int) -> Tuple[Optional[str], Optional[str], int]:
        """从当前位置提取 if/while 条件，支持跨多行拼接。

        返回： (kind, condition) 或 (kind, (condition, new_next_i))
        """
        kind, cond = self._extract_condition(line)
        if not cond:
            return kind, cond, next_i

        # 如果本行就闭合，直接返回
        if self._paren_balance(cond) <= 0:
            return kind, cond, next_i

        # 否则继续拼接后续行，直到括号平衡回到 0 或结束
        acc = [cond]
        bal = self._paren_balance(cond)
        i = next_i
        while i < len(lines) and bal > 0:
            frag = lines[i].strip()
            i += 1
            if not frag:
                continue
            # 去掉行末的 '\\' 与注释尾巴（很粗糙，但能减少噪声）
            frag = re.sub(r'//.*$', '', frag).strip()
            acc.append(frag)
            bal += self._paren_balance(frag)
        joined = ' '.join([x for x in acc if x])
        joined = re.sub(r'\s+', ' ', joined).strip()
        return kind, joined, i

    def _paren_balance(self, s: str) -> int:
        return s.count('(') - s.count(')')

    def _normalize_condition(self, cond: str) -> str:
        # 仅做轻量规范化：压缩空白、统一一些常见宏形式
        s = re.sub(r'\s+', ' ', cond).strip()
        s = s.replace('&&', ' && ').replace('||', ' || ')
        s = re.sub(r'\s+', ' ', s).strip()
        return s

    def _extract_symbols(self, cond: str) -> Set[str]:
        # 提取潜在符号：标识符，剔除关键字/常量
        toks = set(re.findall(r'\b[A-Za-z_]\w*\b', cond))
        drop = set(self.blacklist) | {
            'NULL', 'TRUE', 'FALSE', 'sizeof',
        }
        return {t for t in toks if t not in drop and not t.isupper()}

    def _extract_function_body_from_file(self, dll_name: str, file_name: str, func_name: str) -> str:
        if not self.hq.wine_root:
            return ""
        src_path = self.hq.wine_root / "dlls" / dll_name / file_name
        if not src_path.exists():
            return ""
        lines = src_path.read_text(encoding="utf-8", errors="ignore").splitlines()
        start = None
        for idx, line in enumerate(lines):
            if func_name in line:
                start = idx
                break
        if start is None:
            return ""
        brace = 0
        end = None
        for j in range(start, min(start + 400, len(lines))):
            brace += lines[j].count("{")
            brace -= lines[j].count("}")
            if brace > 0 and end is None:
                end = j
            if brace == 0 and end is not None and j > start:
                end = j
                break
        if end is None:
            end = min(start + 120, len(lines) - 1)
        return "\n".join(lines[start:end + 1])

    def _extract_condition(self, line: str) -> Tuple[Optional[str], Optional[str]]:
        """从单行文本中提取 if/while 条件。返回 (kind, condition)。"""
        m = re.search(r'\bif\s*\((.*)\)\s*$', line)
        if m:
            return "if", m.group(1).strip()
        m = re.search(r'\bwhile\s*\((.*)\)\s*$', line)
        if m:
            return "while", m.group(1).strip()
        return None, None

    def _parse_assignment_call(self, line: str) -> Optional[Tuple[str, str, str]]:
        """解析 x = f(...); 形式的赋值调用。返回 (var, callee, call_expr)。"""
        # 过滤比较运算，避免把 if (a == b) 误判成赋值
        if '==' in line or '!=' in line or '>=' in line or '<=' in line:
            return None
        # 支持：ret = foo(...);  或  ret=foo(...)
        m = re.match(r'^(?:\(.*\)\s*)?(?P<var>[A-Za-z_]\w*)\s*=\s*(?P<callee>[A-Za-z_]\w*)\s*\((?P<args>.*)\)\s*;\s*$', line)
        if not m:
            return None
        var = m.group('var')
        callee = m.group('callee')
        call_expr = f"{callee}({m.group('args')})"
        return var, callee, call_expr

    def _build_minimal_psi(self, cond: str, assigns: Dict[str, Tuple[str, str, int]]) -> Optional[Dict]:
        """把条件表达式 cond 归约为最小 ψ（结构化），并尽量关联到 depends_on。"""
        # 规则优先级：
        #   A) 直接函数调用：if (f(...)) / if (!f(...)) / if (f(...) OP c)
        #   B) 变量比较：if (x OP c)，若 x 来自 x=f(...) 则 depends_on=f
        #   C) 变量布尔：if (x) / if (!x)，同样追踪 x 的来源

        cond_s = cond.strip()
        polarity = "true"  # cond 满足时进入的分支

        # 处理逻辑非
        if cond_s.startswith('!'):
            polarity = "false"
            cond_s = cond_s[1:].strip()
            # 去掉一层括号：!(x) -> x
            if cond_s.startswith('(') and cond_s.endswith(')'):
                cond_s = cond_s[1:-1].strip()

        # 特殊：条件内的赋值调用子表达式 (var = f(...)) OP rhs
        # 例：(!path || (len = lstrlenW(path)) >= MAX_PATH)
        # 这里我们只做“局部”的提取：如果 cond 中存在 (var = callee(...))，则将其写入 assigns，
        # 并且尝试把周围的比较归约为 depends_on=callee。
        inline_asg = re.search(
            r'\((?P<var>[A-Za-z_]\w*)\s*=\s*(?P<callee>[A-Za-z_]\w*)\s*\((?P<args>[^)]*)\)\)\s*(?P<op>==|!=|>=|<=|>|<)\s*(?P<rhs>[^&|]+)',
            cond_s,
        )
        if inline_asg:
            var = inline_asg.group('var')
            callee = inline_asg.group('callee')
            call_expr = f"{callee}({inline_asg.group('args')})"
            assigns[var] = (callee, call_expr, -1)
            op = inline_asg.group('op')
            rhs = self._normalize_rhs(inline_asg.group('rhs').strip())
            return {
                "kind": "call_compare",
                "depends_on": callee,
                "variable": var,
                "op": op,
                "rhs": rhs,
                "polarity": polarity,
            }

        # A) f(...)
        m_call = re.match(r'^(?P<callee>[A-Za-z_]\w*)\s*\((?P<args>.*)\)\s*(?P<rest>.*)$', cond_s)
        if m_call:
            callee = m_call.group('callee')
            rest = m_call.group('rest').strip()
            if not rest:
                return {
                    "kind": "call_truthy",
                    "depends_on": callee,
                    "op": "truthy",
                    "rhs": None,
                    "polarity": polarity,
                }

            cmp_parsed = self._parse_compare(rest)
            if cmp_parsed:
                op, rhs = cmp_parsed
                return {
                    "kind": "call_compare",
                    "depends_on": callee,
                    "op": op,
                    "rhs": rhs,
                    "polarity": polarity,
                }

        # B/C) x OP c / x
        m_var_cmp = re.match(r'^(?P<var>[A-Za-z_]\w*)\s*(?P<op>==|!=|>=|<=|>|<)\s*(?P<rhs>.+)$', cond_s)
        if m_var_cmp:
            var = m_var_cmp.group('var')
            op = m_var_cmp.group('op')
            rhs_raw = m_var_cmp.group('rhs').strip()
            rhs = self._normalize_rhs(rhs_raw)

            depends = None
            if var in assigns:
                depends = assigns[var][0]
            return {
                "kind": "var_compare",
                "variable": var,
                "depends_on": depends,
                "op": op,
                "rhs": rhs,
                "polarity": polarity,
            }

        m_var = re.match(r'^(?P<var>[A-Za-z_]\w*)\s*$', cond_s)
        if m_var:
            var = m_var.group('var')
            depends = None
            if var in assigns:
                depends = assigns[var][0]
            return {
                "kind": "var_truthy",
                "variable": var,
                "depends_on": depends,
                "op": "truthy",
                "rhs": None,
                "polarity": polarity,
            }

        return None

    def _parse_compare(self, s: str) -> Optional[Tuple[str, object]]:
        """解析形如 '== 0'、'> 3' 的比较尾巴。"""
        m = re.match(r'^(==|!=|>=|<=|>|<)\s*(.+)$', s)
        if not m:
            return None
        op = m.group(1)
        rhs = self._normalize_rhs(m.group(2).strip())
        return op, rhs

    def _normalize_rhs(self, rhs_raw: str) -> object:
        """把 rhs 归一化为 int/str。"""
        # 去掉多余括号
        rhs = rhs_raw.strip()
        if rhs.startswith('(') and rhs.endswith(')'):
            rhs = rhs[1:-1].strip()
        # 十六进制/十进制
        if re.match(r'^0x[0-9a-fA-F]+$', rhs):
            try:
                return int(rhs, 16)
            except ValueError:
                return rhs
        if re.match(r'^\d+$', rhs):
            try:
                return int(rhs)
            except ValueError:
                return rhs
        # 常见宏/常量直接保留字符串，以便 LLM 或 stub 生成时参考
        return rhs


def demo():
    """演示用法"""
    import json
    
    analyzer = DependencyAnalyzer("../rag/index.json", "../../wine")
    
    # 分析 PathIsRelativeW（简单，无依赖）
    print("=== PathIsRelativeW ===")
    deps1 = analyzer.analyze("shlwapi", "path.c", "PathIsRelativeW")
    print(json.dumps(deps1, indent=2, ensure_ascii=False))
    
    predicates1 = analyzer.analyze_predicates("shlwapi", "path.c", "PathIsRelativeW")
    print("\n谓词:")
    print(json.dumps(predicates1, indent=2, ensure_ascii=False))
    
    print("\n" + "="*60 + "\n")
    
    # 分析 PathCombineW（复杂，有依赖）
    print("=== PathCombineW ===")
    deps2 = analyzer.analyze("shlwapi", "path.c", "PathCombineW")
    print(json.dumps(deps2, indent=2, ensure_ascii=False))
    
    predicates2 = analyzer.analyze_predicates("shlwapi", "path.c", "PathCombineW")
    print("\n谓词:")
    print(json.dumps(predicates2, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    demo()
