#!/usr/bin/env python3
import argparse
import sqlite3
from pathlib import Path

COLUMNS = {
    "manual_canonical_path": "TEXT",
    "manual_category": "TEXT",
    "manual_notes": "TEXT",
}

def main():
    parser = argparse.ArgumentParser(
        description="Add manual classification fields to canonical_plan."
    )
    parser.add_argument(
        "db",
        nargs="?",
        default=str(Path.home() / "Master-Repository/.archive/catalog.db"),
    )
    args = parser.parse_args()

    db = Path(args.db).expanduser().resolve()
    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    existing = {
        row[1] for row in con.execute("PRAGMA table_info(canonical_plan)")
    }

    for column, definition in COLUMNS.items():
        if column in existing:
            print(f"Already exists: canonical_plan.{column}")
        else:
            con.execute(
                f"ALTER TABLE canonical_plan ADD COLUMN {column} {definition}"
            )
            print(f"Added: canonical_plan.{column}")

    con.commit()
    print("\nMigration complete.")
    print("No source/master files were modified.")
    con.close()

if __name__ == "__main__":
    main()
