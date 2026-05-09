import sqlite3
import os

db_path = "backend/test_persistent.db"

def patch_db():
    if not os.path.exists(db_path):
        print(f"Error: {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    columns_to_add = [
        ("image_url", "TEXT"),
        ("images", "JSON")
    ]

    for col_name, col_type in columns_to_add:
        try:
            print(f"Adding column {col_name} to products table...")
            cursor.execute(f"ALTER TABLE products ADD COLUMN {col_name} {col_type}")
            print(f"Successfully added {col_name}.")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print(f"Column {col_name} already exists. Skipping.")
            else:
                print(f"Error adding {col_name}: {e}")

    conn.commit()
    conn.close()
    print("Database patch complete.")

if __name__ == "__main__":
    patch_db()
