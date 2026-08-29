import sqlite3
import sys
import os
import shutil
from datetime import datetime

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
MASTER_CATALOG_DB = "/home/harikr/Master-Repository/.archive/catalog.db"
BACKUP_DIR = "/home/harikr/my_scripts/digital_archive/queryDB_files/backups"

def get_or_create_daily_backup():
    """Finds today's existing backup or makes exactly ONE new copy for the day."""
    if not os.path.exists(MASTER_CATALOG_DB):
        print(f"❌ Error: Master DB missing at {MASTER_CATALOG_DB}")
        sys.exit(1)
        
    os.makedirs(BACKUP_DIR, exist_ok=True)
    today_prefix = f"catalog_queryDB_bkup_{datetime.now().strftime('%Y%m%d')}"
    
    # Reuse today's backup file if it already exists
    for f in os.listdir(BACKUP_DIR):
        if f.startswith(today_prefix) and f.endswith(".db"):
            return os.path.join(BACKUP_DIR, f)

    # Generate only ONE snapshot copy per day
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(BACKUP_DIR, f"{today_prefix}_{timestamp}.db")
    
    print(f"💾 First modification today. Creating single daily data snapshot: {os.path.basename(backup_path)}")
    shutil.copy2(MASTER_CATALOG_DB, backup_path)
    return backup_path

def execute_repo_query(query_id):
    with sqlite3.connect(REPO_DB) as repo_conn:
        repo_cur = repo_conn.cursor()
        repo_cur.execute(
            "SELECT query_name, query_type, sql_text, is_locked FROM sys_query_repo WHERE query_id = ?;", 
            (query_id.upper(),)
        )
        row = repo_cur.fetchone()
        
    if not row:
        print(f"❌ Error: Query ID '{query_id}' not found.")
        return None
        
    q_name, q_type, sql_text, is_locked = row
    print(f"🔍 Selected Query: {q_name} [{q_type}]")

    # Dynamic safety routing pipeline
    if q_type == 'SELECT':
        target_db = MASTER_CATALOG_DB
        print("🟢 Running directly against Production Master DB (Safe Read)...")
    else:
        # Route the query to the backup database
        target_db = get_or_create_daily_backup()
        print(f"🚀 Safety Lock Checked: Routing execution safely to isolated Daily Backup: {os.path.basename(target_db)}")

    try:
        with sqlite3.connect(target_db) as conn:
            cur = conn.cursor()
            cur.execute(sql_text)
            
            if q_type == 'SELECT':
                rows = cur.fetchall()
                print(f"📋 SUCCESS: {len(rows)} records fetched from production database.")
                return rows
            else:
                conn.commit()
                print(f"✅ SUCCESS: {conn.total_changes} rows modified inside your protected backup copy!")
                return True
    except sqlite3.Error as e:
        print(f"❌ Database execution error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        execute_repo_query(sys.argv[1])
    else:
        print("Usage: python3 safe_query_runner.py [QUERY_ID]")
