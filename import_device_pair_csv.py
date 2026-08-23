#!/usr/bin/env python3
import argparse, csv, sqlite3
from pathlib import Path

SCHEMA = """PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    device_name TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL,
    description TEXT,
    active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS files (
    file_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sha256 TEXT NOT NULL,
    master_path TEXT,
    filename TEXT NOT NULL,
    extension TEXT,
    size_bytes INTEGER NOT NULL,
    media_type TEXT,
    capture_date TEXT,
    created_date TEXT,
    modified_date TEXT,
    status TEXT NOT NULL DEFAULT 'MASTER',
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sha256, master_path)
);
CREATE TABLE IF NOT EXISTS file_sources (
    file_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    source_path TEXT,
    source_filename TEXT,
    source_size_bytes INTEGER,
    source_sha256 TEXT NOT NULL,
    source_modified_date TEXT,
    first_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(file_id, device_id, source_path),
    FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    FOREIGN KEY(device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS restore_preferences (
    file_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    restore_enabled INTEGER NOT NULL DEFAULT 1 CHECK(restore_enabled IN (0,1)),
    target_relative_path TEXT,
    notes TEXT,
    PRIMARY KEY(file_id, device_id),
    FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    FOREIGN KEY(device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS duplicate_groups (
    duplicate_group_id TEXT PRIMARY KEY,
    sha256 TEXT NOT NULL,
    decision TEXT NOT NULL DEFAULT 'REVIEW'
        CHECK(decision IN ('REVIEW','KEEP_ONE','KEEP_ALL','IGNORE')),
    chosen_file_id INTEGER,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(chosen_file_id) REFERENCES files(file_id)
);
CREATE TABLE IF NOT EXISTS duplicate_members (
    duplicate_group_id TEXT NOT NULL,
    file_id INTEGER NOT NULL,
    PRIMARY KEY(duplicate_group_id, file_id),
    FOREIGN KEY(duplicate_group_id) REFERENCES duplicate_groups(duplicate_group_id) ON DELETE CASCADE,
    FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS deletion_events (
    deletion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER,
    device_id TEXT NOT NULL,
    original_path TEXT,
    deleted_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bin_path TEXT,
    reason TEXT,
    sha256 TEXT,
    notes TEXT,
    FOREIGN KEY(file_id) REFERENCES files(file_id),
    FOREIGN KEY(device_id) REFERENCES devices(device_id)
);
CREATE TABLE IF NOT EXISTS file_xattrs (
    file_id INTEGER PRIMARY KEY,
    xattr_supported INTEGER NOT NULL DEFAULT 0 CHECK(xattr_supported IN (0,1)),
    xattr_applied INTEGER NOT NULL DEFAULT 0 CHECK(xattr_applied IN (0,1)),
    xattr_names TEXT,
    last_checked_at TEXT,
    FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE
);"""

def has_marker(path, marker):
    p = path.replace("\\", "/")
    return f"/{marker}/" in p or p.endswith(f"/{marker}") or p.startswith(f"{marker}/")

def device_id(label):
    return label.strip().upper().replace(" ", "_")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("db")
    ap.add_argument("label1")
    ap.add_argument("label2")
    a = ap.parse_args()

    csv_path, db_path = Path(a.csv), Path(a.db)
    if not csv_path.is_file(): raise SystemExit(f"CSV does not exist: {csv_path}")
    if not db_path.is_file(): raise SystemExit(f"Database does not exist: {db_path}")

    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys=ON")
    con.executescript(SCHEMA)

    d1, d2 = device_id(a.label1), device_id(a.label2)
    for did, name in ((d1,a.label1),(d2,a.label2)):
        con.execute("""INSERT INTO devices(device_id,device_name,device_type)
                       VALUES(?,?, 'SOURCE')
                       ON CONFLICT(device_id) DO UPDATE SET device_name=excluded.device_name""",
                    (did,name))

    with csv_path.open(newline="", encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))
    rows = [r for r in rows if r.get("source","").strip() in (a.label1, a.label2)]

    group_rows = {}
    for r in rows:
        g = r.get("duplicate_group","").strip()
        if g:
            group_rows.setdefault(g, []).append(r)

    file_ids = {}
    for r in rows:
        key = (r["sha256"].strip(), r["full_path"].strip())
        cur = con.execute("SELECT file_id FROM files WHERE sha256=? AND master_path=?", key)
        hit = cur.fetchone()
        if hit:
            fid = hit[0]
        else:
            p = Path(r["full_path"].strip())
            ext = r.get("extension","").strip().lower()
            cur = con.execute("""INSERT INTO files
                (sha256,master_path,filename,extension,size_bytes,status,notes)
                VALUES(?,?,?,?,?,'CATALOGED',?)""",
                (r["sha256"].strip(), str(p), r["filename"].strip(), ext,
                 int(r["size_bytes"]), "Imported from reviewed device-pair CSV."))
            fid = cur.lastrowid
        file_ids[key] = fid

        did = d1 if r["source"].strip() == a.label1 else d2
        con.execute("""INSERT OR REPLACE INTO file_sources
            (file_id,device_id,source_path,source_filename,source_size_bytes,source_sha256)
            VALUES(?,?,?,?,?,?)""",
            (fid,did,r["full_path"].strip(),r["filename"].strip(),
             int(r["size_bytes"]),r["sha256"].strip()))

    keep_one = review = groups = 0
    for gid, members in group_rows.items():
        groups += 1
        sha = members[0]["sha256"].strip()
        qualified = [r for r in members if has_marker(r["full_path"].strip(),"HKR")
                     or has_marker(r["full_path"].strip(),"SKP")]
        chosen = None
        note = "Exact duplicate; no HKR/SKP preference applied."
        decision = "REVIEW"
        if qualified:
            pc = [r for r in qualified if r["source"].strip() == a.label2]
            chosen = pc[0] if pc else qualified[0]
            decision = "KEEP_ONE"
            note = ("HKR/SKP rule: selected the only qualifying copy."
                    if len(qualified)==1 else
                    "HKR/SKP rule: both qualify; one copy selected deterministically. "
                    "Either qualifying copy is acceptable.")
        cur = con.execute("SELECT file_id FROM files WHERE sha256=? AND master_path=?",
                          (chosen["sha256"].strip(),chosen["full_path"].strip())) if chosen else None
        chosen_id = cur.fetchone()[0] if cur else None
        con.execute("""INSERT INTO duplicate_groups
            (duplicate_group_id,sha256,decision,chosen_file_id,notes)
            VALUES(?,?,?,?,?)
            ON CONFLICT(duplicate_group_id) DO UPDATE SET
              sha256=excluded.sha256, decision=excluded.decision,
              chosen_file_id=excluded.chosen_file_id, notes=excluded.notes""",
            (gid,sha,decision,chosen_id,note))
        con.execute("DELETE FROM duplicate_members WHERE duplicate_group_id=?", (gid,))
        for r in members:
            fid = file_ids[(r["sha256"].strip(),r["full_path"].strip())]
            con.execute("INSERT OR IGNORE INTO duplicate_members VALUES(?,?)",(gid,fid))
        keep_one += decision == "KEEP_ONE"
        review += decision == "REVIEW"

    con.commit()
    print(f"CSV rows imported       : {len(rows)}")
    print(f"File records            : {con.execute('SELECT COUNT(*) FROM files').fetchone()[0]}")
    print(f"Source links            : {con.execute('SELECT COUNT(*) FROM file_sources').fetchone()[0]}")
    print(f"Duplicate groups        : {groups}")
    print(f"KEEP_ONE groups         : {keep_one}")
    print(f"REVIEW groups           : {review}")
    print("No source files were moved, renamed, deleted, or modified.")
    con.close()

if __name__ == "__main__":
    main()
