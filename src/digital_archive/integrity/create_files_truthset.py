#!/usr/bin/env python3
import argparse, csv, hashlib, json, sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"
DEFAULT_ROOT = Path.home() / "Master-Repository"

def sha256_file(path, chunk=1024*1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda: f.read(chunk), b""):
            h.update(b)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=str(DEFAULT_DB))
    ap.add_argument("--master-root", default=str(DEFAULT_ROOT))
    ap.add_argument("--output-dir", default=str(Path.home()/".archive/files_truthset_v1"))
    a = ap.parse_args()

    db = Path(a.db).expanduser().resolve()
    root = Path(a.master_root).expanduser().resolve()
    out = Path(a.output_dir).expanduser().resolve()
    if not db.is_file():
        raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir():
        raise SystemExit(f"ERROR: master root does not exist: {root}")
    out.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(db)
    con.row_factory = sqlite3.Row
    rows = con.execute("""
        SELECT file_id, sha256, master_path, filename, extension, size_bytes,
               media_type, capture_date, created_date, modified_date, status,
               notes, created_at, updated_at, canonical_path, storage_state,
               external_device_id, external_path, moved_out_at, storage_move_reason
        FROM files
        ORDER BY file_id
    """).fetchall()

    source_counts = dict(con.execute("SELECT file_id, COUNT(*) FROM file_sources GROUP BY file_id"))
    verified_counts = dict(con.execute(
        "SELECT file_id, COUNT(*) FROM copy_manifest WHERE status='VERIFIED' GROUP BY file_id"
    ))

    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    fields = [
        "truthset_version","truthset_created_utc","file_id","sha256","master_path",
        "canonical_path","filename","extension","size_bytes","media_type",
        "capture_date","created_date","modified_date","status","storage_state",
        "external_device_id","external_path","moved_out_at","storage_move_reason",
        "notes","created_at","updated_at","filesystem_checked","filesystem_exists",
        "filesystem_size_bytes","filesystem_sha256","filesystem_sha256_match",
        "source_count","verified_manifest_count"
    ]

    csv_path = out/"files_truthset.csv"
    missing, mismatches = [], []

    with csv_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for r in rows:
            d = dict(r)
            checked = bool(d["storage_state"] == "IN_MASTER" and d["master_path"])
            exists = False
            fs_size = fs_sha = None
            match = None

            if checked:
                p = Path(d["master_path"])
                if p.is_file():
                    exists = True
                    fs_size = p.stat().st_size
                    if fs_size == d["size_bytes"]:
                        fs_sha = sha256_file(p)
                        match = (fs_sha == d["sha256"])
                    else:
                        match = False
                    if not match:
                        mismatches.append(d["file_id"])
                else:
                    missing.append(d["file_id"])

            w.writerow({
                "truthset_version":"1.0",
                "truthset_created_utc":now,
                **d,
                "filesystem_checked":int(checked),
                "filesystem_exists":int(exists),
                "filesystem_size_bytes":fs_size,
                "filesystem_sha256":fs_sha,
                "filesystem_sha256_match":("" if match is None else int(match)),
                "source_count":source_counts.get(d["file_id"],0),
                "verified_manifest_count":verified_counts.get(d["file_id"],0)
            })

    summary = {
        "truthset_version":"1.0",
        "created_utc":now,
        "database":str(db),
        "master_root":str(root),
        "total_files_rows":len(rows),
        "status_counts":dict(Counter(r["status"] for r in rows)),
        "storage_state_counts":dict(Counter(r["storage_state"] for r in rows)),
        "media_type_counts":dict(Counter((r["media_type"] or "NULL") for r in rows)),
        "filesystem_checked_master_rows":sum(
            1 for r in rows if r["storage_state"]=="IN_MASTER" and r["master_path"]
        ),
        "filesystem_missing_master_rows":len(missing),
        "filesystem_sha_mismatches":len(mismatches),
        "verified_manifest_rows_total":sum(verified_counts.values())
    }
    (out/"files_truthset_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False)+"\n", encoding="utf-8"
    )
    (out/"FILES_TRUTHSET_METADATA.sql").write_text(f"""-- Files truth-set generated {now}
SELECT COUNT(*) AS files_rows FROM files;
SELECT status, COUNT(*) AS row_count FROM files GROUP BY status ORDER BY status;
SELECT storage_state, COUNT(*) AS row_count FROM files GROUP BY storage_state ORDER BY storage_state;
SELECT media_type, COUNT(*) AS row_count FROM files GROUP BY media_type ORDER BY media_type;
""", encoding="utf-8")

    print("="*72)
    print("FILES TRUTH SET")
    print("="*72)
    print("Files rows                  :", len(rows))
    print("IN_MASTER filesystem checks :", summary["filesystem_checked_master_rows"])
    print("Missing master files        :", len(missing))
    print("SHA-256 mismatches          :", len(mismatches))
    print("CSV                         :", csv_path)
    print("Summary JSON                :", out/"files_truthset_summary.json")

    con.close()
    if missing or mismatches:
        raise SystemExit(2)

if __name__ == "__main__":
    main()
