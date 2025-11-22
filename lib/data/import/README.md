# Import Service

## Overview

The Import Service provides functionality to import encrypted notes and vault data from previously exported files. It handles file reading, decryption, JSON parsing, conflict resolution, and batch insertion into the local database.

## Features

- **File Selection**: Uses `file_picker` to let users select encrypted export files (.enc)
- **Decryption**: Decrypts file content using the user's DataKey
- **JSON Parsing**: Parses and validates the import data structure
- **Conflict Resolution**: Resolves conflicts based on `updatedAt` timestamps (Last Write Wins)
- **Batch Import**: Efficiently imports multiple records
- **Import Statistics**: Returns counts of imported and skipped records

## Requirements Implemented

- **13.1**: Import file reading using `file_picker`
- **13.2**: Import file decryption (prompts for master password via DataKey)
- **13.3**: Decrypt file content using DataKey
- **13.4**: JSON parsing and batch insertion to local database
- **13.5**: Import conflict resolution based on updatedAt
- **13.6**: Return import success record count

## Usage

### Basic Import

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/import/import_providers.dart';

// In your widget or controller
final importService = ref.read(importServiceProvider);

// Import data (user will be prompted to select a file)
final result = await importService.importFromFile(
  dataKey: dataKey, // 32-byte DataKey from unlocked vault
);

result.when(
  ok: (importResult) {
    print('Notes imported: ${importResult.notesImported}');
    print('Vault items imported: ${importResult.vaultItemsImported}');
    print('Notes skipped: ${importResult.notesSkipped}');
    print('Vault items skipped: ${importResult.vaultItemsSkipped}');
    print('Total imported: ${importResult.totalImported}');
  },
  err: (error) {
    print('Import failed: $error');
  },
);
```

## Import File Format

The import service supports three types of export files:

### 1. Notes Only Export

```json
{
  "type": "notes",
  "version": 1,
  "exportedAt": "2024-01-01T00:00:00.000Z",
  "data": [
    {
      "uuid": "...",
      "title": "...",
      "contentMd": "...",
      "tags": ["tag1", "tag2"],
      "isEncrypted": false,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "deletedAt": null
    }
  ]
}
```

### 2. Vault Only Export

```json
{
  "type": "vault",
  "version": 1,
  "exportedAt": "2024-01-01T00:00:00.000Z",
  "data": [
    {
      "uuid": "...",
      "titleEnc": "nonce:cipher:mac",
      "usernameEnc": "nonce:cipher:mac",
      "passwordEnc": "nonce:cipher:mac",
      "urlEnc": "nonce:cipher:mac",
      "noteEnc": "nonce:cipher:mac",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "deletedAt": null
    }
  ]
}
```

### 3. Full Export (Both Notes and Vault)

```json
{
  "type": "all",
  "version": 1,
  "exportedAt": "2024-01-01T00:00:00.000Z",
  "notes": [...],
  "vault": [...]
}
```

## Conflict Resolution

When importing data, conflicts may occur if a record with the same UUID already exists in the local database. The import service resolves conflicts using the **Last Write Wins (LWW)** strategy:

1. Compare the `updatedAt` timestamp of the imported record with the existing record
2. If the imported record is newer, it replaces the existing record
3. If the existing record is newer, the imported record is skipped
4. The import result includes counts of both imported and skipped records

## Timestamp Preservation

The import service preserves the original timestamps from the export file:

- **Notes**: Both `createdAt` and `updatedAt` are preserved
- **Vault Items**: `updatedAt` is preserved
- **Deleted Items**: `deletedAt` is preserved if present

This ensures that the imported data maintains its original chronology and sync state.

## Error Handling

The import service returns a `Result<ImportResult, String>` type:

- **Success**: Returns `Ok(ImportResult)` with import statistics
- **Failure**: Returns `Err(String)` with error message

Common error scenarios:

- No file selected by user
- Invalid file path
- File does not exist
- Decryption failure (wrong DataKey)
- Invalid JSON format
- Missing required fields in import data
- Unknown import type

## Integration with Riverpod

The import service is provided through Riverpod providers:

```dart
// Import service provider
final importServiceProvider = Provider<ImportService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final vaultDao = ref.watch(vaultDaoProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);
  
  return ImportService(
    notesDao: notesDao,
    vaultDao: vaultDao,
    cryptoService: cryptoService,
  );
});
```

## Testing

The import service can be tested by:

1. Creating test export files with known data
2. Importing the files and verifying the import results
3. Testing conflict resolution with existing data
4. Testing error handling with invalid files

See `test/data/import/import_service_test.dart` for examples.

## Future Enhancements

Potential improvements for the import service:

- Progress callbacks for large imports
- Validation of import data before insertion
- Option to merge instead of replace on conflicts
- Import preview before committing changes
- Rollback capability if import fails partway through
- Support for incremental imports
- Import from cloud storage URLs
