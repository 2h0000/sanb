# Export Service Usage Examples

## Example 1: Export Notes from Settings Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/export/export_providers.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';

class ExportNotesButton extends ConsumerWidget {
  const ExportNotesButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Get the export service
        final exportService = ref.read(exportServiceProvider);
        
        // Get the DataKey (user must have unlocked vault)
        final dataKey = ref.read(dataKeyProvider);
        
        if (dataKey == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please unlock vault first'),
            ),
          );
          return;
        }
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Export notes
        final result = await exportService.exportNotes(
          dataKey: dataKey,
          shareFile: true, // Use system share sheet
        );
        
        // Hide loading indicator
        Navigator.of(context).pop();
        
        // Show result
        if (result.isOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notes exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: const Text('Export Notes'),
    );
  }
}
```

## Example 2: Export Vault with File Picker

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/export/export_providers.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';

class ExportVaultButton extends ConsumerWidget {
  const ExportVaultButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final exportService = ref.read(exportServiceProvider);
        final dataKey = ref.read(dataKeyProvider);
        
        if (dataKey == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please unlock vault first'),
            ),
          );
          return;
        }
        
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Vault'),
            content: const Text(
              'This will export all your vault items in encrypted format. '
              'Keep the export file secure!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Export'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
        
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Export vault with file picker
        final result = await exportService.exportVault(
          dataKey: dataKey,
          shareFile: false, // Use file picker to choose location
        );
        
        Navigator.of(context).pop();
        
        if (result.isOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vault exported to: ${result.value}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: const Text('Export Vault'),
    );
  }
}
```

## Example 3: Export Everything (Full Backup)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/export/export_providers.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';

class FullBackupButton extends ConsumerWidget {
  const FullBackupButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.backup),
      label: const Text('Full Backup'),
      onPressed: () async {
        final exportService = ref.read(exportServiceProvider);
        final dataKey = ref.read(dataKeyProvider);
        
        if (dataKey == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please unlock vault first'),
            ),
          );
          return;
        }
        
        // Show confirmation with info
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Full Backup'),
            content: const Text(
              'This will export all your notes and vault items to a single '
              'encrypted file. This is useful for complete backups.\n\n'
              'The file will be encrypted with your DataKey.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Create Backup'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
        
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Export everything
        final result = await exportService.exportAll(
          dataKey: dataKey,
          shareFile: true,
        );
        
        Navigator.of(context).pop();
        
        if (result.isOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Full backup created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
```

## Example 4: Settings Screen with Export Options

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExportSettingsSection extends ConsumerWidget {
  const ExportSettingsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Export & Backup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.note),
          title: const Text('Export Notes'),
          subtitle: const Text('Export all notes to encrypted file'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show export notes dialog or navigate to export screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Export Vault'),
          subtitle: const Text('Export password vault to encrypted file'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show export vault dialog or navigate to export screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Full Backup'),
          subtitle: const Text('Export everything (notes + vault)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show full backup dialog or navigate to export screen
          },
        ),
        const Divider(),
      ],
    );
  }
}
```

## Example 5: Error Handling Best Practices

```dart
Future<void> exportWithErrorHandling(
  BuildContext context,
  WidgetRef ref,
) async {
  final exportService = ref.read(exportServiceProvider);
  final dataKey = ref.read(dataKeyProvider);
  
  // Check if vault is unlocked
  if (dataKey == null) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vault Locked'),
        content: const Text(
          'You need to unlock the vault before exporting. '
          'This ensures your data is encrypted with the correct key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to vault unlock screen
            },
            child: const Text('Unlock Vault'),
          ),
        ],
      ),
    );
    return;
  }
  
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting...'),
          ],
        ),
      ),
    );
    
    // Perform export
    final result = await exportService.exportAll(
      dataKey: dataKey,
      shareFile: true,
    );
    
    // Hide loading
    Navigator.of(context).pop();
    
    // Handle result
    if (result.isOk) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your data has been exported successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show detailed error
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Failed'),
          content: Text(
            'Failed to export data:\n\n${result.error}\n\n'
            'Please try again or contact support if the problem persists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Hide loading if still showing
    Navigator.of(context).pop();
    
    // Show unexpected error
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unexpected Error'),
        content: Text('An unexpected error occurred: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Notes

1. **Always check if vault is unlocked** before attempting export
2. **Show loading indicators** for better UX during export
3. **Provide clear feedback** on success or failure
4. **Use confirmation dialogs** for destructive or important operations
5. **Handle user cancellation** gracefully (when they cancel file picker/share)
6. **Consider file size** for large exports (show progress if needed)
