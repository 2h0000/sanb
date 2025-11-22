# Key Backup and Recovery Implementation Summary

## Task 9: 密钥备份与恢复实现 (Key Backup and Recovery Implementation)

### Requirements Addressed

This implementation addresses requirements 9.1-9.5:

- **9.1**: Upload key parameters to Firestore after vault initialization ✅
- **9.2**: Download key parameters from Firestore on new devices ✅
- **9.3**: New device unlock flow (download params → enter password → unlock) ✅
- **9.4**: Key parameters not found handling (prompt for new setup) ✅
- **9.5**: Key sync logic (cloud updates → local updates) ✅

## Components Implemented

### 1. KeyBackupService (`lib/core/crypto/key_backup_service.dart`)

Core service that orchestrates key backup and recovery operations.

**Key Methods:**
- `backupKeyParams(uid)` - Uploads key parameters to Firestore
- `downloadAndRestoreKeyParams(uid)` - Downloads and restores key params from cloud
- `hasCloudKeyParams(uid)` - Checks if key params exist in cloud
- `startKeyParamsSync(uid)` - Starts real-time sync of key parameters
- `stopKeyParamsSync()` - Stops key parameter sync
- `unlockOnNewDevice(uid, masterPassword)` - Complete new device unlock flow
- `initializeAndBackup(uid, masterPassword)` - Initialize vault and backup in one operation
- `changeMasterPasswordAndBackup(uid, oldPassword, newPassword)` - Change password and backup

**Features:**
- Automatic download of key params when not present locally
- Real-time sync of key parameter updates across devices
- Handles all edge cases (no local params, no cloud params, etc.)
- Comprehensive error handling with Result types

### 2. KeyBackupProviders (`lib/core/crypto/key_backup_providers.dart`)

Riverpod providers for dependency injection and state management.

**Providers:**
- `keyManagerProvider` - Provides KeyManager instance
- `firebaseClientProvider` - Provides FirebaseClient instance
- `keyBackupServiceProvider` - Provides KeyBackupService instance
- `keyParamsSyncProvider` - Automatically manages sync based on auth state
- `isVaultInitializedProvider` - Checks if vault is initialized locally
- `hasCloudKeyParamsProvider` - Checks if key params exist in cloud
- `dataKeyProvider` - Holds the unlocked data key in memory
- `isVaultUnlockedProvider` - Indicates if vault is currently unlocked

### 3. VaultUnlockService (`lib/features/vault/application/vault_unlock_service.dart`)

High-level service for vault unlock operations.

**Key Methods:**
- `needsSetup()` - Checks if vault needs initial setup
- `setupVault(uid, masterPassword)` - Sets up vault for first time
- `unlockVault(uid, masterPassword)` - Unlocks vault (handles all scenarios)
- `changeMasterPassword(uid, oldPassword, newPassword)` - Changes master password
- `hasCloudBackup(uid)` - Checks for cloud backup existence

**Features:**
- Unified interface for all unlock scenarios
- Automatically detects and handles new device unlock
- Simplifies UI implementation

### 4. VaultProviders (`lib/features/vault/application/vault_providers.dart`)

Providers for vault-specific functionality.

**Providers:**
- `vaultUnlockServiceProvider` - Provides VaultUnlockService instance
- `vaultNeedsSetupProvider` - Checks if vault needs setup

### 5. Enhanced AuthService (`lib/features/auth/application/auth_service.dart`)

Updated to integrate key backup with authentication flow.

**Enhancements:**
- Automatically downloads key params after successful sign-in
- Injects KeyBackupService for seamless integration
- Non-blocking key download (doesn't fail sign-in if download fails)

### 6. Enhanced AuthProviders (`lib/features/auth/application/auth_providers.dart`)

Updated to inject KeyBackupService into AuthService.

## Data Flow

### First-Time Setup Flow

```
User sets master password
    ↓
KeyManager.initializeWithMasterPassword()
    ↓
Generate random dataKey (32 bytes)
    ↓
Derive passwordKey from master password (PBKDF2)
    ↓
Wrap dataKey with passwordKey (AES-GCM)
    ↓
Store wrapped key locally (flutter_secure_storage)
    ↓
KeyBackupService.backupKeyParams()
    ↓
Upload to Firestore (users/{uid}/keys/master)
```

### New Device Unlock Flow

```
User logs in on new device
    ↓
AuthService.signInWithEmailAndPassword()
    ↓
AuthService._attemptKeyParamsDownload()
    ↓
KeyBackupService.downloadAndRestoreKeyParams()
    ↓
Download from Firestore
    ↓
Store in local secure storage
    ↓
User enters master password
    ↓
VaultUnlockService.unlockVault()
    ↓
KeyManager.unlockDataKey()
    ↓
Derive passwordKey from master password
    ↓
Unwrap dataKey using downloaded params
    ↓
Return dataKey for use
```

### Key Sync Flow

```
User changes password on Device A
    ↓
KeyBackupService.changeMasterPasswordAndBackup()
    ↓
Upload new params to Firestore
    ↓
Firestore triggers real-time update
    ↓
Device B receives update (via watchKeyParams)
    ↓
KeyBackupService.startKeyParamsSync() listener
    ↓
Compare local vs cloud params
    ↓
Update local storage with new params
    ↓
Next unlock uses new params
```

## Security Properties

### Zero-Knowledge Architecture Maintained

1. **Master password never leaves device**
   - Only used locally for key derivation
   - Never sent to server or stored in cloud

2. **Cloud only stores encrypted data**
   - wrappedDataKey is encrypted with passwordKey
   - passwordKey is derived from master password
   - Server cannot decrypt without master password

3. **Data key only in memory**
   - Stored in StateProvider during session
   - Cleared on logout
   - Never persisted to disk in plaintext

4. **Forward secrecy**
   - Changing master password re-wraps data key
   - Old password cannot decrypt new wrapped key
   - All devices must use new password after change

### Encryption Parameters

- **Key Derivation**: PBKDF2-HMAC-SHA256, 210,000 iterations
- **Key Wrapping**: AES-256-GCM
- **Data Encryption**: AES-256-GCM
- **Salt**: 16 bytes (random per user)
- **Nonce**: 12 bytes (random per encryption)

## Testing Considerations

### Unit Tests Needed
- KeyBackupService methods
- VaultUnlockService methods
- Error handling paths
- Edge cases (no network, missing params, etc.)

### Integration Tests Needed
- Complete first-