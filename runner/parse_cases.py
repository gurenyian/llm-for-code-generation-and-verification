import struct
from pathlib import Path
p=Path(r'd:/wine/wine-master/oda_demo/runner/_ubuntu_out/pathcombinew/test_cases.bin')
data=p.read_bytes()
def u32(b,off): return struct.unpack_from('<I',b,off)[0]
off=0
case_cnt=u32(data,off); off+=4
print('cases',case_cnt)
for ci in range(case_cnt):
    obj_cnt=u32(data,off); off+=4
    names=[]
    objs={}
    for _ in range(obj_cnt):
        nlen=u32(data,off); off+=4
        name=data[off:off+nlen].decode('utf-8'); off+=nlen
        dlen=u32(data,off); off+=4
        d=data[off:off+dlen]; off+=dlen
        names.append((name,dlen))
        objs[name]=d
    print('case',ci+1,'objs',names)
    if ci==0:
        for k,v in objs.items():
            print(' ',k, v[:32].hex())
    break
