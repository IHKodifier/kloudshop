import sqlite3
import os

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(script_dir)
    env_path = os.path.join(backend_dir, ".env")
    
    # 1. Safety Check: Verify that .env exists
    if not os.path.exists(env_path):
        print("Safety Error: backend/.env file not found. Blocked database purge.")
        return
        
    # 2. Safety Check: Verify that TESTING=1 is set in .env
    is_testing = False
    with open(env_path, "r") as f:
        for line in f:
            line_strip = line.strip()
            if line_strip.startswith("TESTING="):
                val = line_strip.split("=", 1)[1].strip().lower()
                if val in ("1", "true"):
                    is_testing = True
                    
    if not is_testing:
        print("Safety Error: This script can only be run in a local development environment.")
        print("'TESTING=1' must be enabled in backend/.env to target the local SQLite DB.")
        return

    # 3. Safety Check: Verify that the DB path matches local test_persistent.db
    db_path = os.path.join(backend_dir, "test_persistent.db")
    if not db_path.endswith("test_persistent.db"):
        print("Safety Error: Target database is not the local test_persistent.db. Blocked database purge.")
        return
    
    if not os.path.exists(db_path):
        print(f"Error: Database file not found at: {db_path}")
        return

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get list of all tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        tables = [t for t in tables if not t.startswith("sqlite_")]
        
        # Check record count for each table
        candidate_tables = []
        for table in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table};")
                count = cursor.fetchone()[0]
                if count >= 1:
                    candidate_tables.append((table, count))
            except Exception:
                pass
                
        if not candidate_tables:
            print("\nNo tables found with 1 or more records.")
            conn.close()
            return
            
        print("\nTables with 1 or more records:")
        for idx, (table, count) in enumerate(candidate_tables, 1):
            print(f"  {idx:2d}. {table:<30} ({count} records)")
            
        print("\nSelection Options:")
        print("  - Enter numbers separated by commas (e.g., 1, 3, 5)")
        print("  - Enter 'all' to purge all listed tables")
        print("  - Press Enter or enter 'q' to cancel")
        
        user_input = input("\nSelect tables to purge: ").strip()
        if not user_input or user_input.lower() == 'q':
            print("Operation cancelled.")
            conn.close()
            return
            
        selected_indices = []
        if user_input.lower() == 'all':
            selected_indices = list(range(1, len(candidate_tables) + 1))
        else:
            try:
                parts = [p.strip() for p in user_input.split(',')]
                for part in parts:
                    val = int(part)
                    if 1 <= val <= len(candidate_tables):
                        selected_indices.append(val)
                    else:
                        print(f"Warning: Index {val} is out of range and will be ignored.")
            except ValueError:
                print("Error: Invalid input format. Please enter comma-separated numbers.")
                conn.close()
                return
                
        if not selected_indices:
            print("No tables selected. Exiting.")
            conn.close()
            return
            
        # Remove duplicates
        selected_indices = list(set(selected_indices))
        selected_tables = [candidate_tables[idx - 1] for idx in selected_indices]
        
        print("\nYou have selected the following tables to purge:")
        for table, count in selected_tables:
            print(f"  - {table:<30} ({count} records)")
            
        confirm = input("\nAre you sure you want to delete all data from these tables? (y/N): ").strip().lower()
        if confirm not in ('y', 'yes'):
            print("Aborted.")
            conn.close()
            return
            
        # Purge tables
        cursor.execute("PRAGMA foreign_keys = OFF;")
        
        # Check if sqlite_sequence exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='sqlite_sequence';")
        has_sequence_table = cursor.fetchone() is not None
        
        purged_count = 0
        for table, _ in selected_tables:
            try:
                cursor.execute(f"DELETE FROM {table};")
                if has_sequence_table:
                    try:
                        cursor.execute(f"DELETE FROM sqlite_sequence WHERE name='{table}';")
                    except Exception:
                        pass
                purged_count += 1
                print(f"Purged: {table}")
            except Exception as e:
                print(f"Error purging table {table}: {e}")
                
        conn.commit()
        cursor.execute("PRAGMA foreign_keys = ON;")
        conn.close()
        
        print(f"\nSUCCESS: Successfully purged {purged_count} tables from the local database.")
        
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    main()
