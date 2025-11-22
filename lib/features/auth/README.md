# Authentication Feature

This module implements Firebase Authentication for the Encrypted Notebook app.

## Components

### Application Layer

#### `auth_service.dart`
Core authentication service that wraps Firebase Auth operations:
- `signInWithEmailAndPassword()` - Sign in existing users
- `registerWithEmailAndPassword()` - Register new users
- `signOut()` - Sign out current user
- `authStateChanges` - Stream of authentication state changes
- Error handling with user-friendly messages

#### `auth_providers.dart`
Riverpod providers for authentication state management:
- `authServiceProvider` - Provides AuthService instance
- `authStateProvider` - Stream of current user (User?)
- `currentUserProvider` - Synchronous access to current user
- `isAuthenticatedProvider` - Boolean authentication status

### Presentation Layer

#### `login_screen.dart`
Login/Registration UI with:
- Email and password input fields
- Toggle between login and registration modes
- Form validation
- Error message display
- Loading states
- Password visibility toggle

## Usage

### Checking Authentication State

```dart
// In a ConsumerWidget
final authState = ref.watch(authStateProvider);
authState.when(
  data: (user) {
    if (user != null) {
      // User is authenticated
    } else {
      // User is not authenticated
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Sign In

```dart
final authService = ref.read(authServiceProvider);
final result = await authService.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);

result.when(
  ok: (user) => print('Signed in: ${user.email}'),
  error: (error) => print('Error: $error'),
);
```

### Sign Out

```dart
final authService = ref.read(authServiceProvider);
final result = await authService.signOut();

result.when(
  ok: (_) => print('Signed out successfully'),
  error: (error) => print('Error: $error'),
);
```

## Router Integration

The router automatically redirects users based on authentication state:
- Unauthenticated users → `/login`
- Authenticated users on login page → `/notes`

## Requirements Satisfied

- ✅ 11.1: Email/password login with Firebase Authentication
- ✅ 11.2: Authentication success initializes cloud sync (via authStateProvider)
- ✅ 11.3: Authentication failure displays error messages
- ✅ 11.4: User registration creates new Firebase account
- ✅ 11.5: Sign out clears authentication state and stops sync

## Settings Screen

The settings screen (`lib/features/settings/presentation/settings_screen.dart`) provides:
- User account information display
- Sign out functionality with confirmation dialog
- Placeholders for future features (export, import, change password)
- About dialog with app information
