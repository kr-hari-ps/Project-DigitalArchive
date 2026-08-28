#!/usr/bin/env python3
import argparse, csv, hashlib, sqlite3
from pathlib import Path

DEFAULT_DB = Path.home()/ "Master-Repository/.archive/catalog.db"

def sha256_file(path, chunk=1024*1024):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda:f.read(chunk),b""):
            h.update(b)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("truthset_csv")
    ap.add_argument("--db",default=str(DEFAULT_DB))
    args=ap.parse_args()

    truth_path=Path(args.truthset_csv)
    with truth_path.open("r",encoding="utf-8",newline="") as fh:
        truth={int(r["file_id"]):r for r in csv.DictReader(fh)}

    con=sqlite3.connect(Path(args.db).expanduser())
    con.row_factory=sqlite3.Row
    current={
        r["file_id"]:dict(r)
        for r in con.execute("""
          SELECT file_id,sha256,master_path,canonical_path,filename,extension,
                 size_bytes,media_type,status,storage_state
          FROM files
        """)
    }

    added=sorted(set(current)-set(truth))
    removed=sorted(set(truth)-set(current))
    changed=[]
    fields=["sha256","master_path","canonical_path","filename","extension",
            "size_bytes","media_type","status","storage_state"]

    for fid in sorted(set(current)&set(truth)):
        diffs=[]
        for f in fields:
            old=truth[fid].get(f,"")
            new="" if current[fid][f] is None else str(current[fid][f])
            if str(old)!=new:
                diffs.append((f,old,new))
        if diffs:
            changed.append((fid,diffs))

    fs_missing=[]
    fs_mismatch=[]
    for fid,r in current.items():
        if r["storage_state"]!="IN_MASTER" or not r["master_path"]:
            continue
        p=Path(r["master_path"])
        if not p.is_file():
            fs_missing.append(fid)
            continue
        if p.stat().st_size!=r["size_bytes"] or sha256_file(p)!=r["sha256"]:
            fs_mismatch.append(fid)

    print("="*72)
    print("FILES TRUTH-SET COMPARISON")
    print("="*72)
    print("Truth-set rows :",len(truth))
    print("Current rows   :",len(current))
    print("Added rows     :",len(added))
    print("Removed rows   :",len(removed))
    print("Changed rows   :",len(changed))
    print("FS missing     :",len(fs_missing))
    print("FS mismatches  :",len(fs_mismatch))
    con.close()

    if added or removed or changed or fs_missing or fs_mismatch:
        raise SystemExit(2)

if __name__=="__main__":
    main()
