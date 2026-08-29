#!/usr/bin/env python3
"""
Execute the planned physical master copy.

Safety:
- Reads only PLANNED rows from copy_manifest.
- Does not delete, rename, or modify source files.
- Verifies source size and SHA-256 before copy.
- Copies with shutil.copy2() to preserve timestamps where possible.
- Verifies destination size and SHA-256 after copy.
- Marks manifest VERIFIED only after a successful match.
- Records folder metadata and optional xattrs.
"""

import argparse
import hashlib
import os
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path


def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def apply_file_xattrs(path, file_id, device_ids, sha256):
    """
    Optional Linux filesystem metadata.
    Returns (supported, applied, names).
    SQLite remains authoritative.
    """
    attrs = {
        "user.archive.file_id": str(file_id),
        "user.archive.device_map": ",".join(sorted(set(device_ids))),
        "user.archive.sha256": sha256,
    }

    supported = False
    applied = []
    try:
        # A harmless probe: listxattr is available on Linux for xattr-capable FS.
        os.listxattr(path)
        supported = True
    except (AttributeError, OSError):
        return False, False, ""

    for name, value in attrs.items():
        try:
            os.setxattr(path, name, value.encode())
            applied.append(name)
        except (OSError, AttributeError):
            pass

    return supported, bool(applied), ",".join(applied)


def ensure_folder_rows(con, destination):
    """
    Ensure folders table contains each directory in the path.
    Returns nothing; metadata is intentionally minimal at this stage.
    """
    destination = Path(destination)
    folders = list(destination.parents)[::-1]
    # Parents outside the master root may be included by caller filtering.
    for folder in folders:
        folder_str = str(folder)
        name = folder.name
        parent = str(folder.parent) if folder.parent != folder else None
        con.execute("""
            INSERT INTO folders(master_path, folder_name, parent_path, folder_type, description)
            VALUES (?, ?, ?, 'STAGING', NULL)
            ON CONFLICT(master_path) DO NOTHING
        """, (folder_str, name, parent))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--db",
        default=str(Path.home() / "Master-Repository/.archive/catalog.db"),
    )
    ap.add_argument(
        "--master-root",
        default=str(Path.home() / "Master-Repository"),
    )
    ap.add_argument(
        "--device-specific-only",
        action="store_true",
        help="Only copy rows from the selected device IDs.",
    )
    ap.add_argument(
        "--device",
        action="append",
        default=[],
        help="Device ID to include; can be repeated.",
    )
    ap.add_argument(
        "--resume",
        action="store_true",
        help="Process remaining PLANNED rows after previous failures.",
    )
    args = ap.parse_args()

    db = Path(args.db).expanduser().resolve()
    master_root = Path(args.master_root).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")

    master_root.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys = ON")

    sql = """
        SELECT
            cm.manifest_id,
            cm.file_id,
            cm.source_device_id,
            cm.source_path,
            cm.destination_path,
            cm.source_sha256,
            cm.source_size_bytes,
            f.filename
        FROM copy_manifest cm
        JOIN files f ON f.file_id = cm.file_id
        WHERE cm.status = 'PLANNED'
    """
    params = []

    if args.device:
        placeholders = ",".join("?" for _ in args.device)
        sql += f" AND cm.source_device_id IN ({placeholders})"
        params.extend([d.upper() for d in args.device])

    sql += " ORDER BY cm.destination_path"

    rows = con.execute(sql, params).fetchall()

    if not rows:
        print("No PLANNED rows found.")
        con.close()
        return

    totals = {
        "planned": len(rows),
        "verified": 0,
        "failed": 0,
        "skipped_existing_verified": 0,
    }

    print("MODE                : PHYSICAL COPY + VERIFICATION")
    print("Database            :", db)
    print("Master root         :", master_root)
    print("Rows to process     :", len(rows))
    print("Source files        : NEVER modified")
    print()

    for row in rows:
        (
            manifest_id,
            file_id,
            source_device_id,
            source_path,
            destination_path,
            source_sha,
            source_size,
            filename,
        ) = row

        src = Path(source_path).expanduser()
        dst = Path(destination_path).expanduser()

        print(f"[{manifest_id}] {filename}")

        # Safety: source must be a regular file.
        if not src.is_file():
            err = f"Source file missing/not regular: {src}"
            con.execute("""
                UPDATE copy_manifest
                SET status='FAILED', error_message=?, notes=?
                WHERE manifest_id=?
            """, (err, "Source validation failed before copy.", manifest_id))
            con.commit()
            totals["failed"] += 1
            print("  FAILED:", err)
            continue

        actual_source_size = src.stat().st_size
        if actual_source_size != source_size:
            err = (
                f"Source size mismatch: catalog={source_size}, "
                f"actual={actual_source_size}"
            )
            con.execute("""
                UPDATE copy_manifest
                SET status='FAILED', error_message=?, notes=?
                WHERE manifest_id=?
            """, (err, "Source validation failed before copy.", manifest_id))
            con.commit()
            totals["failed"] += 1
            print("  FAILED:", err)
            continue

        actual_source_sha = sha256_file(src)
        if actual_source_sha != source_sha:
            err = (
                f"Source SHA-256 mismatch: catalog={source_sha}, "
                f"actual={actual_source_sha}"
            )
            con.execute("""
                UPDATE copy_manifest
                SET status='FAILED', error_message=?, notes=?
                WHERE manifest_id=?
            """, (err, "Source validation failed before copy.", manifest_id))
            con.commit()
            totals["failed"] += 1
            print("  FAILED:", err)
            continue

        # Prevent accidental overwrite of a different file at destination.
        if dst.exists():
            if not dst.is_file():
                err = f"Destination exists but is not a regular file: {dst}"
                con.execute("""
                    UPDATE copy_manifest
                    SET status='FAILED', error_message=?, notes=?
                    WHERE manifest_id=?
                """, (err, "Destination safety check failed.", manifest_id))
                con.commit()
                totals["failed"] += 1
                print("  FAILED:", err)
                continue

            existing_sha = sha256_file(dst)
            if existing_sha == source_sha and dst.stat().st_size == source_size:
                # Already correct; treat as verified without overwriting.
                copied_at = utc_now()
                con.execute("""
                    UPDATE copy_manifest
                    SET destination_sha256=?,
                        destination_size_bytes=?,
                        copied_at=COALESCE(copied_at, ?),
                        verified_at=?,
                        status='VERIFIED',
                        verification_method='EXISTING_DESTINATION_SHA256',
                        error_message=NULL,
                        notes='Destination already matched source; no overwrite performed.'
                    WHERE manifest_id=?
                """, (existing_sha, dst.stat().st_size, copied_at, copied_at, manifest_id))
                con.commit()

                try:
                    os.makedirs(dst.parent, exist_ok=True)
                    ensure_folder_rows(con, dst.parent)
                    con.commit()
                except Exception:
                    pass

                totals["verified"] += 1
                totals["skipped_existing_verified"] += 1
                print("  VERIFIED (existing destination matches)")
                continue

            err = f"Destination collision with different content: {dst}"
            con.execute("""
                UPDATE copy_manifest
                SET status='FAILED', error_message=?, notes=?
                WHERE manifest_id=?
            """, (err, "Destination safety check failed; no overwrite performed.", manifest_id))
            con.commit()
            totals["failed"] += 1
            print("  FAILED:", err)
            continue

        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            copied_at = utc_now()

            actual_dest_size = dst.stat().st_size
            actual_dest_sha = sha256_file(dst)

            if actual_dest_size != source_size or actual_dest_sha != source_sha:
                err = (
                    f"Destination verification failed: "
                    f"size {actual_dest_size}/{source_size}, "
                    f"sha256 {actual_dest_sha}/{source_sha}"
                )
                con.execute("""
                    UPDATE copy_manifest
                    SET status='FAILED',
                        destination_sha256=?,
                        destination_size_bytes=?,
                        copied_at=?,
                        error_message=?,
                        notes=?
                    WHERE manifest_id=?
                """, (
                    actual_dest_sha, actual_dest_size, copied_at,
                    err, "Copy completed but verification failed.", manifest_id
                ))
                con.commit()
                totals["failed"] += 1
                print("  FAILED:", err)
                continue

            # Collect source-device metadata for the file.
            device_rows = con.execute("""
                SELECT DISTINCT device_id
                FROM file_sources
                WHERE file_id=?
                ORDER BY device_id
            """, (file_id,)).fetchall()
            device_ids = [r[0] for r in device_rows]

            x_supported, x_applied, x_names = apply_file_xattrs(
                dst, file_id, device_ids, source_sha
            )

            con.execute("""
                INSERT INTO folders(
                    master_path, folder_name, parent_path,
                    folder_type, description, device_summary
                )
                VALUES (?, ?, ?, 'STAGING', NULL, ?)
                ON CONFLICT(master_path) DO UPDATE SET
                    device_summary=excluded.device_summary,
                    updated_at=CURRENT_TIMESTAMP
            """, (
                str(dst.parent),
                dst.parent.name,
                str(dst.parent.parent) if dst.parent != dst.parent.parent else None,
                ",".join(device_ids),
            ))

            # Add/update all parent folders beneath the master root.
            current = dst.parent
            parents = []
            while current >= master_root and current != master_root:
                parents.append(current)
                current = current.parent
            for folder in reversed(parents):
                con.execute("""
                    INSERT INTO folders(
                        master_path, folder_name, parent_path,
                        folder_type, device_summary
                    )
                    VALUES (?, ?, ?, 'STAGING', ?)
                    ON CONFLICT(master_path) DO UPDATE SET
                        device_summary=excluded.device_summary,
                        updated_at=CURRENT_TIMESTAMP
                """, (
                    str(folder),
                    folder.name,
                    str(folder.parent),
                    ",".join(device_ids),
                ))

            con.execute("""
                INSERT INTO file_xattrs(
                    file_id, xattr_supported, xattr_applied,
                    xattr_names, last_checked_at
                )
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(file_id) DO UPDATE SET
                    xattr_supported=excluded.xattr_supported,
                    xattr_applied=excluded.xattr_applied,
                    xattr_names=excluded.xattr_names,
                    last_checked_at=excluded.last_checked_at
            """, (
                file_id,
                int(x_supported),
                int(x_applied),
                x_names,
                utc_now(),
            ))

            con.execute("""
                UPDATE copy_manifest
                SET destination_sha256=?,
                    destination_size_bytes=?,
                    copied_at=?,
                    verified_at=?,
                    status='VERIFIED',
                    verification_method='SHA256_SOURCE_AND_DESTINATION',
                    error_message=NULL,
                    notes=?
                WHERE manifest_id=?
            """, (
                actual_dest_sha,
                actual_dest_size,
                copied_at,
                utc_now(),
                "Copied and verified. Optional filesystem xattrs applied where supported.",
                manifest_id,
            ))

            con.execute("""
                UPDATE files
                SET master_path=?,
                    status='MASTER',
                    updated_at=CURRENT_TIMESTAMP
                WHERE file_id=?
            """, (str(dst), file_id))

            con.commit()

            totals["verified"] += 1
            print("  VERIFIED")

        except Exception as exc:
            con.rollback()
            err = f"{type(exc).__name__}: {exc}"
            con.execute("""
                UPDATE copy_manifest
                SET status='FAILED', error_message=?, notes=?
                WHERE manifest_id=?
            """, (err, "Unexpected exception during copy/verification.", manifest_id))
            con.commit()
            totals["failed"] += 1
            print("  FAILED:", err)

    print()
    print("SUMMARY")
    print("-------")
    for k, v in totals.items():
        print(f"{k:28}: {v}")

    if totals["failed"]:
        print()
        print("WARNING: One or more files failed. Review copy_manifest before continuing.")
        con.close()
        raise SystemExit(2)

    con.close()


if __name__ == "__main__":
    main()
