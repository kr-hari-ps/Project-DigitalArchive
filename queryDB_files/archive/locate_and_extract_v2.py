import sqlite3
import os
import re
import hashlib

BK_PATH = "/home/harikr/snap/beekeeper-studio/current/.config/beekeeper-studio/app.db"
TARGET_REPO_PATH = "/home/harikr/my_scripts/digital_archive/queries.db"

if not os.path.exists(BK_PATH):
    print(f"❌ Error: Database file not accessible at {BK_PATH}")
    exit(1)

conn_bk = sqlite3.connect(BK_PATH)
conn_repo = sqlite3.connect(TARGET_REPO_PATH)
cursor_bk = conn_bk.cursor()
cursor_repo = conn_repo.cursor()

# Dynamically detect if the column is named 'text', 'sql', or 'query'
cursor_bk.execute("PRAGMA table_info(used_query);")
columns = [col[1] for col in cursor_bk.fetchall()]
query_text_col = 'text' if 'text' in columns else ('sql' if 'sql' in columns else 'query')

print(f"📊 Extracting all logs from 'used_query' using the text column: '{query_text_col}'...")

# Pull everything from the active runtime log cache
cursor_bk.execute(f"SELECT {query_text_col} FROM used_query WHERE {query_text_col} IS NOT NULL AND {query_text_col} != '';")
raw_queries = cursor_bk.fetchall()

# Deduplicate identical statements
unique_queries = set(row[0].strip() for row in raw_queries if row[0].strip())
print(f"⚙️ Found {len(unique_queries)} unique historical statements out of the log pool. Applying safety filters...")

inserted_count = 0
for sql in unique_queries:
    words = sql.split()
    if not words:
        continue
    
    # Isolate command keyword cleanly
    first_word_clean = re.sub(r'[^A-Z]', '', words[0].upper())
    
    # Classify operations and apply strict lock policies
    if first_word_clean in ['SELECT', 'WITH']:
        q_type = 'SELECT'
        is_locked = 0  # Read actions stay open
    elif first_word_clean in ['UPDATE', 'DELETE', 'INSERT', 'REPLACE']:
        q_type = first_word_clean if first_word_clean != 'REPLACE' else 'INSERT'
        is_locked = 1  # 🔐 DESTRUCTIVE OPERATIONS AUTOMATICALLY LOCKED
    else:
        continue # Bypass infrastructure DDL statements like CREATE/DROP
        
    # Generate unique query signatures
    sql_hash = hashlib.sha256(sql.encode('utf-8')).hexdigest()[:8].upper()
    q_id = f"Q-{q_type[:3]}-{sql_hash}"
    q_name = f"history_{q_type.lower()}_{sql_hash}"
    
    try:
        cursor_repo.execute("""
            INSERT INTO sys_query_repo (query_id, query_name, query_type, description, dependencies, sql_text, is_locked)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(query_id) DO UPDATE SET sql_text = excluded.sql_text;
        """, (q_id, q_name, q_type, "Harvested from full runtime history logs.", "Pending Analysis", sql, is_locked))
        inserted_count += 1
    except sqlite3.Error as err:
        print(f"⚠️ Skipping {q_id} due to database error: {err}")

conn_repo.commit()
print(f"🎉 Success! Migrated {inserted_count} unique historical queries into your locked repository database.")

conn_bk.close()
conn_repo.close()
