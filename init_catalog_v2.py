#!/usr/bin/env python3
import sqlite3,sys
from pathlib import Path
db=Path(sys.argv[1] if len(sys.argv)>1 else Path.home()/'.archive/catalog.db').expanduser()
if db.parent.name!='.archive': db.parent.mkdir(parents=True,exist_ok=True)
else: db.parent.mkdir(parents=True,exist_ok=True)
con=sqlite3.connect(db); con.execute('PRAGMA foreign_keys=ON')
con.executescript(Path(__file__).with_name('schema.sql').read_text())
con.commit()
print('Catalog DB:',db)
print('Schema updated successfully')
print('New tables: folders, copy_manifest')
con.close()
