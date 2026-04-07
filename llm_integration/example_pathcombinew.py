#!/usr/bin/env python3
"""
完整示例：为 PathCombineW 自动生成 ODA 规约

这个脚本展示了完整的流程：
1. 分析依赖函数
2. 分析谓词条件
3. 使用 LLM 生成 ODA 规约
4. 生成 stub 代码
5. 运行 KLEE
6. 根据结果迭代优化

用法:
    python example_pathcombinew.py
"""

import json
import sys
import os

# 添加父目录到路径
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from dependency_analyzer import DependencyAnalyzer
from oda_generator import ODAGenerator, MockLLM


def main():
    print("="*60)
    print("完整示例：为 PathCombineW 生成 ODA 规约")
    print("="*60)
    print()
    
    # ========================================
    # 步骤 1: 分析依赖函数
    # ========================================
    print("[步骤 1/6] 分析依赖函数")
    print("-"*60)
    
    analyzer = DependencyAnalyzer("../rag/index.json", "../../wine")
    
    try:
        dependencies = analyzer.analyze("shlwapi", "path.c", "PathCombineW")
    except Exception as e:
        print(f"警告: 无法分析真实的 PathCombineW: {e}")
        print("使用模拟数据...")
        dependencies = [
            {
                "name": "PathIsRelativeW",
                "signature": "BOOL PathIsRelativeW(LPCWSTR path)",
                "summary": "Determines if a path string is relative",
                "dll": "shlwapi",
                "file": "path.c",
                "call_count": 1
            },
            {
                "name": "lstrlenW",
                "signature": "int lstrlenW(LPCWSTR str)",
                "summary": "Returns the length of a wide string",
                "dll": "kernel32",
                "file": "string.c",
                "call_count": 2
            },
            {
                "name": "lstrcpyW",
                "signature": "LPWSTR lstrcpyW(LPWSTR dest, LPCWSTR src)",
                "summary": "Copies a wide string",
                "dll": "kernel32",
                "file": "string.c",
                "call_count": 1
            }
        ]
    
    print(f"\n找到 {len(dependencies)} 个依赖函数:")
    for dep in dependencies:
        print(f"  - {dep['name']}: {dep['summary']}")
        print(f"    签名: {dep['signature']}")
        print(f"    调用次数: {dep['call_count']}")
    
    print()
    
    # ========================================
    # 步骤 2: 分析谓词条件
    # ========================================
    print("[步骤 2/6] 分析谓词条件")
    print("-"*60)
    
    try:
        predicates = analyzer.analyze_predicates("shlwapi", "path.c", "PathCombineW")
    except Exception as e:
        print(f"警告: 无法分析真实的 PathCombineW: {e}")
        print("使用模拟数据...")
        predicates = [
            {
                "condition": "PathIsRelativeW(file)",
                "depends_on": "PathIsRelativeW",
                "type": "function_call",
                "line": 10
            },
            {
                "condition": "len > 0",
                "type": "variable",
                "line": 15
            }
        ]
    
    print(f"\n找到 {len(predicates)} 个谓词条件:")
    for pred in predicates:
        print(f"  - 行 {pred['line']}: {pred['condition']}")
        print(f"    类型: {pred['type']}")
        if 'depends_on' in pred:
            print(f"    依赖: {pred['depends_on']}")
    
    print()
    
    # ========================================
    # 步骤 3: 使用 LLM 生成 ODA 规约
    # ========================================
    print("[步骤 3/6] 使用 LLM 生成 ODA 规约")
    print("-"*60)
    
    # 注意：这里使用 MockLLM，实际使用时应该替换为真实的 LLM 客户端
    # 例如：
    # from openai import OpenAI
    # llm = OpenAI(api_key="your-api-key")
    
    llm = MockLLM()
    generator = ODAGenerator(llm)
    
    spec = generator.generate("PathCombineW", dependencies, predicates)
    
    print("\n生成的 ODA 规约:")
    print(json.dumps(spec, indent=2, ensure_ascii=False))
    
    print()
    
    # ========================================
    # 步骤 4: 保存规约到文件
    # ========================================
    print("[步骤 4/6] 保存规约到文件")
    print("-"*60)
    
    output_file = "../specs/pathcombinew.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(spec, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ 规约已保存到: {output_file}")
    
    print()
    
    # ========================================
    # 步骤 5: 生成 stub 代码
    # ========================================
    print("[步骤 5/6] 生成 stub 代码")
    print("-"*60)
    
    import subprocess
    
    result = subprocess.run(
        ["python3", "../specs/gen_oda_stub.py", "pathcombinew.json", 
         "-o", "../klee/oda_stubs_pathcombinew.c"],
        cwd="../specs",
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("\n✓ Stub 代码已生成")
        print(result.stdout)
    else:
        print("\n✗ 生成失败")
        print(result.stderr)
    
    print()
    
    # ========================================
    # 步骤 6: 下一步建议
    # ========================================
    print("[步骤 6/6] 下一步")
    print("-"*60)
    
    print("""
现在你可以：

1. 查看生成的规约:
   cat ../specs/pathcombinew.json

2. 查看生成的 stub 代码:
   cat ../klee/oda_stubs_pathcombinew.c

3. 编写 KLEE harness:
   cp ../klee/harness_pathisrelativew.c ../klee/harness_pathcombinew.c
   # 编辑 harness_pathcombinew.c，调用 PathCombineW

4. 运行 KLEE:
   cd ../klee
   ./run_klee.sh harness_pathcombinew.c

5. 如果 KLEE 超时，优化规约:
   python3 optimize_spec.py pathcombinew.json --timeout

6. 如果测试用例太少，优化规约:
   python3 optimize_spec.py pathcombinew.json --few-cases
""")
    
    print()
    print("="*60)
    print("完成！")
    print("="*60)


if __name__ == "__main__":
    main()
