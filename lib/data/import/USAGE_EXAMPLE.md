# Import Service Usage Examples

## Basic Import Flow

### 1. Import from Settings Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/import/import_providers.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from encrypted backup'),
            onTap: () => _handleImport(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
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

    // Perform import
    final importService = ref.read(importServiceProvider);
    final result = await importService.importFromFile(dataKey: dataKey);

    // Hide loading indicator
    Navigator.of(context).pop();

    // Show result
    result.when(
      ok: (importResult) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Successfully imported:\n'
              '• ${importResult.notesImported} notes\n'
              '• ${importResult.vaultItemsImported} vault items\n\n'
              'Skipped (older versions):\n'
              '• ${importResult.notesSkipped} notes\n'
              '• ${importResult.vaultItemsSkipped} vault items',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      err: (error) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 2. Import with Password Prompt

```dart
Future<void> _handleImportWithPasswordPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  // Prompt user for master password
  final password = await showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(),
  );

  if (password == null) {
    return; // User cancelled
  }

  // Unlock DataKey with password
  final keyManager = ref.read(keyManagerProvider);
  final dataKeyResult = await keyManager.unlockDataKey(password);

  dataKeyResult.when(
    ok: (dataKey) async {
      // Proceed with import
      final importService = ref.read(importServiceProvider);
      final result = await importService.importFromFile(dataKey: dataKey);
      
      // Handle result...
    },
    err: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wrong password: $error')),
      );
    },
  );
}

class _PasswordDialog extends StatefulWidget {
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Master Password'),
      content: TextField(
        controller: _controller,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: 'Master Password',
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Unlock'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 3. Import with Detailed Progress

```dart
class ImportProgressDialog extends ConsumerStatefulWidget {
  final List<int> dataKey;

  const ImportProgressDialog({
    Key? key,
    required this.dataKey,
  }) : super(key: key);

  @override
  ConsumerState<ImportProgressDialog> createState() =>
      _ImportProgressDialogState();
}

class _ImportProgressDialogState extends ConsumerState<ImportProgressDialog> {
  String _status = 'Reading file...';
  bool _isComplete = false;
  String? _error;
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
    _performImport();
  }

  Future<void> _performImport() async {
    final importService = ref.read(importServiceProvider);

    setState(() => _status = 'Reading file...');
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _status = 'Decrypting data...');
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _status = 'Parsing records...');
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _status = 'Importing to database...');
    
    final result = await importService.importFromFile(
      dataKey: widget.dataKey,
    );

    result.when(
      ok: (importResult) {
        setState(() {
          _status = 'Import complete!';
          _isComplete = true;
          _result = importResult;
        });
      },
      err: (error) {
        setState(() {
          _status = 'Import failed';
          _isComplete = true;
          _error = error;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importing Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isComplete) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Text(_status),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text(
              'Imported: ${_result!.totalImported}\n'
              'Skipped: ${_result!.totalSkipped}',
              textAlign: TextAlign.center,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

// Usage
Future<void> _showImportProgress(BuildContext context, List<int> dataKey) async {
  final result = await showDialog<ImportResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ImportProgressDialog(dataKey: dataKey),
  );

  if (result != null) {
    // Handle successful import
    print('Import complete: ${result.totalImported} records');
  }
}
```

### 4. Import with Confirmation

```dart
Future<void> _handleImportWithConfirmation(
  BuildContext context,
  WidgetRef ref,
) async {
  // Show warning dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import Data'),
      content: const Text(
        'Importing data will merge with your existing data. '
        'Newer versions will replace older ones.\n\n'
        'Do you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Import'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    return;
  }

  // Proceed with import
  final dataKey = ref.read(dataKeyProvider);
  if (dataKey == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please unlock vault first')),
    );
    return;
  }

  final importService = ref.read(importServiceProvider);
  final result = await importService.importFromFile(dataKey: dataKey);

  // Handle result...
}
```

### 5. Import from Specific File Path

```dart
Future<Result<ImportResult, String>> importFromPath({
  required String filePath,
  required List<int> dataKey,
  required WidgetRef ref,
}) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      return const Err('File does not exist');
    }

    final encryptedContent = await file.readAsString();

    final cryptoService = ref.read(cryptoServiceProvider);
    final decryptResult = await cryptoService.decryptString(
      cipherAll: encryptedContent,
      keyBytes: dataKey,
    );

    if (decryptResult.isErr) {
      return Err('Failed to decrypt: ${decryptResult.error}');
    }

    // Parse and import...
    final importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
    
    // Use import service to process the data
    final importService = ref.read(importServiceProvider);
    // ... continue with import logic
    
  } catch (e) {
    return Err('Import failed: $e');
  }
}
```

## Error Handling Examples

### 1. Handle All Error Cases

```dart
Future<void> _handleImportWithErrorHandling(
  BuildContext context,
  WidgetRef ref,
) async {
  final dataKey = ref.read(dataKeyProvider);
  
  if (dataKey == null) {
    _showError(context, 'Vault Not Unlocked', 
      'Please unlock your vault before importing data.');
    return;
  }

  final importService = ref.read(importServiceProvider);
  final result = await importService.importFromFile(dataKey: dataKey);

  result.when(
    ok: (importResult) {
      if (importResult.totalImported == 0) {
        _showWarning(context, 'No Data Imported',
          'All records were skipped because they are older than existing data.');
      } else {
        _showSuccess(context, 'Import Complete',
          'Successfully imported ${importResult.totalImported} records.');
      }
    },
    err: (error) {
      if (error.contains('No file selected')) {
        // User cancelled, no need to show error
        return;
      } else if (error.contains('decrypt')) {
        _showError(context, 'Decryption Failed',
          'The file could not be decrypted. Make sure you are using the correct master password.');
      } else if (error.contains('parse')) {
        _showError(context, 'Invalid File',
          'The selected file is not a valid export file.');
      } else {
        _showError(context, 'Import Failed', error);
      }
    },
  );
}

void _showError(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showWarning(BuildContext context, String title, String message) {
  // Similar to _showError but with warning styling
}

void _showSuccess(BuildContext context, String title, String message) {
  // Similar to _showError but with success styling
}
```

## Testing Examples

### 1. Unit Test for Import Service

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/import/import_service.dart';

void main() {
  group('ImportService', () {
    late ImportService importService;
    late MockNotesDao mockNotesDao;
    late MockVaultDao mockVaultDao;
    late MockCryptoService mockCryptoService;

    setUp(() {
      mockNotesDao = MockNotesDao();
      mockVaultDao = MockVaultDao();
      mockCryptoService = MockCryptoService();
      
      importService = ImportService(
        notesDao: mockNotesDao,
        vaultDao: mockVaultDao,
        cryptoService: mockCryptoService,
      );
    });

    test('imports notes successfully', () async {
      // Test implementation
    });

    test('resolves conflicts correctly', () async {
      // Test implementation
    });

    test('handles decryption failure', () async {
      // Test implementation
    });
  });
}
```

## Best Practices

1. **Always check vault unlock status** before importing
2. **Show progress indicators** for better UX
3. **Provide detailed error messages** to help users troubleshoot
4. **Confirm before importing** to prevent accidental data changes
5. **Display import statistics** so users know what happened
6. **Handle cancellation gracefully** when user cancels file selection
7. **Test with various file formats** to ensure robustness
