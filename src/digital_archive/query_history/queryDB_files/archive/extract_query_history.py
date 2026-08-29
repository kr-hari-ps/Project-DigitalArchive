import sqlite3
import os
import re
import hashlib

# Expanded path boundaries to account for Linux Snaps and Flatpaks
BEEKEEPER_DB_PATHS = [
    os.path.expanduser("~/.config/beekeeper-studio/config.db"),
    # If installed via Snap Store
    os.path.expanduser("~/snap/beekeeper-studio/current/.config/beekeeper-studio/config.db"),
    os.path.expanduser("~/snap/beekeeper-studio/common/.config/beekeeper-studio/config.db"),
    # If installed via Flatpak
    os.path.expanduser("~/.var/app/io.beekeeperstudio.Studio/config/beekeeper-studio/config.db"),
]
TARGET_REPO_PATH = "/home/harikr/my_scripts/digital_archive/queries.db"

def find_beekeeper_db():
    for path in BEEKEEPER_DB_PATHS:
        if os.path.exists(path):
            return path
    return None

bk_path = find_beekeeper_db()
if not bk_path:
    print("❌ Error: Could not locate Beekeeper's database.")
    print("Checked locations:")
    for p in BEEKEEPER_DB_PATHS:
        print(f"  - {p}")
    exit(1)

print(f"🟢 Found Beekeeper Studio database at: {bk_path}")

conn_bk = sqlite3.connect(bk_path)
conn_repo = sqlite3.connect(TARGET_REPO_PATH)
cursor_bk = conn_bk.cursor()
cursor_repo = conn_repo.cursor()

try:
    # Safely find whatever history table name Beekeeper is using 
    cursor_bk.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%query%history%';")
    table_row = cursor_bk.fetchone()
    if not table_row:
        print("❌ Could not find a query history table inside Beekeeper's DB.")
        exit(1)
        
    table_name = table_row[0]
    cursor_bk.execute(f"SELECT text FROM {table_name} WHERE text IS NOT NULL AND text != '';")
    raw_history = cursor_bk.fetchall()
except Exception as e:
    print(f"❌ Failed to fetch history details: {e}")
    exit(1)

unique_queries = set(row[0].strip() for row in raw_history if row[0].strip())
print(f"📊 Discovered {len(unique_queries)} unique historical statements. Processing safety parameters...")

inserted_count = 0
for sql in unique_queries:
    # Isolate first word to catalog query intent
    words = sql.split()
    if not words:
        continue
    first_word_clean = re.sub(r'[^A-Z]', '', words[0].upper())
    
    # Apply type classification and automated safety locks
    if first_word_clean in ['SELECT', 'WITH']:
        q_type = 'SELECT'
        is_locked = 0  # Safe read queries stay open
    elif first_word_clean in ['UPDATE', 'DELETE', 'INSERT', 'REPLACE']:
        q_type = first_word_clean if first_word_clean != 'REPLACE' else 'INSERT'
        is_locked = 1  # 🔐 DESTRUCTIVE MODIFIERS GET LOCKED BY DEFAULT
    else:
        continue # Skip table management commands like CREATE/DROP
        
    sql_hash = hashlib.sha256(sql.encode('utf-8')).hexdigest()[:8].upper()
    q_id = f"Q-{q_type[:3]}-{sql_hash}"
    q_name = f"extracted_{q_type.lower()}_{sql_hash}"
    
    try:
        cursor_repo.execute("""
            INSERT INTO sys_query_repo (query_id, query_name, query_type, description, dependencies, sql_text, is_locked)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(query_name) DO UPDATE SET sql_text = excluded.sql_text;
        """, (q_id, q_name, q_type, "Harvested from run history tracking log.", "Pending Analysis", sql, is_locked))
        inserted_count += 1
    except sqlite3.Error as err:
        print(f"⚠️ Error inserting {q_id}: {err}")

conn_repo.commit()
print(f"🎉 Success! Processed and added {inserted_count} queries to {TARGET_REPO_PATH}.")

conn_bk.close()
conn_repo.close()
