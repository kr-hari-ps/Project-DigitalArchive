import sqlite3
import re

REPO_DB = "/home/harikr/my_scripts/digital_archive/queries.db"

def parse_fallback_tables(sql):
    """Fallback text scanner that grabs names following common SQL markers."""
    matches = re.findall(r'(?:FROM|JOIN|UPDATE|INTO)\s+([a-zA-Z0-9_]+)', sql, re.IGNORECASE)
    # Ignore common SQL keywords that slip in during loose splitting
    ignore = ['select', 'where', 'left', 'inner', 'join', 'and', 'or', 'on']
    cleaned = [m.lower() for m in matches if m.lower() not in ignore]
    return ", ".join(sorted(list(set(cleaned)))) if cleaned else "system_metadata"

def generate_smart_description(sql, q_type, tables_str):
    sql_upper = sql.upper()
    if q_type == 'SELECT':
        if "COUNT(" in sql_upper: return f"Calculates counts and distribution metrics inside: {tables_str}."
        if "PARTITION" in sql_upper: return f"Window ranking operation to track duplicates inside: {tables_str}."
        return f"Reads rows and attribute configurations from: {tables_str}."
    elif q_type == 'UPDATE': return f"Modifies active states or status labels inside: {tables_str}."
    elif q_type == 'DELETE': return f"Removes targeted records from storage matrix: {tables_str}."
    elif q_type == 'INSERT': return f"Logs new transaction or file metadata rows into: {tables_str}."
    return "Automated data management sequence."

conn = sqlite3.connect(REPO_DB)
cursor = conn.cursor()

cursor.execute("SELECT query_id, sql_text, query_type FROM sys_query_repo;")
all_queries = cursor.fetchall()

print(f"Force-activating and detailing {len(all_queries)} system queries...")

for q_id, sql, q_type in all_queries:
    tables = parse_fallback_tables(sql)
    description = generate_smart_description(sql, q_type, tables)
    
    # Force activation step
    cursor.execute("""
        UPDATE sys_query_repo 
        SET description = ?, dependencies = ?, is_active = 1 
        WHERE query_id = ?;
    """, (description, tables, q_id))

conn.commit()
conn.close()
print("\n🎉 Incremental update completed! All queries have descriptions and are marked active.")
