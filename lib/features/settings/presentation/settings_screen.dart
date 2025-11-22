import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/theme_providers.dart';
import '../../../data/export/export_providers.dart';
import '../../../data/import/import_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleExportData(BuildContext context, WidgetRef ref) async {
    // Check if vault is unlocked (need dataKey for encryption)
    final dataKey = ref.read(dataKeyProvider);
    if (dataKey == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please unlock vault first to export data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show export options dialog
    final exportType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('What would you like to export?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('notes'),
            child: const Text('Notes Only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('vault'),
            child: const Text('Vault Only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('all'),
            child: const Text('Everything'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (exportType == null || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final exportService = ref.read(exportServiceProvider);
    
    // Perform export based on type
    final result = switch (exportType) {
      'notes' => await exportService.exportNotes(dataKey: dataKey),
      'vault' => await exportService.exportVault(dataKey: dataKey),
      'all' => await exportService.exportAll(dataKey: dataKey),
      _ => throw Exception('Invalid export type'),
    };

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      result.when(
        ok: (filePath) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export successful: ${exportType == 'all' ? 'All data' : exportType} exported'),
              backgroundColor: Colors.green,
            ),
          );
        },
        error: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  Future<void> _handleImportData(BuildContext context, WidgetRef ref) async {
    // Check if vault is unlocked (need dataKey for decryption)
    final dataKey = ref.read(dataKeyProvider);
    if (dataKey == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please unlock vault first to import data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will import data from an encrypted backup file. '
          'Existing items with the same ID will be updated if the imported version is newer.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final importService = ref.read(importServiceProvider);
    final result = await importService.importFromFile(dataKey: dataKey);

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      result.when(
        ok: (importResult) {
          final message = 'Import successful!\n'
              'Notes: ${importResult.notesImported} imported, ${importResult.notesSkipped} skipped\n'
              'Vault: ${importResult.vaultItemsImported} imported, ${importResult.vaultItemsSkipped} skipped';
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Complete'),
              content: Text(message),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        error: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  Future<void> _handleChangeMasterPassword(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Master Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final keyManager = ref.read(keyManagerProvider);
    final changeResult = await keyManager.changeMasterPassword(
      oldPasswordController.text,
      newPasswordController.text,
    );

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      changeResult.when(
        ok: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Master password changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear the dataKey to force re-unlock with new password
          ref.read(dataKeyProvider.notifier).state = null;
        },
        error: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change password: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }

    // Clean up controllers
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    
    return ListTile(
      leading: Icon(
        currentThemeMode == ThemeMode.light
            ? Icons.light_mode
            : currentThemeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.brightness_auto,
      ),
      title: const Text('Theme'),
      subtitle: Text(_getThemeModeLabel(currentThemeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final selected = await showDialog<ThemeMode>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  subtitle: const Text('Always use light theme'),
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  subtitle: const Text('Always use dark theme'),
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  subtitle: const Text('Follow system theme'),
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        
        if (selected != null) {
          await ref.read(themeModeProvider.notifier).setThemeMode(selected);
        }
      },
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('About Secure Advanced Notebook'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.1',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'A secure, end-to-end encrypted notebook app with cloud sync and password vault.',
              ),
              const SizedBox(height: 24),
              Text(
                'Encryption & Security',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Zero-knowledge architecture: Your master password never leaves your device\n'
                '• AES-256-GCM encryption for all sensitive data\n'
                '• PBKDF2-HMAC-SHA256 key derivation (210,000 iterations)\n'
                '• Each encrypted field uses a unique nonce for maximum security',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Features',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Offline-first architecture: Works without internet\n'
                '• Cloud synchronization with Firebase\n'
                '• Markdown support for rich note formatting\n'
                '• Secure password vault with encrypted storage\n'
                '• Full-text search across all notes\n'
                '• Export/import with encrypted backups',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your data is encrypted on your device before being synced to the cloud. '
                'We cannot read your notes or vault items. Your master password is never '
                'transmitted or stored on our servers. All encryption keys are derived from '
                'your master password and stored securely on your device.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Data Storage',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Local: SQLite database with encrypted vault items\n'
                '• Cloud: Firebase Firestore (encrypted data only)\n'
                '• Keys: Flutter Secure Storage (device keychain)',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // In local mode, just show a message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local mode: No sign out needed'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildThemeSelector(context, ref),
          
          const Divider(),
          
          // Data Management Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Data'),
            subtitle: const Text('Export notes and vault to encrypted backup'),
            onTap: () => _handleExportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Import from backup (Coming soon)'),
            enabled: false,
            onTap: () {
              // Will be implemented in task 11
            },
          ),
          
          const Divider(),
          
          // Security Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Security',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Change Master Password'),
            subtitle: const Text('Update vault encryption password (Coming soon)'),
            enabled: false,
            onTap: () {
              // Will be implemented later
            },
          ),
          
          const Divider(),
          
          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Secure Advanced Notebook',
                applicationVersion: '1.0.1',
                applicationIcon: const Icon(Icons.lock_outline, size: 48),
                children: [
                  const Text(
                    'A secure, end-to-end encrypted notebook app with '
                    'cloud sync and password vault.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Features:\n'
                    '• Zero-knowledge encryption\n'
                    '• Offline-first architecture\n'
                    '• Cloud synchronization\n'
                    '• Password vault with AES-256-GCM',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
