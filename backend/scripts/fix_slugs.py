import sqlite3
import os
import re

def slugify(text: str) -> str:
    s = text.strip().lower()
    s = re.sub(r'[^a-z0-9\-]+', '-', s)
    s = s.strip('-')
    return s

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(script_dir)
    db_path = os.path.join(backend_dir, "test_persistent.db")
    
    if not os.path.exists(db_path):
        print(f"Database file not found at: {db_path}")
        return
        
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("SELECT product_id, slug, title FROM products;")
    products = cursor.fetchall()
    
    updated_count = 0
    for prod_id, slug, title in products:
        correct_slug = slugify(slug)
        if correct_slug != slug:
            print(f"Updating slug for '{title}': '{slug}' -> '{correct_slug}'")
            cursor.execute("UPDATE products SET slug = ? WHERE product_id = ?;", (correct_slug, prod_id))
            updated_count += 1
            
    conn.commit()
    conn.close()
    print(f"Successfully updated {updated_count} product slugs in the database.")

if __name__ == "__main__":
    main()
