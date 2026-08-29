#!/usr/bin/env python3

import argparse
import sqlite3
from pathlib import Path


SCHEMA = """
CREATE TABLE IF NOT EXISTS canonical_plan (
    plan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER NOT NULL UNIQUE,
    current_canonical_path TEXT,
    proposed_canonical_path TEXT NOT NULL,
    proposal_rule TEXT,
    proposal_reason TEXT,
    review_status TEXT NOT NULL DEFAULT 'REVIEW'
        CHECK(review_status IN ('REVIEW','APPROVED','REJECTED','APPLIED')),
    reviewed_at TEXT,
    reviewed_by TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_canonical_plan_status
    ON canonical_plan(review_status);

CREATE INDEX IF NOT EXISTS idx_canonical_plan_proposed
    ON canonical_plan(proposed_canonical_path);
"""


def normalize(path):
    return path.replace("\\", "/").strip("/")


def source_relative(source_path, source_roots):
    """
    Convert an absolute source path into a source-relative path.

    Example:
      /home/harikr/Migration-Work/Tablet-Original/Download/a.pdf
        -> Download/a.pdf
    """
    source = Path(source_path).expanduser().resolve()

    for device_id, root in source_roots:
        root = Path(root).expanduser().resolve()

        try:
            return device_id.upper(), source.relative_to(root)
        except ValueError:
            continue

    raise ValueError(
        f"Source path is outside configured source roots: {source_path}"
    )


def propose_canonical_path(device_id, relative_path, filename):
    """
    Conservative first-pass document rules.

    No filesystem operation occurs here.
    """

    parts = list(relative_path.parts)
    lower = [p.lower() for p in parts]

    # ---------------------------------------------------------
    # Tablet epsilon structure
    #
    # Preserve epsilon explicitly:
    #
    # Documents/epsilon/Personal/...
    # ---------------------------------------------------------
    if "`epsilon" in lower:
        idx = lower.index("`epsilon")
        tail = parts[idx:]

        return (
            "Documents/" + "/".join(tail),
            "PRESERVE_TABLET_PERSONAL_STRUCTURE",
            "Preserve the existing tablet epsilon/Personal hierarchy."
        )

    # ---------------------------------------------------------
    # Tablet #Personal Docs#
    # ---------------------------------------------------------
    if "#personal docs#" in lower:
        idx = lower.index("#personal docs#")
        tail = parts[idx + 1:]

        destination = "Documents/Personal"

        if tail:
            destination += "/" + "/".join(tail)

        return (
            destination,
            "PERSONAL_DOCS",
            "Consolidate #Personal Docs# under Documents/Personal."
        )

    # ---------------------------------------------------------
    # PC ITR
    # ---------------------------------------------------------
    if "itr" in lower:
        idx = lower.index("itr")
        tail = parts[idx + 1:]

        destination = "Documents/Finance/ITR"

        if tail:
            destination += "/" + "/".join(tail)

        return (
            destination,
            "PRESERVE_PC_ITR_STRUCTURE",
            "Preserve the existing PC ITR structure under Finance/ITR."
        )

    # ---------------------------------------------------------
    # PC personal_job
    # ---------------------------------------------------------
    if "personal_job" in lower:
        idx = lower.index("personal_job")
        tail = parts[idx + 1:]

        destination = "Documents/Work"

        if tail:
            destination += "/" + "/".join(tail)

        return (
            destination,
            "PERSONAL_JOB",
            "Place the existing personal_job hierarchy under Documents/Work."
        )

    # ---------------------------------------------------------
    # Tablet Downloads
    # ---------------------------------------------------------
    if lower and lower[0] == "download":

        tail = parts[1:]

        # ITR package
        if tail and tail[0].lower() == "itr2_ay_25-26_v1.1":
            destination = "Documents/Finance/ITR"

            if tail:
                destination += "/" + "/".join(tail)

            return (
                destination,
                "DOWNLOAD_ITR",
                "Downloaded ITR package placed under Finance/ITR."
            )

        # Quick Share
        if tail and tail[0].lower() == "quick share":
            rest = tail[1:]
            destination = "Documents/To-Review/Quick Share"

            if rest:
                destination += "/" + "/".join(rest)

            return (
                destination,
                "QUICK_SHARE",
                "Quick Share documents grouped for later review."
            )

        # Other Downloads
        destination = "Documents/To-Review/Downloads"

        if tail:
            destination += "/" + "/".join(tail)
        else:
            destination += "/" + filename

        return (
            destination,
            "DOWNLOAD_TO_REVIEW",
            "Downloaded document with no stronger automatic classification."
        )

    # ---------------------------------------------------------
    # Development/project folders
    # ---------------------------------------------------------
    if any(
        item.lower() in {
            "google_cloud",
            "schemas",
            "apps_scripts",
            "node_modules",
        }
        for item in parts
    ):
        destination = "Documents/_Review-NonPersonal/" + "/".join(parts)

        return (
            destination,
            "NON_PERSONAL_REVIEW",
            "Path appears to contain development/project material."
        )

    # ---------------------------------------------------------
    # Conservative fallback
    #
    # IMPORTANT:
    # Uses the RELATIVE source path only.
    # Absolute /home/harikr/... is never included.
    # ---------------------------------------------------------
    destination = "Documents/To-Review/" + "/".join(parts)

    return (
        destination,
        "CONSERVATIVE_REVIEW",
        "No confident category rule; preserve source-relative structure."
    )


def main():

    parser = argparse.ArgumentParser(
        description="Create canonical document path proposals."
    )

    parser.add_argument(
        "--db",
        default=str(
            Path.home() / "Master-Repository/.archive/catalog.db"
        ),
    )

    parser.add_argument(
        "--source-root",
        action="append",
        nargs=2,
        metavar=("DEVICE_ID", "ROOT"),
        required=True,
        help="Source device and absolute root. Repeat for each device."
    )

    args = parser.parse_args()

    db = Path(args.db).expanduser().resolve()

    if not db.is_file():
        raise SystemExit(
            f"ERROR: database does not exist: {db}"
        )

    source_roots = [
        (device.upper(), Path(root).expanduser().resolve())
        for device, root in args.source_root
    ]

    con = sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys = ON")
    con.executescript(SCHEMA)

    rows = con.execute(
        """
        SELECT
            f.file_id,
            f.filename,
            fs.source_path,
            f.canonical_path
        FROM files f
        JOIN file_sources fs
            ON fs.file_id = f.file_id
        LEFT JOIN duplicate_members dm
            ON dm.file_id = f.file_id
        LEFT JOIN duplicate_groups dg
            ON dg.duplicate_group_id = dm.duplicate_group_id
        WHERE
            dg.duplicate_group_id IS NULL
            OR dg.chosen_file_id = f.file_id
        ORDER BY f.file_id
        """
    ).fetchall()

    generated = 0
    errors = []

    for file_id, filename, source_path, current_canonical in rows:

        try:
            device_id, relative = source_relative(
                source_path,
                source_roots
            )

            proposed, rule, reason = propose_canonical_path(
                device_id,
                relative,
                filename
            )

        except ValueError as exc:
            errors.append(str(exc))
            continue

        proposed = proposed.rstrip("/")

        existing = con.execute(
            """
            SELECT
                review_status,
                manual_canonical_path,
                manual_category,
                manual_notes
            FROM canonical_plan
            WHERE file_id=?
            """,
            (file_id,)
        ).fetchone()

        # IMPORTANT:
        # If a row has already been manually classified or approved,
        # do not overwrite it.
        if existing:
            review_status, manual_path, manual_category, manual_notes = existing

            if (
                review_status in ("APPROVED", "APPLIED")
                or manual_path
                or manual_category
                or manual_notes
            ):
                continue

        con.execute(
            """
            INSERT INTO canonical_plan (
                file_id,
                current_canonical_path,
                proposed_canonical_path,
                proposal_rule,
                proposal_reason,
                review_status
            )
            VALUES (?, ?, ?, ?, ?, 'REVIEW')

            ON CONFLICT(file_id) DO UPDATE SET
                current_canonical_path =
                    excluded.current_canonical_path,
                proposed_canonical_path =
                    excluded.proposed_canonical_path,
                proposal_rule =
                    excluded.proposal_rule,
                proposal_reason =
                    excluded.proposal_reason,
                updated_at =
                    CURRENT_TIMESTAMP
            """,
            (
                file_id,
                current_canonical,
                proposed,
                rule,
                reason,
            )
        )

        generated += 1

    con.commit()

    print("MODE            : CANONICAL PLAN ONLY")
    print("Database        :", db)
    print("Master records  :", len(rows))
    print("Plans generated :", generated)

    if errors:
        print()
        print("SOURCE ROOT ERRORS:")
        for error in errors:
            print(" -", error)

    print()
    print(
        "No files were moved, renamed, deleted, or modified."
    )

    con.close()

    if errors:
        raise SystemExit(2)


if __name__ == "__main__":
    main()