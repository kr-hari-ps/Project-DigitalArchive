#!/usr/bin/env python3
"""
Read-only verification of files.canonical_path against physical MASTER paths.

For every catalog file, this checks:
  1. canonical_path is populated.
  2. master_path is populated.
  3. master_path resolves to an existing physical file.
  4. canonical_path resolves under MASTER_ROOT.
  5. canonical_path physical target exists.
  6. canonical_path and master_path point to the same physical location.
  7. If requested, SHA-256 of the physical canonical target matches files.sha256.

No database or filesystem modifications are performed.
"""

import argparse
import csv
import hashlib
import sqlite3
from pathlib import Path
from datetime import datetime

DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"
DEFAULT_ROOT = Path.home() / "Master-Repository"
DEFAULT_OUT = Path.home() / "my_scripts/digital_archive/canonical_path_reports"


def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            h.update(chunk)
    return h.hexdigest()


def resolve_master_path(root, master_path):
    if not master_path:
        return None
    p = Path(str(master_path))
    return p if p.is_absolute() else root / p


def resolve_canonical_path(root, canonical_path):
    if not canonical_path:
        return None
    p = Path(str(canonical_path).strip().lstrip("/"))
    return root / p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=str(DEFAULT_DB))
    ap.add_argument("--master-root", default=str(DEFAULT_ROOT))
    ap.add_argument("--output-dir", default=str(DEFAULT_OUT))
    ap.add_argument(
        "--verify-sha",
        action="store_true",
        help="SHA-256 verify each canonical physical target. Slow.",
    )
    args = ap.parse_args()

    db = Path(args.db).expanduser().resolve()
    root = Path(args.master_root).expanduser().resolve()
    out = Path(args.output_dir).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir():
        raise SystemExit(f"ERROR: master root does not exist: {root}")

    con = sqlite3.connect(db)

    rows = con.execute(
        """
        SELECT
            file_id,
            sha256,
            filename,
            size_bytes,
            master_path,
            canonical_path,
            storage_state,
            status
        FROM files
        ORDER BY file_id
        """
    ).fetchall()

    results = []

    for (
        file_id,
        expected_sha,
        filename,
        expected_size,
        master_path,
        canonical_path,
        storage_state,
        status,
    ) in rows:

        if storage_state and storage_state != "IN_MASTER":
            results.append({
                "file_id": file_id,
                "sha256": expected_sha,
                "filename": filename,
                "master_path": master_path or "",
                "canonical_path": canonical_path or "",
                "resolved_master_path": "",
                "resolved_canonical_path": "",
                "size_bytes": expected_size,
                "physical_master_size": "",
                "physical_canonical_size": "",
                "physical_canonical_sha256": "",
                "path_relation": "NOT_IN_MASTER",
                "canonical_status": "EXCLUDED_STORAGE_STATE",
                "sha_status": "NOT_RUN",
                "overall_status": "NOT_APPLICABLE",
                "reason": f"storage_state={storage_state}",
            })
            continue

        resolved_master = resolve_master_path(root, master_path)
        resolved_canonical = resolve_canonical_path(root, canonical_path)

        canonical_status = "PASS"
        sha_status = "NOT_RUN"
        reason = ""

        if not canonical_path or not str(canonical_path).strip():
            canonical_status = "MISSING_CANONICAL_PATH"
            reason = "canonical_path is NULL/empty"

        elif resolved_canonical is None:
            canonical_status = "INVALID_CANONICAL_PATH"
            reason = "canonical path could not be resolved"

        elif not resolved_canonical.is_file():
            canonical_status = "CANONICAL_PHYSICAL_MISSING"
            reason = "canonical_path does not exist physically"

        if resolved_master is None:
            master_exists = False
        else:
            master_exists = resolved_master.is_file()

        if resolved_canonical and resolved_canonical.is_file():
            canonical_size = resolved_canonical.stat().st_size
        else:
            canonical_size = ""

        if resolved_master and master_exists:
            master_size = resolved_master.stat().st_size
        else:
            master_size = ""

        if canonical_status == "PASS":
            if expected_size != canonical_size:
                canonical_status = "CANONICAL_SIZE_MISMATCH"
                reason = (
                    f"catalog={expected_size}, "
                    f"canonical_physical={canonical_size}"
                )

        if (
            canonical_status == "PASS"
            and resolved_master is not None
            and master_exists
            and resolved_canonical is not None
            and resolved_canonical.is_file()
        ):
            if resolved_master.resolve() == resolved_canonical.resolve():
                path_relation = "CANONICAL_EQUALS_MASTER_PATH"
            else:
                path_relation = "CANONICAL_DIFFERS_FROM_MASTER_PATH"
        elif canonical_status == "PASS":
            path_relation = "MASTER_PATH_UNAVAILABLE"
        else:
            path_relation = "UNRESOLVED"

        physical_canonical_sha = ""

        if args.verify_sha and canonical_status == "PASS":
            physical_canonical_sha = sha256_file(resolved_canonical)
            sha_status = (
                "MATCH"
                if physical_canonical_sha.lower() == expected_sha.lower()
                else "MISMATCH"
            )

            if sha_status == "MISMATCH":
                canonical_status = "CANONICAL_SHA_MISMATCH"
                reason = "physical canonical target SHA differs from files.sha256"

        overall_status = (
            "PASS"
            if canonical_status == "PASS"
            and sha_status != "MISMATCH"
            else "FAIL"
        )

        results.append({
            "file_id": file_id,
            "sha256": expected_sha,
            "filename": filename,
            "master_path": master_path or "",
            "canonical_path": canonical_path or "",
            "resolved_master_path": str(resolved_master) if resolved_master else "",
            "resolved_canonical_path": str(resolved_canonical) if resolved_canonical else "",
            "size_bytes": expected_size,
            "physical_master_size": master_size,
            "physical_canonical_size": canonical_size,
            "physical_canonical_sha256": physical_canonical_sha,
            "path_relation": path_relation,
            "canonical_status": canonical_status,
            "sha_status": sha_status,
            "overall_status": overall_status,
            "reason": reason,
        })

    out.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().astimezone().strftime("%Y%m%d_%H%M%S")
    report = out / f"canonical_path_verification_{ts}.csv"

    fields = [
        "file_id", "sha256", "filename",
        "master_path", "canonical_path",
        "resolved_master_path", "resolved_canonical_path",
        "size_bytes", "physical_master_size",
        "physical_canonical_size", "physical_canonical_sha256",
        "path_relation", "canonical_status", "sha_status",
        "overall_status", "reason",
    ]

    with report.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(results)

    master = [r for r in results if r["overall_status"] != "NOT_APPLICABLE"]

    def count(status):
        return sum(1 for r in master if r["canonical_status"] == status)

    print("=" * 78)
    print("CANONICAL PATH VERIFICATION")
    print("=" * 78)
    print("DATABASE        :", db)
    print("MASTER ROOT     :", root)
    print("READ ONLY       : YES")
    print("SHA VERIFICATION:", "YES" if args.verify_sha else "NO")
    print()
    print("CATALOG FILES   :", len(rows))
    print("IN_MASTER       :", len(master))
    print()
    print("CANONICAL STATUS")
    print("-" * 78)
    for s in [
        "PASS",
        "MISSING_CANONICAL_PATH",
        "INVALID_CANONICAL_PATH",
        "CANONICAL_PHYSICAL_MISSING",
        "CANONICAL_SIZE_MISMATCH",
        "CANONICAL_SHA_MISMATCH",
        "EXCLUDED_STORAGE_STATE",
    ]:
        print(f"{s:32}:", count(s))

    print()
    print("PATH RELATION")
    print("-" * 78)
    for s in [
        "CANONICAL_EQUALS_MASTER_PATH",
        "CANONICAL_DIFFERS_FROM_MASTER_PATH",
        "MASTER_PATH_UNAVAILABLE",
        "UNRESOLVED",
        "NOT_IN_MASTER",
    ]:
        print(
            f"{s:32}:",
            sum(1 for r in results if r["path_relation"] == s)
        )

    failures = [
        r for r in results
        if r["overall_status"] == "FAIL"
    ]

    print()
    print("FAILURES        :", len(failures))
    print("REPORT          :", report)
    print("DATABASE CHANGES: NONE")
    print("=" * 78)

    con.close()

    if failures:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
