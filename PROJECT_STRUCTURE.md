# Project Structure

This document describes the complete project structure for the Encrypted Notebook app.

## Directory Overview

```
encrypted_notebook/
├── .kiro/                          # Kiro specs and configuration
│   └── specs/
│       └── encrypted-notebook-app/
│           ├── requirements.md     # Feature requirements
│           ├── design.md          # Design document
│           └── tasks.md           # Implementation tasks
│
├── android/                        # Android platform configuration
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/            # MainActivity
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle           # App-level Gradle config
│   ├── build.gradle               # Project-level Gradle config
│   ├── settings.gradle            # Gradle settings
│   └── gradle.properties          # Gradle properties
│
├── ios/                           # iOS platform configuration
│   └── Runner/
│       └── Info.plist            # iOS app configuration
│
├── lib/                           # Main application code
│   ├── app/                       # App-level configuration
│   │   ├── app.dart              # Main app widget
│   │   ├── router.dart           # Go Router configuration
│   │   └── theme.dart            # Material theme
│   │
│   ├── core/                      # Core utilities and services
│   │   ├── crypto/               # Cryptography services
│   │   │   ├── crypto_service.dart    # AES-GCM encryption (Task 2)
│   │   │   └── key_manager.dart       # Key derivation (Task 2)
│   │   └── utils/                # Utility classes
│   │       ├── result.dart       # Result<T, E> type
│   │       └── logger.dart       # Logging utility
│   │
│   ├── data/                      # Data layer
│   │   ├── local/db/             # Local database
│   │   │   ├── app_database.dart      # Drift database (Task 3)
│   │   │   ├── notes_dao.dart         # Notes DAO (Task 4)
│   │   │   └── vault_dao.dart         # Vault DAO (Task 5)
│   │   ├── remote/               # Remote data sources
│   │   │   └── firebase_client.dart   # Firebase client (Task 6)
│   │   └── sync/                 # Synchronization
│   │       └── sync_service.dart      # Sync service (Task 8)
│   │
│   ├── domain/                    # Domain layer
│   │   ├── entities/             # Business entities
│   │   │   ├── note.dart         # Note entity
│   │   │   └── vault_item.dart   # VaultItem entity
│   │   └── repositories/         # Repository interfaces
│   │       ├── notes_repository.dart
│   │       └── vault_repository.dart
│   │
│   ├── features/                  # Feature modules
│   │   ├── notes/                # Notes feature
│   │   │   ├── presentation/     # UI (Task 15)
│   │   │   └── application/      # Business logic
│   │   ├── vault/                # Password vault feature
│   │   │   ├── presentation/     # UI (Task 16)
│   │   │   └── application/      # Business logic
│   │   ├── auth/                 # Authentication feature
│   │   │   ├── presentation/     # UI (Task 17)
│   │   │   └── application/      # Business logic (Task 7)
│   │   └── settings/             # Settings feature
│   │       └── presentation/     # UI (Task 18)
│   │
│   ├── firebase_options.dart      # Firebase configuration
│   └── main.dart                  # App entry point
│
├── test/                          # Test files
│   └── widget_test.dart          # Placeholder test
│
├── .gitignore                     # Git ignore rules
├── analysis_options.yaml          # Dart analyzer configuration
├── build.yaml                     # Build configuration
├── pubspec.yaml                   # Dependencies
├── README.md                      # Project documentation
├── SETUP.md                       # Setup instructions
└── PROJECT_STRUCTURE.md           # This file
```

## Layer Responsibilities

### App Layer (`lib/app/`)
- Application-wide configuration
- Routing and navigation
- Theme and styling

### Core Layer (`lib/core/`)
- Cryptography services (AES-GCM, PBKDF2)
- Utility classes (Result type, Logger)
- Cross-cutting concerns

### Data Layer (`lib/data/`)
- **Local**: Drift database, DAOs
- **Remote**: Firebase client (Firestore, Storage, Auth)
- **Sync**: Synchronization logic between local and remote

### Domain Layer (`lib/domain/`)
- **Entities**: Business objects (Note, VaultItem)
- **Repositories**: Abstract interfaces for data access

### Features Layer (`lib/features/`)
- **Presentation**: UI components (screens, widgets)
- **Application**: Business logic (use cases, state management)

## Key Files

### Configuration Files
- `pubspec.yaml`: Dependencies and project metadata
- `analysis_options.yaml`: Linting rules
- `build.yaml`: Code generation configuration
- `firebase_options.dart`: Firebase platform configuration

### Entry Points
- `lib/main.dart`: Application entry point
- `lib/app/app.dart`: Root widget
- `lib/app/router.dart`: Navigation configuration

### Platform Configuration
- `android/app/build.gradle`: Android build configuration
- `ios/Runner/Info.plist`: iOS app configuration

## Implementation Status

✅ **Task 1 Complete**: Project initialization and directory structure
- All directories created
- Dependencies configured in pubspec.yaml
- Basic app structure implemented
- Placeholder files for future tasks

🔜 **Next Task**: Task 2 - Core encryption services implementation

## Notes

- Placeholder files are marked with TODO comments
- Firebase configuration needs to be completed using `flutterfire configure`
- Code generation required after implementing Drift tables and Riverpod providers
- See SETUP.md for detailed setup instructions
