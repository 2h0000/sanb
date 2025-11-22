# Import Service Integration Checklist

## Prerequisites

Before integrating the import service, ensure the following are in place:

- [ ] Flutter project with Riverpod state management
- [ ] Drift database with Notes and VaultItems tables
- [ ] CryptoService for encryption/decryption
- [ ] KeyManager for master password and DataKey management
- [ ] file_picker package added to pubspec.yaml
- [ ] Export service implemented (for creating test files)

## Integration Steps

### 1. Add Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  drift: ^2.13.0
  file_picker: ^6.0.0
  cryptography: ^2.5.0
  path_provider: ^2.1.0
```

### 2. Import the Service

Add import statements to your feature files:

```dart
import 'package:encrypted_notebook/data/import/import_service.dart';
import 'package:encrypted_notebook/data/import/import_providers.dart';
```

### 3. Set Up Providers

The import service providers are already configured in `import_providers.dart`. You can use them directly:

```dart
// In your widget
final importService = ref.read(importServiceProvider);
```

### 4. Implement UI Integration

#### Settings Screen

Add an import option to your settings screen:

```dart
ListTile(
  leading: const Icon(Icons.file_download),
  title: const Text('Import Data'),
  subtitle: const Text('Restore from encrypted backup'),
  onTap: () => _handleImport(context, ref),
)
```

#### Import Handler

Implement the import handler:

```dart
Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
  // 1. Check if vault is unlocked
  final dataKey = ref.read(dataKeyProvider);
  if (dataKey == null) {
    // Show error: vault must be unlocked
    return;
  }

  // 2. Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // 3. Perform import
  final importService = ref.read(importServiceProvider);
  final result = await importService.importFromFile(dataKey: dataKey);

  // 4. Hide loading indicator
  Navigator.of(context).pop();

  // 5. Show result
  result.when(
    ok: (importResult) => _showImportSuccess(context, importResult),
    err: (error) => _showImportError(context, error),
  );
}
```

### 5. Handle Import Results

Implement result handlers:

```dart
void _showImportSuccess(BuildContext context, ImportResult result) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import Complete'),
      content: Text(
        'Successfully imported:\n'
        '• ${result.notesImported} notes\n'
        '• ${result.vaultItemsImported} vault items\n\n'
        'Skipped (older versions):\n'
        '• ${result.notesSkipped} notes\n'
        '• ${result.vaultItemsSkipped} vault items',
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

void _showImportError(BuildContext context, String error) {
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
}
```

### 6. Add Vault Unlock Check

Ensure users unlock vault before importing:

```dart
// In your vault unlock provider
final vaultUnlockedProvider = StateProvider<bool>((ref) => false);
final dataKeyProvider = StateProvider<List<int>?>((ref) => null);

// Check before import
if (!ref.read(vaultUnlockedProvider)) {
  // Navigate to vault unlock screen
  Navigator.of(context).pushNamed('/vault/unlock');
  return;
}
```

### 7. Test the Integration

Create test scenarios:

1. **Basic Import Test**
   - [ ] Export some data
   - [ ] Delete local data
   - [ ] Import the exported file
   - [ ] Verify data is restored

2. **Conflict Resolution Test**
   - [ ] Create a note with UUID "test-1"
   - [ ] Export data
   - [ ] Modify the note locally
   - [ ] Import the exported file
   - [ ] Verify newer version is kept

3. **Error Handling Test**
   - [ ] Try importing without unlocking vault
   - [ ] Try importing with wrong password
   - [ ] Try importing invalid file
   - [ ] Cancel file selection
   - [ ] Verify appropriate error messages

4. **Mixed Import Test**
   - [ ] Export both notes and vault items
   - [ ] Import the file
   - [ ] Verify both types are imported correctly

## Verification Checklist

After integration, verify the following:

### Functionality
- [ ] File picker opens when import is triggered
- [ ] .enc files are filtered in file picker
- [ ] File selection cancellation is handled gracefully
- [ ] Decryption works with correct DataKey
- [ ] Decryption fails with incorrect DataKey
- [ ] JSON parsing handles valid export files
- [ ] JSON parsing rejects invalid files
- [ ] Conflict resolution keeps newer records
- [ ] Import statistics are accurate
- [ ] Timestamps are preserved correctly

### User Experience
- [ ] Loading indicator shows during import
- [ ] Success message displays import statistics
- [ ] Error messages are clear and helpful
- [ ] User can cancel file selection
- [ ] Import doesn't block UI
- [ ] Large imports complete successfully

### Error Handling
- [ ] Vault unlock check works
- [ ] Decryption errors are caught
- [ ] JSON parsing errors are caught
- [ ] File read errors are caught
- [ ] Database errors are caught
- [ ] All errors show user-friendly messages

### Data Integrity
- [ ] Imported notes appear in notes list
- [ ] Imported vault items appear in vault list
- [ ] Timestamps match original export
- [ ] Tags are preserved
- [ ] Encrypted fields remain encrypted
- [ ] Deleted items are handled correctly
- [ ] No data corruption occurs

## Common Issues and Solutions

### Issue: "Vault Not Unlocked" Error

**Solution**: Ensure user unlocks vault before importing:

```dart
final dataKey = ref.read(dataKeyProvider);
if (dataKey == null) {
  // Show unlock prompt or navigate to unlock screen
}
```

### Issue: "Decryption Failed" Error

**Solution**: Verify the DataKey is correct:

```dart
// The DataKey used for import must match the one used for export
// If user changed master password, they need the old password
```

### Issue: Import Shows 0 Records Imported

**Solution**: Check if all records are older than existing data:

```dart
if (importResult.totalImported == 0 && importResult.totalSkipped > 0) {
  // All records were skipped due to being older
  // This is expected behavior with LWW conflict resolution
}
```

### Issue: File Picker Not Opening

**Solution**: Check platform permissions:

```dart
// Android: Add to AndroidManifest.xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

// iOS: Add to Info.plist
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to select import files</string>
```

## Performance Considerations

### Large Imports

For large import files (>1000 records):

1. **Show Progress**: Implement progress callbacks
2. **Batch Processing**: Process records in batches
3. **Background Processing**: Use isolates for heavy processing
4. **Memory Management**: Stream large files instead of loading entirely

Example:

```dart
// Future enhancement: batch processing
const batchSize = 100;
for (var i = 0; i < records.length; i += batchSize) {
  final batch = records.skip(i).take(batchSize);
  await _processBatch(batch);
  // Update progress: (i + batchSize) / records.length
}
```

## Security Considerations

1. **DataKey Protection**: Never log or display the DataKey
2. **File Cleanup**: Delete temporary files after import
3. **Error Messages**: Don't expose sensitive information in errors
4. **Validation**: Validate all imported data before insertion

## Next Steps

After successful integration:

1. [ ] Add import to user documentation
2. [ ] Create user guide with screenshots
3. [ ] Add analytics to track import usage
4. [ ] Monitor for import errors in production
5. [ ] Gather user feedback on import UX
6. [ ] Consider adding import preview feature
7. [ ] Consider adding selective import (choose what to import)

## Support

If you encounter issues during integration:

1. Check the README.md for detailed documentation
2. Review USAGE_EXAMPLE.md for code examples
3. Check IMPLEMENTATION_SUMMARY.md for technical details
4. Review the test files for working examples
5. Check diagnostics with `getDiagnostics` tool

## Maintenance

Regular maintenance tasks:

- [ ] Update import format version when schema changes
- [ ] Add migration logic for old export formats
- [ ] Monitor import success/failure rates
- [ ] Update documentation with new features
- [ ] Keep dependencies up to date
