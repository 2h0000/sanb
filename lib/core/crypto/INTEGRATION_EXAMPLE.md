# Key Backup and Recovery Integration Example

This document provides a complete example of how the key backup and recovery system integrates with the authentication and vault features.

## Complete Flow Example

### 1. App Initialization

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/crypto/key_backup_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch key params sync provider to enable automatic sync
    ref.watch(keyParamsSyncProvider);
    
    return MaterialApp(
      title: 'Encrypted Notebook',
      home: const AuthGate(),
    );
  }
}
```

### 2. Authentication Gate

```dart
// Determines which screen to show based on auth state
class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        } else {
          return const HomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### 3. Login Screen with Automatic Key Download

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    
    // Sign in - this automatically downloads key params if needed
    final result = await authService.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    result.when(
      ok: (user) {
        // Navigation handled by AuthGate
      },
      err: (error) {
        setState(() => _errorMessage = error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Home Screen with Vault Access

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Notebook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notes'),
            onTap: () {
              // Navigate to notes list
            },
          ),
          ListTile(
            leading: Icon(
              Icons.lock,
              color: isVaultUnlocked ? Colors.green : Colors.grey,
            ),
            title: const Text('Vault'),
            subtitle: Text(
              isVaultUnlocked ? 'Unlocked' : 'Locked',
            ),
            onTap: () {
              if (isVaultUnlocked) {
                // Navigate to vault list
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VaultUnlockScreen(),
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

### 5. Vault Unlock Screen (Handles All Scenarios)

```dart
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

    // This handles all scenarios:
    // - First-time setup
    // - Unlock on same device
    // - Unlock on new device (downloads params automatically)
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
        // Store data key in state
        ref.read(dataKeyProvider.notifier).state = dataKey;
        
        // Navigate back or to vault list
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault unlocked successfully')),
        );
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
            // Dynamic message based on state
            needsSetupAsync.when(
              data: (needsSetup) {
                if (needsSetup) {
                  return hasCloudBackupAsync.when(
                    data: (hasBackup) {
                      if (hasBackup) {
                        return _buildInfoCard(
                          'Welcome back!',
                          'Enter your master password to unlock your vault on this device.',
                          Icons.cloud_download,
                          Colors.blue,
                        );
                      } else {
                        return _buildInfoCard(
                          'Set Up Vault',
                          'Create a master password to secure your sensitive data.',
                          Icons.lock_outline,
                          Colors.green,
                        );
                      }
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                } else {
                  return _buildInfoCard(
                    'Unlock Vault',
                    'Enter your master password to access your vault.',
                    Icons.lock,
                    Colors.orange,
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                helperText: 'This password encrypts all your vault data',
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _handleUnlock(),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleUnlock,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : needsSetupAsync.maybeWhen(
                      data: (needsSetup) => Text(
                        needsSetup ? 'Set Up Vault' : 'Unlock',
                        style: const TextStyle(fontSize: 16),
                      ),
                      orElse: () => const Text('Unlock'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String message, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6. Settings Screen with Master Password Change

```dart
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            subtitle: Text(user?.email ?? 'Not logged in'),
          ),
          const Divider(),
          if (isVaultUnlocked)
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Change Master Password'),
              onTap: () => _showChangeMasterPasswordDialog(context, ref),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeMasterPasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final oldPassword = await _showPasswordDialog(context, 'Current Password');
    if (oldPassword == null) return;

    final newPassword = await _showPasswordDialog(context, 'New Password');
    if (newPassword == null) return;

    final confirmPassword = await _showPasswordDialog(context, 'Confirm New Password');
    if (confirmPassword != newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final vaultService = ref.read(vaultUnlockServiceProvider);
    final result = await vaultService.changeMasterPassword(
      uid: user.uid,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    Navigator.of(context).pop(); // Close loading dialog

    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Master password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      },
      err: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final keyManager = ref.read(keyManagerProvider);
    
    // Clear data key from memory
    ref.read(dataKeyProvider.notifier).state = null;
    
    // Sign out
    await authService.signOut();
    
    // Note: We don't clear local key params on logout
    // This allows the user to unlock vault without re-downloading
  }
}
```

## Key Points

### Automatic Key Download
- When user logs in, `AuthService` automatically checks for cloud key params
- If found, downloads and stores them locally
- User doesn't need to manually trigger download

### Seamless Cross-Device Experience
- User sets up vault on Device A
- Logs in on Device B
- Key params are automatically downloaded
- User enters same master password
- Vault unlocks with all data synced

### Automatic Sync
- `keyParamsSyncProvider` watches auth state
- When user logs in, starts listening to Firestore
- When master password changes on any device, all devices update
- No manual intervention required

### Security
- Master password never sent to server
- Only encrypted key params stored in cloud
- Data key only in memory during session
- Zero-knowledge architecture maintained

## Testing the Flow

### Test Scenario 1: New User
1. Register new account
2. Navigate to vault
3. Set master password
4. Verify vault unlocks
5. Add vault item
6. Logout and login
7. Verify vault unlocks with same password

### Test Scenario 2: New Device
1. Login on Device A, set up vault
2. Add some vault items
3. Login on Device B (new device)
4. Navigate to vault
5. Enter same master password
6. Verify vault unlocks and items are synced

### Test Scenario 3: Password Change
1. Login on Device A
2. Change master password
3. Verify vault still works on Device A
4. Open app on Device B
5. Try old password (should fail)
6. Try new password (should work)

### Test Scenario 4: Offline to Online
1. Login while online
2. Go offline
3. Try to unlock vault (should work with cached params)
4. Go back online
5. Verify sync still works
