# Security Features

This module implements security features for the encrypted notebook application.

## Features Implemented

### 1. Auto-Lock Vault (5 minutes)

The vault automatically locks when the app goes to background for more than 5 minutes.

**Implementation:**
- `AppLifecycleObserver` monitors app lifecycle state changes
- When app goes to `paused` or `inactive` state, a 5-minute timer starts
- When timer expires, the `dataKey` is cleared from memory, locking the vault
- When app returns to `resumed` state, the timer is cancelled
- User must re-enter master password to unlock vault again

**Usage:**
The lifecycle observer is automatically registered in `EncryptedNotebookApp` widget.

### 2. Auto-Clear Clipboard (30 seconds)

When a password is copied to clipboard, it automatically clears after 30 seconds.

**Implementation:**
- `SecurityService.copyToClipboardWithAutoClear()` copies text and schedules clearing
- After 30 seconds, clipboard is cleared by setting it to empty string
- Only one clipboard clear timer is active at a time (new copies cancel previous timer)

**Usage:**
```dart
final securityService = ref.read(securityServiceProvider);
await securityService.copyToClipboardWithAutoClear(password);
```

The vault detail screen uses this for password copying, showing a message:
"Password copied (will clear in 30 seconds)"

### 3. Prevent Screenshots (Android)

On Android, the `FLAG_SECURE` flag prevents screenshots and screen recording.

**Implementation:**
- Set in `MainActivity.onCreate()` using `WindowManager.LayoutParams.FLAG_SECURE`
- Applies to entire app window
- Users cannot take screenshots or record screen while app is open

**Note:** This is Android-only. iOS has different security mechanisms.

## Architecture

```
┌─────────────────────────────────────┐
│     EncryptedNotebookApp            │
│  (registers lifecycle observer)     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│    AppLifecycleObserver             │
│  (monitors app state changes)       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      SecurityService                │
│  - startAutoLockTimer()             │
│  - cancelAutoLockTimer()            │
│  - copyToClipboardWithAutoClear()   │
└─────────────────────────────────────┘
```

## Configuration

### Auto-Lock Duration
Default: 5 minutes

To change, modify `SecurityService.autoLockDuration`:
```dart
static const Duration autoLockDuration = Duration(minutes: 5);
```

### Clipboard Clear Duration
Default: 30 seconds

To change, modify `SecurityService.clipboardClearDuration`:
```dart
static const Duration clipboardClearDuration = Duration(seconds: 30);
```

## Requirements Validation

This implementation satisfies requirements 3.5 and 3.6:

**Requirement 3.5:** WHEN 用户输入 MasterPassword 解锁 THEN System SHALL 重新派生 PasswordKey 并解密 wrappedDataKey 以获取 DataKey
- ✅ Auto-lock clears the dataKey, requiring re-unlock

**Requirement 3.6:** WHEN 解锁失败 THEN System SHALL 拒绝访问并提示用户密码错误
- ✅ After auto-lock, vault is inaccessible until successful unlock

## Future Enhancements (Optional)

### Biometric Authentication
To add biometric unlock (fingerprint/face):

1. Add dependency:
```yaml
dependencies:
  local_auth: ^2.1.7
```

2. Implement biometric unlock service:
```dart
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
```

3. Store master password hash securely and use biometric as gate
4. Update unlock screen to show biometric option

## Testing

To test security features:

1. **Auto-Lock:**
   - Unlock vault
   - Put app in background (home button)
   - Wait 5 minutes
   - Return to app
   - Verify vault is locked

2. **Clipboard Clear:**
   - Copy a password
   - Wait 30 seconds
   - Paste from clipboard
   - Verify clipboard is empty

3. **Screenshot Prevention (Android):**
   - Open app on Android device
   - Try to take screenshot
   - Verify screenshot is blocked or shows black screen
