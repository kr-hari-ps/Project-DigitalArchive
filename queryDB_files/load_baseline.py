import sqlite3
import csv
import os
import re

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
BASELINE_TSV = "/home/harikr/my_scripts/digital_archive/queryDB_files/query_baseline.tsv"
CATALOG_DB = "/home/harikr/Master-Repository/.archive/catalog.db"

def profile_query_plan(sql_text):
    """Passes the query to catalog.db via EXPLAIN QUERY PLAN to extract index profiles."""
    if not os.path.exists(CATALOG_DB):
        return "Plan Profile: Pending (Catalog DB not found)"
    
    # Pragma queries cannot be explained normally
    if sql_text.strip().lower().startswith("pragma"):
        return "Plan Profile: SQLite internal pragma system metadata routine."

    try:
        with sqlite3.connect(CATALOG_DB) as conn:
            cur = conn.cursor()
            # Intercept execution strategy using SQLite's optimizer explainer
            cur.execute(f"EXPLAIN QUERY PLAN {sql_text}")
            plan_rows = cur.fetchall()
            
            # Extract and join the text details from the query plan output rows
            plan_details = [row[3] for row in plan_rows]
            
            # Create a smart summary based on the database engine notes
            summary = " | ".join(plan_details)
            if "SCAN TABLE" in summary:
                summary += " ⚠️ [Performance Alert: Performs unindexed full table scan]"
            elif "USING INDEX" in summary or "USING COVERING INDEX" in summary:
                summary += " ⚡ [Optimized: Fast index lookup active]"
                
            return f"Plan Profile: {summary}"
    except sqlite3.Error as e:
        # Catch syntax errors or unresolved batch parameters safely
        return f"Plan Profile: Dynamic runtime execution mapping required (Details: {e})"

def initialize_baseline():
    if not os.path.exists(BASELINE_TSV):
        print(f"❌ Error: Missing master file layout at {BASELINE_TSV}")
        return

    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS sys_query_repo (
        query_id TEXT PRIMARY KEY,
        query_name TEXT NOT NULL UNIQUE,
        query_type TEXT CHECK(query_type IN ('SELECT', 'UPDATE', 'DELETE', 'INSERT', 'DDL')),
        description TEXT NOT NULL,
        dependencies TEXT,
        sql_text TEXT NOT NULL,
        is_locked INTEGER DEFAULT 0 CHECK(is_locked IN (0, 1)),
        is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
        user_comments TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    """)
    
    cursor.execute("DELETE FROM sys_query_repo;")
    print("🧹 Purging repository indices. Processing pristine entries via EXPLAIN engine...")

    batch_records = []
    with open(BASELINE_TSV, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            q_id = row['query_id'].upper()
            q_name = row['query_name']
            q_type = row['query_type'].upper()
            desc = row['description']
            deps = row['dependencies']
            raw_sql = row['sql_text']
            lock_state = int(row['is_locked'])

            # 🧠 ENGINE UPGRADE: Call the explainer to profile performance characteristics live
            query_plan_profile = profile_query_plan(raw_sql)

            # Formulate the updated comment block layout with performance parameters
            formatted_sql_with_header = (
                f"-- USER DESCRIPTION: {desc}\n"
                f"-- QUERY ID: {q_id} | NAME: {q_name} | TARGETS: {deps}\n"
                f"-- OPTIMIZER PLAN: {query_plan_profile}\n"
                f"{raw_sql}"
            )

            batch_records.append((
                q_id, q_name, q_type, desc, deps, formatted_sql_with_header, lock_state
            ))

    cursor.executemany("""
        INSERT INTO sys_query_repo (query_id, query_name, query_type, description, dependencies, sql_text, is_locked)
        VALUES (?, ?, ?, ?, ?, ?, ?);
    """, batch_records)

    conn.commit()
    cursor.execute("SELECT COUNT(*) FROM sys_query_repo;")
    print(f"🎉 Success! Loaded {cursor.fetchone()} queries. Optimizer plan analytics appended directly into headers.")
    conn.close()

if __name__ == "__main__":
    initialize_baseline()
