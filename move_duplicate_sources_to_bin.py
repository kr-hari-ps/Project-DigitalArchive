#!/usr/bin/env python3
import argparse
import hashlib
import sqlite3
import shutil
from datetime import datetime
from pathlib import Path


def sha256_file(path, chunk=1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            data = f.read(chunk)
            if not data:
                break
            h.update(data)
    return h.hexdigest()


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def unique_bin_path(bin_root, device_id, source_path):
    source = Path(source_path)
    device_dir = bin_root / f"{device_id}_deleted"
    device_dir.mkdir(parents=True, exist_ok=True)

    candidate = device_dir / source.name
    index = 1

    while candidate.exists():
        candidate = device_dir / f"{source.stem}__{index}{source.suffix}"
        index += 1

    return candidate


def get_candidates(con):
    return con.execute(
        """
        SELECT
            f.file_id,
            f.filename,
            f.sha256,
            f.size_bytes,
            fs.device_id,
            fs.source_path,
            dg.duplicate_group_id,
            dg.chosen_file_id,
            dg.decision,
            chosen.file_id AS chosen_file_id_check,
            cm.destination_path AS verified_master_path,
            cm.destination_sha256 AS verified_master_sha256,
            cm.destination_size_bytes AS verified_master_size,
            cm.status AS master_copy_status
        FROM files f
        JOIN file_sources fs
            ON fs.file_id = f.file_id
        JOIN duplicate_members dm
            ON dm.file_id = f.file_id
        JOIN duplicate_groups dg
            ON dg.duplicate_group_id = dm.duplicate_group_id
        JOIN files chosen
            ON chosen.file_id = dg.chosen_file_id
        JOIN copy_manifest cm
            ON cm.file_id = chosen.file_id
           AND cm.status = 'VERIFIED'
        WHERE dg.decision = 'KEEP_ONE'
          AND f.file_id <> dg.chosen_file_id
        ORDER BY dg.duplicate_group_id, fs.device_id, fs.source_path
        """
    ).fetchall()


def main():
    ap = argparse.ArgumentParser(
        description="Move non-chosen exact duplicate source files to the device deletion bin."
    )

    ap.add_argument(
        "--db",
        default=str(
            Path.home() / "Master-Repository/.archive/catalog.db"
        ),
    )

    ap.add_argument(
        "--bin-root",
        default=str(
            Path.home() / "Master-Repository/_Bin"
        ),
    )

    mode = ap.add_mutually_exclusive_group()

    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate candidates without moving anything.",
    )

    mode.add_argument(
        "--execute",
        action="store_true",
        help="Move validated duplicate source files to the bin.",
    )

    args = ap.parse_args()

    dry_run = not args.execute

    db = Path(args.db).expanduser().resolve()
    bin_root = Path(args.bin_root).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(
            f"ERROR: database does not exist: {db}"
        )

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    rows = get_candidates(con)

    print("=" * 72)
    print("DUPLICATE SOURCE CLEANUP")
    print("=" * 72)
    print("MODE       :", "DRY RUN" if dry_run else "EXECUTE")
    print("Candidates :", len(rows))
    print("Bin root   :", bin_root)
    print()
    print(
        "Only non-chosen exact duplicates from KEEP_ONE groups are eligible."
    )
    print()

    validated = 0
    moved = 0
    failed = 0

    for row in rows:
        (
            file_id,
            filename,
            expected_sha,
            expected_size,
            device_id,
            source_path,
            group_id,
            chosen_file_id,
            decision,
            chosen_file_id_check,
            verified_master_path,
            verified_master_sha,
            verified_master_size,
            master_copy_status,
        ) = row

        src = Path(source_path).expanduser().resolve()

        print(f"[{group_id}] {filename}")
        print(f"  DEVICE : {device_id}")
        print(f"  SOURCE : {src}")
        print(f"  MASTER : {verified_master_path}")

        errors = []

        if decision != "KEEP_ONE":
            errors.append(
                f"duplicate group decision is {decision}"
            )

        if file_id == chosen_file_id:
            errors.append(
                "candidate is the chosen file"
            )

        if not src.is_file():
            errors.append(
                "source file does not exist"
            )
        else:
            actual_size = src.stat().st_size

            if actual_size != expected_size:
                errors.append(
                    f"source size mismatch "
                    f"(catalog={expected_size}, actual={actual_size})"
                )

            actual_sha = sha256_file(src)

            if actual_sha != expected_sha:
                errors.append(
                    "source SHA-256 mismatch"
                )

        if master_copy_status != "VERIFIED":
            errors.append(
                "chosen master copy is not VERIFIED"
            )

        if not verified_master_path:
            errors.append(
                "chosen master destination is missing"
            )
        else:
            master = Path(verified_master_path)

            if not master.is_file():
                errors.append(
                    "chosen master file does not exist"
                )
            else:
                master_size = master.stat().st_size
                master_sha = sha256_file(master)

                if master_size != expected_size:
                    errors.append(
                        "chosen master size does not match duplicate source"
                    )

                if master_sha != expected_sha:
                    errors.append(
                        "chosen master SHA-256 does not match duplicate source"
                    )

        if errors:
            print("  REFUSED")
            for error in errors:
                print(f"    - {error}")

            failed += 1
            print()
            continue

        validated += 1

        destination = unique_bin_path(
            bin_root,
            device_id,
            source_path,
        )

        print(f"  BIN    : {destination}")

        if dry_run:
            print("  DRY-RUN: validated; no move performed.")
            print()
            continue

        try:
            destination.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            shutil.move(
                str(src),
                str(destination),
            )

            # Verify the file is intact in the bin.
            moved_size = destination.stat().st_size
            moved_sha = sha256_file(destination)

            if (
                moved_size != expected_size
                or moved_sha != expected_sha
            ):
                raise RuntimeError(
                    "Moved bin copy failed SHA-256/size verification."
                )

            ts = now()

            con.execute(
                """
                INSERT INTO deletion_events(
                    file_id,
                    device_id,
                    original_path,
                    deleted_at,
                    bin_path,
                    reason,
                    sha256,
                    notes
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    file_id,
                    device_id,
                    source_path,
                    ts,
                    str(destination),
                    "EXACT_DUPLICATE_NON_CHOSEN",
                    expected_sha,
                    (
                        f"Moved to device deletion bin after verified "
                        f"canonical master copy; duplicate group={group_id}."
                    ),
                ),
            )

            con.execute(
                """
                UPDATE files
                SET
                    storage_state='IN_BIN',
                    updated_at=CURRENT_TIMESTAMP
                WHERE file_id=?
                """,
                (file_id,),
            )

            con.commit()

            moved += 1

            print(
                "  MOVED + VERIFIED + CATALOGED"
            )
            print()

        except Exception as exc:
            con.rollback()

            failed += 1

            print(
                "  FAILED:",
                type(exc).__name__,
                exc,
            )
            print()

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print("Candidates :", len(rows))
    print("Validated  :", validated)
    print("Moved      :", moved)
    print("Failed     :", failed)

    if dry_run:
        print()
        print(
            "DRY RUN ONLY - no files or database records were changed."
        )

    con.close()

    if failed:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
