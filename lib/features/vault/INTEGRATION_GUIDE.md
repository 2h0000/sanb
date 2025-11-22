# Vault UI Integration Guide

## Quick Start

The vault UI has been fully implemented and integrated into the application. Here's how to use it:

### 1. First Time Setup

When a user first accesses the vault:
1. Navigate to `/vault` or `/vault/unlock`
2. The system detects no master password is set
3. User sees "Set Up Master Password" screen
4. User enters and confirms a master password (minimum 8 characters)
5. System creates encryption keys and stores them securely
6. User is automatically redirected to the vault list

### 2. Subsequent Access

When returning to the vault:
1. Navigate to `/vault`
2. If vault is locked, router redirects to `/vault/unlock`
3. User enters master password
4. System unlocks vault and loads data key into memory
5. User is redirected to vault list

### 3. Managing Vault Items

#### Creating Items
1. From vault list, tap the + button
2. Fill in the form (only title is required)
3. Use the password generator if needed (sparkle icon)
4. Tap "Save" in the app bar

#### Viewing Items
1. From vault list, tap any item
2. View all fields (password is hidden by default)
3. Tap eye icon to show/hide password
4. Tap copy icon to copy any field to clipboard

#### Editing Items
1. From detail screen, tap edit icon
2. Modify any fields
3. Tap "Save" in the app bar

#### Deleting Items
1. From detail screen, tap delete icon
2. Confirm deletion in dialog
3. Item is soft-deleted from database

#### Searching Items
1. From vault list, use the search bar at the top
2. Type to filter items by title
3. Clear search with X button

### 4. Locking the Vault

From the vault list screen:
1. Tap the lock icon in the app bar
2. Data key is cleared from memory
3. Router automatically redirects to unlock screen

## Router Behavior

The router has built-in guards:
- **Not authenticated** → Redirects to `/login`
- **Authenticated but vault locked** → Redirects to `/vault/unlock`
- **Vault unlocked** → Full access to vault screens

## State Management

### Key Providers

```dart
// Check if vault is unlocked
final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);

// Get data key (null if locked)
final dataKey = ref.watch(dataKeyProvider);

// Get vault service (null if locked)
final vaultService = ref.watch(vaultServiceProvider);

// Watch vault items list
final vaultItems = ref.watch(vaultItemsListProvider);

// Get single vault item
final item = ref.watch(vaultItemProvider('uuid-here'));
```

### Locking/Unlocking

```dart
// Lock vault
ref.read(dataKeyProvider.notifier).state = null;

// Unlock vault (done by VaultUnlockScreen)
ref.read(dataKeyProvider.notifier).state = dataKeyBytes;
```

## Security Features

### Implemented
- ✅ Master password with PBKDF2 key derivation
- ✅ AES-GCM encryption for all sensitive fields
- ✅ Data key stored in memory only (not persisted)
- ✅ Manual vault locking
- ✅ Router guards prevent unauthorized access
- ✅ Password fields obscured by default
- ✅ Clipboard copy with user feedback

### Recommended Additions
- ⏳ Auto-lock after inactivity (5 minutes)
- ⏳ Biometric unlock (fingerprint/face)
- ⏳ Auto-clear clipboard after 30 seconds
- ⏳ Screenshot prevention (FLAG_SECURE on Android)

## Testing the Implementation

### Manual Test Flow

1. **Setup Flow**
   ```
   Login → Navigate to /vault → See setup screen → 
   Enter password → Confirm password → See vault list
   ```

2. **Create Item Flow**
   ```
   Vault list → Tap + → Fill form → Generate password → 
   Save → See item in list
   ```

3. **View Item Flow**
   ```
   Vault list → Tap item → See details → 
   Toggle password visibility → Copy fields
   ```

4. **Edit Item Flow**
   ```
   Detail screen → Tap edit → Modify fields → 
   Save → See updated item
   ```

5. **Delete Item Flow**
   ```
   Detail screen → Tap delete → Confirm → 
   Return to list (item removed)
   ```

6. **Search Flow**
   ```
   Vault list → Type in search → See filtered results → 
   Clear search → See all items
   ```

7. **Lock/Unlock Flow**
   ```
   Vault list → Tap lock → Redirected to unlock → 
   Enter password → Return to vault list
   ```

### Edge Cases to Test

- Empty password during setup
- Mismatched passwords during setup
- Wrong password during unlock
- Empty vault list
- Search with no results
- Very long field values
- Special characters in all fields
- Rapid navigation between screens
- Network offline (should work)

## Password Generator

The password generator is accessible from the edit screen:

### Features
- Length: 8-32 characters (slider)
- Character types: Uppercase, Lowercase, Numbers, Symbols
- Real-time preview
- Regenerate button
- Validation (at least one type must be selected)

### Usage
1. From edit screen, tap sparkle icon next to password field
2. Adjust settings as needed
3. Tap regenerate if desired
4. Tap "Use This Password" to apply

## Common Issues and Solutions

### Issue: Vault won't unlock
**Solution**: Verify the master password is correct. If forgotten, there's no recovery - user must reset the app data.

### Issue: Items not appearing in list
**Solution**: Check that vault is unlocked (`isVaultUnlockedProvider` should be true).

### Issue: Can't save vault item
**Solution**: Ensure title field is not empty (it's required).

### Issue: Router keeps redirecting
**Solution**: Check authentication state and vault unlock state. Router guards are working as designed.

### Issue: Decryption errors
**Solution**: Verify data key is valid and matches the key used for encryption.

## Architecture Overview

```
User Input
    ↓
VaultEditScreen
    ↓
VaultService.createVaultItem()
    ↓
VaultItem.encrypt() [uses CryptoService + DataKey]
    ↓
VaultDao.createVaultItem() [stores encrypted data]
    ↓
Database (SQLite)
    ↓
VaultDao.watchAllVaultItems() [emits stream]
    ↓
vaultItemsListProvider [decrypts items]
    ↓
VaultListScreen [displays items]
```

## Next Steps

After verifying the vault UI works correctly:

1. **Task 17**: Implement authentication UI (login/register screens)
2. **Task 18**: Implement settings page with export/import
3. **Task 19**: Add security features (auto-lock, clipboard clearing)
4. **Task 20**: Implement error handling and logging

## Files Reference

### Application Layer
- `lib/features/vault/application/vault_service.dart` - CRUD operations
- `lib/features/vault/application/vault_providers.dart` - State management
- `lib/features/vault/application/vault_unlock_service.dart` - Unlock coordination

### Presentation Layer
- `lib/features/vault/presentation/vault_unlock_screen.dart` - Setup/unlock
- `lib/features/vault/presentation/vault_list_screen.dart` - List view
- `lib/features/vault/presentation/vault_detail_screen.dart` - Detail view
- `lib/features/vault/presentation/vault_edit_screen.dart` - Create/edit

### Integration
- `lib/app/router.dart` - Route definitions and guards
- `lib/app/providers.dart` - Global providers

## Support

For issues or questions about the vault implementation, refer to:
- Design document: `.kiro/specs/encrypted-notebook-app/design.md`
- Requirements: `.kiro/specs/encrypted-notebook-app/requirements.md`
- Implementation summary: `lib/features/vault/presentation/VAULT_UI_IMPLEMENTATION.md`
