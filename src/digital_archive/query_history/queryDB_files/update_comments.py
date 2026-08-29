import sqlite3
import sys

REPO_DB = "/home/harikr/my_scripts/digital_archive/queryDB_files/queries.db"

def append_repository_comment(query_id, comment_text):
    """Appends annotations safely to any target query id row layer."""
    conn = sqlite3.connect(REPO_DB)
    cursor = conn.cursor()
    
    try:
        # Check tracking presence first
        cursor.execute("SELECT query_name, user_comments FROM sys_query_repo WHERE query_id = ?;", (query_id.upper(),))
        record = cursor.fetchone()
        
        if not record:
            print(f"❌ Query row target '{query_id}' not found.")
            return
            
        current_comments = record[1]
        timestamped_comment = f"[{sqlite3.datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}] {comment_text}"
        
        # Merge previous historical text blocks smoothly if present
        new_comment_payload = f"{current_comments}\n{timestamped_comment}" if current_comments else timestamped_comment

        cursor.execute("""
            UPDATE sys_query_repo 
            SET user_comments = ?, updated_at = CURRENT_TIMESTAMP 
            WHERE query_id = ?;
        """, (new_comment_payload, query_id.upper()))
        
        conn.commit()
        print(f"📝 Appended comment to {query_id} successfully.")
    except sqlite3.Error as e:
        print(f"❌ Database Issue: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 update_comments.py [QUERY_ID] '[YOUR COMMENT TEXT]'")
    else:
        append_repository_comment(sys.argv[1], sys.argv[2])
