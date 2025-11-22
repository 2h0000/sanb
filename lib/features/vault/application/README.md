# Vault Feature

This directory contains the vault (password manager) feature implementation.

## Key Backup and Recovery Integration

The vault feature integrates with the key backup system to provide seamless cross-device access.

### Example: Vault Unlock Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/crypto/key_backup_providers.dart';
import '../../../features/auth/application/auth_providers.dart';
import 'vault_providers.dart';

class VaultUnlockScreen extends ConsumerStatefulWidget {
  const VaultUnlockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends ConsumerState<VaultUnlockScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _errorMessage = 'Not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vaultService = ref.read(vaultUnlockServiceProvider);
    final masterPassword = _passwordController.text;

    // Check if this is first-time setup
    final needsSetup = await vaultService.needsSetup();

    final result = needsSetup
        ? await vaultService.setupVault(
            uid: user.uid,
            masterPassword: masterPassword,
          )
        : await vaultService.unlockVault(
            uid: user.uid,
            masterPassword: masterPassword,
          );

    setState(() => _isLoading = false);

    result.when(
      ok: (dataKey) {
        // Store data key in state for use throughout the app
        ref.read(dataKeyProvider.notifier).state = dataKey;
        
        // Navigate to vault list
        Navigator.of(context).pushReplacementNamed('/vault');
      },
      err: (error) {
        setState(() => _errorMessage = error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsSetupAsync = ref.watch(vaultNeedsSetupProvider);
    final hasCloudBackupAsync = ref.watch(hasCloudKeyParamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Vault'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show status information
            needsSetupAsync.when(
              data: (needsSetup) {
                if (needsSetup) {
                  return hasCloudBackupAsync.when(
                    data: (hasBackup) {
                      if (hasBackup) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Enter your master password to unlock vault on this device',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      } else {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Set up your master password to secure your vault',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      }
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                } else {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Enter your master password',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Password input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
                helperText: 'This password encrypts your vault data',
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _handleUnlock(),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Unlock button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleUnlock,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : needsSetupAsync.maybeWhen(
                      data: (needsSetup) => Text(
                        needsSetup ? 'Set Up Vault' : 'Unlock',
                      ),
                      orElse: () => const Text('Unlock'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example: Change Master Password

```dart
Future<void> _changeMasterPassword(BuildContext context, WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final oldPassword = await _showPasswordDialog(context, 'Enter current password');
  if (oldPassword == null) return;

  final newPassword = await _showPasswordDialog(context, 'Enter new password');
  if (newPassword == null) return;

  final confirmPassword = await _showPasswordDialog(context, 'Confirm new password');
  if (confirmPassword != newPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwords do not match')),
    );
    return;
  }

  final vaultService = ref.read(vaultUnlockServiceProvider);
  final result = await vaultService.changeMasterPassword(
    uid: user.uid,
    oldPassword: oldPassword,
    newPassword: newPassword,
  );

  result.when(
    ok: (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master password changed successfully')),
      );
    },
    err: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $error')),
      );
    },
  );
}
```

## Automatic Key Sync

Key parameters are automatically synced across devices. To enable this, ensure the `keyParamsSyncProvider` is watched in your app:

```dart
// In your main app widget or a provider observer
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This ensures key sync starts when user logs in
    ref.watch(keyParamsSyncProvider);
    
    return MaterialApp(
      // ... app configuration
    );
  }
}
```

## Flows

### First-Time Setup Flow

1. User creates account and logs in
2. User navigates to vault
3. System detects vault needs setup
4. User enters master password
5. System creates vault and backs up to cloud
6. User can now add vault items

### Unlock on Same Device Flow

1. User opens app
2. User navigates to vault
3. System detects vault is locked
4. User enters master password
5. System unlocks vault
6. User can access vault items

### Unlock on New Device Flow

1. User logs in on new device
2. System downloads key parameters from cloud
3. User navigates to vault
4. User enters master password
5. System unlocks vault using downloaded parameters
6. User can access vault items

### Master Password Change Flow

1. User goes to settings
2. User selects "Change Master Password"
3. User enters old password
4. User enters new password
5. System re-wraps data key with new password
6. System backs up new parameters to cloud
7. Other devices receive update automatically

## Security Notes

- Master password never leaves the device
- Cloud only stores encrypted key parameters
- Data key is only in memory during app session
- All vault data is encrypted with AES-256-GCM
- PBKDF2 with 210,000 iterations protects against brute force
