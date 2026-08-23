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

def under(path, root):
    try:
        Path(path).resolve().relative_to(Path(root).resolve())
        return True
    except ValueError:
        return False

def select_rows(con, apply_reviewed):
    if not apply_reviewed:
        where = "cp.review_status='APPROVED'"
    else:
        where = """
        (
            cp.review_status='APPROVED'
            OR (
                cp.review_status='REVIEW'
                AND COALESCE(
                    NULLIF(TRIM(cp.manual_canonical_path), ''),
                    NULLIF(TRIM(cp.proposed_canonical_path), '')
                ) IS NOT NULL
            )
        )
        """

    return con.execute(f"""
        SELECT
            cp.plan_id,
            f.file_id,
            f.filename,
            f.sha256,
            f.size_bytes,
            f.master_path,
            COALESCE(
                NULLIF(TRIM(cp.manual_canonical_path), ''),
                cp.proposed_canonical_path
            ) AS target,
            CASE
                WHEN cp.review_status='APPROVED' THEN 'APPROVED'
                WHEN NULLIF(TRIM(cp.manual_canonical_path), '') IS NOT NULL THEN 'MANUAL'
                WHEN NULLIF(TRIM(cp.proposed_canonical_path), '') IS NOT NULL THEN 'PROPOSED_ONLY'
                ELSE 'NONE'
            END AS path_source
        FROM canonical_plan cp
        JOIN files f ON f.file_id=cp.file_id
        WHERE {where}
        ORDER BY cp.plan_id
    """).fetchall()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=str(Path.home() / "Master-Repository/.archive/catalog.db"))
    ap.add_argument("--master-root", default=str(Path.home() / "Master-Repository"))
    ap.add_argument("--apply-reviewed", action="store_true")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--execute", action="store_true")
    ap.add_argument("--confirm-proposed", action="store_true")
    args = ap.parse_args()

    dry_run = not args.execute

    db = Path(args.db).expanduser().resolve()
    root = Path(args.master_root).expanduser().resolve()
    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir():
        raise SystemExit(f"ERROR: master root does not exist: {root}")

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")
    rows = select_rows(con, args.apply_reviewed)

    approved_rows = [r for r in rows if r[7] == "APPROVED"]
    manual_rows = [r for r in rows if r[7] == "MANUAL"]
    proposed_only_rows = [r for r in rows if r[7] == "PROPOSED_ONLY"]

    print("=" * 72)
    print("CANONICAL PATH APPLY")
    print("=" * 72)
    print("MODE           :", "DRY RUN" if dry_run else "EXECUTE")
    print("Eligible rows  :", len(rows))
    print("  APPROVED     :", len(approved_rows))
    print("  MANUAL       :", len(manual_rows))
    print("  PROPOSED_ONLY:", len(proposed_only_rows))
    print("Master root    :", root)
    print("Original Tablet/PC source trees are NOT touched.")
    print()

    if proposed_only_rows:
        print("=" * 72)
        print("CAUTION: PROPOSED CANONICAL PATHS")
        print("=" * 72)
        print(f"{len(proposed_only_rows)} file(s) have no manual_canonical_path.")
        print("They will use proposed_canonical_path.")
        print("These paths were not manually overridden.")
        print("Execution requires --confirm-proposed and interactive confirmation.")
        print("=" * 72)
        print()

    if not dry_run and proposed_only_rows and not args.confirm_proposed:
        con.close()
        raise SystemExit(
            "Execution stopped: proposed-only rows are present. "
            "Re-run with --confirm-proposed."
        )

    if not dry_run and proposed_only_rows and args.confirm_proposed:
        answer = input("Proceed with these proposed paths? [yes/no]: ").strip().lower()
        if answer != "yes":
            con.close()
            raise SystemExit("Execution cancelled by user.")
        print("User confirmation accepted.")
        print()

    if not rows:
        print("No eligible rows found.")
        con.close()
        return

    successful = 0
    failed = 0

    for (
        plan_id,
        file_id,
        filename,
        expected_sha,
        expected_size,
        current_path,
        target,
        path_source,
    ) in rows:

        src = Path(current_path).expanduser().resolve()
        target_path = Path(target)

        print(f"[{plan_id}] {filename}")
        print(f"  PATH SOURCE : {path_source}")
        print(f"  FROM        : {src}")
        print(f"  TO          : {target}")

        if target_path.is_absolute():
            print("  REFUSED: canonical target is absolute.")
            failed += 1
            print()
            continue

        dst = (root / target_path).resolve()

        if not under(src, root):
            print("  REFUSED: current source is outside Master-Repository.")
            failed += 1
            print()
            continue

        if not under(dst, root):
            print("  REFUSED: target escapes Master-Repository.")
            failed += 1
            print()
            continue

        if not src.is_file():
            print("  REFUSED: source file does not exist.")
            failed += 1
            print()
            continue

        actual_size = src.stat().st_size
        if actual_size != expected_size:
            print(f"  REFUSED: source size mismatch (catalog={expected_size}, actual={actual_size}).")
            failed += 1
            print()
            continue

        actual_sha = sha256_file(src)
        if actual_sha != expected_sha:
            print("  REFUSED: source SHA-256 mismatch.")
            failed += 1
            print()
            continue

        if src == dst:
            if not dry_run:
                ts = now()
                con.execute("""
                    UPDATE files
                    SET canonical_path=?, master_path=?, status='MASTER', updated_at=CURRENT_TIMESTAMP
                    WHERE file_id=?
                """, (target, str(dst), file_id))
                con.execute("""
                    UPDATE canonical_plan
                    SET review_status='APPLIED',
                        reviewed_at=COALESCE(reviewed_at, ?),
                        updated_at=CURRENT_TIMESTAMP
                    WHERE plan_id=?
                """, (ts, plan_id))
                con.commit()
            print("  OK: already at canonical destination.")
            successful += 1
            print()
            continue

        if dst.exists():
            if not dst.is_file():
                print("  REFUSED: destination exists but is not a file.")
                failed += 1
                print()
                continue

            existing_size = dst.stat().st_size
            existing_sha = sha256_file(dst)

            if existing_size == expected_size and existing_sha == expected_sha:
                if not dry_run:
                    ts = now()
                    con.execute("""
                        UPDATE files
                        SET canonical_path=?, master_path=?, status='MASTER', updated_at=CURRENT_TIMESTAMP
                        WHERE file_id=?
                    """, (target, str(dst), file_id))
                    con.execute("""
                        UPDATE canonical_plan
                        SET review_status='APPLIED',
                            reviewed_at=COALESCE(reviewed_at, ?),
                            updated_at=CURRENT_TIMESTAMP
                        WHERE plan_id=?
                    """, (ts, plan_id))
                    con.commit()
                print("  OK: matching destination already exists.")
                successful += 1
                print()
                continue

            print("  REFUSED: destination collision with different content.")
            failed += 1
            print()
            continue

        if dry_run:
            print("  DRY-RUN: source validation passed; destination is available.")
            successful += 1
            print()
            continue

        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))

            moved_size = dst.stat().st_size
            moved_sha = sha256_file(dst)

            if moved_size != expected_size or moved_sha != expected_sha:
                if dst.exists() and not src.exists():
                    src.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(dst), str(src))
                raise RuntimeError("Post-move SHA-256/size verification failed.")

            ts = now()

            con.execute("""
                UPDATE files
                SET canonical_path=?, master_path=?, status='MASTER', updated_at=CURRENT_TIMESTAMP
                WHERE file_id=?
            """, (target, str(dst), file_id))

            con.execute("""
                UPDATE canonical_plan
                SET review_status='APPLIED',
                    reviewed_at=COALESCE(reviewed_at, ?),
                    updated_at=CURRENT_TIMESTAMP
                WHERE plan_id=?
            """, (ts, plan_id))

            con.execute("""
                UPDATE copy_manifest
                SET destination_path=?,
                    destination_sha256=?,
                    destination_size_bytes=?,
                    verified_at=?,
                    verification_method='SHA256_AFTER_CANONICAL_MOVE',
                    notes=COALESCE(notes, '') || ' | Canonical path applied and verified.'
                WHERE file_id=? AND status='VERIFIED'
            """, (str(dst), moved_sha, moved_size, ts, file_id))

            con.execute("""
                INSERT INTO folders(
                    master_path, folder_name, parent_path, folder_type
                )
                VALUES (?, ?, ?, 'CANONICAL')
                ON CONFLICT(master_path)
                DO UPDATE SET
                    folder_type='CANONICAL',
                    updated_at=CURRENT_TIMESTAMP
            """, (str(dst.parent), dst.parent.name, str(dst.parent.parent)))

            con.commit()
            print("  VERIFIED + APPLIED")
            successful += 1
            print()

        except Exception as exc:
            con.rollback()
            failed += 1
            print("  FAILED:", type(exc).__name__, exc)
            print()

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print("Eligible       :", len(rows))
    print("Successful     :", successful)
    print("Failed/refused :", failed)
    print("Manual paths   :", len(manual_rows))
    print("Proposed-only  :", len(proposed_only_rows))

    if dry_run:
        print("DRY RUN ONLY - no files were moved.")

    con.close()

    if failed:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
