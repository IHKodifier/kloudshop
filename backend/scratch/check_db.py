import sqlite3
import os

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(script_dir)
    db_path = os.path.join(backend_dir, "test_persistent.db")
    print(f"Connecting to database at: {db_path}")
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT name FROM sqlite_master WHERE type='table';")
    print([r[0] for r in c.fetchall()])
    conn.close()

if __name__ == "__main__":
    main()
