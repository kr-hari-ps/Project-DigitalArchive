#!/usr/bin/env python3
import sqlite3,sys
db=sys.argv[1] if len(sys.argv)>1 else str(__import__('pathlib').Path.home()/'Master-Repository/.archive/catalog.db')
con=sqlite3.connect(db)
for t in ['devices','files','file_sources','restore_preferences','duplicate_groups','duplicate_members','folders','copy_manifest','deletion_events','file_xattrs']:
    print(f'{t:22} {con.execute("SELECT COUNT(*) FROM "+t).fetchone()[0]}')
print('\nCopy manifest status:')
for s,n in con.execute('SELECT status,COUNT(*) FROM copy_manifest GROUP BY status ORDER BY status'):
    print(f'{s:12} {n}')
con.close()
