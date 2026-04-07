#!/usr/bin/env python3
"""
将 KLEE 生成的 .ktest 文件转换为测试用例

.ktest 文件包含 KLEE 生成的符号变量的具体值。
我们将这些值转换为统一的二进制格式，供跨平台测试使用。

用法:
    python ktest_to_cases.py klee-out-0/ -o test_cases.bin
"""

import os
import struct
import argparse
import subprocess
import re
from pathlib import Path
from typing import Dict, List, Tuple


class KTestParser:
    """解析 KLEE .ktest 文件"""
    
    def __init__(self, ktest_path: str):
        self.ktest_path = ktest_path
        self.objects = {}
    
    def parse(self) -> Dict[str, bytes]:
        """
        解析 .ktest 文件，返回符号对象字典
        
        Returns:
            {"path": b"C:\\Windows", ...}
        """
        # 使用 ktest-tool 解析（KLEE 自带工具）
        # 注意：不同发行版的 ktest-tool 对 `--write-ints` 支持不一致，可能 exit=2。
        # 因此这里做两级解析：
        #   1) 优先 `--write-ints`（便于直接得到逐字节 int）
        #   2) 失败则回退到默认输出解析（包含 object name/size/data）
        try:
            result = subprocess.run(
                ['ktest-tool', '--write-ints', self.ktest_path],
                capture_output=True,
                text=True,
                check=True
            )
            return self._parse_write_ints_output(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"警告: 无法用 --write-ints 解析 {self.ktest_path}: {e}")
        except FileNotFoundError:
            print("错误: ktest-tool 未找到，请确保 KLEE 已正确安装")
            return {}

        # fallback: 默认输出
        try:
            result2 = subprocess.run(
                ['ktest-tool', self.ktest_path],
                capture_output=True,
                text=True,
                check=True
            )
            return self._parse_default_output(result2.stdout)
        except subprocess.CalledProcessError as e:
            print(f"警告: 无法解析 {self.ktest_path}: {e}")
            return {}
        except FileNotFoundError:
            print("错误: ktest-tool 未找到，请确保 KLEE 已正确安装")
            return {}

    def _parse_write_ints_output(self, out: str) -> Dict[str, bytes]:
        lines = out.split('\n')
        current_obj = None
        current_data: List[int] = []

        for line in lines:
            # object 0: name: 'path'
            if line.strip().startswith('object') and ': name:' in line:
                if current_obj is not None:
                    self.objects[current_obj] = bytes(current_data)

                parts = line.split("'")
                if len(parts) >= 2:
                    current_obj = parts[1]
                    current_data = []
                else:
                    current_obj = None
                    current_data = []

            elif line.strip().startswith('int') and ':' in line and current_obj:
                try:
                    value_part = line.split(':', 1)[1].split('(')[0].strip()
                    value = int(value_part)
                    current_data.append(value & 0xFF)
                except (ValueError, IndexError):
                    pass

        if current_obj is not None:
            self.objects[current_obj] = bytes(current_data)

        # 去掉空对象
        return {k: v for k, v in self.objects.items() if v is not None}

    def _parse_default_output(self, out: str) -> Dict[str, bytes]:
        """解析 `ktest-tool file.ktest` 的默认输出。

        常见格式片段（不同版本略有差异）：
          object 0: name: 'path'
          object 0: size: 520
          object 0: data: 0x43 0x00 0x3a ...
        """
        lines = [ln.rstrip('\r') for ln in out.split('\n')]
        current_obj: str | None = None
        current_bytes: List[int] = []
        in_data_block = False

        def flush():
            nonlocal current_obj, current_bytes, in_data_block
            if current_obj is not None:
                self.objects[current_obj] = bytes(current_bytes)
            in_data_block = False

        def consume_tokens(token_line: str):
            nonlocal current_bytes
            for tok in token_line.replace(',', ' ').split():
                t = tok.strip()
                if not t:
                    continue
                try:
                    if t.startswith(('0x', '0X')):
                        current_bytes.append(int(t, 16) & 0xFF)
                    else:
                        current_bytes.append(int(t) & 0xFF)
                except ValueError:
                    # 忽略无法识别的 token（有些版本会打印 '\xHH' 或其它装饰字符）
                    pass

        def consume_bytes_repr(bytes_literal: str):
            """解析形如 b'\\x00\\x01...' 的 Python bytes repr（ktest-tool 默认输出会这样打印）。"""
            nonlocal current_bytes

            s = bytes_literal.strip()
            # 允许用户传入包含前缀 b'' 的整段
            if s.startswith('b"') or s.startswith("b'"):
                s = s[1:].lstrip()

            if (len(s) >= 2) and ((s[0] == "'" and s[-1] == "'") or (s[0] == '"' and s[-1] == '"')):
                s = s[1:-1]

            i = 0
            while i < len(s):
                ch = s[i]
                if ch != '\\':
                    # ktest-tool 的 bytes repr 正常不会有裸字符（大多都是 \xHH），但为了稳妥，按 latin-1 吃掉
                    current_bytes.append(ord(ch) & 0xFF)
                    i += 1
                    continue

                # escape
                i += 1
                if i >= len(s):
                    break
                esc = s[i]
                i += 1

                if esc == 'x' and i + 1 < len(s):
                    hh = s[i:i+2]
                    if re.fullmatch(r"[0-9a-fA-F]{2}", hh):
                        current_bytes.append(int(hh, 16) & 0xFF)
                        i += 2
                        continue
                    # 非法 \x，回退
                    current_bytes.append(ord('x'))
                    continue

                # 常见转义
                mapping = {
                    '0': 0,
                    'n': 10,
                    'r': 13,
                    't': 9,
                    "\\": 92,
                    "'": 39,
                    '"': 34,
                }
                if esc in mapping:
                    current_bytes.append(mapping[esc] & 0xFF)
                else:
                    # 未知转义：保留原字符
                    current_bytes.append(ord(esc) & 0xFF)

        for ln in lines:
            s = ln.strip()

            # new object
            if s.startswith('object') and ": name:" in s:
                flush()
                parts = s.split("'")
                current_obj = parts[1] if len(parts) >= 2 else None
                current_bytes = []
                continue

            if current_obj is None:
                continue

            # 进入 data block：有些 ktest-tool 会输出 "object N: data:" ，后续多行都是 "0x.."
            if 'data:' in s:
                in_data_block = True
                after = s.split('data:', 1)[1].strip()
                if after:
                    # 你的 ktest-tool 会输出：data: b'\x00\x01...'
                    if after.startswith('b"') or after.startswith("b'"):
                        consume_bytes_repr(after)
                        in_data_block = False
                    else:
                        consume_tokens(after)
                continue

            # 你的输出里还有：object 0: hex : 0x.... （长度=2*size）
            if 'hex' in s and '0x' in s:
                m = re.search(r"0x([0-9a-fA-F]+)", s)
                if m:
                    hx = m.group(1)
                    if len(hx) % 2 == 0:
                        try:
                            current_bytes = list(bytes.fromhex(hx))
                        except ValueError:
                            pass
                in_data_block = False
                continue

            # data block 的后续行：通常是若干个 0x.. token
            if in_data_block:
                if not s:
                    # 空行一般表示 data 块结束
                    in_data_block = False
                    continue
                if s.startswith('object'):
                    # 意外情况：未通过 name 行切换到下一个 object
                    in_data_block = False
                    continue
                # 如果这一行看起来像 "0x12 0x34 ..." 就吃掉；否则退出 data 块
                if '0x' in s or s[0].isdigit():
                    consume_tokens(s)
                    continue
                in_data_block = False

        flush()

        # 去掉空对象
        return {k: v for k, v in self.objects.items() if v}


class TestCaseWriter:
    """将测试用例写入二进制文件"""
    
    def __init__(self, output_path: str):
        self.output_path = output_path
        self.cases = []
    
    def add_case(self, objects: Dict[str, bytes]):
        """添加一个测试用例"""
        self.cases.append(objects)
    
    def write(self):
        """
        写入二进制文件
        
        格式:
        - 用例数量: 4 字节 (uint32)
        - 每个用例:
            - 对象数量: 4 字节 (uint32)
            - 每个对象:
                - 名称长度: 4 字节 (uint32)
                - 名称: N 字节 (UTF-8)
                - 数据长度: 4 字节 (uint32)
                - 数据: M 字节
        """
        with open(self.output_path, 'wb') as f:
            # 写入用例数量
            f.write(struct.pack('<I', len(self.cases)))
            
            for case in self.cases:
                # 写入对象数量
                f.write(struct.pack('<I', len(case)))
                
                for name, data in case.items():
                    # 写入对象名
                    name_bytes = name.encode('utf-8')
                    f.write(struct.pack('<I', len(name_bytes)))
                    f.write(name_bytes)
                    
                    # 写入对象数据
                    f.write(struct.pack('<I', len(data)))
                    f.write(data)
        
        print(f"测试用例已保存到: {self.output_path}")
        print(f"  总计: {len(self.cases)} 个用例")
        
        # 显示文件大小
        size = os.path.getsize(self.output_path)
        print(f"  大小: {size} 字节 ({size / 1024:.2f} KB)")


def preview_case(objects: Dict[str, bytes], max_len: int = 50):
    """预览测试用例内容"""
    for name, data in objects.items():
        # 尝试解码为字符串
        try:
            # 尝试 UTF-16LE (WCHAR)
            text = data.decode('utf-16le').rstrip('\x00')
            if text.isprintable():
                preview = text[:max_len]
                if len(text) > max_len:
                    preview += "..."
                return f"{name} = \"{preview}\""
        except:
            pass
        
        try:
            # 尝试 UTF-8
            text = data.decode('utf-8').rstrip('\x00')
            if text.isprintable():
                preview = text[:max_len]
                if len(text) > max_len:
                    preview += "..."
                return f"{name} = \"{preview}\""
        except:
            pass
        
        # 显示十六进制
        hex_str = data[:16].hex()
        if len(data) > 16:
            hex_str += "..."
        return f"{name} = 0x{hex_str}"
    
    return "(empty)"


def main():
    parser = argparse.ArgumentParser(
        description="将 KLEE .ktest 文件转换为测试用例",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python ktest_to_cases.py klee-out-0/ -o test_cases.bin
  python ktest_to_cases.py klee-out-0/ -o test_cases.bin --preview
        """
    )
    parser.add_argument("klee_dir", help="KLEE 输出目录")
    parser.add_argument("-o", "--output", default="test_cases.bin", 
                       help="输出文件路径")
    parser.add_argument("--preview", action="store_true",
                       help="预览每个测试用例的内容")
    parser.add_argument("--dump-ktest-tool", default=None,
                       help="将 `ktest-tool <file.ktest>` 的输出保存到指定目录（用于排查格式差异）")
    
    args = parser.parse_args()
    
    klee_dir = Path(args.klee_dir)
    
    if not klee_dir.exists():
        print(f"错误: 目录不存在: {klee_dir}")
        return 1
    
    # 查找所有 .ktest 文件
    ktest_files = sorted(klee_dir.glob("*.ktest"))
    
    if not ktest_files:
        print(f"错误: 在 {klee_dir} 中没有找到 .ktest 文件")
        return 1
    
    print(f"找到 {len(ktest_files)} 个 .ktest 文件")
    print("")
    
    # 解析所有测试用例
    writer = TestCaseWriter(args.output)
    dump_dir = Path(args.dump_ktest_tool) if args.dump_ktest_tool else None
    if dump_dir:
        dump_dir.mkdir(parents=True, exist_ok=True)
    
    for i, ktest_file in enumerate(ktest_files, 1):
        print(f"[{i}/{len(ktest_files)}] 解析: {ktest_file.name}")
        
        # 如果需要 dump，则先抓一份 ktest-tool 默认输出（不影响解析逻辑）
        if dump_dir:
            try:
                res = subprocess.run(
                    ['ktest-tool', str(ktest_file)],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                base = ktest_file.name
                (dump_dir / f"{base}.stdout.txt").write_text(res.stdout, encoding='utf-8', errors='replace')
                (dump_dir / f"{base}.stderr.txt").write_text(res.stderr, encoding='utf-8', errors='replace')
                (dump_dir / f"{base}.exitcode.txt").write_text(str(res.returncode), encoding='utf-8')
            except FileNotFoundError:
                pass

        parser = KTestParser(str(ktest_file))
        objects = parser.parse()
        
        if objects:
            writer.add_case(objects)
            
            if args.preview:
                preview = preview_case(objects)
                print(f"  内容: {preview}")
        else:
            print(f"  警告: 无法解析")
        
        print("")
    
    # 写入文件
    writer.write()
    
    return 0


if __name__ == "__main__":
    exit(main())
