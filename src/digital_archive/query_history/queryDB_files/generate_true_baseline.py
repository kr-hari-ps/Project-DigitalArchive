import sqlite3
import os
import re
import hashlib

BK_PATH = "/home/harikr/snap/beekeeper-studio/current/.config/beekeeper-studio/app.db"
OUTPUT_TSV = "/home/harikr/my_scripts/digital_archive/queryDB_files/query_baseline.tsv"

if not os.path.exists(BK_PATH):
    print(f"❌ Error: Beekeeper history database not found at {BK_PATH}")
    exit(1)

conn = sqlite3.connect(BK_PATH)
cursor = conn.cursor()
cursor.execute("SELECT text FROM used_query WHERE text IS NOT NULL AND text != '';")
raw_queries = cursor.fetchall()
conn.close()

unique_queries = set(row[0].strip() for row in raw_queries if row[0].strip())
print(f"📋 Harvesting {len(unique_queries)} unique queries into your true TSV file...")

with open(OUTPUT_TSV, "w", encoding="utf-8") as f:
    f.write("query_id\tquery_name\tquery_type\tdescription\tdependencies\tsql_text\tis_locked\n")
    
    # Track assigned hashes to add serial counters to duplicates
    name_seen = {}
    
    for sql in unique_queries:
        sql_single_line = " ".join(sql.split())
        words = sql_single_line.split()
        if not words:
            continue
            
        first_word = re.sub(r'[^A-Z]', '', words[0].upper())
        if first_word in ['SELECT', 'WITH']:
            q_type = 'SELECT'
            is_locked = '0'
        elif first_word in ['UPDATE', 'DELETE', 'INSERT', 'REPLACE']:
            q_type = first_word if first_word != 'REPLACE' else 'INSERT'
            is_locked = '1'
        else:
            continue
            
        sql_hash = hashlib.sha256(sql_single_line.encode('utf-8')).hexdigest()[:8].upper()
        
        # Incremental naming counter logic
        name_seen[sql_hash] = name_seen.get(sql_hash, 0) + 1
        q_id = f"Q-{q_type[:3]}-{sql_hash}-{name_seen[sql_hash]}"
        q_name = f"history_{q_type.lower()}_{sql_hash}_{name_seen[sql_hash]}"
        
        if "multi_media_assets" in sql_single_line:
            deps = "multi_media_assets"
            desc = f"Historical {q_type} statement targeting the primary multi_media_assets registry."
        else:
            deps = "system_metadata"
            desc = f"Historical administrative metadata processing loop."

        f.write(f"{q_id}\t{q_name}\t{q_type}\t{desc}\t{deps}\t{sql_single_line}\t{is_locked}\n")

print(f"🎉 True baseline workbook generated smoothly at: {OUTPUT_TSV}")
