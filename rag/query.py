#!/usr/bin/env python3
"""
分层查询 Wine 源码索引

用法:
    from query import HierarchicalQuery
    
    hq = HierarchicalQuery("index.json")
    dlls = hq.list_dlls()
    files = hq.list_files("shlwapi")
    functions = hq.list_functions("shlwapi", "path.c")
    code = hq.get_function_code("shlwapi", "path.c", "PathIsRelativeW")
"""

import json
import re
from typing import List, Dict, Optional, Iterable, Tuple
from pathlib import Path


class HierarchicalQuery:
    """分层查询接口"""
    
    def __init__(self, index_path: str, wine_root: Optional[str] = None):
        """
        初始化查询器
        
        Args:
            index_path: 索引文件路径
            wine_root: Wine 源码根目录（用于读取完整代码）
        """
        with open(index_path, 'r', encoding='utf-8') as f:
            self.index = json.load(f)
        
        self.wine_root = Path(wine_root) if wine_root else None

    def _function_map(self, file_info: Dict) -> Dict[str, Dict]:
        """兼容 index 的两种 functions 结构，统一成 name -> info 的 dict。"""
        funcs = file_info.get("functions", {})
        if isinstance(funcs, dict):
            return funcs
        if isinstance(funcs, list):
            mapped: Dict[str, Dict] = {}
            for fi in funcs:
                if isinstance(fi, dict) and "name" in fi:
                    mapped[fi["name"]] = fi
            return mapped
        return {}
    
    def list_dlls(self, keyword: Optional[str] = None) -> List[Dict]:
        """
        列出所有 DLL（第一层）
        
        Args:
            keyword: 可选的关键字过滤
        
        Returns:
            [{"name": "shlwapi", "description": "...", "file_count": 10}, ...]
        """
        dlls = []
        
        for dll_name, dll_info in self.index["dlls"].items():
            if keyword and keyword.lower() not in dll_name.lower():
                continue
            
            dlls.append({
                "name": dll_name,
                "description": dll_info.get("description", ""),
                "file_count": len(dll_info["files"])
            })
        
        return sorted(dlls, key=lambda x: x["name"])
    
    def list_files(self, dll_name: str) -> List[Dict]:
        """
        列出指定 DLL 的所有文件（第二层）
        
        Args:
            dll_name: DLL 名称
        
        Returns:
            [{"name": "path.c", "description": "...", "function_count": 20}, ...]
        """
        if dll_name not in self.index["dlls"]:
            raise ValueError(f"DLL '{dll_name}' not found in index")
        
        dll_info = self.index["dlls"][dll_name]
        files = []
        
        for file_name, file_info in dll_info["files"].items():
            files.append({
                "name": file_name,
                "description": file_info.get("description", ""),
                "function_count": len(file_info["functions"])
            })
        
        return sorted(files, key=lambda x: x["name"])
    
    def list_functions(self, dll_name: str, file_name: str, 
                      keyword: Optional[str] = None) -> List[Dict]:
        """
        列出指定文件的所有函数（第三层，只返回摘要）
        
        Args:
            dll_name: DLL 名称
            file_name: 文件名
            keyword: 可选的关键字过滤
        
        Returns:
            [{"name": "PathIsRelativeW", "signature": "...", "summary": "...", 
              "complexity": "low", "dependencies": [...]}, ...]
        """
        if dll_name not in self.index["dlls"]:
            raise ValueError(f"DLL '{dll_name}' not found")
        
        dll_info = self.index["dlls"][dll_name]
        
        if file_name not in dll_info["files"]:
            raise ValueError(f"File '{file_name}' not found in DLL '{dll_name}'")
        
        file_info = dll_info["files"][file_name]
        functions = []

        funcs = file_info.get("functions", {})
        # 兼容两种 index 结构：
        #  1) {"functions": {"Func": {...}}}
        #  2) {"functions": [{"name": "Func", ...}, ...]}
        if isinstance(funcs, list):
            func_iter = []
            for fi in funcs:
                if not isinstance(fi, dict) or "name" not in fi:
                    continue
                name = fi["name"]
                func_iter.append((name, fi))
        else:
            func_iter = list(funcs.items())

        for func_name, func_info in func_iter:
            if keyword and keyword.lower() not in func_name.lower():
                continue

            summary = (
                func_info.get("llm_summary")
                or func_info.get("summary")
                or func_info.get("static_summary")
                or ""
            )
            
            functions.append({
                "name": func_name,
                "signature": func_info.get("signature", ""),
                "summary": summary,
                "complexity": func_info.get("complexity", "unknown"),
                "dependencies": func_info.get("dependencies", []),
                "line_range": (
                    f"{func_info.get('line_start','?')}-{func_info.get('line_end','?')}"
                    if ("line_start" in func_info or "line_end" in func_info)
                    else "?"
                )
            })
        
        return sorted(functions, key=lambda x: x["name"])
    
    def get_function_info(self, dll_name: str, file_name: str, 
                         func_name: str) -> Dict:
        """
        获取函数的详细信息（不包括代码）
        
        Args:
            dll_name: DLL 名称
            file_name: 文件名
            func_name: 函数名
        
        Returns:
            完整的函数元数据
        """
        if dll_name not in self.index["dlls"]:
            raise ValueError(f"DLL '{dll_name}' not found")
        
        dll_info = self.index["dlls"][dll_name]
        
        if file_name not in dll_info["files"]:
            raise ValueError(f"File '{file_name}' not found")
        
        file_info = dll_info["files"][file_name]

        funcs = self._function_map(file_info)
        if func_name in funcs:
            return funcs[func_name]

        # 兜底：大小写/空白不一致时，尝试宽松匹配
        lookup = {k.strip().lower(): k for k in funcs.keys()}
        key = lookup.get(func_name.strip().lower())
        if key:
            return funcs[key]

        raise ValueError(f"Function '{func_name}' not found")
    
    def get_function_code(self, dll_name: str, file_name: str, 
                         func_name: str) -> str:
        """
        获取函数的完整代码（第四层）
        
        Args:
            dll_name: DLL 名称
            file_name: 文件名
            func_name: 函数名
        
        Returns:
            函数的完整源代码
        """
        if not self.wine_root:
            raise ValueError("需要指定 wine_root 才能读取源代码")
        
        func_info = self.get_function_info(dll_name, file_name, func_name)

        if "line_start" not in func_info or "line_end" not in func_info:
            # 索引里缺少行号时，无法精确切片源码；返回空字符串避免依赖分析崩溃。
            return ""
        
        # 构建文件路径
        file_path = self.wine_root / "dlls" / dll_name / file_name
        
        if not file_path.exists():
            raise FileNotFoundError(f"源文件不存在: {file_path}")
        
        # 读取指定行范围
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        start = func_info["line_start"] - 1
        end = func_info["line_end"]
        
        return ''.join(lines[start:end])
    
    def search_functions(self, keyword: str, max_results: int = 20) -> List[Dict]:
        """
        全局搜索函数（跨所有 DLL）
        
        Args:
            keyword: 搜索关键字
            max_results: 最大返回结果数
        
        Returns:
            [{"dll": "shlwapi", "file": "path.c", "name": "PathIsRelativeW", ...}, ...]
        """
        results = []
        keyword_lower = keyword.lower()
        
        for dll_name, dll_info in self.index["dlls"].items():
            for file_name, file_info in dll_info["files"].items():
                funcs = self._function_map(file_info)
                for func_name, func_info in funcs.items():
                    if keyword_lower in func_name.lower():
                        summary = (
                            func_info.get("llm_summary")
                            or func_info.get("summary")
                            or func_info.get("static_summary")
                            or ""
                        )
                        results.append({
                            "dll": dll_name,
                            "file": file_name,
                            "name": func_name,
                            "signature": func_info["signature"],
                            "summary": summary
                        })
                        
                        if len(results) >= max_results:
                            return results
        
        return results

    def search_functions_exact(self, func_name: str, max_results: int = 20) -> List[Dict]:
        """全局精确搜索函数名（大小写不敏感）。

        返回格式与 search_functions 一致。
        """
        results: List[Dict] = []
        want = func_name.strip().lower()
        for dll_name, dll_info in self.index.get("dlls", {}).items():
            for file_name, file_info in dll_info.get("files", {}).items():
                funcs = self._function_map(file_info)
                for name, info in funcs.items():
                    if name.strip().lower() != want:
                        continue
                    summary = (
                        info.get("llm_summary")
                        or info.get("summary")
                        or info.get("static_summary")
                        or ""
                    )
                    results.append({
                        "dll": dll_name,
                        "file": file_name,
                        "name": name,
                        "signature": info.get("signature", ""),
                        "summary": summary,
                    })
                    if len(results) >= max_results:
                        return results
        return results

    def grep_symbol_in_file(self, dll_name: str, file_name: str, symbol: str, max_hits: int = 50) -> List[Dict]:
        """在指定源文件中 grep 某个 symbol（仅在 wine_root 可用时）。

        主要用途：当索引缺 line range 或依赖列表不可靠时，补充“调用点证据”。
        返回：[{"line": 123, "text": "..."}, ...]
        """
        if not self.wine_root:
            return []
        src_path = self.wine_root / "dlls" / dll_name / file_name
        if not src_path.exists():
            return []
        pat = re.compile(rf"\\b{re.escape(symbol)}\\b")
        hits: List[Dict] = []
        with open(src_path, "r", encoding="utf-8", errors="ignore") as f:
            for i, line in enumerate(f, 1):
                if pat.search(line):
                    hits.append({"line": i, "text": line.rstrip("\n")})
                    if len(hits) >= max_hits:
                        break
        return hits
    
    def get_related_functions(self, dll_name: str, file_name: str, 
                             func_name: str) -> List[Dict]:
        """
        获取相关函数（基于依赖关系）
        
        Args:
            dll_name: DLL 名称
            file_name: 文件名
            func_name: 函数名
        
        Returns:
            相关函数列表
        """
        func_info = self.get_function_info(dll_name, file_name, func_name)
        dependencies = func_info.get("dependencies", [])
        
        related = []
        
        # 在同一文件中查找依赖函数
        file_info = self.index["dlls"][dll_name]["files"][file_name]
        funcs = self._function_map(file_info)
        for dep in dependencies:
            if dep in funcs:
                related.append({
                    "dll": dll_name,
                    "file": file_name,
                    "name": dep,
                    "signature": file_info["functions"][dep]["signature"],
                    "summary": file_info["functions"][dep]["summary"]
                })
        
        return related


def demo():
    """演示用法"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法: python query.py <index.json> [wine_root]")
        return
    
    index_path = sys.argv[1]
    wine_root = sys.argv[2] if len(sys.argv) > 2 else None
    
    hq = HierarchicalQuery(index_path, wine_root)
    
    print("=== 第一层：列出所有 DLL ===")
    dlls = hq.list_dlls()
    print(f"找到 {len(dlls)} 个 DLL")
    for dll in dlls[:5]:
        print(f"  - {dll['name']}: {dll['description']} ({dll['file_count']} 文件)")
    
    print("\n=== 第二层：列出 shlwapi 的文件 ===")
    files = hq.list_files("shlwapi")
    for file in files[:5]:
        print(f"  - {file['name']}: {file['description']} ({file['function_count']} 函数)")
    
    print("\n=== 第三层：列出 path.c 的函数 ===")
    functions = hq.list_functions("shlwapi", "path.c")
    for func in functions[:5]:
        print(f"  - {func['name']}: {func['summary']}")
        print(f"    签名: {func['signature']}")
        print(f"    复杂度: {func['complexity']}, 依赖: {func['dependencies']}")
    
    if wine_root:
        print("\n=== 第四层：获取 PathIsRelativeW 的代码 ===")
        try:
            code = hq.get_function_code("shlwapi", "path.c", "PathIsRelativeW")
            print(code[:500] + "...")
        except Exception as e:
            print(f"无法读取代码: {e}")


if __name__ == "__main__":
    demo()
