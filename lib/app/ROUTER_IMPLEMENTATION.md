# Router Implementation Summary

## Overview

This document describes the implementation of the application routing system using `go_router`. The router handles navigation between all screens and implements two critical guards: authentication and vault unlock.

## Implemented Routes

### Authentication Routes
- `/login` - Login screen (accessible when not authenticated)

### Notes Routes
- `/notes` - Notes list screen (main screen after login)
- `/notes/new` - Create new note screen
- `/notes/:id` - View note detail screen
- `/notes/:id/edit` - Edit existing note screen

### Vault Routes
- `/vault/unlock` - Vault unlock screen (requires authentication)
- `/vault` - Vault items list screen (requires authentication + vault unlock)
- `/vault/new` - Create new vault item screen (requires authentication + vault unlock)
- `/vault/:id` - View vault item detail screen (requires authentication + vault unlock)
- `/vault/:id/edit` - Edit existing vault item screen (requires authentication + vault unlock)

### Settings Routes
- `/settings` - Settings screen (requires authentication)

## Route Guards

### 1. Authentication Guard (需求 11.1)

**Purpose**: Ensures only authenticated users can access protected routes.

**Implementation**:
```dart
// If not authenticated and not on login page, redirect to login
if (!isAuthenticated && !isLoggingIn) {
  return '/login';
}

// If authenticated and on login page, redirect to notes
if (isAuthenticated && isLoggingIn) {
  return '/notes';
}
```

**Behavior**:
- Unauthenticated users attempting to access any route (except `/login`) are redirected to `/login`
- Authenticated users on `/login` are automatically redirected to `/notes`
- Uses `authStateProvider` to watch Firebase authentication state changes

### 2. Vault Unlock Guard (需求 3.5)

**Purpose**: Ensures vault is unlocked before accessing vault data.

**Implementation**:
```dart
// If accessing vault routes (except unlock page) and vault is not unlocked,
// redirect to unlock page
if (isAuthenticated && isVaultRoute && !isVaultUnlockRoute && !isVaultUnlocked) {
  return '/vault/unlock';
}

// If vault is unlocked and on unlock page, redirect to vault list
if (isAuthenticated && isVaultUnlockRoute && isVaultUnlocked) {
  return '/vault';
}
```

**Behavior**:
- Users attempting to access `/vault/*` routes (except `/vault/unlock`) without unlocking the vault are redirected to `/vault/unlock`
- Users who have unlocked the vault and visit `/vault/unlock` are automatically redirected to `/vault`
- Uses `isVaultUnlockedProvider` to check if `dataKey` is available in memory

## Provider Integration

The router integrates with the following providers:

1. **authStateProvider**: Watches Firebase authentication state
   - Returns `Stream<User?>` that updates when auth state changes
   - Used to determine if user is authenticated

2. **isVaultUnlockedProvider**: Checks if vault is unlocked
   - Returns `bool` based on whether `dataKey` is available
   - Used to enforce vault unlock guard

## Navigation Flow

### First-Time User Flow
1. App starts → `/notes` (initial location)
2. Not authenticated → Redirect to `/login`
3. User logs in → Redirect to `/notes`
4. User navigates to `/vault` → Redirect to `/vault/unlock` (vault not unlocked)
5. User unlocks vault → Redirect to `/vault`

### Returning User Flow (Already Authenticated)
1. App starts → `/notes` (initial location)
2. Already authenticated → Stay on `/notes`
3. User navigates to `/vault` → Redirect to `/vault/unlock` (vault not unlocked)
4. User unlocks vault → Redirect to `/vault`

### Vault Access Flow
1. User on any screen → Navigates to `/vault`
2. If vault unlocked → Show `/vault` list
3. If vault not unlocked → Redirect to `/vault/unlock`
4. After unlock → Redirect to `/vault`

## Placeholder Screens

All screens are currently implemented as placeholders with basic UI structure. They will be fully implemented in later tasks:

- **Task 15**: Notes UI implementation
- **Task 16**: Vault UI implementation
- **Task 17**: Authentication UI enhancements

Each placeholder screen includes:
- AppBar with title
- Navigation actions (settings, edit, etc.)
- Placeholder text indicating "Coming Soon"
- Floating action buttons where appropriate (add note/vault item)

## Requirements Validation

### 需求 11.1: 用户认证
✅ **WHEN 用户输入邮箱和密码并点击登录 THEN System SHALL 调用 Firebase Authentication 验证凭证**
- Router redirects unauthenticated users to login screen
- Login screen integration ready for authentication implementation

### 需求 3.5: 密码库解锁
✅ **WHEN 用户输入 MasterPassword 解锁 THEN System SHALL 重新派生 PasswordKey 并解密 wrappedDataKey 以获取 DataKey**
- Router enforces vault unlock before accessing vault routes
- Vault unlock screen integration ready for unlock implementation

## Technical Details

### Router Provider
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);
  
  return GoRouter(
    initialLocation: '/notes',
    redirect: (context, state) {
      // Guard logic here
    },
    routes: [
      // Route definitions here
    ],
  );
});
```

### Key Features
1. **Reactive Navigation**: Router automatically updates when auth state or vault unlock state changes
2. **Type-Safe Parameters**: Route parameters (`:id`) are extracted using `state.pathParameters`
3. **Declarative Guards**: All guard logic centralized in the `redirect` callback
4. **Initial Location**: App starts at `/notes` (will redirect based on auth state)

## Future Enhancements

When implementing the actual screens (Tasks 15-17), the placeholder screens should be replaced with:

1. **Notes Screens**: Full CRUD operations, search, markdown editing
2. **Vault Screens**: Secure credential management, password generation, copy-to-clipboard
3. **Unlock Screen**: Master password input, biometric authentication (optional)

The routing structure is designed to accommodate these enhancements without requiring changes to the route definitions or guard logic.
