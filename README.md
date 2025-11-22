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
lib/
├── app/                    # App configuration, routing, theme
├── core/                   # Core utilities and cryptography
│   ├── crypto/            # Encryption services
│   └── utils/             # Utilities (Result type, logger)
├── data/                   # Data layer
│   ├── local/db/          # Local database (Drift)
│   ├── remote/            # Firebase client
│   └── sync/              # Synchronization service
├── domain/                 # Domain layer
│   ├── entities/          # Business entities
│   └── repositories/      # Repository interfaces
├── features/               # Feature modules
│   ├── notes/             # Notes feature
│   ├── vault/             # Password vault feature
│   ├── auth/              # Authentication
│   └── settings/          # Settings
└── main.dart              # App entry point
```

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

## License

This project is licensed under the MIT License.
