#!/usr/bin/env python3
import argparse, hashlib, sqlite3
from datetime import datetime
from pathlib import Path

DOC_EXTS={"pdf","doc","docx","xls","xlsx","xlsm","ppt","pptx","odt","ods","odp","rtf","txt","csv","html","htm","mht","mhtml"}
PHOTO_EXTS={"jpg","jpeg","png","gif","bmp","webp","tif","tiff","heic","heif","raw","cr2","cr3","nef","arw","dng","orf","rw2"}
MUSIC_EXTS={"mp3","m4a","aac","wav","flac","ogg","oga","opus","wma","alac"}
VIDEO_EXTS={"mp4","mkv","avi","mov","m4v","wmv","webm","3gp","mts","m2ts"}
ARCHIVE_EXTS={"zip","rar","7z","tar","gz","bz2","xz"}
EBOOK_EXTS={"epub","mobi","azw","azw3"}

def sha256_file(path, chunk=1024*1024):
    h=hashlib.sha256()
    with open(path,"rb") as f:
        while True:
            b=f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def is_generated_thumbnail(path):
    parts=[p.lower() for p in path.parts if p not in ("",".")]
    if any(p in {".thumbnails","thumbnails","thumbs"} for p in parts):
        return True
    joined="/".join(parts)
    return any(x in f"/{joined}/" for x in ("/.thumbnails/","/cache/thumbnails/","/cache/thumbnail/"))

def is_ignored_dependency(path):
    """
    Skip generated dependency trees that should never enter the
    multimedia migration inventory.
    """
    parts = [p.lower() for p in path.parts if p not in ("", ".")]

    return "node_modules" in parts


def category_for(path):
    if is_ignored_dependency(path): return None
    if is_generated_thumbnail(path): return "DERIVED_CACHE"
    e=path.suffix.lower().lstrip(".")
    if e in PHOTO_EXTS: return "PHOTO"
    if e in MUSIC_EXTS: return "MUSIC"
    if e in VIDEO_EXTS: return "VIDEO"
    if e in ARCHIVE_EXTS: return "ARCHIVE"
    if e in EBOOK_EXTS: return "EBOOK"
    if e in DOC_EXTS: return None
    return "OTHER"

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--db",default=str(Path.home()/ "Master-Repository/.archive/catalog.db"))
    ap.add_argument("--source-root",action="append",nargs=2,metavar=("DEVICE_ID","ROOT"),required=True)
    ap.add_argument("--batch-id",default=datetime.now().strftime("NONDOC_%Y%m%d_%H%M%S"))
    ap.add_argument("--replace-batch",action="store_true")
    a=ap.parse_args()

    db=Path(a.db).expanduser().resolve()
    if not db.is_file(): raise SystemExit(f"Database does not exist: {db}")
    roots=[(d.upper(),Path(r).expanduser().resolve()) for d,r in a.source_root]

    con=sqlite3.connect(db); con.execute("PRAGMA foreign_keys=ON")
    cols={r[1] for r in con.execute("PRAGMA table_info(multi_media_assets)")}
    required={"batch_id","source_device_id","source_path","relative_path","filename","extension","category","size_bytes","sha256","source_created_at","source_modified_at","source_accessed_at","source_ctime_at","duplicate_group","duplicate_status","keep_decision","duplicate_reason","proposed_category","proposed_canonical_path","manual_category","manual_canonical_path","manual_notes",}
    missing=required-cols
    if missing: raise SystemExit("multi_media_assets is missing columns: "+", ".join(sorted(missing)))

    if a.replace_batch:
        con.execute("DELETE FROM multi_media_assets WHERE batch_id=?",(a.batch_id,)); con.commit()  

    records=[]; hash_map={}; scanned=0
    print("BATCH:",a.batch_id)
    print("MODE : LOAD NON-DOCUMENT INVENTORY")
    print("THUMBNAIL/CACHE RULE: DERIVED_CACHE + EXCLUDE")
    print()

    for device,root in roots:
        if not root.is_dir(): raise SystemExit(f"Source root does not exist: {root}")
        for p in root.rglob("*"):
            if not p.is_file(): continue
            category=category_for(p)
            if category is None: continue
            scanned+=1
            stat = p.stat()
            record={"device":device,"path":str(p),"relative":str(p.relative_to(root)),"filename":p.name,"extension":p.suffix.lower().lstrip("."),"category":category,"size":p.stat().st_size,"sha":sha256_file(p),"source_created_at": stat.st_ctime,"source_modified_at": stat.st_mtime,"source_accessed_at": stat.st_atime,"source_ctime_at": stat.st_ctime,} 
            records.append(record)
            if category!="DERIVED_CACHE": hash_map.setdefault(record["sha"],[]).append(record)

    groups={} 
    n=0
    for sha,members in hash_map.items():
        if len(members)>1:
            n+=1; groups[sha]=f"NONDOC-DUP-{n:04d}"

    for r in records:
        is_cache=r["category"]=="DERIVED_CACHE"             
        dg=None if is_cache else groups.get(r["sha"])
        status=("DERIVED_CACHE" if is_cache else ("DUPLICATE_EXACT" if dg else "UNIQUE"))
        keep="EXCLUDE" if is_cache else None
        proposed_category=("DERIVED_CACHE" if is_cache else None)
        proposed_canonical_path = None
        duplicate_reason = ("GENERATED_CACHE" if is_cache else None)
        notes=("Generated thumbnail/cache file; exclude from master migration." if is_cache else None)
        con.execute("""INSERT INTO multi_media_assets(batch_id,source_device_id,source_path,relative_path,filename,extension,category,size_bytes,sha256,source_created_at,source_modified_at,source_accessed_at,source_ctime_at,duplicate_group,duplicate_status,keep_decision,proposed_category,proposed_canonical_path,manual_category,manual_canonical_path,manual_notes,duplicate_reason)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (a.batch_id,r["device"],r["path"],r["relative"],r["filename"],r["extension"],r["category"],r["size"],r["sha"],r["source_created_at"],r["source_modified_at"],r["source_accessed_at"],r["source_ctime_at"],dg,status,keep,proposed_category,proposed_canonical_path,None,None,notes,duplicate_reason,))
    con.commit()

    loaded=con.execute("SELECT COUNT(*) FROM multi_media_assets WHERE batch_id=?",(a.batch_id,)).fetchone()[0]
    print("Scanned :",scanned); print("Loaded  :",loaded); print()
    print("By category:")
    for c,count in con.execute("SELECT category,COUNT(*) FROM multi_media_assets WHERE batch_id=? GROUP BY category ORDER BY COUNT(*) DESC,category",(a.batch_id,)):
        print(f"  {c:15} {count}")
    dg=con.execute("SELECT COUNT(DISTINCT duplicate_group) FROM multi_media_assets WHERE batch_id=? AND duplicate_group IS NOT NULL",(a.batch_id,)).fetchone()[0]
    dr=con.execute("SELECT COUNT(*) FROM multi_media_assets WHERE batch_id=? AND duplicate_group IS NOT NULL",(a.batch_id,)).fetchone()[0]
    dc=con.execute("SELECT COUNT(*) FROM multi_media_assets WHERE batch_id=? AND category='DERIVED_CACHE' AND keep_decision='EXCLUDE'",(a.batch_id,)).fetchone()[0]
    print(); print("Exact duplicate groups :",dg); print("Exact duplicate records:",dr); print("Derived cache excluded :",dc)
    con.close()

if __name__=="__main__": 
    main()