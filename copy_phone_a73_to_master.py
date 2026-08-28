#!/usr/bin/env python3

import csv
import hashlib
import os
import shutil
import sys
from pathlib import Path
from datetime import datetime

MANIFEST = Path.home() / \
    "my_scripts/digital_archive/PHONE_A73_physical_copy_manifest.csv"

MASTER_ROOT = Path.home() / "Master-Repository"

LOG = Path.home() / \
    "my_scripts/digital_archive/PHONE_A73_physical_copy.log"

CHUNK = 4 * 1024 * 1024


def sha256_file(path):
    h = hashlib.sha256()

    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(CHUNK), b""):
            h.update(chunk)

    return h.hexdigest()


def safe_destination(relative_path):
    p = Path(relative_path)

    if p.is_absolute():
        raise RuntimeError(
            f"Absolute canonical path is not allowed: {relative_path}"
        )

    if ".." in p.parts:
        raise RuntimeError(
            f"Path traversal detected: {relative_path}"
        )

    return MASTER_ROOT / p


def log(message):
    line = (
        f"{datetime.now().isoformat(timespec='seconds')} "
        f"{message}"
    )

    print(line, flush=True)

    with LOG.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def main():

    if not MANIFEST.is_file():
        raise SystemExit(
            f"Manifest not found: {MANIFEST}"
        )

    if not MASTER_ROOT.is_dir():
        raise SystemExit(
            f"Master repository not found: {MASTER_ROOT}"
        )

    with MANIFEST.open(
        "r",
        encoding="utf-8",
        newline=""
    ) as f:
        rows = list(csv.DictReader(f))

    required = {
        "source_path",
        "size_bytes",
        "sha256",
        "manual_canonical_path",
    }

    missing = required - set(rows[0])

    if missing:
        raise SystemExit(
            f"Manifest missing columns: {sorted(missing)}"
        )

    # Ensure manifest really contains one row per SHA/path.
    sha_seen = set()
    path_seen = set()

    for n, row in enumerate(rows, 2):

        sha = row["sha256"].strip().lower()
        dest_rel = row["manual_canonical_path"].strip()

        if not sha:
            raise SystemExit(
                f"Blank SHA at manifest row {n}"
            )

        if sha in sha_seen:
            raise SystemExit(
                f"Duplicate SHA at manifest row {n}: {sha}"
            )

        if dest_rel in path_seen:
            raise SystemExit(
                f"Duplicate destination at manifest row {n}: {dest_rel}"
            )

        sha_seen.add(sha)
        path_seen.add(dest_rel)

    print("=" * 78)
    print("PHONE A73 → MASTER REPOSITORY")
    print("=" * 78)
    print("Manifest rows :", len(rows))
    print("Unique SHA    :", len(sha_seen))
    print("Master root   :", MASTER_ROOT)
    print()

    counters = {
        "COPIED": 0,
        "ALREADY_PRESENT": 0,
        "FAILED": 0,
    }

    total_bytes = 0

    for i, row in enumerate(rows, 1):

        source = Path(row["source_path"]).expanduser()
        expected_sha = row["sha256"].strip().lower()
        expected_size = int(row["size_bytes"])
        dest = safe_destination(
            row["manual_canonical_path"].strip()
        )

        log(
            f"[{i}/{len(rows)}] "
            f"{row['manual_canonical_path']}"
        )

        if not source.is_file():
            counters["FAILED"] += 1
            log(f"ERROR: source missing: {source}")
            raise SystemExit(2)

        actual_source_size = source.stat().st_size

        if actual_source_size != expected_size:
            counters["FAILED"] += 1
            log(
                f"ERROR: source size mismatch: "
                f"expected={expected_size} "
                f"actual={actual_source_size}"
            )
            raise SystemExit(2)

        dest.parent.mkdir(
            parents=True,
            exist_ok=True
        )

        if dest.exists():

            if not dest.is_file():
                counters["FAILED"] += 1
                log(
                    f"ERROR: destination exists but is not a file: "
                    f"{dest}"
                )
                raise SystemExit(2)

            actual_dest_size = dest.stat().st_size

            if actual_dest_size != expected_size:
                counters["FAILED"] += 1
                log(
                    f"ERROR: destination collision/size mismatch: "
                    f"{dest}"
                )
                raise SystemExit(2)

            dest_sha = sha256_file(dest)

            if dest_sha != expected_sha:
                counters["FAILED"] += 1
                log(
                    f"ERROR: destination SHA mismatch: "
                    f"expected={expected_sha} "
                    f"actual={dest_sha}"
                )
                raise SystemExit(2)

            counters["ALREADY_PRESENT"] += 1
            log("ALREADY_PRESENT verified by SHA")
            continue

        # Copy to a temporary file in the destination directory.
        temp = dest.with_name(
            dest.name + ".a73-copying"
        )

        if temp.exists():
            temp.unlink()

        shutil.copy2(source, temp)

        temp_size = temp.stat().st_size

        if temp_size != expected_size:
            temp.unlink(missing_ok=True)

            counters["FAILED"] += 1
            log("ERROR: copied file size mismatch")
            raise SystemExit(2)

        temp_sha = sha256_file(temp)

        if temp_sha != expected_sha:
            temp.unlink(missing_ok=True)

            counters["FAILED"] += 1
            log(
                f"ERROR: copied file SHA mismatch: "
                f"expected={expected_sha} "
                f"actual={temp_sha}"
            )
            raise SystemExit(2)

        os.replace(temp, dest)

        counters["COPIED"] += 1
        total_bytes += expected_size

        log(
            f"COPIED + VERIFIED "
            f"{expected_size / 1024**2:.2f} MiB"
        )

    print()
    print("=" * 78)
    print("COPY COMPLETE")
    print("=" * 78)

    for key, value in counters.items():
        print(f"{key:20}: {value}")

    print(
        f"Bytes copied this run : "
        f"{total_bytes:,}"
    )

    print("Log:", LOG)


if __name__ == "__main__":
    main()
