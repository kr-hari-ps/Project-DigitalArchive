#!/usr/bin/env python3

import argparse
import csv
import hashlib
import sqlite3
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path


DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"
DEFAULT_MASTER_ROOT = Path.home() / "Master-Repository"
DEFAULT_MANIFEST = (
    Path.home()
    / "my_scripts/digital_archive/PHONE_A73_physical_copy_manifest.csv"
)

BATCH_ID = "NONDOC_20260827_PHONE1_A73"
DEVICE_ID = "PHONE1_A73"


def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()

    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            h.update(chunk)

    return h.hexdigest()


def extension(filename):
    if "." not in filename or filename.startswith("."):
        return None
    return filename.rsplit(".", 1)[1].lower()


def media_type(category, filename):
    category = (category or "").strip().upper()
    ext = (extension(filename) or "").lower()

    if category.startswith("PHOTO") or category in {
        "IMAGE",
        "PICTURE",
        "PICTURES",
        "ICON",
        "PHOTO_ID",
        "PHOTO_ICONS",
    }:
        return "image"

    if category in {
        "MUSIC",
        "MUSIC_VEDIC",
        "RINGTONE",
        "AUDIO",
        "RECORDING",
    }:
        return "audio"

    if category in {"VIDEO", "MOVIE", "MOVIES"}:
        return "video"

    if category in {"ARCHIVE", "ARCHIVES"}:
        return "archive"

    if ext in {
        "jpg", "jpeg", "png", "gif", "webp",
        "heic", "heif", "tif", "tiff", "bmp",
        "svg", "avif",
    }:
        return "image"

    if ext in {
        "mp3", "m4a", "aac", "flac", "wav",
        "ogg", "opus", "wma",
    }:
        return "audio"

    if ext in {
        "mp4", "mkv", "avi", "mov", "webm",
        "m4v", "3gp", "wmv",
    }:
        return "video"

    if ext in {
        "zip", "rar", "7z", "tar", "gz",
        "bz2", "xz", "iso",
    }:
        return "archive"

    return "other"


def parent_folders(canonical_path):
    parts = [p for p in canonical_path.split("/") if p]

    return [
        "/".join(parts[:i])
        for i in range(1, len(parts))
    ]


def fail(message):
    print(f"ABORT: {message}")
    sys.exit(2)


def load_manifest(path):
    if not path.is_file():
        fail(f"manifest does not exist: {path}")

    with path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as f:
        rows = list(csv.DictReader(f))

    if not rows:
        fail("manifest is empty")

    required = {
        "sha256",
        "manual_canonical_path",
        "source_path",
    }

    missing = required - set(rows[0])

    if missing:
        fail(
            "manifest missing required columns: "
            + ", ".join(sorted(missing))
        )

    return rows


def main():
    parser = argparse.ArgumentParser(
        description="Register verified PHONE1_A73 objects in the master catalog."
    )

    parser.add_argument(
        "--db",
        default=str(DEFAULT_DB),
    )

    parser.add_argument(
        "--master-root",
        default=str(DEFAULT_MASTER_ROOT),
    )

    parser.add_argument(
        "--manifest",
        default=str(DEFAULT_MANIFEST),
    )

    parser.add_argument(
        "--execute",
        action="store_true",
        help="Commit database changes. Default is dry-run.",
    )

    args = parser.parse_args()

    db = Path(args.db).expanduser().resolve()
    master_root = Path(args.master_root).expanduser().resolve()
    manifest_path = Path(args.manifest).expanduser().resolve()

    print("=" * 78)
    print("PHONE A73 → MASTER CATALOG REGISTRATION")
    print("=" * 78)
    print("MODE              :", "EXECUTE" if args.execute else "DRY RUN")
    print("DATABASE           :", db)
    print("MASTER ROOT        :", master_root)
    print("MANIFEST           :", manifest_path)
    print("BATCH              :", BATCH_ID)
    print("DEVICE             :", DEVICE_ID)
    print()

    if not db.is_file():
        fail(f"database does not exist: {db}")

    if not master_root.is_dir():
        fail(f"master root does not exist: {master_root}")

    manifest = load_manifest(manifest_path)

    print("MANIFEST ROWS      :", len(manifest))

    manifest_sha = {}
    manifest_paths = set()

    for row in manifest:
        sha = row["sha256"].strip().lower()
        destination = row["manual_canonical_path"].strip()

        if not sha:
            fail("manifest contains empty SHA")

        if sha in manifest_sha:
            fail(f"duplicate manifest SHA: {sha}")

        if destination in manifest_paths:
            fail(f"duplicate manifest destination: {destination}")

        manifest_sha[sha] = row
        manifest_paths.add(destination)

    print("MANIFEST UNIQUE SHA:", len(manifest_sha))
    print("MANIFEST PATH FIELD : manual_canonical_path")
    print()

    try:
        con = sqlite3.connect(db)
        con.execute("PRAGMA foreign_keys=ON")
    except Exception as exc:
        fail(f"database connection failed: {exc}")

    try:
        # ------------------------------------------------------------
        # A73 source population
        # ------------------------------------------------------------

        a73_rows = con.execute(
            """
            SELECT
                inventory_id,
                source_device_id,
                source_path,
                filename,
                sha256,
                size_bytes,
                source_created_at,
                source_modified_at,
                source_accessed_at,
                source_ctime_at,
                manual_category,
                manual_canonical_path,
                manual_notes,
                duplicate_reason
            FROM multi_media_assets
            WHERE batch_id=?
              AND keep_decision='KEEP'
            ORDER BY inventory_id
            """,
            (BATCH_ID,),
        ).fetchall()

        print("A73 KEEP ROWS      :", len(a73_rows))
        print(
            "A73 KEEP UNIQUE SHA:",
            len({r[4].lower() for r in a73_rows}),
        )
        print()

        if len(a73_rows) != 5639:
            fail(
                f"expected 5639 KEEP rows, found {len(a73_rows)}"
            )

        keep_sha = {r[4].lower() for r in a73_rows}

        if len(keep_sha) != 5440:
            fail(
                f"expected 5440 KEEP unique SHA, found {len(keep_sha)}"
            )

        # ------------------------------------------------------------
        # Validate physical-copy manifest
        #
        # IMPORTANT:
        # multi_media_assets.manual_canonical_path belongs to the
        # individual source occurrence and may legitimately differ
        # between duplicate A73 occurrences of the same SHA.
        #
        # The manifest is the authoritative master destination map:
        # exactly one destination per newly copied SHA.
        # ------------------------------------------------------------

        manifest_sha_set = set(manifest_sha)

        if len(manifest_sha_set) != len(manifest_sha):
            fail("manifest SHA map is not unique")

        # ------------------------------------------------------------
        # Manifest must represent exactly the genuinely new SHA
        # ------------------------------------------------------------

        new_sha_expected = keep_sha - {
            r[0].lower()
            for r in con.execute(
                """
                SELECT DISTINCT sha256
                FROM files
                WHERE sha256 IS NOT NULL
                """
            ).fetchall()
        }

        print(
            "SHA NOT ALREADY IN files:",
            len(new_sha_expected),
        )

        if new_sha_expected != set(manifest_sha):
            missing_manifest = new_sha_expected - set(manifest_sha)
            extra_manifest = set(manifest_sha) - new_sha_expected

            print("MISSING FROM MANIFEST :", len(missing_manifest))
            print("EXTRA IN MANIFEST     :", len(extra_manifest))

            if missing_manifest:
                print(
                    "Example missing:",
                    next(iter(missing_manifest)),
                )

            if extra_manifest:
                print(
                    "Example extra:",
                    next(iter(extra_manifest)),
                )

            fail(
                "manifest does not exactly match new A73 SHA population"
            )

        # ------------------------------------------------------------
        # Physical verification
        # ------------------------------------------------------------

        print()
        print("VERIFYING MASTER DESTINATIONS...")

        physical_errors = []

        for sha, manifest_row in manifest_sha.items():
            destination = (
                master_root
                / manifest_row["manual_canonical_path"].lstrip("/")
            )

            if not destination.is_file():
                physical_errors.append(
                    f"{sha}: missing {destination}"
                )
                continue

            expected_size = manifest_row.get("destination_size_bytes")

            if expected_size:
                expected_size = int(expected_size)
                
                actual_size = destination.stat().st_size

                if actual_size != expected_size:
                    physical_errors.append(
                        f"{sha}: size mismatch at {destination}: "
                        f"expected={expected_size}, actual={actual_size}"
                    )
                    

        if physical_errors:
            print(
                "PHYSICAL ERRORS:",
                len(physical_errors),
            )

            for error in physical_errors[:20]:
                print("  ", error)

            fail("physical destination verification failed")

        print("PHYSICAL VERIFICATION: PASS")
        print("Verification basis : previously SHA-256-verified physical-copy manifest")

        # ------------------------------------------------------------
        # Resolve existing masters
        # ------------------------------------------------------------

        existing_master = {}
        new_sha = set()

        for sha in keep_sha:
            rows = con.execute(
                """
                SELECT
                    file_id,
                    canonical_path,
                    master_path,
                    status,
                    storage_state
                FROM files
                WHERE lower(sha256)=?
                ORDER BY file_id
                """,
                (sha,),
            ).fetchall()

            preferred = None

            for r in rows:
                if (
                    r[3] == "MASTER"
                    and r[4] == "IN_MASTER"
                ):
                    preferred = r
                    break

            if preferred:
                existing_master[sha] = preferred[0]
            else:
                new_sha.add(sha)

        print()
        print("EXISTING MASTER SHA :", len(existing_master))
        print("NEW MASTER SHA      :", len(new_sha))

        if len(existing_master) != 68:
            fail(
                f"expected 68 existing MASTER SHA, "
                f"found {len(existing_master)}"
            )

        if len(new_sha) != 5372:
            fail(
                f"expected 5372 new SHA, found {len(new_sha)}"
            )

        # ------------------------------------------------------------
        # Build occurrence plan
        # ------------------------------------------------------------

        source_plan = []

        for row in a73_rows:
            (
                inv,
                dev,
                source_path,
                original_filename,
                sha,
                size_bytes,
                created_at,
                modified_at,
                accessed_at,
                ctime_at,
                manual_category,
                manual_canonical_path,
                manual_notes,
                duplicate_reason,
            ) = row

            sha = sha.lower()

            source_plan.append(
                {
                    "inventory_id": inv,
                    "device_id": dev,
                    "source_path": source_path,
                    "source_filename": original_filename,
                    "source_size_bytes": size_bytes,
                    "source_sha256": sha,
                    "source_modified_date": modified_at,
                    "source_created_at": created_at,
                    "source_accessed_at": accessed_at,
                    "source_ctime_at": ctime_at,
                    "manual_category": manual_category,
                    "manual_canonical_path": manual_canonical_path,
                    "manual_notes": manual_notes,
                    "duplicate_reason": duplicate_reason,
                }
            )

        # ------------------------------------------------------------
        # Existing source relationships
        # ------------------------------------------------------------

        existing_source_count = 0
        duplicate_source_keys = []

        for item in source_plan:
            fid = existing_master.get(item["source_sha256"])

            if fid is None:
                continue

            found = con.execute(
                """
                SELECT file_id
                FROM file_sources
                WHERE file_id=?
                  AND device_id=?
                  AND source_path=?
                """,
                (
                    fid,
                    item["device_id"],
                    item["source_path"],
                ),
            ).fetchone()

            if found:
                existing_source_count += 1

        # ------------------------------------------------------------
        # Folder plan
        # ------------------------------------------------------------

        folders = set()

        for row in manifest_sha.values():
            cp = row["manual_canonical_path"].strip()
            folders.update(parent_folders(cp))

        print()
        print("EXPECTED NEW files  :", len(new_sha))
        print("A73 SOURCE ROWS     :", len(source_plan))
        print(
            "EXISTING SOURCES    :",
            existing_source_count,
        )
        print("MASTER FOLDERS      :", len(folders))
        print(
            "SOURCE-PATH DIFFERENCES:",
            "allowed; master path comes from manifest/existing files",
        )
        print()

        if not args.execute:
            print("=" * 78)
            print("DRY RUN COMPLETE")
            print("DATABASE MODIFICATIONS: NONE")
            print("=" * 78)
            con.close()
            return

        # ============================================================
        # EXECUTE
        # ============================================================

        print("=" * 78)
        print("BEGIN TRANSACTION")
        print("=" * 78)

        con.execute("BEGIN IMMEDIATE")

        try:
            new_file_ids = {}

            # --------------------------------------------------------
            # Insert new MASTER files
            # --------------------------------------------------------

            for sha in sorted(new_sha):
                manifest_row = manifest_sha[sha]

                destination = manifest_row[
                    "manual_canonical_path"
                ].strip()

                filename = Path(destination).name

                source_rows = [
                    x
                    for x in source_plan
                    if x["source_sha256"] == sha
                ]

                if not source_rows:
                    raise RuntimeError(
                        f"no A73 source row for SHA {sha}"
                    )

                src = source_rows[0]

                cur = con.execute(
                    """
                    INSERT INTO files
                    (
                        sha256,
                        master_path,
                        filename,
                        extension,
                        size_bytes,
                        media_type,
                        modified_date,
                        status,
                        notes,
                        canonical_path,
                        storage_state,
                        updated_at
                    )
                    VALUES
                    (
                        ?, ?, ?, ?, ?, ?, ?,
                        'MASTER',
                        ?, ?,
                        'IN_MASTER',
                        CURRENT_TIMESTAMP
                    )
                    """,
                    (
                        sha,
                        destination,
                        filename,
                        extension(filename),
                        src["source_size_bytes"],
                        media_type(
                            src["manual_category"],
                            filename,
                        ),
                        src["source_modified_date"],
                        src["manual_notes"],
                        destination,
                    ),
                )

                new_file_ids[sha] = cur.lastrowid

            # --------------------------------------------------------
            # Resolve all file IDs
            # --------------------------------------------------------

            file_ids = dict(existing_master)

            for sha, fid in new_file_ids.items():
                file_ids[sha] = fid

            if len(file_ids) != 5440:
                raise RuntimeError(
                    f"file ID resolution expected 5440, "
                    f"got {len(file_ids)}"
                )

            # --------------------------------------------------------
            # Insert file_sources
            # --------------------------------------------------------

            source_inserted = 0

            for item in source_plan:
                fid = file_ids[item["source_sha256"]]

                exists = con.execute(
                    """
                    SELECT 1
                    FROM file_sources
                    WHERE file_id=?
                      AND device_id=?
                      AND source_path=?
                    """,
                    (
                        fid,
                        item["device_id"],
                        item["source_path"],
                    ),
                ).fetchone()

                if exists:
                    continue

                con.execute(
                    """
                    INSERT INTO file_sources
                    (
                        file_id,
                        device_id,
                        source_path,
                        source_filename,
                        source_size_bytes,
                        source_sha256,
                        source_modified_date
                    )
                    VALUES (?,?,?,?,?,?,?)
                    """,
                    (
                        fid,
                        item["device_id"],
                        item["source_path"],
                        item["source_filename"],
                        item["source_size_bytes"],
                        item["source_sha256"],
                        item["source_modified_date"],
                    ),
                )

                source_inserted += 1

            # --------------------------------------------------------
            # Copy manifest registration
            # --------------------------------------------------------

            manifest_inserted = 0
            timestamp = datetime.now().astimezone().isoformat(
                timespec="seconds"
            )

            for sha, row in manifest_sha.items():
                fid = file_ids[sha]

                destination = row[
                    "manual_canonical_path"
                ].strip()

                source_path = row["source_path"].strip()

                exists = con.execute(
                    """
                    SELECT 1
                    FROM copy_manifest
                    WHERE file_id=?
                      AND source_device_id=?
                      AND source_path=?
                      AND manual_canonical_path=?
                    """,
                    (
                        fid,
                        DEVICE_ID,
                        source_path,
                        destination,
                    ),
                ).fetchone()

                if exists:
                    continue

                source_size = row.get(
                    "source_size_bytes"
                )

                destination_size = row.get(
                    "destination_size_bytes"
                )

                con.execute(
                    """
                    INSERT INTO copy_manifest
                    (
                        file_id,
                        source_device_id,
                        source_path,
                        manual_canonical_path,
                        source_sha256,
                        destination_sha256,
                        source_size_bytes,
                        destination_size_bytes,
                        copied_at,
                        verified_at,
                        status,
                        verification_method,
                        notes
                    )
                    VALUES
                    (?,?,?,?,?,?,?,?,?,?,?,?,?)
                    """,
                    (
                        fid,
                        DEVICE_ID,
                        source_path,
                        destination,
                        sha,
                        sha,
                        int(source_size)
                        if source_size
                        else None,
                        int(destination_size)
                        if destination_size
                        else None,
                        timestamp,
                        timestamp,
                        "VERIFIED",
                        "SHA256_DIRECT_MEDIA_REBUILD",
                        "PHONE1_A73 verified master copy.",
                    ),
                )

                manifest_inserted += 1

            # --------------------------------------------------------
            # Folders
            # --------------------------------------------------------

            folder_inserted = 0

            for folder in sorted(
                folders,
                key=lambda x: (x.count("/"), x),
            ):
                exists = con.execute(
                    """
                    SELECT 1
                    FROM folders
                    WHERE master_path=?
                    """,
                    (folder,),
                ).fetchone()

                if exists:
                    continue

                name = folder.rstrip("/").split("/")[-1]

                parent = (
                    folder.rstrip("/").rsplit("/", 1)[0]
                    if "/" in folder.rstrip("/")
                    else None
                )

                con.execute(
                    """
                    INSERT INTO folders
                    (
                        master_path,
                        folder_name,
                        parent_path,
                        folder_type,
                        description,
                        device_summary,
                        updated_at
                    )
                    VALUES
                    (?,?,?,?,?,?,CURRENT_TIMESTAMP)
                    """,
                    (
                        folder,
                        name,
                        parent,
                        "MASTER",
                        "Created during PHONE1_A73 catalog registration.",
                        DEVICE_ID,
                    ),
                )

                folder_inserted += 1

            # --------------------------------------------------------
            # Transaction validation
            # --------------------------------------------------------

            registered_new = con.execute(
                """
                SELECT COUNT(DISTINCT sha256)
                FROM files
                WHERE lower(sha256) IN (
                    SELECT lower(sha256)
                    FROM multi_media_assets
                    WHERE batch_id=?
                      AND keep_decision='KEEP'
                )
                  AND status='MASTER'
                  AND storage_state='IN_MASTER'
                """,
                (BATCH_ID,),
            ).fetchone()[0]

            if registered_new != 5440:
                raise RuntimeError(
                    f"post-insert A73 MASTER count expected 5440, "
                    f"got {registered_new}"
                )

            registered_sources = con.execute(
                """
                SELECT COUNT(*)
                FROM file_sources fs
                JOIN files f
                  ON f.file_id=fs.file_id
                WHERE fs.device_id=?
                  AND lower(fs.source_sha256) IN (
                      SELECT lower(sha256)
                      FROM multi_media_assets
                      WHERE batch_id=?
                        AND keep_decision='KEEP'
                  )
                """,
                (
                    DEVICE_ID,
                    BATCH_ID,
                ),
            ).fetchone()[0]

            if registered_sources < len(source_plan):
                raise RuntimeError(
                    f"file_sources expected at least "
                    f"{len(source_plan)}, "
                    f"got {registered_sources}"
                )

            print()
            print("NEW files INSERTED :", len(new_file_ids))
            print("file_sources INSERT:", source_inserted)
            print("copy_manifest INSERT:", manifest_inserted)
            print("folders INSERTED   :", folder_inserted)
            print("MASTER SHA VALIDATION:", registered_new)
            print("SOURCE VALIDATION    :", registered_sources)

            con.commit()

            print()
            print("=" * 78)
            print("CATALOG REGISTRATION COMPLETE")
            print("TRANSACTION COMMITTED")
            print("=" * 78)

        except Exception:
            con.rollback()
            print()
            print("=" * 78)
            print("ABORT: TRANSACTION ROLLED BACK")
            print("=" * 78)
            raise

    finally:
        con.close()


if __name__ == "__main__":
    main()
