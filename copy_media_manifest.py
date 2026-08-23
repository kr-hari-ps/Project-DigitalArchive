#!/usr/bin/env python3

import argparse
import hashlib
import sqlite3
import shutil
from datetime import datetime
from pathlib import Path


def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()

    with open(path, "rb") as f:
        while True:
            data = f.read(chunk_size)
            if not data:
                break
            h.update(data)

    return h.hexdigest()


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def under(path, root):
    try:
        Path(path).resolve().relative_to(Path(root).resolve())
        return True
    except ValueError:
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Copy and verify planned multimedia staging files."
    )

    parser.add_argument(
        "--db",
        default=str(
            Path.home() /
            "Master-Repository/.archive/catalog.db"
        ),
    )

    parser.add_argument(
        "--batch-id",
        required=True,
        help="media_copy_manifest batch ID",
    )

    parser.add_argument(
        "--master-root",
        default=str(
            Path.home() /
            "Master-Repository"
        ),
    )

    mode = parser.add_mutually_exclusive_group()

    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate all planned rows without copying.",
    )

    mode.add_argument(
        "--execute",
        action="store_true",
        help="Perform physical copy and verification.",
    )

    args = parser.parse_args()

    dry_run = not args.execute

    db = Path(args.db).expanduser().resolve()
    master_root = Path(args.master_root).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(
            f"ERROR: database does not exist: {db}"
        )

    if not master_root.is_dir():
        raise SystemExit(
            f"ERROR: master root does not exist: {master_root}"
        )

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys = ON")

    rows = con.execute(
        """
        SELECT
            manifest_id,
            inventory_id,
            source_device_id,
            source_path,
            destination_path,
            source_sha256,
            source_size_bytes,
            category
        FROM media_copy_manifest
        WHERE batch_id=?
          AND status='PLANNED'
        ORDER BY manifest_id
        """,
        (args.batch_id,),
    ).fetchall()

    print("=" * 72)
    print("MULTIMEDIA PHYSICAL COPY")
    print("=" * 72)
    print("MODE        :", "DRY RUN" if dry_run else "EXECUTE")
    print("Batch       :", args.batch_id)
    print("Rows        :", len(rows))
    print("Master root :", master_root)
    print("Source files: NEVER modified")
    print()

    if not rows:
        print(
            "No PLANNED rows found for this manifest batch."
        )
        con.close()
        return

    successful = 0
    failed = 0

    for (
        manifest_id,
        inventory_id,
        device_id,
        source_path,
        destination_path,
        expected_sha,
        expected_size,
        category,
    ) in rows:

        src = Path(source_path).expanduser().resolve()
        dst = Path(destination_path).expanduser().resolve()

        print(
            f"[{manifest_id}] "
            f"{category} | inventory_id={inventory_id}"
        )
        print(
            f"  SOURCE: {src}"
        )
        print(
            f"  DEST  : {dst}"
        )

        # ------------------------------------------------------
        # Safety checks
        # ------------------------------------------------------

        if not src.is_file():
            print(
                "  REFUSED: source file does not exist."
            )
            failed += 1
            print()
            continue

        if not under(dst, master_root):
            print(
                "  REFUSED: destination is outside Master-Repository."
            )
            failed += 1
            print()
            continue

        actual_size = src.stat().st_size

        if actual_size != expected_size:
            print(
                "  REFUSED: source size mismatch "
                f"(catalog={expected_size}, actual={actual_size})."
            )
            failed += 1
            print()
            continue

        actual_sha = sha256_file(src)

        if actual_sha != expected_sha:
            print(
                "  REFUSED: source SHA-256 mismatch."
            )
            failed += 1
            print()
            continue

        # ------------------------------------------------------
        # Existing destination
        # ------------------------------------------------------

        if dst.exists():

            if not dst.is_file():
                print(
                    "  REFUSED: destination exists but "
                    "is not a regular file."
                )
                failed += 1
                print()
                continue

            existing_size = dst.stat().st_size
            existing_sha = sha256_file(dst)

            if (
                existing_size == expected_size
                and existing_sha == expected_sha
            ):
                if not dry_run:
                    ts = now()

                    con.execute(
                        """
                        UPDATE media_copy_manifest
                        SET
                            destination_sha256=?,
                            destination_size_bytes=?,
                            copied_at=COALESCE(copied_at, ?),
                            verified_at=?,
                            status='VERIFIED',
                            verification_method='SHA256_EXISTING_DESTINATION',
                            error_message=NULL,
                            updated_at=CURRENT_TIMESTAMP
                        WHERE manifest_id=?
                        """,
                        (
                            existing_sha,
                            existing_size,
                            ts,
                            ts,
                            manifest_id,
                        ),
                    )

                    con.commit()

                print(
                    "  VERIFIED: matching destination already exists."
                )
                successful += 1
                print()
                continue

            print(
                "  REFUSED: destination collision with different content."
            )
            failed += 1
            print()
            continue

        # ------------------------------------------------------
        # Dry run
        # ------------------------------------------------------

        if dry_run:
            print(
                "  DRY-RUN: source verified; destination available."
            )
            successful += 1
            print()
            continue

        # ------------------------------------------------------
        # Copy
        # ------------------------------------------------------

        try:
            dst.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            shutil.copy2(
                src,
                dst,
            )

            copied_at = now()

            destination_size = dst.stat().st_size
            destination_sha = sha256_file(dst)

            if destination_size != expected_size:
                raise RuntimeError(
                    "Destination size verification failed."
                )

            if destination_sha != expected_sha:
                raise RuntimeError(
                    "Destination SHA-256 verification failed."
                )

            verified_at = now()

            con.execute(
                """
                UPDATE media_copy_manifest
                SET
                    destination_sha256=?,
                    destination_size_bytes=?,
                    copied_at=?,
                    verified_at=?,
                    status='VERIFIED',
                    verification_method='SHA256_SOURCE_AND_DESTINATION',
                    error_message=NULL,
                    updated_at=CURRENT_TIMESTAMP
                WHERE manifest_id=?
                """,
                (
                    destination_sha,
                    destination_size,
                    copied_at,
                    verified_at,
                    manifest_id,
                ),
            )

            con.commit()

            print(
                "  COPIED + VERIFIED"
            )

            successful += 1
            print()

        except Exception as exc:

            con.rollback()

            failed += 1

            # Best effort cleanup of an incomplete destination.
            try:
                if dst.exists() and dst.is_file():
                    dst.unlink()
            except OSError:
                pass

            con.execute(
                """
                UPDATE media_copy_manifest
                SET
                    status='FAILED',
                    error_message=?,
                    updated_at=CURRENT_TIMESTAMP
                WHERE manifest_id=?
                """,
                (
                    f"{type(exc).__name__}: {exc}",
                    manifest_id,
                ),
            )

            con.commit()

            print(
                "  FAILED:",
                type(exc).__name__,
                exc,
            )
            print()

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print("Rows processed :", len(rows))
    print("Successful     :", successful)
    print("Failed         :", failed)

    if dry_run:
        print()
        print(
            "DRY RUN ONLY - no files were copied."
        )

    con.close()

    if failed:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
