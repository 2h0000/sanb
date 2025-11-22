# Secure Advanced Notebook

A cross-platform encrypted notebook application with end-to-end encryption, built with Flutter.

## Features

- 📝 **Note Management**: Create, edit, and organize notes with Markdown support
- 🔐 **Password Vault**: Securely store passwords and credentials with AES-256-GCM encryption
- ☁️ **Cloud Sync**: Automatic synchronization across devices using Firebase
- 🔒 **Zero-Knowledge Architecture**: Your master password never leaves your device
- 📱 **Offline-First**: Full functionality without internet connection
- 🌓 **Dark Mode**: Beautiful light and dark themes

## Architecture

The app follows a clean architecture pattern with the following layers:

- **Presentation Layer**: UI components and state management (Riverpod)
- **Application Layer**: Use cases and business logic
- **Domain Layer**: Entities and repository interfaces
- **Data Layer**: Local database (Drift + SQLite) and remote API (Firebase)
- **Core Layer**: Cryptography, utilities, and error handling

## Security

- **Encryption**: AES-256-GCM for data encryption
- **Key Derivation**: PBKDF2-HMAC-SHA256 with 210,000 iterations
- **Secure Storage**: flutter_secure_storage for key management
- **Zero-Knowledge**: Master password is never transmitted or stored

## Setup

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Firebase project (for cloud sync)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

4. Generate code (for Drift and Riverpod):
   ```bash
   dart run build_runner build
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
├── lib/                    # Source code
│   ├── app/               # App configuration, routing, theme
│   ├── core/              # Core utilities and cryptography
│   ├── data/              # Data layer (local DB, Firebase)
│   ├── domain/            # Domain layer (entities, repositories)
│   └── features/          # Feature modules (notes, vault, auth, settings)
├── docs/                   # Documentation
│   ├── setup/             # Setup guides
│   ├── build/             # Build and release guides
│   ├── development/       # Development documentation
│   └── history/           # Change history and fixes
├── scripts/                # Utility scripts
│   ├── build/             # Build scripts
│   ├── setup/             # Setup scripts
│   └── version/           # Version management scripts
├── firebase/               # Firebase configuration
│   ├── firestore.rules    # Firestore security rules
│   └── storage.rules      # Storage security rules
├── assets/                 # App assets (icons, images)
├── android/                # Android platform code
├── ios/                    # iOS platform code
└── test/                   # Unit and widget tests
```

See [docs/](./docs/) for detailed documentation.

## Dependencies

### Core
- `flutter_riverpod`: State management
- `go_router`: Navigation and routing
- `drift`: Local database
- `cryptography`: Encryption library
- `flutter_secure_storage`: Secure key storage

### Firebase
- `firebase_core`: Firebase SDK
- `firebase_auth`: Authentication
- `firebase_firestore`: Cloud database
- `firebase_storage`: File storage
- `firebase_crashlytics`: Crash reporting

### Utilities
- `uuid`: UUID generation
- `intl`: Internationalization
- `file_picker`: File selection
- `share_plus`: File sharing

## Development

### Code Generation

Run code generation when you modify Drift tables or Riverpod providers:

```bash
dart run build_runner watch
```

### Testing

Run tests:

```bash
flutter test
```

### Building Release

Use the build script for creating release builds:

```bash
# Windows
scripts\build\build_release.bat

# Linux/Mac
./scripts/build/build_release.sh
```

See [scripts/README.md](./scripts/README.md) for more utility scripts.

## Documentation

- 📚 [Full Documentation](./docs/) - Complete project documentation
- 🚀 [Setup Guide](./docs/setup/SETUP.md) - Getting started
- 🔨 [Build Guide](./docs/build/BUILD_RELEASE_GUIDE.md) - Building releases
- 🔥 [Firebase Setup](./firebase/README.md) - Firebase configuration

## License

This project is licensed under the MIT License.
