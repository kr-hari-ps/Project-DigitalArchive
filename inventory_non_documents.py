#!/usr/bin/env python3
import argparse, csv, hashlib, os
from pathlib import Path
from collections import defaultdict

DOCUMENT_EXTS = {
    'pdf','doc','docx','xls','xlsx','xlsm','ppt','pptx','odt','ods','odp',
    'rtf','txt','csv','html','htm','mht','mhtml','zip','rar','7z'
}
IMAGE_EXTS = {'jpg','jpeg','png','gif','webp','heic','heif','bmp','tif','tiff','raw','cr2','cr3','nef','arw','dng','orf','rw2'}
MUSIC_EXTS = {'mp3','m4a','aac','flac','wav','ogg','oga','opus','wma','alac','aiff'}
VIDEO_EXTS = {'mp4','m4v','mov','avi','mkv','webm','3gp','3g2','mts','m2ts','wmv','flv','mpeg','mpg'}
ARCHIVE_EXTS = {'tar','gz','bz2','xz','iso','img','cab','zst'}
EBOOK_EXTS = {'epub','mobi','azw','azw3','fb2'}
AUDIOVISUAL_EXTS = MUSIC_EXTS | VIDEO_EXTS


def sha256_file(path, chunk=1024*1024):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def category(ext):
    ext = ext.lower().lstrip('.')
    if ext in IMAGE_EXTS:
        return 'PHOTO'
    if ext in MUSIC_EXTS:
        return 'MUSIC'
    if ext in VIDEO_EXTS:
        return 'VIDEO'
    if ext in ARCHIVE_EXTS:
        return 'ARCHIVE'
    if ext in EBOOK_EXTS:
        return 'EBOOK'
    if ext in DOCUMENT_EXTS:
        return 'DOCUMENT'
    return 'OTHER'


def ext_of(path):
    return path.suffix.lower().lstrip('.')


def main():
    ap = argparse.ArgumentParser(description='Inventory non-document files from two device/source trees.')
    ap.add_argument('--source-root', action='append', nargs=2, metavar=('DEVICE','ROOT'), required=True)
    ap.add_argument('--output', default='non_document_pair_inventory.csv')
    args = ap.parse_args()

    records = []
    by_hash = defaultdict(list)

    for device, root_arg in args.source_root:
        device = device.upper()
        root = Path(root_arg).expanduser().resolve()
        if not root.is_dir():
            raise SystemExit(f'ERROR: source root does not exist: {root}')

        for path in root.rglob('*'):
            if not path.is_file():
                continue

            ext = ext_of(path)
            cat = category(ext)
            if cat == 'DOCUMENT':
                continue

            rel = path.relative_to(root).as_posix()
            size = path.stat().st_size
            sha = sha256_file(path)
            rec = {
                'source': device,
                'relative_path': rel,
                'full_path': str(path),
                'filename': path.name,
                'extension': ext,
                'media_category': cat,
                'size_bytes': size,
                'sha256': sha,
            }
            idx = len(records)
            records.append(rec)
            by_hash[sha].append(idx)

    group_no = 0
    for sha, idxs in by_hash.items():
        if len(idxs) > 1:
            group_no += 1
            for idx in idxs:
                records[idx]['duplicate_group'] = f'DUP-ND-{group_no:04d}'
                records[idx]['duplicate_status'] = 'DUPLICATE_EXACT'
        else:
            records[idxs[0]]['duplicate_group'] = ''
            records[idxs[0]]['duplicate_status'] = 'UNIQUE_TO_SCAN'

    records.sort(key=lambda r: (r['media_category'], r['source'], r['relative_path']))

    fields = ['record_id','source','relative_path','full_path','filename','extension','media_category','size_bytes','sha256','duplicate_group','duplicate_status']
    out = Path(args.output).expanduser().resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for i, rec in enumerate(records, 1):
            rec = dict(rec)
            rec['record_id'] = i
            w.writerow(rec)

    print(f'CSV: {out}')
    print(f'Non-document files: {len(records)}')
    cats = defaultdict(int)
    for r in records:
        cats[r['media_category']] += 1
    print('By category:')
    for k, v in sorted(cats.items(), key=lambda x: (-x[1], x[0])):
        print(f'  {k:10} {v}')
    dup_groups = sum(1 for v in by_hash.values() if len(v) > 1)
    dup_records = sum(len(v) for v in by_hash.values() if len(v) > 1)
    print(f'Exact-duplicate groups: {dup_groups}')
    print(f'Exact-duplicate records: {dup_records}')

if __name__ == '__main__':
    main()
