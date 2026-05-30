# seed_db.py
import datetime
import firebase_admin
from firebase_admin import credentials, auth, firestore

"""
RECOMMENDED FIREBASE FIRESTORE SECURITY RULES:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: read own, admin reads all, admin writes all
    match /users/{uid} {
      allow read: if request.auth != null && (request.auth.uid == uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin']);
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    // Courses: anyone authenticated reads, teacher/admin writes
    match /courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'teacher'];
    }
    // Enrollments: user reads/writes own
    match /enrollments/{enrollmentId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
    // Lessons/Quizzes: authenticated reads, teacher/admin writes
    match /lessons/{lessonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'teacher'];
    }
    match /quizzes/{quizId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'teacher'];
    }
  }
}
"""

# 1. Initialize Firebase Admin SDK
# Make sure you have downloaded your 'serviceAccountKey.json' file from the
# Firebase Console (Project Settings -> Service accounts) and placed it in this folder.
try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK successfully initialized!")
except Exception as e:
    print("❌ Error initializing Firebase Admin SDK.")
    print("Please make sure 'serviceAccountKey.json' exists in this directory and is valid.")
    print(f"Error Details: {e}")
    exit(1)

# Get Firestore Client
db = firestore.client()

def create_user_if_not_exists(email, password, name, role):
    try:
        try:
            # Check if Auth user already exists
            user = auth.get_user_by_email(email)
            uid = user.uid
            print(f"⚠️  Auth user for {role} already exists with email: {email} (UID: {uid})")
        except auth.UserNotFoundError:
            # Create in Firebase Auth
            user = auth.create_user(email=email, password=password, display_name=name)
            uid = user.uid
            print(f"✅ Created Auth user for {role}: {email} (UID: {uid})")
        
        # Write user profile doc to /users/{uid} in Firestore
        user_ref = db.collection("users").document(uid)
        if not user_ref.get().exists:
            user_ref.set({
                "uid": uid,
                "name": name,
                "email": email,
                "role": role,
                "avatarUrl": None,
                "createdAt": datetime.datetime.now(datetime.timezone.utc)
            })
            print(f"✅ Created Firestore document for {role}: {email}")
        else:
            # If doc exists, update/assert the role is correct
            user_ref.update({"role": role})
            print(f"⚠️  Firestore document for {email} already exists (role asserted/updated to: {role}).")
    except Exception as e:
        print(f"❌ Error creating/updating {role} ({email}): {e}")


# Define Pre-configured Course IDs for relational link integrity
FLUTTER_COURSE_ID = "flutter_masterclass_101"
UIUX_COURSE_ID = "uiux_fundamentals_202"
AWS_COURSE_ID = "aws_cloud_architecture_303"

# 2. Define Mock Data
courses_data = {
    FLUTTER_COURSE_ID: {
        "title": "Mastering Flutter & Dart",
        "description": "Learn to build beautiful, high-performance native apps for iOS, Android, Web, and Desktop from scratch with the ultimate Flutter guide!",
        "imageUrl": "https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=600&q=80",
        "instructorName": "Sarah Jenkins",
        "rating": 4.8,
        "totalLessons": 3,
        "totalStudents": 1540,
        "category": "Development",
        "level": "Beginner",
        "durationMinutes": 120,
        "isFeatured": True,
        "createdAt": datetime.datetime.now(datetime.timezone.utc)
    },
    UIUX_COURSE_ID: {
        "title": "Modern UI/UX Design Fundamentals",
        "description": "Master Figma, wireframing, prototyping, and user research to create stunning digital products that users love.",
        "imageUrl": "https://images.unsplash.com/photo-1541462608143-67571c6738dd?auto=format&fit=crop&w=600&q=80",
        "instructorName": "Marcus Sterling",
        "rating": 4.9,
        "totalLessons": 2,
        "totalStudents": 850,
        "category": "Design",
        "level": "Beginner",
        "durationMinutes": 90,
        "isFeatured": True,
        "createdAt": datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=2)
    },
    AWS_COURSE_ID: {
        "title": "Advanced Cloud Architecture on AWS",
        "description": "Deep dive into AWS cloud services, serverless computing, microservices scaling, and high-availability architecture.",
        "imageUrl": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&q=80",
        "instructorName": "Dr. Alex Rivera",
        "rating": 4.7,
        "totalLessons": 2,
        "totalStudents": 420,
        "category": "Development",
        "level": "Advanced",
        "durationMinutes": 150,
        "isFeatured": False,
        "createdAt": datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=5)
    }
}

lessons_data = [
    # ── Flutter Course Lessons ──
    {
        "courseId": FLUTTER_COURSE_ID,
        "title": "Introduction to Flutter & Setup",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-software-developer-working-on-his-computer-34281-large.mp4",
        "notes": "In this lesson, we will explore what Flutter is, why it is so popular, and how to set up the development environment on Windows, macOS, and Linux. Ensure you have the Flutter SDK and VS Code/Android Studio installed before moving to the next lesson.",
        "order": 1,
        "durationMinutes": 40,
        "isPreview": True
    },
    {
        "courseId": FLUTTER_COURSE_ID,
        "title": "Understanding Widgets & Layouts",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-hands-of-a-man-typing-on-a-keyboard-40618-large.mp4",
        "notes": "Everything in Flutter is a Widget! We'll cover StatelessWidget, StatefulWidget, and building complex layouts using Row, Column, Stack, and Container. Try creating your first layout task in the exercise files.",
        "order": 2,
        "durationMinutes": 45,
        "isPreview": False
    },
    {
        "courseId": FLUTTER_COURSE_ID,
        "title": "State Management with Provider",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-man-working-on-a-laptop-42261-large.mp4",
        "notes": "Managing state is a crucial part of app development. We will learn how to use the Provider package to propagate changes across widgets efficiently, separate business logic from UI, and handle user authentication state.",
        "order": 3,
        "durationMinutes": 35,
        "isPreview": False
    },

    # ── UI/UX Course Lessons ──
    {
        "courseId": UIUX_COURSE_ID,
        "title": "Introduction to User-Centered Design",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-close-up-of-hands-drawing-on-a-tablet-42250-large.mp4",
        "notes": "Welcome to the world of UX! In this introductory lesson, we will cover the core principles of User-Centered Design (UCD) and how User Research guides digital product decisions.",
        "order": 1,
        "durationMinutes": 40,
        "isPreview": True
    },
    {
        "courseId": UIUX_COURSE_ID,
        "title": "Typography and Color Theory in Figma",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-graphic-designer-working-on-a-digital-tablet-39878-large.mp4",
        "notes": "Learn how to choose harmonious color palettes, establish a robust typographic hierarchy, and build reusable styles in Figma for clean interface development.",
        "order": 2,
        "durationMinutes": 50,
        "isPreview": False
    },

    # ── AWS Course Lessons ──
    {
        "courseId": AWS_COURSE_ID,
        "title": "Designing Resilient Multi-Region Infrastructure",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-data-servers-racks-with-flashing-led-lights-31845-large.mp4",
        "notes": "Learn how to design high-availability and disaster recovery architectures on AWS using VPC Peering, Route 53, and multi-region RDS database deployments.",
        "order": 1,
        "durationMinutes": 70,
        "isPreview": True
    },
    {
        "courseId": AWS_COURSE_ID,
        "title": "Serverless Scaling with AWS Lambda & API Gateway",
        "videoUrl": "https://assets.mixkit.co/videos/preview/mixkit-server-room-rack-cabinet-with-blinking-blue-lights-40348-large.mp4",
        "notes": "Deep dive into serverless microservices architecture, cold start optimization, API Gateway custom authorizers, and dynamoDB caching strategies.",
        "order": 2,
        "durationMinutes": 80,
        "isPreview": False
    }
]

quizzes_data = [
    # ── Flutter Course Quizzes ──
    {
        "courseId": FLUTTER_COURSE_ID,
        "question": "Which programming language is used to build Flutter apps?",
        "options": ["Java", "Swift", "Dart", "Kotlin"],
        "correctAnswer": 2,
        "order": 1,
        "explanation": "Flutter apps are written in Dart, an object-oriented language developed by Google."
    },
    {
        "courseId": FLUTTER_COURSE_ID,
        "question": "What is the primary difference between StatelessWidget and StatefulWidget?",
        "options": [
            "StatelessWidget is faster", 
            "StatefulWidget can rebuild dynamically when state changes", 
            "StatelessWidget cannot contain text", 
            "StatefulWidget is only for iOS apps"
        ],
        "correctAnswer": 1,
        "order": 2,
        "explanation": "StatefulWidget maintains state that can change over time, triggering a rebuild using setState(). StatelessWidget is immutable."
    },
    {
        "courseId": FLUTTER_COURSE_ID,
        "question": "Which widget is commonly used to create overlapping children in Flutter?",
        "options": ["Row", "Column", "Stack", "ListView"],
        "correctAnswer": 2,
        "order": 3,
        "explanation": "The Stack widget allows you to position children relative to the edges of its box, enabling overlapping layouts."
    },

    # ── UI/UX Course Quizzes ──
    {
        "courseId": UIUX_COURSE_ID,
        "question": "What does the 'UX' in UI/UX stand for?",
        "options": ["User Experience", "User Interface", "Universal Xenon", "User Exchange"],
        "correctAnswer": 0,
        "order": 1,
        "explanation": "UX stands for User Experience, which encompasses all aspects of the end-user's interaction with the company, its services, and its products."
    },
    {
        "courseId": UIUX_COURSE_ID,
        "question": "Which tool is currently the industry standard for collaborative UI design?",
        "options": ["Photoshop", "MS Paint", "Figma", "Xcode"],
        "correctAnswer": 2,
        "order": 2,
        "explanation": "Figma is the leading browser-based collaborative UI/UX design tool."
    },

    # ── AWS Course Quizzes ──
    {
        "courseId": AWS_COURSE_ID,
        "question": "Which AWS service is designed for serverless execution of code in response to events?",
        "options": ["EC2", "Lambda", "S3", "RDS"],
        "correctAnswer": 1,
        "order": 1,
        "explanation": "AWS Lambda lets you run code without provisioning or managing servers, executing only when triggered by events."
    },
    {
        "courseId": AWS_COURSE_ID,
        "question": "What is the primary benefit of multi-region database replication?",
        "options": [
            "Reduced cloud billing costs", 
            "Higher local storage capacity", 
            "High availability and disaster recovery", 
            "Faster database queries for all local users"
        ],
        "correctAnswer": 2,
        "order": 2,
        "explanation": "Replicating databases across multiple geographic regions provides high fault tolerance, high availability, and faster recovery during major cloud outages."
    }
]

# 3. Seed Database Function
def seed_database():
    print("\n🚀 Starting Database Seeding on Firestore...")
    
    # ── Seed Courses ──
    print("\n📚 Seeding Courses...")
    for course_id, data in courses_data.items():
        db.collection("courses").document(course_id).set(data)
        print(f"   Saved Course: '{data['title']}' (ID: {course_id})")

    # ── Seed Lessons ──
    print("\n🎬 Seeding Lessons...")
    # Delete old lessons first to avoid duplicates
    existing_lessons = db.collection("lessons").stream()
    for l in existing_lessons:
        l.reference.delete()
    
    for lesson in lessons_data:
        # Create unique auto-generated ID for each lesson doc
        doc_ref = db.collection("lessons").document()
        doc_ref.set(lesson)
        print(f"   Saved Lesson: '{lesson['title']}' for Course ID: {lesson['courseId']}")

    # ── Seed Quizzes ──
    print("\n🎯 Seeding Quizzes...")
    # Delete old quizzes first to avoid duplicates
    existing_quizzes = db.collection("quizzes").stream()
    for q in existing_quizzes:
        q.reference.delete()

    for quiz in quizzes_data:
        # Create unique auto-generated ID for each quiz doc
        doc_ref = db.collection("quizzes").document()
        doc_ref.set(quiz)
        print(f"   Saved Quiz Question: '{quiz['question'][:30]}...' for Course ID: {quiz['courseId']}")

    print("\n✨ Firestore Seeding Completed Successfully! ✨\n")

if __name__ == "__main__":
    # Create required bootstrap users first
    print("\n👤 Bootstrapping Auth & User Accounts...")
    create_user_if_not_exists(
        email="hazemehabsat@gmail.com",
        password="H123456",
        name="Hazem Ehab",
        role="admin"
    )
    create_user_if_not_exists(
        email="hazemehab2742001@gmail.com",
        password="Teacher@2024",
        name="Hazem Ehab",
        role="teacher"
    )
    
    seed_database()
