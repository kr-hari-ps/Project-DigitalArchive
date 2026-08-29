#!/usr/bin/env python3
import argparse, hashlib, shutil, sqlite3
from pathlib import Path

DEFAULT_DB = Path.home()/ "Master-Repository/.archive/catalog.db"
DEFAULT_ROOT = Path.home()/ "Master-Repository"
BATCH = "NONDOC_20260820_202341"
EXCLUDED = (2616, 3670, 3671, 3672, 3673, 3674)

def sha256_file(path, chunk=1024*1024):
    h=hashlib.sha256()
    with open(path,"rb") as f:
        for b in iter(lambda:f.read(chunk),b""):
            h.update(b)
    return h.hexdigest()

def inside(path, root):
    try:
        Path(path).resolve().relative_to(Path(root).resolve()); return True
    except ValueError:
        return False

def final_path(p):
    if p == "DCIM" or p.startswith("DCIM/"):
        return "Pictures/" + p
    if p == "schemas" or p.startswith("schemas/"):
        return "Electronics/" + p
    return p

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--db",default=str(DEFAULT_DB))
    ap.add_argument("--master-root",default=str(DEFAULT_ROOT))
    ap.add_argument("--batch",default=BATCH)
    mg=ap.add_mutually_exclusive_group(required=True)
    mg.add_argument("--dry-run",action="store_true")
    mg.add_argument("--execute",action="store_true")
    a=ap.parse_args()

    db=Path(a.db).expanduser().resolve()
    root=Path(a.master_root).expanduser().resolve()
    if not db.is_file(): raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir(): raise SystemExit(f"ERROR: master root does not exist: {root}")

    con=sqlite3.connect(db)
    rows=con.execute("""
        SELECT inventory_id, source_device_id, source_path,
               sha256, size_bytes, manual_category, manual_canonical_path
        FROM multi_media_assets
        WHERE batch_id=?
          AND manual_canonical_path IS NOT NULL
          AND TRIM(manual_canonical_path)<>''
          AND inventory_id NOT IN (?,?,?,?,?,?)
        ORDER BY inventory_id
    """,(a.batch,*EXCLUDED)).fetchall()

    print("="*78)
    print("MEDIA DIRECT CANONICAL REBUILD v2")
    print("="*78)
    print("MODE :", "DRY RUN" if a.dry_run else "EXECUTE")
    print("ROWS :", len(rows))
    print("EXCLUDED :", EXCLUDED)
    print()

    if len(rows)!=579:
        con.close()
        raise SystemExit(f"ABORT: expected 573 rows, found {len(rows)}")

    errs=[]; dests={}; plans=[]
    corr={"DCIM_to_Pictures_DCIM":0,"schemas_to_Electronics_schemas":0,"unchanged":0}

    for inv,dev,src,expected_sha,expected_size,cat,reviewed in rows:
        cp=final_path(reviewed)
        if cp!=reviewed:
            if reviewed=="DCIM" or reviewed.startswith("DCIM/"):
                corr["DCIM_to_Pictures_DCIM"]+=1
            else:
                corr["schemas_to_Electronics_schemas"]+=1
        else:
            corr["unchanged"]+=1

        srcp=Path(src).expanduser().resolve()
        dst=(root/cp.lstrip("/")).resolve()

        if not inside(dst,root):
            errs.append(f"{inv}: destination outside master")
            continue
        if not srcp.is_file():
            errs.append(f"{inv}: source missing: {srcp}")
            continue
        if dst in dests and dests[dst]!=inv:
            errs.append(f"destination collision: {dst} ({dests[dst]}, {inv})")
            continue
        dests[dst]=inv

        if srcp.stat().st_size != expected_size:
            errs.append(f"{inv}: source size mismatch")
            continue
        if sha256_file(srcp) != expected_sha:
            errs.append(f"{inv}: source SHA-256 mismatch")
            continue

        state="AVAILABLE"
        if dst.exists():
            if not dst.is_file():
                errs.append(f"{inv}: destination is not a file: {dst}")
                continue
            if dst.stat().st_size==expected_size and sha256_file(dst)==expected_sha:
                state="ALREADY_IDENTICAL"
            else:
                errs.append(f"{inv}: destination exists with different content: {dst}")
                continue

        plans.append((inv,dev,srcp,expected_sha,expected_size,cp,dst,state))

    print("PLANNED ROWS       :", len(plans))
    print("ERRORS             :", len(errs))
    print("PATH CORRECTIONS   :", corr)
    print("NEW COPIES         :", sum(1 for x in plans if x[-1]=="AVAILABLE"))
    print("ALREADY IDENTICAL  :", sum(1 for x in plans if x[-1]=="ALREADY_IDENTICAL"))
    if errs:
        for e in errs[:100]: print("ERROR:",e)
        con.close()
        raise SystemExit(2)

    if a.dry_run:
        print("DRY RUN ONLY - no files changed.")
        con.close()
        return

    ok=failed=0
    for inv,dev,src,expected_sha,expected_size,cp,dst,state in plans:
        print(f"[{inv}] {dev} -> {cp}")
        try:
            dst.parent.mkdir(parents=True,exist_ok=True)
            if state=="ALREADY_IDENTICAL":
                print("  SKIP: identical destination")
                ok+=1
                continue
            shutil.copy2(src,dst)
            if dst.stat().st_size != expected_size:
                raise RuntimeError("post-copy size mismatch")
            if sha256_file(dst) != expected_sha:
                raise RuntimeError("post-copy SHA-256 mismatch")
            print("  COPIED + VERIFIED")
            ok+=1
        except Exception as exc:
            print("  FAILED:",type(exc).__name__,exc)
            failed+=1

    print("="*78)
    print("SUMMARY")
    print("Rows        :",len(plans))
    print("Successful  :",ok)
    print("Failed      :",failed)
    print("Corrections :",corr)
    con.close()
    if failed: raise SystemExit(2)

if __name__=="__main__": main()
