import sqlite3, json, sys
from pathlib import Path
p = Path('d:/wine/wine-master/oda_demo/_remote_out/pathcombinew_llm/klee-out-0/run.stats')
conn = sqlite3.connect(p)
c = conn.cursor()
cols = [r[1] for r in c.execute('PRAGMA table_info(stats)')]
rows = list(c.execute('select * from stats'))
print('rows', len(rows))
print(json.dumps(dict(zip(cols, rows[-1])) if rows else {}, indent=2))
conn.close()
