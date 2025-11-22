import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers_dev.dart';
import '../../../app/theme_providers.dart';

/// Development version of settings screen
class SettingsScreenDev extends ConsumerWidget {
  const SettingsScreenDev({super.key});

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
      final mockAuthService = ref.read(mockAuthServiceProvider);
      final result = await mockAuthService.signOut();
      
      if (context.mounted) {
        result.when(
          ok: (_) {
            // Clear vault data key
            ref.read(dataKeyProvider.notifier).state = null;
            
            // Navigate to login
            context.go('/login');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signed out successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to sign out: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
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
          // Dev Mode Banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.developer_mode, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Development Mode - Local Storage Only',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // User Info Section
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.fingerprint),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'UID: ${user.uid}',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          const Divider(),
          
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
                applicationName: 'Secure Advanced Notebook (Dev)',
                applicationVersion: '1.0.0-dev',
                applicationIcon: const Icon(Icons.lock_outline, size: 48),
                children: const [
                  Text(
                    'Development Mode\n\n'
                    'A secure, end-to-end encrypted notebook app with '
                    'local storage.\n\n'
                    'Features:\n'
                    '• Zero-knowledge encryption\n'
                    '• Offline-first architecture\n'
                    '• Password vault with AES-256-GCM\n'
                    '• Mock authentication for testing',
                  ),
                ],
              );
            },
          ),
          
          const Divider(),
          
          // Sign Out
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
