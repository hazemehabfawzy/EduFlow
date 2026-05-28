import firebase_admin
from firebase_admin import credentials, auth, firestore
import datetime

def main():
    print("Initializing Firebase Admin...")
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
        print("[SUCCESS] Firebase Admin successfully initialized!")
    except Exception as e:
        print(f"[ERROR] Error initializing Firebase Admin: {e}")
        return

    db = firestore.client()
    emails = ["hazemehabsat@gmail.com", "hazemehabsat@gamil.com"]
    password = "H123456"

    for email in emails:
        uid = None
        try:
            print(f"\nChecking user: {email}...")
            user = auth.get_user_by_email(email)
            uid = user.uid
            print(f"[SUCCESS] Found existing user (UID: {uid}). Updating password...")
            auth.update_user(uid, password=password)
            print("[SUCCESS] Password successfully updated!")
        except Exception as e:
            print(f"User {email} not found. Creating user...")
            try:
                user = auth.create_user(
                    email=email,
                    password=password,
                    display_name="Hazem Ehab"
                )
                uid = user.uid
                print(f"[SUCCESS] Created user with UID: {uid}")
            except Exception as create_err:
                print(f"[ERROR] Failed to create user {email}: {create_err}")
                continue
        
        # Ensure Firestore document exists and role is admin
        if uid:
            try:
                doc_ref = db.collection("users").document(uid)
                doc = doc_ref.get()
                if not doc.exists:
                    print(f"Creating Firestore user document for {email}...")
                    doc_ref.set({
                        "uid": uid,
                        "name": "Hazem Ehab",
                        "email": email,
                        "role": "admin",
                        "createdAt": datetime.datetime.now(datetime.timezone.utc)
                    })
                    print("[SUCCESS] Firestore user document created as admin!")
                else:
                    print(f"Updating Firestore user document role to admin for {email}...")
                    doc_ref.update({
                        "role": "admin"
                    })
                    print("[SUCCESS] Firestore user document updated to admin!")
            except Exception as db_err:
                print(f"[ERROR] Failed to set Firestore doc role for {email}: {db_err}")

if __name__ == "__main__":
    main()
