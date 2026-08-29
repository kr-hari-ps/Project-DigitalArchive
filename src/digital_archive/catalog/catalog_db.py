#!/usr/bin/env python3
import argparse, os, sqlite3
from pathlib import Path

SCHEMA = Path(__file__).with_name('schema.sql').read_text()

def connect(db):
    c=sqlite3.connect(db); c.execute('PRAGMA foreign_keys=ON'); return c

def init_db(db):
    Path(db).parent.mkdir(parents=True, exist_ok=True)
    c=connect(db); c.executescript(SCHEMA); c.commit(); c.close()

def set_xattr(path, ids):
    value=','.join(sorted(set(x.strip() for x in ids.split(',') if x.strip()))).encode()
    os.setxattr(path, 'user.archive.device_map', value)

def get_xattr(path):
    try: return os.getxattr(path, 'user.archive.device_map').decode()
    except OSError: return ''

def main():
    p=argparse.ArgumentParser(); s=p.add_subparsers(dest='cmd', required=True)
    a=s.add_parser('init'); a.add_argument('db')
    a=s.add_parser('device'); a.add_argument('db'); a.add_argument('device_id'); a.add_argument('device_name'); a.add_argument('device_type'); a.add_argument('--description',default='')
    a=s.add_parser('set-xattr'); a.add_argument('path'); a.add_argument('device_ids')
    a=s.add_parser('get-xattr'); a.add_argument('path')
    x=p.parse_args()
    if x.cmd=='init': init_db(x.db); print(f'Initialized: {x.db}')
    elif x.cmd=='device':
        init_db(x.db); c=connect(x.db); c.execute('''INSERT INTO devices(device_id,device_name,device_type,description) VALUES(?,?,?,?) ON CONFLICT(device_id) DO UPDATE SET device_name=excluded.device_name,device_type=excluded.device_type,description=excluded.description''',(x.device_id,x.device_name,x.device_type,x.description)); c.commit(); c.close(); print(f'Registered: {x.device_id}')
    elif x.cmd=='set-xattr': set_xattr(x.path,x.device_ids); print('Applied user.archive.device_map')
    else: print(get_xattr(x.path))
if __name__=='__main__': main()
