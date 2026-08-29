#!/usr/bin/env python3
import argparse
import csv
import sqlite3
import hashlib
from pathlib import Path
from datetime import datetime

DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"
DEFAULT_MASTER_ROOT = Path.home() / "Master-Repository"
DEFAULT_OUTPUT_DIR = Path.home() / "my_scripts/digital_archive/device_restore_manifests"

def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            h.update(chunk)
    return h.hexdigest()

def resolve_master_path(master_root, master_path):
    if not master_path:
        return None
    p = Path(str(master_path))
    return p if p.is_absolute() else master_root / p

def main():
    ap = argparse.ArgumentParser(
        description="Build a read-only restore manifest from files + file_sources."
    )
    ap.add_argument("--db", default=str(DEFAULT_DB))
    ap.add_argument("--device", required=True)
    ap.add_argument("--master-root", default=str(DEFAULT_MASTER_ROOT))
    ap.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR))
    ap.add_argument("--verify-sha", action="store_true",
                    help="Hash every MASTER file; slow for large devices.")
    args = ap.parse_args()

    db = Path(args.db).expanduser().resolve()
    master_root = Path(args.master_root).expanduser().resolve()
    out = Path(args.output_dir).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")
    if not master_root.is_dir():
        raise SystemExit(f"ERROR: master root does not exist: {master_root}")

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    device = con.execute(
        "SELECT device_id, device_name, device_type, active FROM devices WHERE device_id=?",
        (args.device,),
    ).fetchone()
    if not device:
        con.close()
        raise SystemExit(f"ERROR: device does not exist: {args.device}")

    # One restore object per file_id. Multiple source occurrences of the same
    # logical file are not recreated as multiple copies.
    source_rows = con.execute(
        """
        SELECT
            f.file_id,
            f.sha256,
            f.filename,
            f.extension,
            f.size_bytes,
            f.master_path,
            f.canonical_path,
            f.storage_state,
            f.status,
            COUNT(*) AS source_occurrences
        FROM files f
        JOIN file_sources fs ON fs.file_id = f.file_id
        WHERE fs.device_id=?
        GROUP BY
            f.file_id, f.sha256, f.filename, f.extension, f.size_bytes,
            f.master_path, f.canonical_path, f.storage_state, f.status
        ORDER BY f.canonical_path, f.file_id
        """,
        (args.device,),
    ).fetchall()

    rows = []
    seen_targets = {}
    for rec in source_rows:
        (
            file_id, sha, filename, extension, size_bytes,
            master_path, canonical_path, storage_state, status,
            source_occurrences,
        ) = rec

        if not canonical_path or not str(canonical_path).strip():
            rows.append({
                "file_id": file_id, "sha256": sha, "filename": filename,
                "extension": extension or "", "size_bytes": size_bytes,
                "master_path": master_path or "",
                "canonical_path": "",
                "restore_source": "",
                "source_occurrences": source_occurrences,
                "storage_state": storage_state or "",
                "catalog_status": status or "",
                "physical_status": "NO_CANONICAL_PATH",
                "physical_size_bytes": "",
                "physical_sha256": "",
                "size_status": "NOT_CHECKED",
                "sha_status": "NOT_RUN",
                "restore_status": "BLOCKED",
                "reason": "NO_CANONICAL_PATH",
            })
            continue

        target = str(canonical_path).strip().lstrip("/")
        target_parts = Path(target).parts
        if Path(target).is_absolute() or ".." in target_parts:
            rows.append({
                "file_id": file_id, "sha256": sha, "filename": filename,
                "extension": extension or "", "size_bytes": size_bytes,
                "master_path": master_path or "",
                "canonical_path": target,
                "restore_source": "",
                "source_occurrences": source_occurrences,
                "storage_state": storage_state or "",
                "catalog_status": status or "",
                "physical_status": "INVALID_TARGET",
                "physical_size_bytes": "",
                "physical_sha256": "",
                "size_status": "NOT_CHECKED",
                "sha_status": "NOT_RUN",
                "restore_status": "BLOCKED",
                "reason": "INVALID_CANONICAL_PATH",
            })
            continue

        if target in seen_targets:
            rows.append({
                "file_id": file_id, "sha256": sha, "filename": filename,
                "extension": extension or "", "size_bytes": size_bytes,
                "master_path": master_path or "",
                "canonical_path": target,
                "restore_source": "",
                "source_occurrences": source_occurrences,
                "storage_state": storage_state or "",
                "catalog_status": status or "",
                "physical_status": "DUPLICATE_TARGET",
                "physical_size_bytes": "",
                "physical_sha256": "",
                "size_status": "NOT_CHECKED",
                "sha_status": "NOT_RUN",
                "restore_status": "BLOCKED",
                "reason": f"DUPLICATE_CANONICAL_TARGET_FILE_ID={seen_targets[target]}",
            })
            continue

        seen_targets[target] = file_id
        physical = resolve_master_path(master_root, master_path)

        if physical is None or not physical.is_file():
            rows.append({
                "file_id": file_id, "sha256": sha, "filename": filename,
                "extension": extension or "", "size_bytes": size_bytes,
                "master_path": master_path or "",
                "canonical_path": target,
                "restore_source": str(physical) if physical else "",
                "source_occurrences": source_occurrences,
                "storage_state": storage_state or "",
                "catalog_status": status or "",
                "physical_status": "MISSING",
                "physical_size_bytes": "",
                "physical_sha256": "",
                "size_status": "NOT_CHECKED",
                "sha_status": "NOT_RUN",
                "restore_status": "BLOCKED",
                "reason": "MASTER_PHYSICAL_FILE_MISSING",
            })
            continue

        physical_size = physical.stat().st_size
        size_status = "MATCH" if physical_size == size_bytes else "MISMATCH"

        physical_sha = ""
        sha_status = "NOT_RUN"
        if args.verify_sha:
            physical_sha = sha256_file(physical)
            sha_status = "MATCH" if physical_sha.lower() == sha.lower() else "MISMATCH"

        restore_status = "READY" if size_status == "MATCH" and sha_status != "MISMATCH" else "BLOCKED"
        reason = "MASTER_PATH_AND_SIZE_VALID" if restore_status == "READY" else "MASTER_VALIDATION_FAILED"

        rows.append({
            "file_id": file_id,
            "sha256": sha,
            "filename": filename,
            "extension": extension or "",
            "size_bytes": size_bytes,
            "master_path": master_path or "",
            "canonical_path": target,
            "restore_source": str(physical),
            "source_occurrences": source_occurrences,
            "storage_state": storage_state or "",
            "catalog_status": status or "",
            "physical_status": "PRESENT",
            "physical_size_bytes": physical_size,
            "physical_sha256": physical_sha,
            "size_status": size_status,
            "sha_status": sha_status,
            "restore_status": restore_status,
            "reason": reason,
        })

    out.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().astimezone().strftime("%Y%m%d_%H%M%S")
    manifest = out / f"{args.device}_restore_manifest_{ts}.csv"

    fields = [
        "device_id", "file_id", "sha256", "filename", "extension",
        "size_bytes", "master_path", "canonical_path", "restore_source",
        "restore_target_relative_path", "source_occurrences",
        "storage_state", "catalog_status", "physical_status",
        "physical_size_bytes", "physical_sha256", "size_status",
        "sha_status", "restore_status", "reason",
    ]

    with manifest.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({
                **r,
                "device_id": args.device,
                "restore_target_relative_path": r["canonical_path"],
            })

    ready = sum(r["restore_status"] == "READY" for r in rows)
    blocked = len(rows) - ready

    print("=" * 78)
    print("DEVICE RESTORE MANIFEST")
    print("=" * 78)
    print("MODE             : READ ONLY")
    print("DEVICE           :", args.device)
    print("Source occurrences:", sum(r["source_occurrences"] for r in rows))
    print("Unique file_ids  :", len(rows))
    print("READY            :", ready)
    print("BLOCKED          :", blocked)
    print("SHA verification:", "RUN" if args.verify_sha else "NOT RUN")
    print("OUTPUT           :", manifest)
    print("DATABASE CHANGES: NONE")
    print("=" * 78)

    con.close()
    if blocked:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
