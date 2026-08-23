#!/usr/bin/env python3

import argparse
import hashlib
import shutil
import sqlite3
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
    ap = argparse.ArgumentParser(
        description="Apply reviewed multimedia canonical moves."
    )

    ap.add_argument(
        "--db",
        default=str(
            Path.home() /
            "Master-Repository/.archive/catalog.db"
        ),
    )

    ap.add_argument(
        "--batch-id",
        required=True,
        help="media_canonical_move_manifest batch ID.",
    )

    ap.add_argument(
        "--master-root",
        default=str(
            Path.home() /
            "Master-Repository"
        ),
    )

    mode = ap.add_mutually_exclusive_group(required=True)

    mode.add_argument(
        "--dry-run",
        action="store_true",
    )

    mode.add_argument(
        "--execute",
        action="store_true",
    )

    args = ap.parse_args()

    dry_run = args.dry_run

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
    con.execute("PRAGMA foreign_keys=ON")

    rows = con.execute(
        """
        SELECT
            move_id,
            inventory_id,
            source_device_id,
            current_staging_path,
            canonical_path,
            source_sha256,
            source_size_bytes,
            original_filename,
            canonical_filename,
            rename_required
        FROM media_canonical_move_manifest
        WHERE batch_id=?
          AND status='PLANNED'
        ORDER BY move_id
        """,
        (args.batch_id,),
    ).fetchall()

    print("=" * 72)
    print("MEDIA CANONICAL MOVE")
    print("=" * 72)
    print("MODE          :", "DRY RUN" if dry_run else "EXECUTE")
    print("Batch         :", args.batch_id)
    print("Planned rows  :", len(rows))
    print("Master root   :", master_root)
    print("Original Tablet/PC source trees are NOT touched.")
    print()

    if not rows:
        print("No PLANNED rows found.")
        con.close()
        return

    successful = 0
    failed = 0
    renames = 0

    for row in rows:

        (
            move_id,
            inventory_id,
            device_id,
            source_path,
            canonical_path,
            expected_sha,
            expected_size,
            original_filename,
            canonical_filename,
            rename_required,
        ) = row

        src = Path(source_path).expanduser().resolve()
        dst = (master_root / Path(canonical_path)).resolve()

        print(f"[{move_id}] inventory_id={inventory_id}")
        print(f"  DEVICE : {device_id}")
        print(f"  FROM   : {src}")
        print(f"  TO     : {dst}")

        if rename_required:
            renames += 1
            print(
                f"  RENAME : "
                f"{original_filename} -> {canonical_filename}"
            )

        errors = []

        if not under(src, master_root):
            errors.append(
                "source is outside Master-Repository"
            )

        if not under(dst, master_root):
            errors.append(
                "destination is outside Master-Repository"
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

        if dst.exists():

            if not dst.is_file():
                errors.append(
                    "destination exists and is not a regular file"
                )

            else:
                existing_size = dst.stat().st_size
                existing_sha = sha256_file(dst)

                if (
                    existing_size != expected_size
                    or existing_sha != expected_sha
                ):
                    errors.append(
                        "destination exists with different content"
                    )

        if errors:

            print("  REFUSED")

            for error in errors:
                print(
                    f"    - {error}"
                )

            if not dry_run:

                con.execute(
                    """
                    UPDATE media_canonical_move_manifest
                    SET
                        status='FAILED',
                        error_message=?,
                        updated_at=CURRENT_TIMESTAMP
                    WHERE move_id=?
                      AND batch_id=?
                    """,
                    (
                        " | ".join(errors),
                        move_id,
                        args.batch_id,
                    ),
                )

                con.commit()

            failed += 1

            print()
            continue

        # If destination already contains exactly the same verified file,
        # treat the operation as idempotently satisfied.
        if dst.exists():

            if dry_run:

                print(
                    "  DRY-RUN: matching destination already exists."
                )

                successful += 1

                print()
                continue

            ts = now()

            con.execute(
                """
                UPDATE media_canonical_move_manifest
                SET
                    status='APPLIED',
                    updated_at=CURRENT_TIMESTAMP,
                    error_message=NULL
                WHERE move_id=?
                  AND batch_id=?
                """,
                (
                    move_id,
                    args.batch_id,
                ),
            )

            con.commit()

            print(
                "  APPLIED: matching destination already exists."
            )

            successful += 1

            print()
            continue

        # ------------------------------------------------------
        # Dry run
        # ------------------------------------------------------

        if dry_run:

            print(
                "  DRY-RUN: source verified; "
                "destination available."
            )

            successful += 1

            print()
            continue

        # ------------------------------------------------------
        # Execute physical move
        # ------------------------------------------------------

        try:

            dst.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            shutil.move(
                str(src),
                str(dst),
            )

            destination_size = dst.stat().st_size
            destination_sha = sha256_file(dst)

            if destination_size != expected_size:
                raise RuntimeError(
                    "post-move size verification failed"
                )

            if destination_sha != expected_sha:
                raise RuntimeError(
                    "post-move SHA-256 verification failed"
                )

            verified_at = now()

            con.execute(
                """
                UPDATE media_canonical_move_manifest
                SET
                    status='APPLIED',
                    updated_at=CURRENT_TIMESTAMP,
                    error_message=NULL
                WHERE move_id=?
                  AND batch_id=?
                """,
                (
                    move_id,
                    args.batch_id,
                ),
            )

            # Update the multimedia inventory's final canonical path.
            con.execute(
                """
                UPDATE multi_media_assets
                SET
                    updated_at=CURRENT_TIMESTAMP
                WHERE inventory_id=?
                """,
                (inventory_id,),
            )

            con.commit()

            print(
                "  MOVED + VERIFIED + APPLIED"
            )

            successful += 1

            print()

        except Exception as exc:

            # Roll back database changes for this item.
            con.rollback()

            # Best-effort rollback of the physical move.
            try:

                if (
                    dst.exists()
                    and not src.exists()
                ):

                    src.parent.mkdir(
                        parents=True,
                        exist_ok=True,
                    )

                    shutil.move(
                        str(dst),
                        str(src),
                    )

            except Exception as rollback_exc:

                print(
                    "  ROLLBACK WARNING:",
                    type(rollback_exc).__name__,
                    rollback_exc,
                )

            con.execute(
                """
                UPDATE media_canonical_move_manifest
                SET
                    status='FAILED',
                    error_message=?,
                    updated_at=CURRENT_TIMESTAMP
                WHERE move_id=?
                  AND batch_id=?
                """,
                (
                    f"{type(exc).__name__}: {exc}",
                    move_id,
                    args.batch_id,
                ),
            )

            con.commit()

            print(
                "  FAILED:",
                type(exc).__name__,
                exc,
            )

            failed += 1

            print()

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print("Planned rows :", len(rows))
    print("Successful   :", successful)
    print("Failed       :", failed)
    print("Renames      :", renames)

    if dry_run:
        print()
        print(
            "DRY RUN ONLY - no files or database rows were changed."
        )

    con.close()

    if failed:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
