from pathlib import Path
p=Path(r'D:/wine/wine-master/oda_demo/runner/_ubuntu_out/pathcombinew/klee-out-0_run.stats')
data=p.read_bytes()
try:
    txt=data.decode('utf-8')
    print(txt)
except UnicodeDecodeError:
    print('not utf8, len',len(data))
