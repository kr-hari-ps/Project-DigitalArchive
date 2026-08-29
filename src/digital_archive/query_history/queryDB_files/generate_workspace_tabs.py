import sqlite3
import os

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
OUTPUT_DIR = "/home/harikr/my_scripts/digital_archive/queryDB_files/beekeeper_tabs"

def build_tabs():
    if not os.path.exists(REPO_DB):
        print("❌ Error: Repository DB missing.")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()
    cursor.execute("SELECT query_type, sql_text FROM sys_query_repo WHERE is_active = 1;")
    rows = cursor.fetchall()
    conn.close()

    # Bucket queries dynamically by type
    tab_buckets = {}
    for q_type, sql_text in rows:
        if q_type not in tab_buckets:
            tab_buckets[q_type] = []
        tab_buckets[q_type].append(sql_text)

    print(f"📂 Grouping queries into workspace tab scripts...")
    
    for q_type, queries in tab_buckets.items():
        # Name files matching your targeted workspace tab strategy
        filename = f"TAB_{q_type}_QUERIES.sql"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(f"-- ============================================================\n")
            f.write(f"-- BEEKEEPER WORKSPACE TAB: {q_type} OPERATIONS\n")
            f.write(f"-- Total Scripts in this Tab: {len(queries)}\n")
            f.write(f"-- ============================================================\n\n")
            
            # Join all queries together separated by double blank lines
            f.write("\n\n-- ------------------------------------------------------------\n\n".join(queries))
            
        print(f"  🟢 Generated Tab File: {filename} ({len(queries)} queries)")

    print(f"\n🎉 Workspace generation complete! Files saved to: {OUTPUT_DIR}")

if __name__ == "__main__":
    build_tabs()
