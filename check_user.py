import firebase_admin
from firebase_admin import credentials, auth, firestore

def main():
    print("Initializing Firebase Admin...")
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
        print("[SUCCESS] Firebase Admin successfully initialized!")
    except Exception as e:
        print(f"[ERROR] Error initializing Firebase Admin: {e}")
        return

    email = "hazemehabsat@gmail.com"
    password = "H123456"

    try:
        print(f"Fetching user by email: {email}...")
        user = auth.get_user_by_email(email)
        print(f"[SUCCESS] Found user (UID: {user.uid}). Updating password...")
        
        # Explicitly update the user's password to H123456
        auth.update_user(
            user.uid,
            password=password
        )
        print("[SUCCESS] Password successfully updated to 'H123456'!")
    except Exception as e:
        print(f"[ERROR] Failed to fetch or update user: {e}")

if __name__ == "__main__":
    main()
