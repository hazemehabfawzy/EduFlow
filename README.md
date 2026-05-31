# EduFlow 🎓

A modern Flutter educational app built with Firebase.

## Features
- 🔐 Role-based auth (Admin / Teacher / Student)
- 📚 Course browsing with search and category filter
- 🎬 Lesson viewer with progress tracking
- ⭐ Course rating system
- 🔔 In-app notification center
- 📊 Admin analytics dashboard (fl_chart)
- 🌙 Dark mode with persistence
- 👨🏫 Teacher dashboard with lesson management
- 📧 Enrollment confirmation emails (Firebase Functions)

## Tech Stack
- Flutter 3.x
- Firebase (Auth, Firestore, Storage, Messaging)
- Provider state management
- fl_chart for analytics
- Google Fonts (Poppins + DM Sans)

## Accounts
See `accounts.txt` for login credentials.

## Setup
1. Clone the repo
2. Run `flutter pub get`
3. Add your `google-services.json` to `android/app/`
4. Add your `serviceAccountKey.json` to root (not committed)
5. Run `flutter run`

## Firebase Rules
See Firebase Console for Firestore security rules.
