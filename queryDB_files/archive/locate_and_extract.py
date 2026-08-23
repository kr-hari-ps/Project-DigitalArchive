import sqlite3
import os
import re
import hashlib

# Updated to look directly for Beekeeper's standard app.db file
POSSIBLE_PATHS = [
    os.path.expanduser("~/.config/beekeeper-studio/app.db"),
    os.path.expanduser("~/.config/Beekeeper Studio/app.db"),
    os.path.expanduser("~/snap/beekeeper-studio/current/.config/beekeeper-studio/app.db"),
    os.path.expanduser("~/snap/beekeeper-studio/common/.config/beekeeper-studio/app.db"),
    os.path.expanduser("~/.var/app/io.beekeeperstudio.Studio/config/beekeeper-studio/app.db")
]
TARGET_REPO_PATH = "/home/harikr/my_scripts/digital_archive/queries.db"

def locate_database():
    for p in POSSIBLE_PATHS:
        if os.path.exists(p):
            return p
    # Deep directory search targeting app.db across configuration hubs
    search_roots = [os.path.expanduser("~/.config"), os.path.expanduser("~/snap"), os.path.expanduser("~/.var")]
    print("🔍 Probing directories for Beekeeper app.db tracking store...")
    for root_dir in search_roots:
        if os.path.exists(root_dir):
            for root, dirs, files in os.walk(root_dir):
                for f in files:
                    if f == 'app.db':
                        return os.path.join(root, f)
    return None

bk_path = locate_database()
if not bk_path:
    print("❌ Critical: Unable to locate your Beekeeper app.db file.")
    print("Please manually locate app.db by running: find ~ -name 'app.db' 2>/dev/null")
    exit(1)

print(f"🟢 Found active Beekeeper configuration instance at: {bk_path}")

try:
    conn_bk = sqlite3.connect(bk_path)
    cursor_bk = conn_bk.cursor()
    cursor_bk.execute("SELECT name FROM sqlite_master WHERE type='table';")
    all_tables = [t[0] for t in cursor_bk.fetchall()]
except sqlite3.OperationalError as e:
    print(f"🛑 Security Lockout: {e}")
    print(f"If permission is denied due to Snaps/Flatpaks, copy the file out to run it:")
    print(f"cp '{bk_path}' /tmp/app.db")
    print("Then modify the bk_path variable in this script to '/tmp/app.db'")
    exit(1)

conn_repo = sqlite3.connect(TARGET_REPO_PATH)
cursor_repo = conn_repo.cursor()

target_table = None
# Historical and saved items generally use 'favorite_query' or 'query_history' structures
for t in ['favorite_query', 'query_history', 'QueryHistory']:
    if t in all_tables:
        target_table = t
        break

if not target_table:
    print(f"❌ Metatable lookup failed. Found structures: {all_tables}")
    exit(1)

# Extract column names dynamically to handle schema mapping versions
cursor_bk.execute(f"PRAGMA table_info({target_table});")
columns = [col[1] for col in cursor_bk.fetchall()]
query_text_col = 'text' if 'text' in columns else ('sql' if 'sql' in columns else 'query')

print(f"📊 Accessing historical records via table '{target_table}' using column '{query_text_col}'...")
cursor_bk.execute(f"SELECT {query_text_col} FROM {target_table} WHERE {query_text_col} IS NOT NULL AND {query_text_col} != '';")
raw_queries = cursor_bk.fetchall()

unique_queries = set(row[0].strip() for row in raw_queries if row[0].strip())
print(f"⚙️ Found {len(unique_queries)} unique historical statements. Processing safety parameters...")

inserted_count = 0
for sql in unique_queries:
    words = sql.split()
    if not words:
        continue
    first_word_clean = re.sub(r'[^A-Z]', '', words[0].upper())
    
    # Classify statements and apply safety locks
    if first_word_clean in ['SELECT', 'WITH']:
        q_type = 'SELECT'
        is_locked = 0  
    elif first_word_clean in ['UPDATE', 'DELETE', 'INSERT', 'REPLACE']:
        q_type = first_word_clean if first_word_clean != 'REPLACE' else 'INSERT'
        is_locked = 1  # Destructive modifiers are locked by default
    else:
        continue # Avoid pulling infrastructure commands (CREATE, DROP)
        
    sql_hash = hashlib.sha256(sql.encode('utf-8')).hexdigest()[:8].upper()
    q_id = f"Q-{q_type[:3]}-{sql_hash}"
    q_name = f"extracted_{q_type.lower()}_{sql_hash}"
    
    try:
        cursor_repo.execute("""
            INSERT INTO sys_query_repo (query_id, query_name, query_type, description, dependencies, sql_text, is_locked)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(query_id) DO UPDATE SET sql_text = excluded.sql_text;
        """, (q_id, q_name, q_type, "Harvested from run history tracking log.", "Pending Analysis", sql, is_locked))
        inserted_count += 1
    except sqlite3.Error as err:
        print(f"⚠️ Insertion issue with {q_id}: {err}")

conn_repo.commit()
print(f"🎉 Success! Migrated {inserted_count} historical items into {TARGET_REPO_PATH}.")

conn_bk.close()
conn_repo.close()
