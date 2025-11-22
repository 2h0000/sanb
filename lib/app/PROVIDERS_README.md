# Riverpod State Management Configuration

This document describes the centralized provider configuration for the Encrypted Notebook application.

## Overview

All core providers are defined in `lib/app/providers.dart` to avoid duplication and ensure consistency across the application. This file serves as the single source of truth for:

- Database and DAO providers
- Crypto service providers
- Authentication state providers
- Vault unlock state providers
- Notes list stream providers

## Provider Categories

### 1. Core Providers - Database, DAOs, and Crypto Services

#### `databaseProvider`
- **Type**: `Provider<AppDatabase>`
- **Purpose**: Provides the singleton AppDatabase instance
- **Lifecycle**: Automatically closes database when disposed
- **Usage**: Access the Drift database connection

#### `notesDaoProvider`
- **Type**: `Provider<NotesDao>`
- **Purpose**: Provides access to notes table operations
- **Dependencies**: `databaseProvider`
- **Usage**: CRUD operations for notes

#### `vaultDaoProvider`
- **Type**: `Provider<VaultDao>`
- **Purpose**: Provides access to vault items table operations
- **Dependencies**: `databaseProvider`
- **Usage**: CRUD operations for encrypted vault items

#### `cryptoServiceProvider`
- **Type**: `Provider<CryptoService>`
- **Purpose**: Handles AES-GCM encryption and decryption
- **Usage**: Encrypt/decrypt strings with AES-256-GCM

#### `keyManagerProvider`
- **Type**: `Provider<KeyManager>`
- **Purpose**: Manages master password, key derivation (PBKDF2), and key wrapping
- **Usage**: Initialize vault, unlock vault, change master password

#### `firebaseClientProvider`
- **Type**: `Provider<FirebaseClient>`
- **Purpose**: Encapsulates Firestore and Storage operations
- **Usage**: Access Firebase collections and documents

#### `keyBackupServiceProvider`
- **Type**: `Provider<KeyBackupService>`
- **Purpose**: Handles backup and sync of encryption key parameters to/from cloud
- **Dependencies**: `keyManagerProvider`, `firebaseClientProvider`
- **Lifecycle**: Automatically disposed when provider is disposed

### 2. Authentication Providers

#### `authStateProvider`
- **Type**: `StreamProvider<User?>`
- **Purpose**: Streams the current Firebase authentication state
- **Updates**: Automatically when user signs in/out
- **Usage**: Watch for authentication state changes

#### `currentUserProvider`
- **Type**: `Provider<User?>`
- **Purpose**: Provides synchronous access to current user
- **Dependencies**: `authStateProvider`
- **Returns**: Current user or null if not authenticated

#### `isAuthenticatedProvider`
- **Type**: `Provider<bool>`
- **Purpose**: Check if user is authenticated
- **Dependencies**: `currentUserProvider`
- **Returns**: true if user is logged in

### 3. Vault Unlock State Providers

#### `dataKeyProvider`
- **Type**: `StateProvider<List<int>?>`
- **Purpose**: Holds the decrypted 32-byte data key in memory after vault unlock
- **Security**: Key is only in memory, cleared on app restart
- **Usage**: Used to encrypt/decrypt vault items

#### `isVaultUnlockedProvider`
- **Type**: `Provider<bool>`
- **Purpose**: Check if vault is currently unlocked
- **Dependencies**: `dataKeyProvider`
- **Returns**: true if dataKey is available

#### `isVaultInitializedProvider`
- **Type**: `FutureProvider<bool>`
- **Purpose**: Check if vault has been initialized locally
- **Dependencies**: `keyManagerProvider`
- **Returns**: true if key parameters exist in secure storage

#### `hasCloudKeyParamsProvider`
- **Type**: `FutureProvider<bool>`
- **Purpose**: Check if key parameters exist in cloud
- **Dependencies**: `currentUserProvider`, `keyBackupServiceProvider`
- **Returns**: true if user has backed up key parameters to Firestore

#### `keyParamsSyncProvider`
- **Type**: `Provider<void>`
- **Purpose**: Automatically manages key params sync based on auth state
- **Behavior**: 
  - When user logs in: starts syncing key parameters from cloud
  - When user logs out: stops syncing
- **Dependencies**: `keyBackupServiceProvider`, `currentUserProvider`

### 4. Notes List Provider (StreamProvider)

#### `notesListProvider`
- **Type**: `StreamProvider<List<Note>>`
- **Purpose**: Streams all non-deleted notes, sorted by updatedAt descending
- **Dependencies**: `notesDaoProvider`
- **Updates**: Automatically when notes change in database
- **Usage**: Display notes list in UI

#### `notesCountProvider`
- **Type**: `StreamProvider<int>`
- **Purpose**: Streams the count of non-deleted notes
- **Dependencies**: `notesDaoProvider`
- **Updates**: Automatically when notes are added/deleted
- **Usage**: Display note count in UI

## Migration from Old Provider Files

The following files have been updated to use the centralized providers:

1. **`lib/core/crypto/key_backup_providers.dart`**
   - Now re-exports from `lib/app/providers.dart`
   - Marked as deprecated

2. **`lib/features/auth/application/auth_providers.dart`**
   - Removed duplicate provider definitions
   - Only contains `authServiceProvider`
   - Imports from `lib/app/providers.dart`

3. **`lib/features/vault/application/vault_providers.dart`**
   - Imports from `lib/app/providers.dart`
   - Contains vault-specific providers

4. **`lib/data/sync/offline_providers.dart`**
   - Imports from `lib/app/providers.dart`
   - Contains connectivity and sync providers

5. **`lib/data/import/import_providers.dart`**
   - Imports from `lib/app/providers.dart`
   - Contains import service provider

6. **`lib/data/export/export_providers.dart`**
   - Imports from `lib/app/providers.dart`
   - Contains export service provider

## Usage Examples

### Accessing the Database

```dart
final database = ref.watch(databaseProvider);
```

### Watching Notes List

```dart
final notesAsync = ref.watch(notesListProvider);

notesAsync.when(
  data: (notes) => ListView.builder(
    itemCount: notes.length,
    itemBuilder: (context, index) => NoteListItem(note: notes[index]),
  ),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Checking Authentication

```dart
final isAuthenticated = ref.watch(isAuthenticatedProvider);

if (isAuthenticated) {
  // Show authenticated content
} else {
  // Show login screen
}
```

### Unlocking Vault

```dart
final keyManager = ref.read(keyManagerProvider);
final dataKey = await keyManager.unlockDataKey(masterPassword);

// Store in state
ref.read(dataKeyProvider.notifier).state = dataKey;
```

### Encrypting Vault Item

```dart
final cryptoService = ref.read(cryptoServiceProvider);
final dataKey = ref.read(dataKeyProvider);

if (dataKey != null) {
  final encrypted = await cryptoService.encryptString(
    plaintext: 'my secret',
    keyBytes: dataKey,
  );
}
```

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 1.4**: Notes list provider with StreamProvider for real-time updates
- **Requirement 3.5**: Vault unlock state and DataKey providers for secure key management
- **Requirement 11.2**: Authentication state provider for user session management

## Best Practices

1. **Use `ref.watch()` in build methods** to rebuild when provider changes
2. **Use `ref.read()` in event handlers** to avoid unnecessary rebuilds
3. **Use `ref.listen()` to react to provider changes** without rebuilding
4. **Always check if vault is unlocked** before accessing vault items
5. **Clear dataKey on logout** to ensure security

## Security Considerations

- The `dataKeyProvider` holds sensitive encryption keys in memory
- Keys are automatically cleared when the app is closed
- Keys are never persisted to disk in plaintext
- Always verify vault is unlocked before performing vault operations
- Use `flutter_secure_storage` for persistent key storage (handled by KeyManager)
