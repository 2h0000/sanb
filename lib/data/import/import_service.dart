import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/vault_item.dart';
import '../local/db/notes_dao.dart';
import '../local/db/vault_dao.dart';

/// Result of an import operation
class ImportResult {
  final int notesImported;
  final int vaultItemsImported;
  final int notesSkipped;
  final int vaultItemsSkipped;

  const ImportResult({
    required this.notesImported,
    required this.vaultItemsImported,
    required this.notesSkipped,
    required this.vaultItemsSkipped,
  });

  int get totalImported => notesImported + vaultItemsImported;
  int get totalSkipped => notesSkipped + vaultItemsSkipped;
}

/// Service for importing notes and vault data
class ImportService {
  final NotesDao _notesDao;
  final VaultDao _vaultDao;
  final CryptoService _cryptoService;

  ImportService({
    required NotesDao notesDao,
    required VaultDao vaultDao,
    required CryptoService cryptoService,
  })  : _notesDao = notesDao,
        _vaultDao = vaultDao,
        _cryptoService = cryptoService;

  /// Import data from an encrypted file
  /// 
  /// Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6
  /// 
  /// Returns the import result with counts or an error message
  Future<Result<ImportResult, String>> importFromFile({
    required List<int> dataKey,
  }) async {
    try {
      // Requirement 13.1: Read import file using file_picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['enc'],
        dialogTitle: 'Select Import File',
      );

      if (result == null || result.files.isEmpty) {
        return const Err('No file selected');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return const Err('Invalid file path');
      }

      // Read file content
      final file = File(filePath);
      if (!await file.exists()) {
        return const Err('File does not exist');
      }

      final encryptedContent = await file.readAsString();

      // Requirement 13.3: Decrypt file content using DataKey
      final decryptResult = await _cryptoService.decryptString(
        cipherAll: encryptedContent,
        keyBytes: dataKey,
      );

      if (decryptResult.isErr) {
        return Err('Failed to decrypt file: ${decryptResult.error}');
      }

      // Requirement 13.4: Parse JSON data
      final Map<String, dynamic> importData;
      try {
        importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
      } catch (e) {
        return Err('Failed to parse JSON: $e');
      }

      // Validate import data structure
      final type = importData['type'] as String?;
      if (type == null) {
        return const Err('Invalid import file: missing type field');
      }

      // Import based on type
      switch (type) {
        case 'notes':
          return await _importNotes(importData);
        case 'vault':
          return await _importVault(importData);
        case 'all':
          return await _importAll(importData);
        default:
          return Err('Unknown import type: $type');
      }
    } catch (e) {
      return Err('Import failed: $e');
    }
  }

  /// Import notes from parsed data
  Future<Result<ImportResult, String>> _importNotes(
    Map<String, dynamic> importData,
  ) async {
    try {
      final dataList = importData['data'] as List<dynamic>?;
      if (dataList == null) {
        return const Err('Invalid notes import: missing data field');
      }

      int imported = 0;
      int skipped = 0;

      for (final item in dataList) {
        final noteJson = item as Map<String, dynamic>;
        final note = Note.fromJson(noteJson);

        // Requirement 13.5: Resolve conflicts based on updatedAt
        final shouldImport = await _shouldImportNote(note);
        
        if (shouldImport) {
          await _insertOrUpdateNote(note);
          imported++;
        } else {
          skipped++;
        }
      }

      // Requirement 13.6: Return count of imported records
      return Ok(ImportResult(
        notesImported: imported,
        vaultItemsImported: 0,
        notesSkipped: skipped,
        vaultItemsSkipped: 0,
      ));
    } catch (e) {
      return Err('Failed to import notes: $e');
    }
  }

  /// Import vault items from parsed data
  Future<Result<ImportResult, String>> _importVault(
    Map<String, dynamic> importData,
  ) async {
    try {
      final dataList = importData['data'] as List<dynamic>?;
      if (dataList == null) {
        return const Err('Invalid vault import: missing data field');
      }

      int imported = 0;
      int skipped = 0;

      for (final item in dataList) {
        final vaultJson = item as Map<String, dynamic>;
        final vaultItem = VaultItemEncrypted.fromJson(vaultJson);

        // Requirement 13.5: Resolve conflicts based on updatedAt
        final shouldImport = await _shouldImportVaultItem(vaultItem);
        
        if (shouldImport) {
          await _insertOrUpdateVaultItem(vaultItem);
          imported++;
        } else {
          skipped++;
        }
      }

      // Requirement 13.6: Return count of imported records
      return Ok(ImportResult(
        notesImported: 0,
        vaultItemsImported: imported,
        notesSkipped: 0,
        vaultItemsSkipped: skipped,
      ));
    } catch (e) {
      return Err('Failed to import vault: $e');
    }
  }

  /// Import both notes and vault from parsed data
  Future<Result<ImportResult, String>> _importAll(
    Map<String, dynamic> importData,
  ) async {
    try {
      int notesImported = 0;
      int notesSkipped = 0;
      int vaultImported = 0;
      int vaultSkipped = 0;

      // Import notes
      final notesList = importData['notes'] as List<dynamic>?;
      if (notesList != null) {
        for (final item in notesList) {
          final noteJson = item as Map<String, dynamic>;
          final note = Note.fromJson(noteJson);

          final shouldImport = await _shouldImportNote(note);
          
          if (shouldImport) {
            await _insertOrUpdateNote(note);
            notesImported++;
          } else {
            notesSkipped++;
          }
        }
      }

      // Import vault items
      final vaultList = importData['vault'] as List<dynamic>?;
      if (vaultList != null) {
        for (final item in vaultList) {
          final vaultJson = item as Map<String, dynamic>;
          final vaultItem = VaultItemEncrypted.fromJson(vaultJson);

          final shouldImport = await _shouldImportVaultItem(vaultItem);
          
          if (shouldImport) {
            await _insertOrUpdateVaultItem(vaultItem);
            vaultImported++;
          } else {
            vaultSkipped++;
          }
        }
      }

      // Requirement 13.6: Return count of imported records
      return Ok(ImportResult(
        notesImported: notesImported,
        vaultItemsImported: vaultImported,
        notesSkipped: notesSkipped,
        vaultItemsSkipped: vaultSkipped,
      ));
    } catch (e) {
      return Err('Failed to import all data: $e');
    }
  }

  /// Check if a note should be imported based on conflict resolution
  /// 
  /// Requirement 13.5: Resolve conflicts based on updatedAt timestamp
  Future<bool> _shouldImportNote(Note note) async {
    final existing = await _notesDao.findByUuid(note.uuid);
    
    if (existing == null) {
      // No conflict, import the note
      return true;
    }

    // Compare updatedAt timestamps - keep the newer version
    return note.updatedAt.isAfter(existing.updatedAt);
  }

  /// Check if a vault item should be imported based on conflict resolution
  /// 
  /// Requirement 13.5: Resolve conflicts based on updatedAt timestamp
  Future<bool> _shouldImportVaultItem(VaultItemEncrypted vaultItem) async {
    final existing = await _vaultDao.findByUuid(vaultItem.uuid);
    
    if (existing == null) {
      // No conflict, import the item
      return true;
    }

    // Compare updatedAt timestamps - keep the newer version
    return vaultItem.updatedAt.isAfter(existing.updatedAt);
  }

  /// Insert or update a note in the database
  /// Uses upsertNoteWithTimestamps to preserve original timestamps
  Future<void> _insertOrUpdateNote(Note note) async {
    await _notesDao.upsertNoteWithTimestamps(
      uuid: note.uuid,
      title: note.title,
      contentMd: note.contentMd,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      deletedAt: note.deletedAt,
    );
  }

  /// Insert or update a vault item in the database
  /// Uses upsertVaultItemWithTimestamps to preserve original timestamps
  Future<void> _insertOrUpdateVaultItem(VaultItemEncrypted vaultItem) async {
    await _vaultDao.upsertVaultItemWithTimestamps(
      uuid: vaultItem.uuid,
      titleEnc: vaultItem.titleEnc,
      usernameEnc: vaultItem.usernameEnc,
      passwordEnc: vaultItem.passwordEnc,
      urlEnc: vaultItem.urlEnc,
      noteEnc: vaultItem.noteEnc,
      updatedAt: vaultItem.updatedAt,
      deletedAt: vaultItem.deletedAt,
    );
  }
}
