import firebase_admin
from firebase_admin import credentials, auth
import os

def test_firebase():
    print("Testing Firebase initialization...")
    sa_path = "service_account.json"
    if not os.path.exists(sa_path):
        sa_path = os.path.join(os.getcwd(), "backend", "service_account.json")
    
    if os.path.exists(sa_path):
        print(f"Found service account at {sa_path}")
        cred = credentials.Certificate(sa_path)
        try:
            firebase_admin.initialize_app(cred)
            print("Firebase initialized successfully.")
            # Try a simple auth operation
            # We don't have a UID, but we can try to list users (requires permissions)
            # Or just check if auth service is accessible
            print(f"Firebase apps: {firebase_admin._apps}")
        except Exception as e:
            print(f"Firebase initialization failed: {e}")
    else:
        print("Service account NOT found.")

if __name__ == "__main__":
    test_firebase()
