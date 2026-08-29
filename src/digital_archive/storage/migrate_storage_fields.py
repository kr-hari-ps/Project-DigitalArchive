#!/usr/bin/env python3
import argparse
import sqlite3
from pathlib import Path

COLUMNS = {
    "canonical_path": "TEXT",
    "storage_state": "TEXT NOT NULL DEFAULT 'IN_MASTER' CHECK(storage_state IN ('IN_MASTER','MOVED_EXTERNAL','IN_BIN','MISSING'))",
    "external_device_id": "TEXT",
    "external_path": "TEXT",
    "moved_out_at": "TEXT",
    "storage_move_reason": "TEXT",
}

def column_exists(con, table, column):
    return con.execute(
        "SELECT 1 FROM pragma_table_info(?) WHERE name=?",
        (table, column),
    ).fetchone() is not None

def main():
    ap = argparse.ArgumentParser(
        description="Add canonical path and storage-state tracking to archive catalog."
    )
    ap.add_argument(
        "db",
        nargs="?",
        default=str(Path.home() / "Master-Repository/.archive/catalog.db"),
    )
    args = ap.parse_args()

    db = Path(args.db).expanduser().resolve()
    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    for column, definition in COLUMNS.items():
        if not column_exists(con, "files", column):
            con.execute(f"ALTER TABLE files ADD COLUMN {column} {definition}")
            print(f"Added files.{column}")
        else:
            print(f"Already exists: files.{column}")

    # Backfill canonical_path from the current staging master path if empty.
    # This does not alter the physical files.
    con.execute("""
        UPDATE files
        SET canonical_path = master_path
        WHERE canonical_path IS NULL OR canonical_path = ''
    """)

    # Existing cataloged/copied files are currently physically in Master-Repository.
    con.execute("""
        UPDATE files
        SET storage_state = 'IN_MASTER'
        WHERE storage_state IS NULL OR storage_state = ''
    """)

    con.commit()

    print()
    print("Catalog migration completed.")
    print("No source or master files were moved or deleted.")

    for column in COLUMNS:
        row = con.execute(
            "SELECT COUNT(*) FROM files WHERE " + column + " IS NOT NULL"
        ).fetchone()
        print(f"{column:24} populated={row[0]}")

    con.close()

if __name__ == "__main__":
    main()
