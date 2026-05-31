# EduFlow Setup Guide 🚀

## Requirements
- Flutter SDK (stable channel)
- Android Studio
- VS Code
- Git
- Java JDK 17

## Steps

### 1. Clone
```bash
git clone https://github.com/hazemehabfawzy/EduFlow.git
cd EduFlow
```

### 2. Add Firebase Config
Place google-services.json inside android/app/
(Get this file from the project owner)

### 3. Install packages
```bash
flutter pub get
```

### 4. Run
```bash
flutter run
```

## Common Fixes
- Build error: flutter clean then flutter run
- No devices: connect phone with USB debugging ON
- Packages error: flutter pub get
