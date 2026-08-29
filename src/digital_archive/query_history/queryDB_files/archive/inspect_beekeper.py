import sqlite3

bk_path = "/home/harikr/snap/beekeeper-studio/current/.config/beekeeper-studio/app.db"
conn = sqlite3.connect(bk_path)
cursor = conn.cursor()

print("📋 AVAILABLE TABLES IN BEEKEEPER STUDIO:")
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [row[0] for row in cursor.fetchall()]
for table in tables:
    cursor.execute(f"SELECT COUNT(*) FROM {table};")
    row_count = cursor.fetchone()[0]
    print(f"  - {table} ({row_count} records)")

print("\n🔍 SCHEMAS OF LOG/HISTORY TABLES:")
for table in ['query_history', 'QueryHistory', 'history_query', 'history']:
    if table in tables:
        print(f"\nStructure for table: {table}")
        cursor.execute(f"PRAGMA table_info({table});")
        for col in cursor.fetchall():
            print(f"  Column ID: {col[0]} | Name: {col[1]} | Type: {col[2]}")

conn.close()
