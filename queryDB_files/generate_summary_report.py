import sqlite3
import os

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
REPORT_MD = "/home/harikr/my_scripts/digital_archive/queryDB_files/QUERY_SUMMARY_REPORT.md"

def build_report():
    if not os.path.exists(REPO_DB):
        print(f"❌ Error: Repository database missing at {REPO_DB}")
        return

    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()
    
    # Fetch all queries sorted by their dependencies and type
    cursor.execute("""
        SELECT query_id, query_name, query_type, dependencies, description, sql_text, is_locked 
        FROM sys_query_repo 
        ORDER BY dependencies, query_type, query_id;
    """)
    rows = cursor.fetchall()
    conn.close()

    print(f"piling {len(rows)} statements into a clean markdown document...")

    # Organize queries by table dependencies
    sections = {}
    for r in rows:
        deps = r[3] if r[3] else "unclassified_tables"
        if deps not in sections:
            sections[deps] = []
        sections[deps].append(r)

    with open(REPORT_MD, "w", encoding="utf-8") as f:
        f.write("# 📑 Digital Archive Query Inventory Summary\n\n")
        f.write(f"**Total Records Tracked:** {len(rows)} unique operations managed across isolation states.\n\n")
        
        # Table of Contents
        f.write("## 🗂️ Table of Contents\n")
        for table_group in sorted(sections.keys()):
            f.write(f"- [{table_group.upper()}](#-{table_group.lower()})\n")
        f.write("\n---\n\n")

        # Inject queries by section group
        for table_group, queries in sorted(sections.items()):
            f.write(f"## 📦 {table_group.upper()}\n")
            f.write(f"Managed query commands targeting the `{table_group}` schema layer.\n\n")
            
            f.write("| Query ID | Operation Type | Security Lock | Description |\n")
            f.write("| :--- | :--- | :--- | :--- |\n")
            
            for q in queries:
                lock_icon = "🛑 LOCKED" if q[6] == 1 else "🟢 UNLOCKED"
                f.write(f"| `{q[0]}` | **{q[2]}** | {lock_icon} | {q[4]} |\n")
            
            f.write("\n### 📜 Code Definitions Snippet\n")
            for q in queries:
                f.write(f"#### ID: {q[0]} ({q[1]})\n")
                f.write(f"```sql\n{q[5]}\n```\n\n")
            f.write("\n---\n\n")

    print(f"🎉 Success! Generated query catalog notebook at: {REPORT_MD}")

if __name__ == "__main__":
    build_report()
