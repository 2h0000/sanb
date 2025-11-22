# Setup Instructions

This document provides step-by-step instructions for setting up the Encrypted Notebook app development environment.

## Prerequisites

1. **Flutter SDK**: Install Flutter 3.0 or higher
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. **Firebase Project**: Create a Firebase project
   - Go to: https://console.firebase.google.com/
   - Create a new project
   - Enable Authentication, Firestore, and Storage

## Step 1: Install Dependencies

```bash
flutter pub get
```

## Step 2: Configure Firebase

### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase for your project:
```bash
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Generate `lib/firebase_options.dart` with your configuration
- Create platform-specific configuration files

### Option B: Manual Configuration

If you prefer manual configuration:

1. **Android**: Download `google-services.json` from Firebase Console
   - Place it in `android/app/google-services.json`

2. **iOS**: Download `GoogleService-Info.plist` from Firebase Console
   - Place it in `ios/Runner/GoogleService-Info.plist`

3. **Update `lib/firebase_options.dart`** with your Firebase configuration values

## Step 3: Generate Code

Run code generation for Drift database and Riverpod providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous code generation during development:

```bash
dart run build_runner watch
```

## Step 4: Firebase Security Rules

### Firestore Rules

Go to Firebase Console > Firestore Database > Rules and add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Storage Rules

Go to Firebase Console > Storage > Rules and add:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Step 5: Run the App

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Web

```bash
flutter run -d chrome
```

## Development Workflow

1. **Make changes** to your code
2. **Hot reload**: Press `r` in the terminal or save the file
3. **Hot restart**: Press `R` in the terminal
4. **Run tests**: `flutter test`

## Troubleshooting

### Flutter Doctor Issues

Run `flutter doctor` and follow the instructions to resolve any issues.

### Build Runner Issues

If code generation fails:
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Firebase Connection Issues

1. Verify `firebase_options.dart` has correct configuration
2. Check that Firebase services are enabled in console
3. Ensure internet connection is available

### Android Build Issues

1. Check that `android/app/google-services.json` exists
2. Verify `minSdk` is at least 21 in `android/app/build.gradle`
3. Clean and rebuild: `flutter clean && flutter pub get`

### iOS Build Issues

1. Check that `ios/Runner/GoogleService-Info.plist` exists
2. Run `pod install` in the `ios` directory
3. Open Xcode and verify signing configuration

## Next Steps

After setup is complete, you can start implementing the features according to the task list in `.kiro/specs/encrypted-notebook-app/tasks.md`.

The next task is to implement the core encryption services (Task 2).
