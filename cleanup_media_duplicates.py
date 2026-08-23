#!/usr/bin/env python3

import hashlib
import sqlite3
from pathlib import Path


DB = Path.home() / "Master-Repository/.archive/catalog.db"


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    h = hashlib.sha256()

    with path.open("rb") as f:
        while True:
            data = f.read(chunk_size)

            if not data:
                break

            h.update(data)

    return h.hexdigest()


def main() -> None:
    con = sqlite3.connect(DB)

    rows = con.execute(
        """
        SELECT
            cleanup_id,
            inventory_id,
            sha256,
            keep_path,
            remove_path
        FROM media_physical_cleanup_manifest
        WHERE status='PLANNED'
        ORDER BY cleanup_id
        """
    ).fetchall()

    print("=" * 72)
    print("MEDIA PHYSICAL CLEANUP")
    print("=" * 72)
    print("Planned rows:", len(rows))
    print()

    failed = 0

    for (
        cleanup_id,
        inventory_id,
        expected_sha,
        keep_path,
        remove_path,
    ) in rows:

        keep = Path(keep_path)
        remove = Path(remove_path)

        print(
            f"[{cleanup_id}] inventory_id={inventory_id}"
        )
        print(
            f"  KEEP   : {keep}"
        )
        print(
            f"  REMOVE : {remove}"
        )

        errors = []

        if not keep.is_file():
            errors.append("retained file does not exist")
        else:
            keep_sha = sha256_file(keep)

            if keep_sha != expected_sha:
                errors.append(
                    "retained file SHA-256 mismatch"
                )

        if not remove.is_file():
            errors.append("remove file does not exist")
        else:
            remove_sha = sha256_file(remove)

            if remove_sha != expected_sha:
                errors.append(
                    "remove file SHA-256 mismatch"
                )

        if errors:

            print("  REFUSED")

            for error in errors:
                print("   -", error)

            con.execute(
                """
                UPDATE media_physical_cleanup_manifest
                SET
                    status='FAILED',
                    error_message=?,
                    updated_at=CURRENT_TIMESTAMP
                WHERE cleanup_id=?
                """,
                (
                    "; ".join(errors),
                    cleanup_id,
                ),
            )

            con.commit()

            failed += 1

            print()
            continue

        remove.unlink()

        con.execute(
            """
            UPDATE media_physical_cleanup_manifest
            SET
                status='DELETED',
                error_message=NULL,
                updated_at=CURRENT_TIMESTAMP
            WHERE cleanup_id=?
            """,
            (cleanup_id,),
        )

        con.commit()

        print(
            "  VERIFIED BOTH COPIES → DELETED LOSING COPY"
        )
        print()

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)

    for status, count in con.execute(
        """
        SELECT
            status,
            COUNT(*)
        FROM media_physical_cleanup_manifest
        GROUP BY status
        ORDER BY status
        """
    ):
        print(
            f"{status:10} {count}"
        )

    con.close()

    if failed:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
