#!/usr/bin/env python3

import csv
import hashlib
import os
from datetime import datetime
from pathlib import Path

ROOT = Path.home() / "Migration-Work/Phone1-A73-Original/sdcard"
OUTPUT = Path.home() / "my_scripts/digital_archive/PHONE_A73_inventory.csv"

# Relative directory prefixes to exclude from the archive inventory.
# These are intentionally narrow: Android/media is NOT excluded.
EXCLUDED_DIRS = {
    "Android",
}

CHUNK_SIZE = 1024 * 1024


def should_exclude(relative_path: Path) -> bool:
    path_text = relative_path.as_posix().rstrip("/")

    for excluded in EXCLUDED_DIRS:
        if (
            path_text == excluded
            or path_text.startswith(excluded + "/")
        ):
            return True

    return False


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()

    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(CHUNK_SIZE), b""):
            h.update(chunk)

    return h.hexdigest()


def main():
    if not ROOT.is_dir():
        raise SystemExit(f"ERROR: mirror not found: {ROOT}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    files = []

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue

        rel = path.relative_to(ROOT)

        if should_exclude(rel):
            continue

        files.append(path)

    files.sort()

    print("=" * 78)
    print("PHONE A73 INVENTORY")
    print("=" * 78)
    print("Source :", ROOT)
    print("Output :", OUTPUT)
    print()
    print("Excluded directories:")
    for item in sorted(EXCLUDED_DIRS):
        print("  ", item)
    print()
    print("Files to hash:", len(files))
    print()

    with OUTPUT.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        writer.writerow([
            "source_relative_path",
            "filename",
            "size_bytes",
            "modified_time",
            "sha256",
        ])

        for i, path in enumerate(files, 1):
            rel = path.relative_to(ROOT)

            try:
                stat = path.stat()
                sha = sha256_file(path)

                writer.writerow([
                    rel.as_posix(),
                    path.name,
                    stat.st_size,
                    datetime.fromtimestamp(
                        stat.st_mtime
                    ).isoformat(timespec="seconds"),
                    sha,
                ])

                # Flush frequently so progress survives interruption.
                if i % 25 == 0:
                    f.flush()

                if i % 100 == 0 or i == len(files):
                    print(
                        f"Hashed {i}/{len(files)}",
                        flush=True,
                    )

            except Exception as exc:
                print(
                    f"ERROR: {rel}: {type(exc).__name__}: {exc}",
                    flush=True,
                )

    print()
    print("Inventory complete.")
    print("CSV:", OUTPUT)


if __name__ == "__main__":
    main()
