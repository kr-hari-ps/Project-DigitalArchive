#!/usr/bin/env python3
import argparse, shutil, sqlite3
from pathlib import Path

MEDIA_BATCH = "NONDOC_20260820_202341"
MOVE_BATCH = "MEDIA_CANONICAL_20260823"
PROTECTED = (31, 83, 206)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--db", default=str(Path.home()/ "Master-Repository/.archive/catalog.db"))
    p.add_argument("--execute", action="store_true")
    a = p.parse_args()
    db = Path(a.db).expanduser().resolve()
    if not db.is_file():
        raise SystemExit(f"ERROR: missing database: {db}")

    backup = db.with_name(db.stem + "_before_media_reset_v1.db")
    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    ids = [r[0] for r in con.execute("""
        SELECT DISTINCT f.file_id
        FROM files f
        JOIN multi_media_assets mma
          ON mma.manual_canonical_path=f.canonical_path
         AND mma.batch_id=?
        WHERE mma.manual_canonical_path IS NOT NULL
          AND TRIM(mma.manual_canonical_path)<>''
          AND f.file_id NOT IN (?,?,?)
        ORDER BY f.file_id
    """, (MEDIA_BATCH, *PROTECTED))]

    print("="*72)
    print("MEDIA CATALOG RESET")
    print("="*72)
    print("MODE :", "EXECUTE" if a.execute else "DRY RUN")
    print("MEDIA FILE IDs :", len(ids))
    print("PROTECTED      :", PROTECTED)

    if len(ids) != 576:
        con.close()
        raise SystemExit(f"ABORT: expected 576 media-created file IDs, found {len(ids)}")

    qmarks=",".join("?"*len(ids))
    checks={}
    for name, table in [
        ("file_sources","file_sources"),
        ("copy_manifest","copy_manifest"),
        ("canonical_plan","canonical_plan"),
        ("file_xattrs","file_xattrs"),
        ("restore_preferences","restore_preferences"),
        ("deletion_events","deletion_events"),
        ("duplicate_members","duplicate_members"),
    ]:
        checks[name]=con.execute(
            f"SELECT COUNT(*) FROM {table} WHERE file_id IN ({qmarks})", ids
        ).fetchone()[0]
        print(f"{name:22}: {checks[name]}")

    expected = {
        "file_sources":576, "copy_manifest":576, "canonical_plan":0,
        "file_xattrs":0, "restore_preferences":0,
        "deletion_events":0, "duplicate_members":0
    }
    if checks != expected:
        con.close()
        raise SystemExit(f"ABORT: reference counts do not match expected: {checks}")

    if not a.execute:
        print("DRY RUN: no database changes.")
        con.close()
        return

    shutil.copy2(db, backup)
    print("Backup:", backup)

    con.execute("BEGIN")
    try:
        con.execute(f"DELETE FROM file_sources WHERE file_id IN ({qmarks})", ids)
        con.execute(f"DELETE FROM copy_manifest WHERE file_id IN ({qmarks})", ids)
        con.execute(f"DELETE FROM files WHERE file_id IN ({qmarks})", ids)
        con.execute("DELETE FROM media_canonical_move_manifest WHERE batch_id=?", (MOVE_BATCH,))
        con.execute("DELETE FROM media_physical_cleanup_manifest")
        con.execute("DELETE FROM media_manual_review_import")
        con.commit()
    except Exception:
        con.rollback()
        con.close()
        raise

    remaining = con.execute(f"SELECT COUNT(*) FROM files WHERE file_id IN ({qmarks})", ids).fetchone()[0]
    protected = con.execute("SELECT COUNT(*) FROM files WHERE file_id IN (?,?,?)", PROTECTED).fetchone()[0]
    move_rows = con.execute("SELECT COUNT(*) FROM media_canonical_move_manifest WHERE batch_id=?", (MOVE_BATCH,)).fetchone()[0]
    import_rows = con.execute("SELECT COUNT(*) FROM media_manual_review_import").fetchone()[0]
    cleanup_rows = con.execute("SELECT COUNT(*) FROM media_physical_cleanup_manifest").fetchone()[0]

    print("RESET COMPLETE")
    print("media-created files remaining :", remaining)
    print("protected files remaining     :", protected)
    print("move-manifest rows remaining  :", move_rows)
    print("manual-import rows remaining  :", import_rows)
    print("cleanup-manifest rows remaining:", cleanup_rows)

    if (remaining, protected, move_rows, import_rows, cleanup_rows) != (0,3,0,0,0):
        con.close()
        raise SystemExit("POST-RESET VERIFICATION FAILED")

    con.close()

if __name__ == "__main__":
    main()
