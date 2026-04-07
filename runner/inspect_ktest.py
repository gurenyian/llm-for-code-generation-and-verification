import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parents[1]))  # add oda_demo root
from klee.ktest_to_cases import KTestParser

klee_dir=Path(r'd:/wine/wine-master/oda_demo/runner/_ubuntu_out/pathcombinew/klee-out-0')
for p in sorted(klee_dir.glob('test*.ktest')):
    objs=KTestParser(str(p)).parse()
    print(p.name, list(objs.keys()))
    break
