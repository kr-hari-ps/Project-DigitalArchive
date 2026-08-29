#!/usr/bin/env python3
import sqlite3, sys
db=sys.argv[1] if len(sys.argv)>1 else ""
con=sqlite3.connect(db)
for label,sql in [
("devices","SELECT COUNT(*) FROM devices"),
("files","SELECT COUNT(*) FROM files"),
("source_links","SELECT COUNT(*) FROM file_sources"),
("duplicate_groups","SELECT COUNT(*) FROM duplicate_groups"),
("KEEP_ONE","SELECT COUNT(*) FROM duplicate_groups WHERE decision='KEEP_ONE'"),
("REVIEW","SELECT COUNT(*) FROM duplicate_groups WHERE decision='REVIEW'")]:
    print(f"{label}: {con.execute(sql).fetchone()[0]}")
print("\nDuplicate groups:")
for r in con.execute("SELECT duplicate_group_id,decision,chosen_file_id,notes FROM duplicate_groups ORDER BY duplicate_group_id"):
    print(r)
con.close()
