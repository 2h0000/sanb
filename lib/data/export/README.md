# Export Service

## Overview

The Export Service provides functionality to export notes and vault data to encrypted files. All exports are encrypted using the user's DataKey to ensure data security.

## Features

### 1. Notes Export (Requirement 12.1)
- Exports all non-deleted notes to JSON format
- Includes title, content, tags, timestamps, and metadata
- Deleted notes (with `deletedAt` set) are excluded from export

### 2. Vault Export (Requirement 12.2)
- Exports all non-deleted vault items
- Vault items remain in their encrypted state (double encryption)
- Includes all encrypted fields: title, username, password, URL, and notes

### 3. Export File Encryption (Requirement 12.3)
- All export files are encrypted using AES-256-GCM
- Uses the user's DataKey for encryption
- Export file format: `nonce:cipher:mac` (Base64 encoded)

### 4. File Saving (Requirement 12.4)
- Supports two methods:
  - **Share**: Uses `share_plus` to let users share/save via system share sheet
  - **Save**: Uses `file_picker` to let users choose a specific save location
- Files are saved with `.enc` extension
- Filename includes timestamp for uniqueness

## Usage

### Basic Export

```dart
// Get the export service from Riverpod
final exportService = ref.read(exportServiceProvider);

// Get the user's DataKey (from vault unlock)
final dataKey = ref.read(dataKeyProvider);

// Export notes
final result = await exportService.exportNotes(
  dataKey: dataKey,
  shareFile: true, // Use share sheet
);

if (result.isOk) {
  print('Export saved to: ${result.value}');
} else {
  print('Export failed: ${result.error}');
}
```

### Export Vault

```dart
// Export vault items (already encrypted)
final result = await exportService.exportVault(
  dataKey: dataKey,
  shareFile: false, // Use file picker
);
```

### Export Everything

```dart
// Export both notes and vault in one file
final result = await exportService.exportAll(
  dataKey: dataKey,
  shareFile: true,
);
```

## Export File Format

### Notes Export Structure
```json
{
  "type": "notes",
  "version": 1,
  "exportedAt": "2024-01-01T12:00:00.000Z",
  "data": [
    {
      "uuid": "...",
      "title": "...",
      "contentMd": "...",
      "tags": ["tag1", "tag2"],
      "isEncrypted": false,
      "createdAt": "...",
      "updatedAt": "...",
      "deletedAt": null
    }
  ]
}
```

### Vault Export Structure
```json
{
  "type": "vault",
  "version": 1,
  "exportedAt": "2024-01-01T12:00:00.000Z",
  "data": [
    {
      "uuid": "...",
      "titleEnc": "nonce:cipher:mac",
      "usernameEnc": "nonce:cipher:mac",
      "passwordEnc": "nonce:cipher:mac",
      "urlEnc": "nonce:cipher:mac",
      "noteEnc": "nonce:cipher:mac",
      "updatedAt": "...",
      "deletedAt": null
    }
  ]
}
```

### Full Export Structure
```json
{
  "type": "all",
  "version": 1,
  "exportedAt": "2024-01-01T12:00:00.000Z",
  "notes": [...],
  "vault": [...]
}
```

## Security Considerations

1. **Double Encryption for Vault**: Vault items are already encrypted in the database. The export adds another layer of encryption using the DataKey.

2. **DataKey Required**: Users must have unlocked the vault (and have access to the DataKey) to perform exports.

3. **Encrypted File Format**: Export files use the same encryption format as individual fields (`nonce:cipher:mac`), ensuring consistency.

4. **No Plaintext Storage**: Export files never contain plaintext sensitive data. Even temporary files are encrypted.

## Error Handling

The service returns `Result<String, String>` types:
- **Ok(filePath)**: Export succeeded, contains path to saved file
- **Err(message)**: Export failed, contains error description

Common errors:
- Invalid DataKey (wrong length)
- Encryption failure
- File system errors
- User cancelled operation

## Testing

Unit tests are provided in `test/data/export/export_service_test.dart`:
- Tests export of notes (excluding deleted)
- Tests export of vault items (maintaining encryption)
- Tests full export
- Tests encryption/decryption round-trip
- Tests error handling with invalid keys

## Integration

The export service is provided via Riverpod:

```dart
final exportServiceProvider = Provider<ExportService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final vaultDao = ref.watch(vaultDaoProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  
  return ExportService(
    notesDao: notesDao,
    vaultDao: vaultDao,
    cryptoService: cryptoService,
  );
});
```

## Future Enhancements

- Progress callbacks for large exports
- Selective export (choose specific notes/items)
- Export format versioning for backward compatibility
- Compression before encryption
- Cloud backup integration
