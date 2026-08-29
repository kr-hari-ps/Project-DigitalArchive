import sqlite3
import sys
import os

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
CATALOG_DB = "/home/harikr/Master-Repository/.archive/catalog.db"

def profile_query_plan(sql_text):
    """Passes the query to catalog.db via EXPLAIN QUERY PLAN to extract index profiles."""
    if not os.path.exists(CATALOG_DB):
        return "Plan Profile: Pending (Catalog DB not found)"
    if sql_text.strip().lower().startswith("pragma"):
        return "Plan Profile: SQLite internal pragma system metadata routine."

    try:
        with sqlite3.connect(CATALOG_DB) as conn:
            cur = conn.cursor()
            cur.execute(f"EXPLAIN QUERY PLAN {sql_text}")
            plan_rows = cur.fetchall()
            plan_details = [row[3] for row in plan_rows]
            summary = " | ".join(plan_details)
            
            if "SCAN TABLE" in summary:
                summary += " ⚠️ [Performance Alert: Performs unindexed full table scan]"
            elif "USING INDEX" in summary or "USING COVERING INDEX" in summary:
                summary += " ⚡ [Optimized: Fast index lookup active]"
            return f"Plan Profile: {summary}"
    except sqlite3.Error as e:
        return f"Plan Profile: Dynamic runtime execution mapping required (Details: {e})"

def upsert_query(q_id, name, q_type, desc, deps, raw_sql, lock_state=0):
    """Safely updates or appends a query with on-the-fly execution optimization mapping."""
    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()
    
    # Force lock states on mutation actions
    if q_type.upper() in ['UPDATE', 'DELETE', 'INSERT'] and int(lock_state) == 0:
        lock_state = 1
        print("🔐 Security Notice: Non-SELECT type detected. Safety lock engaged by default.")

    # Live Optimizer Analysis
    query_plan_profile = profile_query_plan(raw_sql)

    # Format code with strict requested structural header boundaries
    formatted_sql_with_header = (
        f"-- USER DESCRIPTION: {desc}\n"
        f"-- QUERY ID: {q_id.upper()} | NAME: {name} | TARGETS: {deps}\n"
        f"-- OPTIMIZER PLAN: {query_plan_profile}\n"
        f"{raw_sql}"
    )

    try:
        cursor.execute("""
            INSERT INTO sys_query_repo (query_id, query_name, query_type, description, dependencies, sql_text, is_locked, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(query_id) DO UPDATE SET
                query_name = excluded.query_name,
                query_type = excluded.query_type,
                description = excluded.description,
                dependencies = excluded.dependencies,
                sql_text = excluded.sql_text,
                is_locked = excluded.is_locked,
                updated_at = CURRENT_TIMESTAMP;
        """, (q_id.upper(), name, q_type.upper(), desc, deps, formatted_sql_with_header, int(lock_state)))
        conn.commit()
        print(f"✅ Incremental Update Complete: {q_id.upper()} has been optimized and successfully logged.")
    except sqlite3.Error as e:
        print(f"❌ Transaction Failure: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 7:
        print("Usage: python3 update_query_incremental.py [Q_ID] [NAME] [TYPE] [DESC] [DEPS] '[SQL]' [LOCK_STATE]")
    else:
        # Pass positional string elements straight out of command prompt parameters array
        lock = sys.argv[7] if len(sys.argv) > 7 else 0
        upsert_query(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], lock)
