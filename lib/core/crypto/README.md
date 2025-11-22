# Encryption and Key Management

This directory contains the core encryption and key management components for the encrypted notebook app.

## Components

### CryptoService
Provides AES-256-GCM encryption and decryption operations.

**Key Features:**
- Symmetric encryption using AES-256-GCM
- Authenticated encryption (prevents tampering)
- Random nonce generation for each encryption
- Base64 encoding for storage

**Usage:**
```dart
final crypto = CryptoService();

// Encrypt
final result = await crypto.encryptString(
  plaintext: 'sensitive data',
  keyBytes: dataKey, // 32-byte key
);

// Decrypt
final decrypted = await crypto.decryptString(
  cipherAll: encryptedString,
  keyBytes: dataKey,
);
```

### KeyManager
Manages master password, key derivation, and key wrapping.

**Key Features:**
- PBKDF2-HMAC-SHA256 key derivation (210,000 iterations)
- Secure key wrapping using AES-GCM
- Local storage using flutter_secure_storage
- Master password change support

**Key Hierarchy:**
```
Master Password (user input)
    ↓ PBKDF2 (210k iterations)
Password Key (32 bytes)
    ↓ AES-GCM wrap
Data Key (32 bytes) ← Used to encrypt vault data
```

**Usage:**
```dart
final keyManager = KeyManager();

// Initialize vault (first time)
await keyManager.initializeWithMasterPassword('user_password');

// Unlock vault
final result = await keyManager.unlockDataKey('user_password');
if (result.isOk) {
  final dataKey = result.value; // Use this to encrypt/decrypt vault items
}

// Change master password
await keyManager.changeMasterPassword('old_password', 'new_password');
```

### KeyBackupService
Handles backup and recovery of key parameters to/from Firestore.

**Key Features:**
- Automatic backup to Firestore after vault initialization
- Download key parameters on new devices
- Real-time sync of key parameter updates
- New device unlock flow

**Cloud Storage:**
Key parameters are stored in Firestore at: `users/{uid}/keys/master`

The stored parameters include:
- `kdfSalt`: Salt used for PBKDF2 (Base64)
- `kdfIterations`: Number of PBKDF2 iterations
- `wrappedDataKey`: Encrypted data key (Base64)

**Usage:**
```dart
final keyBackupService = KeyBackupService(
  keyManager: keyManager,
  firebaseClient: firebaseClient,
);

// Backup after initialization
await keyBackupService.backupKeyParams(uid);

// Download on new device
await keyBackupService.downloadAndRestoreKeyParams(uid);

// Start automatic sync
keyBackupService.startKeyParamsSync(uid);

// New device unlock flow
final result = await keyBackupService.unlockOnNewDevice(
  uid: uid,
  masterPassword: 'user_password',
);
```

## Workflows

### First-Time Setup (New User)

1. User creates account and logs in
2. User sets master password
3. System generates random data key
4. System derives password key from master password
5. System wraps data key with password key
6. System stores wrapped key locally
7. System backs up key parameters to Firestore

```dart
// In UI code
final vaultUnlockService = ref.read(vaultUnlockServiceProvider);
final user = ref.read(currentUserProvider);

final result = await vaultUnlockService.setupVault(
  uid: user!.uid,
  masterPassword: masterPassword,
);

if (result.isOk) {
  // Store data key in state
  ref.read(dataKeyProvider.notifier).state = result.value;
}
```

### Unlock on Same Device

1. User enters master password
2. System retrieves wrapped key from local storage
3. System derives password key from master password
4. System unwraps data key
5. Data key is available for encrypting/decrypting vault items

```dart
final result = await vaultUnlockService.unlockVault(
  uid: user!.uid,
  masterPassword: masterPassword,
);

if (result.isOk) {
  ref.read(dataKeyProvider.notifier).state = result.value;
}
```

### Unlock on New Device

1. User logs in on new device
2. System detects no local key parameters
3. System downloads key parameters from Firestore
4. User enters master password
5. System derives password key from master password
6. System unwraps data key using downloaded parameters
7. Data key is available for use

```dart
// Same code as above - the service handles new device detection automatically
final result = await vaultUnlockService.unlockVault(
  uid: user!.uid,
  masterPassword: masterPassword,
);
```

### Master Password Change

1. User enters old and new passwords
2. System unlocks with old password to get data key
3. System derives new password key from new password
4. System re-wraps data key with new password key
5. System updates local storage
6. System backs up new parameters to Firestore
7. Other devices receive update via real-time sync

```dart
final result = await vaultUnlockService.changeMasterPassword(
  uid: user!.uid,
  oldPassword: oldPassword,
  newPassword: newPassword,
);
```

### Key Parameter Sync

The system automatically syncs key parameters across devices:

1. User changes master password on Device A
2. New key parameters are uploaded to Firestore
3. Device B receives real-time update
4. Device B updates local storage with new parameters
5. Next unlock on Device B uses new parameters

This is handled automatically by the `keyParamsSyncProvider`.

## Security Considerations

### What's Stored Where

**Local Storage (flutter_secure_storage):**
- Wrapped data key (encrypted)
- KDF salt
- KDF iterations

**Firestore:**
- Wrapped data key (encrypted)
- KDF salt
- KDF iterations

**Never Stored:**
- Master password
- Unwrapped data key (only in memory during app session)
- Password key (derived on-demand)

### Zero-Knowledge Architecture

The system implements zero-knowledge encryption:
- Master password never leaves the device
- Cloud only stores encrypted data key
- Server cannot decrypt vault data
- Only the user with the master password can decrypt

### Key Derivation Parameters

- **Algorithm:** PBKDF2-HMAC-SHA256
- **Iterations:** 210,000 (OWASP recommended minimum)
- **Salt:** 16 bytes (random per user)
- **Output:** 256 bits (32 bytes)

### Encryption Parameters

- **Algorithm:** AES-256-GCM
- **Key Size:** 256 bits (32 bytes)
- **Nonce Size:** 96 bits (12 bytes, random per encryption)
- **Tag Size:** 128 bits (16 bytes, for authentication)

## Error Handling

All operations return `Result<T, String>` types:

```dart
final result = await keyManager.unlockDataKey(password);

result.when(
  ok: (dataKey) {
    // Success - use dataKey
  },
  err: (error) {
    // Handle error - show to user
  },
);
```

Common errors:
- `"Vault is not initialized"` - Need to set up vault first
- `"Incorrect master password"` - Wrong password entered
- `"No key parameters found in cloud"` - User hasn't set up vault on any device
- `"Failed to backup key params"` - Network error during backup

## Testing

See `test/core/crypto/` for comprehensive tests including:
- Property-based tests for key derivation determinism
- Property-based tests for encryption round-trip
- Property-based tests for key wrapping
- Unit tests for edge cases

## Future Enhancements

Possible improvements:
- Biometric unlock (using local_auth)
- Key rotation
- Multiple vault support
- Hardware security module integration
- Backup encryption key (recovery key)
