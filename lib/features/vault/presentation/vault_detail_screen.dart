import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/security_providers.dart';
import '../application/vault_providers.dart';

/// Screen displaying details of a single vault item
class VaultDetailScreen extends ConsumerWidget {
  final String itemId;

  const VaultDetailScreen({super.key, required this.itemId});

  Future<void> _copyToClipboard(
    BuildContext context,
    WidgetRef ref,
    String text,
    String label, {
    bool isPassword = false,
  }) async {
    if (isPassword) {
      // Use secure clipboard copy for passwords (auto-clears after 30 seconds)
      final securityService = ref.read(securityServiceProvider);
      await securityService.copyToClipboardWithAutoClear(text);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied (will clear in 30 seconds)'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Regular clipboard copy for non-sensitive data
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vault Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final vaultService = ref.read(vaultServiceProvider);
    if (vaultService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault is locked')),
      );
      return;
    }

    final result = await vaultService.deleteVaultItem(itemId);
    
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
        context.go('/vault');
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItemAsync = ref.watch(vaultItemProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/vault/$itemId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteItem(context, ref),
          ),
        ],
      ),
      body: vaultItemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(
              child: Text('Vault item not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                _DetailCard(
                  icon: Icons.title,
                  label: 'Title',
                  value: item.title,
                  onCopy: () => _copyToClipboard(context, ref, item.title, 'Title'),
                ),
                const SizedBox(height: 12),

                // Username
                if (item.username != null && item.username!.isNotEmpty) ...[
                  _DetailCard(
                    icon: Icons.person,
                    label: 'Username',
                    value: item.username!,
                    onCopy: () =>
                        _copyToClipboard(context, ref, item.username!, 'Username'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Password
                if (item.password != null && item.password!.isNotEmpty) ...[
                  _PasswordCard(
                    password: item.password!,
                    onCopy: () =>
                        _copyToClipboard(context, ref, item.password!, 'Password', isPassword: true),
                  ),
                  const SizedBox(height: 12),
                ],

                // URL
                if (item.url != null && item.url!.isNotEmpty) ...[
                  _DetailCard(
                    icon: Icons.link,
                    label: 'URL',
                    value: item.url!,
                    onCopy: () => _copyToClipboard(context, ref, item.url!, 'URL'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Note
                if (item.note != null && item.note!.isNotEmpty) ...[
                  _DetailCard(
                    icon: Icons.note,
                    label: 'Note',
                    value: item.note!,
                    onCopy: () => _copyToClipboard(context, ref, item.note!, 'Note'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),
                ],

                // Last updated
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Updated',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(item.updatedAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading vault item'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;
  final int? maxLines;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: maxLines,
                    overflow: maxLines != null ? TextOverflow.ellipsis : null,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: 'Copy',
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordCard extends StatefulWidget {
  final String password;
  final VoidCallback onCopy;

  const _PasswordCard({
    required this.password,
    required this.onCopy,
  });

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.password,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isVisible ? widget.password : '••••••••',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _isVisible = !_isVisible;
                });
              },
              tooltip: _isVisible ? 'Hide' : 'Show',
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: widget.onCopy,
              tooltip: 'Copy',
            ),
          ],
        ),
      ),
    );
  }
}
