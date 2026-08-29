#!/usr/bin/env python3
import argparse
import csv
import hashlib
import shutil
from pathlib import Path


def sha256_file(path, chunk_size=1024 * 1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(chunk_size), b""):
            h.update(chunk)
    return h.hexdigest()


def load_manifest(path):
    required = {
        "manifest_id",
        "source_device_id",
        "source_relative_path",
        "source_path",
        "destination_path",
        "sha256",
        "size_bytes",
    }

    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)

        if reader.fieldnames is None:
            raise SystemExit("ERROR: manifest has no header")

        missing = required - set(reader.fieldnames)
        if missing:
            raise SystemExit(
                f"ERROR: missing manifest columns: {sorted(missing)}"
            )

        rows = []
        for row_no, row in enumerate(reader, start=2):
            try:
                row["size_bytes"] = int(row["size_bytes"])
            except Exception:
                raise SystemExit(
                    f"ERROR: row {row_no}: invalid size_bytes"
                )

            row["sha256"] = row["sha256"].strip().lower()

            if len(row["sha256"]) != 64:
                raise SystemExit(
                    f"ERROR: row {row_no}: SHA-256 must be 64 hex characters"
                )

            rows.append(row)

    return rows


def main():
    parser = argparse.ArgumentParser(
        description="Manifest-driven physical copy with SHA-256 verification."
    )
    parser.add_argument("manifest_csv")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--execute", action="store_true")
    args = parser.parse_args()

    manifest = Path(args.manifest_csv).expanduser().resolve()

    if not manifest.is_file():
        raise SystemExit(
            f"ERROR: manifest does not exist: {manifest}"
        )

    rows = load_manifest(manifest)

    errors = []
    plans = {}
    destinations = {}

    for row in rows:
        mid = row["manifest_id"]
        source = Path(row["source_path"]).expanduser().resolve()
        destination = Path(row["destination_path"]).expanduser().resolve()

        if destination in destinations:
            errors.append(
                f"{mid}: destination collision with "
                f"{destinations[destination]}: {destination}"
            )
            continue

        destinations[destination] = mid

        if not source.is_file():
            errors.append(
                f"{mid}: source missing: {source}"
            )
            continue

        expected_size = row["size_bytes"]
        expected_sha = row["sha256"]

        actual_size = source.stat().st_size
        if actual_size != expected_size:
            errors.append(
                f"{mid}: source size mismatch "
                f"(expected={expected_size}, actual={actual_size})"
            )
            continue

        actual_sha = sha256_file(source)
        if actual_sha != expected_sha:
            errors.append(
                f"{mid}: source SHA-256 mismatch: {source}"
            )
            continue

        state = "COPY_REQUIRED"

        if destination.exists():
            if not destination.is_file():
                errors.append(
                    f"{mid}: destination exists but is not a file: "
                    f"{destination}"
                )
                continue

            destination_size = destination.stat().st_size
            destination_sha = sha256_file(destination)

            if (
                destination_size == expected_size
                and destination_sha == expected_sha
            ):
                state = "ALREADY_IDENTICAL"
            else:
                errors.append(
                    f"{mid}: destination exists with different content: "
                    f"{destination}"
                )
                continue

        plans[mid] = (row, source, destination, state)

    print("=" * 78)
    print("PHYSICAL COPY / MANIFEST")
    print("=" * 78)
    print("MODE              :", "DRY RUN" if args.dry_run else "EXECUTE")
    print("MANIFEST ROWS     :", len(rows))
    print("PLANNED ROWS      :", len(plans))
    print("ERRORS            :", len(errors))

    copy_required = sum(
        1 for _, _, _, state in plans.values()
        if state == "COPY_REQUIRED"
    )
    identical = sum(
        1 for _, _, _, state in plans.values()
        if state == "ALREADY_IDENTICAL"
    )

    print("COPY REQUIRED     :", copy_required)
    print("ALREADY IDENTICAL :", identical)

    if errors:
        print()
        for error in errors[:100]:
            print("ERROR:", error)
        raise SystemExit(2)

    if args.dry_run:
        print()
        print("DRY RUN ONLY - no physical files changed.")
        return

    successful = 0

    for mid, (row, source, destination, state) in plans.items():
        expected_size = row["size_bytes"]
        expected_sha = row["sha256"]

        print(f"[{mid}]")
        print(f"  FROM: {source}")
        print(f"  TO  : {destination}")

        destination.parent.mkdir(parents=True, exist_ok=True)

        if state == "ALREADY_IDENTICAL":
            print("  SKIP: destination already matches SHA-256")
            successful += 1
            continue

        shutil.copy2(source, destination)

        copied_size = destination.stat().st_size
        if copied_size != expected_size:
            raise SystemExit(
                f"{mid}: post-copy size mismatch"
            )

        copied_sha = sha256_file(destination)
        if copied_sha != expected_sha:
            raise SystemExit(
                f"{mid}: post-copy SHA-256 mismatch"
            )

        print("  COPIED + VERIFIED")
        successful += 1

    print("=" * 78)
    print("COPY COMPLETE")
    print("Manifest rows :", len(rows))
    print("Successful    :", successful)


if __name__ == "__main__":
    main()
