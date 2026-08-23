import sqlite3
import os
import re

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"
ADVISOR_OUTPUT = "/home/harikr/my_scripts/digital_archive/queryDB_files/INDEX_RECOMMENDATIONS.sql"

def parse_where_clause_columns(sql_text):
    """Extracts column names used in WHERE filters to build optimal indexes."""
    # Standard cleanup to isolate token strings
    sql_clean = " ".join(sql_text.split()).lower()
    
    # Isolate text after WHERE clause up to GROUP/ORDER/LIMIT boundaries
    where_match = re.search(r'where\s+(.*?)(?:\s+group\s+by|\s+order\s+by|\s+limit|;|$)', sql_clean)
    if not where_match:
        return []
        
    where_content = where_match.group(1)
    
    # Common SQL operators to strip out
    where_content = re.sub(r'\'[^\']*\'|"[^"]*"|\d+', '', where_content) 
    tokens = re.split(r'\s+|=|<|>|!|like|and|or|is\s+not|is\s+null|in\s*\(', where_content)
    
    # Filter for real potential column name markers
    ignore_keywords = {'', 'not', 'null', 'in', 'between', 'like', 'is'}
    potential_cols = []
    for token in tokens:
        token_clean = token.strip('().,`"\'')
        # Skip subquery tokens, function transformations, or standard qualifiers
        if token_clean and token_clean not in ignore_keywords and not token_clean.startswith('f.'):
            # Strip table aliases if present (e.g. m.batch_id -> batch_id)
            if '.' in token_clean:
                token_clean = token_clean.split('.')[1]
            potential_cols.append(token_clean)
            
    return sorted(list(set(potential_cols)))

def run_index_advisor():
    if not os.path.exists(REPO_DB):
        print(f"❌ Error: Repository database missing at {REPO_DB}")
        return

    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()
    
    # Query only active scripts containing full table scan flags
    cursor.execute("""
        SELECT query_id, query_name, dependencies, sql_text 
        FROM sys_query_repo 
        WHERE is_active = 1 AND sql_text LIKE '%Performance Alert%';
    """)
    unoptimized_queries = cursor.fetchall()
    conn.close()

    if not unoptimized_queries:
        print("🎉 Excellent! Zero unindexed full table scans detected across your 272 queries.")
        return

    print(f"🔍 Analyzing {len(unoptimized_queries)} unoptimized queries for missing indexes...")

    generated_indexes = set()
    recommendations_log = []

    for q_id, q_name, deps, full_text in unoptimized_queries:
        # Extract the underlying raw SQL embedded below your headers
        sql_lines = full_text.split('\n')
        raw_sql = "".join([line for line in sql_lines if not line.startswith('--')])
        
        target_table = deps.split(',')[0].strip() if deps else "multi_media_assets"
        if target_table == "system_metadata" or "pragma" in raw_sql.lower():
            continue
            
        columns = parse_where_clause_columns(raw_sql)
        if not columns:
            continue
            
        # Build composite or single column indexing recommendation commands
        cols_str = ", ".join(columns)
        index_hash = "".join([c[0] for c in columns])[:4].upper()
        index_name = f"idx_{target_table}_{index_hash}"
        
        index_sql = f"CREATE INDEX IF NOT EXISTS {index_name} ON {target_table} ({cols_str});"
        
        if index_sql not in generated_indexes:
            generated_indexes.add(index_sql)
            recommendations_log.append((q_id, q_name, index_sql, cols_str, target_table))

    # Write out the clean SQL deployment file
    with open(ADVISOR_OUTPUT, "w", encoding="utf-8") as f:
        f.write("-- ============================================================\n")
        f.write("-- ⚡ AUTOMATED INDEX OPTIMIZATION BLUEPRINT\n")
        f.write(f"-- Generated across your repository query portfolio tracks\n")
        f.write("-- ============================================================\n\n")
        
        for q_id, q_name, idx_sql, columns, table in recommendations_log:
            f.write(f"-- Fixes full table scan inside Query: {q_id} ({q_name})\n")
            f.write(f"-- Targets lookup variables: [{columns}] inside table `{table}`\n")
            f.write(f"{idx_sql}\n\n")

    print(f"🎉 Analysis Complete! Generated {len(generated_indexes)} missing index patterns.")
    print(f"💾 File saved to: {ADVISOR_OUTPUT}")

if __name__ == "__main__":
    run_index_advisor()
