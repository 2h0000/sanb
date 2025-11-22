# Security Features Integration Guide

This guide explains how the security features are integrated into the encrypted notebook app.

## Quick Start

The security features are **automatically active** once the code is deployed. No additional configuration needed!

## What's Automatically Enabled

### 1. Auto-Lock (5 minutes)
✅ **Already integrated** in `lib/app/app.dart`

The `AppLifecycleObserver` is registered when the app starts and monitors app state changes.

### 2. Clipboard Auto-Clear (30 seconds)
✅ **Already integrated** in `lib/features/vault/presentation/vault_detail_screen.dart`

Password copying uses the secure clipboard method automatically.

### 3. Screenshot Prevention (Android)
✅ **Already integrated** in `android/app/src/main/kotlin/com/example/encrypted_notebook/MainActivity.kt`

FLAG_SECURE is set when the app launches on Android.

## How It Works

### App Startup Sequence

```
1. main.dart
   └─> runApp(ProviderScope(child: EncryptedNotebookApp()))

2. EncryptedNotebookApp (app.dart)
   └─> initState()
       └─> Creates AppLifecycleObserver(ref)
       └─> Registers with WidgetsBinding

3. MainActivity.kt (Android only)
   └─> onCreate()
       └─> Sets FLAG_SECURE on window

4. Security features are now ACTIVE
```

### When User Unlocks Vault

```
1. User enters master password
   └─> VaultUnlockService.unlock()
       └─> Sets dataKeyProvider to decrypted key

2. Vault is now UNLOCKED
   └─> vaultServiceProvider is available
   └─> User can view/edit vault items

3. User switches to another app
   └─> AppLifecycleObserver detects 'paused'
       └─> SecurityService.startAutoLockTimer()
           └─> 5-minute countdown begins

4. After 5 minutes (if user doesn't return)
   └─> Timer expires
       └─> onAutoLock callback fires
           └─> dataKeyProvider set to null
               └─> Vault is LOCKED
```

### When User Copies Password

```
1. User taps copy button on password field
   └─> VaultDetailScreen._copyToClipboard()
       └─> Calls with isPassword: true

2. SecurityService.copyToClipboardWithAutoClear()
   └─> Copies password to clipboard
   └─> Starts 30-second timer
   └─> Shows message: "Password copied (will clear in 30 seconds)"

3. After 30 seconds
   └─> Timer expires
       └─> _clearClipboard() called
           └─> Clipboard set to empty string
```

## Provider Dependencies

```
securityServiceProvider
  ├─> Depends on: dataKeyProvider (from app/providers.dart)
  └─> Used by: AppLifecycleObserver, VaultDetailScreen

dataKeyProvider (app/providers.dart)
  ├─> Set by: VaultUnlockService
  └─> Cleared by: SecurityService (on auto-lock)

vaultServiceProvider (vault/application/vault_providers.dart)
  ├─> Depends on: dataKeyProvider
  └─> Returns null when vault is locked
```

## Adding Security to New Screens

### If you add a new screen that displays passwords:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/security_providers.dart';

class MyNewPasswordScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Your password display
          Text(password),
          
          // Copy button with auto-clear
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () async {
              final securityService = ref.read(securityServiceProvider);
              await securityService.copyToClipboardWithAutoClear(password);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password copied (will clear in 30 seconds)'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### If you want to manually lock the vault:

```dart
// In any ConsumerWidget or ConsumerStatefulWidget
void lockVault(WidgetRef ref) {
  ref.read(dataKeyProvider.notifier).state = null;
  // Vault is now locked
}
```

### If you want to check if vault is locked:

```dart
// In any ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final isUnlocked = ref.watch(isVaultUnlockedProvider);
  
  if (!isUnlocked) {
    return Text('Vault is locked');
  }
  
  return Text('Vault is unlocked');
}
```

## Customizing Security Settings

### Change Auto-Lock Duration

Edit `lib/core/security/security_service.dart`:

```dart
// Change from 5 minutes to 10 minutes
static const Duration autoLockDuration = Duration(minutes: 10);
```

### Change Clipboard Clear Duration

Edit `lib/core/security/security_service.dart`:

```dart
// Change from 30 seconds to 60 seconds
static const Duration clipboardClearDuration = Duration(seconds: 60);
```

### Disable Auto-Lock (Not Recommended)

If you really need to disable auto-lock:

```dart
// In app_lifecycle_observer.dart, comment out:
// case AppLifecycleState.paused:
// case AppLifecycleState.inactive:
//   securityService.startAutoLockTimer();
//   break;
```

### Disable Screenshot Prevention (Not Recommended)

If you need to allow screenshots on Android:

```kotlin
// In MainActivity.kt, comment out:
// window.setFlags(
//     WindowManager.LayoutParams.FLAG_SECURE,
//     WindowManager.LayoutParams.FLAG_SECURE
// )
```

## Testing the Integration

### Test Auto-Lock

1. Build and run the app
2. Unlock the vault with master password
3. Press home button (app goes to background)
4. Wait 5 minutes
5. Return to app
6. Verify vault is locked (shows unlock screen)

### Test Clipboard Auto-Clear

1. Build and run the app
2. Unlock vault and open a password item
3. Tap copy button on password
4. Verify message shows: "Password copied (will clear in 30 seconds)"
5. Immediately paste in another app (should work)
6. Wait 30 seconds
7. Try to paste again (clipboard should be empty)

### Test Screenshot Prevention

1. Build and run the app on Android device
2. Open any screen in the app
3. Try to take a screenshot (Power + Volume Down)
4. Verify screenshot is blocked or shows black screen

## Troubleshooting

### Auto-lock not working

**Problem**: Vault doesn't lock after 5 minutes

**Solutions**:
- Check that `AppLifecycleObserver` is registered in `app.dart`
- Verify `securityServiceProvider` is created
- Check console for any errors
- Ensure app actually goes to background (not just screen off)

### Clipboard not clearing

**Problem**: Password still in clipboard after 30 seconds

**Solutions**:
- Check that `copyToClipboardWithAutoClear()` is being called
- Verify timer is starting (add debug print)
- Some clipboard managers may cache clipboard history
- Test on different device

### Screenshots still working on Android

**Problem**: Can take screenshots despite FLAG_SECURE

**Solutions**:
- Verify `MainActivity.kt` has the FLAG_SECURE code
- Rebuild the app (clean build)
- Some Android ROMs may bypass FLAG_SECURE
- Test on different device

## Security Best Practices

### ✅ DO:
- Use `copyToClipboardWithAutoClear()` for all sensitive data
- Keep auto-lock duration reasonable (5-10 minutes)
- Test security features on real devices
- Document any security customizations

### ❌ DON'T:
- Don't disable auto-lock in production
- Don't store passwords in regular clipboard
- Don't remove FLAG_SECURE on Android
- Don't extend clipboard clear duration beyond 60 seconds

## Additional Resources

- [README.md](./README.md) - Feature overview and configuration
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - Implementation details
- [SECURITY_FLOW.md](./SECURITY_FLOW.md) - Flow diagrams and state transitions

## Support

If you encounter issues with security features:

1. Check the troubleshooting section above
2. Review the flow diagrams in SECURITY_FLOW.md
3. Verify all files are present and unmodified
4. Check for any diagnostic errors in the code
5. Test on a different device to rule out device-specific issues
