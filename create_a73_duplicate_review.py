#!/usr/bin/env python3

import csv
from pathlib import Path

INPUT = (
    Path.home()
    / "my_scripts/digital_archive/PHONE_A73_duplicates/duplicate_groups.csv"
)

OUTPUT = (
    Path.home()
    / "my_scripts/digital_archive/PHONE_A73_duplicates/"
      "PHONE_A73_duplicate_review.csv"
)

FIELDNAMES = [
    "sha256",
    "duplicate_group_size",
    "folder_name",
    "file_name",
    "relative_path",
    "size_bytes",
    "keep_decision",
    "manual_filename",
    "manual_canonical_path",
]


def main():
    if not INPUT.is_file():
        raise SystemExit(f"ERROR: input not found: {INPUT}")

    rows = []

    with INPUT.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)

        required = {
            "sha256",
            "duplicate_count",
            "size_bytes",
            "paths",
        }

        missing = required - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(
                f"ERROR: input missing columns: {sorted(missing)}"
            )

        for group in reader:
            sha = group["sha256"].strip()
            group_size = group["duplicate_count"].strip()
            size_bytes = group["size_bytes"].strip()

            # Paths were stored as "path1 | path2 | path3"
            paths = [
                p.strip()
                for p in group["paths"].split(" | ")
                if p.strip()
            ]

            for relative_path in paths:
                path = Path(relative_path)

                rows.append(
                    {
                        "sha256": sha,
                        "duplicate_group_size": group_size,
                        "folder_name": path.parent.as_posix(),
                        "file_name": path.name,
                        "relative_path": relative_path,
                        "size_bytes": size_bytes,
                        "keep_decision": "",
                        "manual_filename": "",
                        "manual_canonical_path": "",
                    }
                )

    # Sort by SHA, then folder, then filename.
    rows.sort(
        key=lambda r: (
            r["sha256"],
            r["folder_name"],
            r["file_name"],
        )
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=FIELDNAMES,
        )
        writer.writeheader()
        writer.writerows(rows)

    print("=" * 72)
    print("PHONE A73 DUPLICATE REVIEW CSV")
    print("=" * 72)
    print("Duplicate groups :", len(set(r["sha256"] for r in rows)))
    print("Physical rows    :", len(rows))
    print("Output           :", OUTPUT)
    print()
    print("Manual columns:")
    print("  keep_decision")
    print("  manual_filename")
    print("  manual_canonical_path")


if __name__ == "__main__":
    main()
