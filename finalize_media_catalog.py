#!/usr/bin/env python3
import argparse, hashlib, sqlite3
from pathlib import Path
from datetime import datetime

DEFAULT_DB=Path.home()/ "Master-Repository/.archive/catalog.db"
DEFAULT_ROOT=Path.home()/ "Master-Repository"
MEDIA_BATCH="NONDOC_20260820_202341"
MOVE_BATCH="MEDIA_CANONICAL_20260823"

def sha256_file(p, chunk=1024*1024):
    h=hashlib.sha256()
    with open(p,"rb") as f:
        while True:
            b=f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def fname(cp): return cp.rstrip("/").split("/")[-1]
def ext(fn):
    return fn.rsplit(".",1)[1].lower() if "." in fn and not fn.startswith(".") else None

def media_type(cat, fn):
    c=(cat or "").strip().upper(); e=(ext(fn) or "")
    if c.startswith("PHOTO") or c in {"IMAGE","PICTURE","PICTURES"}: return "image"
    if c in {"MUSIC","AUDIO"}: return "audio"
    if c in {"VIDEO","VIDEOS","MOVIE","MOVIES"}: return "video"
    if c in {"ARCHIVE","ARCHIVES"}: return "archive"
    if e in {"jpg","jpeg","png","gif","webp","heic","heif","tif","tiff","bmp","svg","avif"}: return "image"
    if e in {"mp3","m4a","aac","flac","wav","ogg","opus","wma"}: return "audio"
    if e in {"mp4","mkv","avi","mov","webm","m4v","3gp","wmv"}: return "video"
    if e in {"zip","rar","7z","tar","gz","bz2","xz","iso"}: return "archive"
    return "other"

def inside(p, root):
    try: Path(p).resolve().relative_to(root.resolve()); return True
    except ValueError: return False

def parent_folders(cp):
    parts=[x for x in cp.split("/") if x]
    return ["/".join(parts[:i]) for i in range(1,len(parts))]

def parent(cp):
    x=cp.rstrip("/")
    return x.rsplit("/",1)[0] if "/" in x else None

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--db",default=str(DEFAULT_DB))
    ap.add_argument("--media-batch",default=MEDIA_BATCH)
    ap.add_argument("--move-batch",default=MOVE_BATCH)
    ap.add_argument("--master-root",default=str(DEFAULT_ROOT))
    ap.add_argument("--execute",action="store_true")
    a=ap.parse_args()

    db=Path(a.db).expanduser().resolve()
    root=Path(a.master_root).expanduser().resolve()
    if not db.is_file(): raise SystemExit(f"ERROR: database does not exist: {db}")
    if not root.is_dir(): raise SystemExit(f"ERROR: master root does not exist: {root}")

    con=sqlite3.connect(db)
    con.execute("PRAGMA foreign_keys=ON")
    
    #
    #rows=con.execute("""
    #  SELECT mma.inventory_id,mma.source_device_id,mma.source_path,mma.filename,
    #         mma.sha256,mma.size_bytes,mma.source_modified_at,
    #         mma.manual_category,mma.manual_canonical_path,mma.manual_notes
    #  FROM multi_media_assets mma
    #  JOIN media_canonical_move_manifest mcm
    #    ON mcm.inventory_id=mma.inventory_id
    #   AND mcm.batch_id=? AND mcm.status='APPLIED'
    #  WHERE mma.batch_id=?
    #    AND mma.manual_canonical_path IS NOT NULL
    #    AND TRIM(mma.manual_canonical_path)<>''
    #  ORDER BY mma.inventory_id
    #""",(a.move_batch,a.media_batch)).fetchall()
    #
    
    rows = con.execute("""
    SELECT
        mma.inventory_id,
        mma.sha256,
        mma.manual_canonical_path
    FROM multi_media_assets mma
    JOIN media_canonical_move_manifest mcm
      ON mcm.inventory_id = mma.inventory_id
     AND mcm.batch_id = 'MEDIA_CANONICAL_20260823'
     AND mcm.status = 'APPLIED'
    WHERE mma.batch_id = 'NONDOC_20260820_202341'
      AND mma.manual_canonical_path IS NOT NULL
      AND TRIM(mma.manual_canonical_path) <> ''
      AND mma.inventory_id NOT IN (
          2616, 3670, 3671, 3672, 3673, 3674
      )
    ORDER BY mma.inventory_id
""").fetchall()

    print("="*78)
    print("MULTIMEDIA CATALOG FINALIZATION")
    print("="*78)
    print("MODE :", "EXECUTE" if a.execute else "DRY RUN")
    print("ROWS :", len(rows))

    errors=[]; reuse=[]; new=[]; sources=[]; manifests=[]; folders=set(); seen={}
    resolved_fileids={}

    for r in rows:
        inv,dev,src,orig,sha,size,mod,cat,cp,notes=r
        cp=cp.strip(); dst=(root/cp.lstrip("/")).resolve()
        if not inside(dst,root): errors.append(f"{inv}: destination outside master"); continue
        if seen.get(cp,inv)!=inv: errors.append(f"canonical collision: {cp}"); continue
        seen[cp]=inv
        if not dst.is_file(): errors.append(f"{inv}: missing canonical file: {dst}"); continue
        if dst.stat().st_size!=size: errors.append(f"{inv}: size mismatch"); continue
        if sha256_file(dst)!=sha: errors.append(f"{inv}: SHA-256 mismatch"); continue

        candidates=con.execute("""
          SELECT file_id,canonical_path,storage_state,status
          FROM files WHERE sha256=?
          ORDER BY CASE WHEN storage_state='IN_MASTER' AND status='MASTER' THEN 0
                       WHEN storage_state='IN_MASTER' THEN 1 ELSE 2 END,
                   file_id
        """,(sha,)).fetchall()

        chosen=None
        for x in candidates:
            if x[2]=='IN_MASTER' and x[3]=='MASTER' and x[1]==cp: chosen=x; break
        if chosen is None:
            for x in candidates:
                if x[2]=='IN_MASTER' and x[3]=='MASTER': chosen=x; break

        if chosen:
            fid=chosen[0]; reuse.append((inv,fid,cp,cat))
        else:
            fid=None
            new.append((inv,sha,str(dst),fname(cp),ext(fname(cp)),size,media_type(cat,fname(cp)),mod,notes,cp))

        sources.append((inv,fid,dev,src,orig,size,sha,mod))
        manifests.append((inv,fid,dev,src,str(dst),sha,size))
        folders.update(parent_folders(cp))

    if errors:
        print("VALIDATION ERRORS:",len(errors))
        for e in errors: print(" -",e)
        con.close(); raise SystemExit(2)

    print("REUSE EXISTING MASTER :",len(reuse))
    print("NEW FILE ROWS         :",len(new))
    print("FOLDERS               :",len(folders))
    if not a.execute:
        print("DRY RUN: no database changes.")
        con.close(); return

    con.execute("BEGIN")
    try:
        newids={}
        for inv,sha,mp,fn,extension,size,mt,mod,notes,cp in new:
            cur=con.execute("""
              INSERT INTO files(sha256,master_path,filename,extension,size_bytes,media_type,
                                modified_date,status,notes,canonical_path,storage_state,updated_at)
              VALUES(?,?,?,?,?,?,?,'MASTER',?,?,'IN_MASTER',CURRENT_TIMESTAMP)
            """,(sha,mp,fn,extension,size,mt,mod,notes,cp))
            newids[inv]=cur.lastrowid

        for inv,fid,dev,src,orig,size,sha,mod in sources:
            if fid is None: fid=newids[inv]
            if not con.execute("""
                SELECT 1 FROM file_sources WHERE file_id=? AND device_id=? AND source_path=?
            """,(fid,dev,src)).fetchone():
                con.execute("""
                  INSERT INTO file_sources(file_id,device_id,source_path,source_filename,
                                           source_size_bytes,source_sha256,source_modified_date)
                  VALUES(?,?,?,?,?,?,?)
                """,(fid,dev,src,orig,size,sha,mod))

        ts=datetime.now().astimezone().isoformat(timespec="seconds")
        for inv,fid,dev,src,dst,sha,size in manifests:
            if fid is None: fid=newids[inv]
            if not con.execute("""
                SELECT 1 FROM copy_manifest
                WHERE file_id=? AND source_device_id=? AND source_path=? AND destination_path=?
            """,(fid,dev,src,dst)).fetchone():
                con.execute("""
                  INSERT INTO copy_manifest
                  (file_id,source_device_id,source_path,destination_path,source_sha256,
                   destination_sha256,source_size_bytes,destination_size_bytes,copied_at,
                   verified_at,status,verification_method,notes)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)
                """,(fid,dev,src,dst,sha,sha,size,size,ts,ts,"VERIFIED",
                     "SHA256_CANONICAL_MEDIA_MOVE",
                     "Catalog finalization from verified multimedia canonical move."))

        for fp in sorted(folders,key=lambda x:(x.count("/"),x)):
            if not con.execute("SELECT 1 FROM folders WHERE master_path=?",(fp,)).fetchone():
                name=fp.rstrip("/").split("/")[-1]
                con.execute("""
                  INSERT INTO folders(master_path,folder_name,parent_path,folder_type,description,
                                      device_summary,updated_at)
                  VALUES(?,?,?,?,?,?,CURRENT_TIMESTAMP)
                """,(fp,name,parent(fp),"MASTER",
                     "Created during multimedia catalog finalization.",None))

        con.commit()
    except Exception:
        con.rollback(); con.close(); raise

    print("CATALOG FINALIZATION COMPLETE")
    print("NEW FILES:",len(new),"REUSED:",len(reuse))
    con.close()

if __name__=="__main__": main()
