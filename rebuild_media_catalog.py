#!/usr/bin/env python3
import argparse
import hashlib
import sqlite3
from pathlib import Path
from datetime import datetime

DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"
DEFAULT_ROOT = Path.home() / "Master-Repository"
BATCH = "NONDOC_20260820_202341"
EXCLUDED = (2616, 3670, 3671, 3672, 3673, 3674)

def sha256_file(path, chunk=1024*1024):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda: f.read(chunk), b""):
            h.update(b)
    return h.hexdigest()

def fn_from_cp(cp):
    return cp.rstrip("/").split("/")[-1]

def ext_from_fn(fn):
    return fn.rsplit(".", 1)[1].lower() if "." in fn and not fn.startswith(".") else None

def media_type(category, filename):
    c = (category or "").strip().upper()
    ext = (ext_from_fn(filename) or "").lower()
    if c.startswith("PHOTO") or c in {"IMAGE","PICTURE","PICTURES","ICON","PHOTO_ID","PHOTO_ICONS"}:
        return "image"
    if c in {"MUSIC","MUSIC_VEDIC","RINGTONE","AUDIO","RECORDING"}:
        return "audio"
    if c in {"VIDEO","MOVIE","MOVIES"}:
        return "video"
    if c in {"ARCHIVE","ARCHIVES"}:
        return "archive"
    if ext in {"jpg","jpeg","png","gif","webp","heic","heif","tif","tiff","bmp","svg","avif"}:
        return "image"
    if ext in {"mp3","m4a","aac","flac","wav","ogg","opus","wma"}:
        return "audio"
    if ext in {"mp4","mkv","avi","mov","webm","m4v","3gp","wmv"}:
        return "video"
    if ext in {"zip","rar","7z","tar","gz","bz2","xz","iso"}:
        return "archive"
    return "other"

def parent_folders(cp):
    parts=[p for p in cp.split("/") if p]
    return ["/".join(parts[:i]) for i in range(1,len(parts))]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--db",default=str(DEFAULT_DB))
    ap.add_argument("--master-root",default=str(DEFAULT_ROOT))
    ap.add_argument("--batch",default=BATCH)
    ap.add_argument("--execute",action="store_true")
    a=ap.parse_args()

    db=Path(a.db).expanduser().resolve()
    root=Path(a.master_root).expanduser().resolve()
    if not db.is_file(): raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir(): raise SystemExit(f"ERROR: master root does not exist: {root}")

    con=sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")

    rows=con.execute("""
      SELECT inventory_id, source_device_id, source_path, filename,
             sha256, size_bytes, source_modified_at,
             manual_category, manual_canonical_path, manual_notes
      FROM multi_media_assets
      WHERE batch_id=?
        AND manual_canonical_path IS NOT NULL
        AND TRIM(manual_canonical_path)<>''
        AND inventory_id NOT IN (?,?,?,?,?,?)
      ORDER BY inventory_id
    """,(a.batch,*EXCLUDED)).fetchall()

    print("="*78)
    print("MEDIA CATALOG REBUILD v2")
    print("="*78)
    print("MODE :", "EXECUTE" if a.execute else "DRY RUN")
    print("INPUT ROWS :", len(rows))
    if len(rows)!=579:
        con.close()
        raise SystemExit(f"ABORT: expected 579 catalog rows, found {len(rows)}")

    errors=[]; seen={}; new=[]; reused=[]; source_plan=[]; manifest_plan=[]; folders=set()

    for inv,dev,src,orig,sha,size,mod,cat,cp,notes in rows:
        cp=cp.strip()
        if cp in seen:
            errors.append(f"duplicate canonical path {cp}: {seen[cp]} and {inv}")
            continue
        seen[cp]=inv
        p=(root/cp.lstrip("/")).resolve()
        if not p.is_file():
            errors.append(f"{inv}: missing canonical file {p}")
            continue
        if p.stat().st_size != size:
            errors.append(f"{inv}: size mismatch at {p}")
            continue
        if sha256_file(p) != sha:
            errors.append(f"{inv}: SHA-256 mismatch at {p}")
            continue

        existing=con.execute("""
          SELECT file_id, canonical_path, storage_state, status
          FROM files
          WHERE sha256=?
          ORDER BY
            CASE WHEN storage_state='IN_MASTER' AND status='MASTER' THEN 0
                 WHEN storage_state='IN_MASTER' THEN 1 ELSE 2 END,
            file_id
        """,(sha,)).fetchall()

        chosen=None
        for r in existing:
            if r[2]=='IN_MASTER' and r[3]=='MASTER' and r[1]==cp:
                chosen=r; break
        if chosen is None:
            for r in existing:
                if r[2]=='IN_MASTER' and r[3]=='MASTER':
                    chosen=r; break

        fid=chosen[0] if chosen else None
        if fid is not None:
            reused.append((inv,fid,cp,sha))
        else:
            fn=fn_from_cp(cp)
            new.append((inv,sha,str(p),fn,ext_from_fn(fn),size,media_type(cat,fn),mod,notes,cp))

        source_plan.append((inv,fid,dev,src,orig,size,sha,mod))
        manifest_plan.append((inv,fid,dev,src,str(p),sha,size,size))
        folders.update(parent_folders(cp))

    if errors:
        print("VALIDATION ERRORS:", len(errors))
        for e in errors[:100]: print(" -",e)
        con.close()
        raise SystemExit(2)

    print("REUSE EXISTING MASTER :", len(reused))
    print("NEW FILE IDENTITIES   :", len(new))
    print("FOLDER PATHS          :", len(folders))
    print("CANONICAL COLLISIONS  : 0")

    if not a.execute:
        print("DRY RUN ONLY - no database changes.")
        con.close(); return

    con.execute("BEGIN")
    try:
        new_ids={}
        for inv,sha,mp,fn,ext,size,mt,mod,notes,cp in new:
            cur=con.execute("""
              INSERT INTO files
              (sha256,master_path,filename,extension,size_bytes,media_type,
               modified_date,status,notes,canonical_path,storage_state,updated_at)
              VALUES (?,?,?,?,?,?,?,'MASTER',?,?,'IN_MASTER',CURRENT_TIMESTAMP)
            """,(sha,mp,fn,ext,size,mt,mod,notes,cp))
            new_ids[inv]=cur.lastrowid

        source_inserted=0
        for inv,fid,dev,src,orig,size,sha,mod in source_plan:
            if fid is None: fid=new_ids[inv]
            exists=con.execute("""
              SELECT 1 FROM file_sources
              WHERE file_id=? AND device_id=? AND source_path=?
            """,(fid,dev,src)).fetchone()
            if not exists:
                con.execute("""
                  INSERT INTO file_sources
                  (file_id,device_id,source_path,source_filename,source_size_bytes,
                   source_sha256,source_modified_date)
                  VALUES (?,?,?,?,?,?,?)
                """,(fid,dev,src,orig,size,sha,mod))
                source_inserted+=1

        manifest_inserted=0
        ts=datetime.now().astimezone().isoformat(timespec="seconds")
        for inv,fid,dev,src,dst,sha,ss,ds in manifest_plan:
            if fid is None: fid=new_ids[inv]
            exists=con.execute("""
              SELECT 1 FROM copy_manifest
              WHERE file_id=? AND source_device_id=? AND source_path=? AND destination_path=?
            """,(fid,dev,src,dst)).fetchone()
            if not exists:
                con.execute("""
                  INSERT INTO copy_manifest
                  (file_id,source_device_id,source_path,destination_path,source_sha256,
                   destination_sha256,source_size_bytes,destination_size_bytes,copied_at,
                   verified_at,status,verification_method,notes)
                  VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
                """,(fid,dev,src,dst,sha,sha,ss,ds,ts,ts,"VERIFIED",
                     "SHA256_DIRECT_MEDIA_REBUILD",
                     "Catalog rebuilt from verified direct media canonical rebuild."))
                manifest_inserted+=1

        folder_inserted=0
        for fp in sorted(folders,key=lambda x:(x.count("/"),x)):
            if not con.execute("SELECT 1 FROM folders WHERE master_path=?",(fp,)).fetchone():
                name=fp.rstrip("/").split("/")[-1]
                parent=fp.rstrip("/").rsplit("/",1)[0] if "/" in fp.rstrip("/") else None
                con.execute("""
                  INSERT INTO folders
                  (master_path,folder_name,parent_path,folder_type,description,device_summary,updated_at)
                  VALUES (?,?,?,?,?,?,CURRENT_TIMESTAMP)
                """,(fp,name,parent,"MASTER","Created during multimedia catalog rebuild.",None))
                folder_inserted+=1

        con.commit()
    except Exception:
        con.rollback(); con.close(); raise

    print("CATALOG REBUILD COMPLETE")
    print("New files inserted   :",len(new))
    print("Existing files reused:",len(reused))
    print("file_sources inserted:",source_inserted)
    print("copy_manifest inserted:",manifest_inserted)
    print("folders inserted     :",folder_inserted)
    con.close()

if __name__=="__main__": main()
