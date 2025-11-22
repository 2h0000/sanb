import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/vault_item.dart';
import '../local/db/notes_dao.dart';
import '../local/db/vault_dao.dart';

/// Service for exporting notes and vault data
class ExportService {
  final NotesDao _notesDao;
  final VaultDao _vaultDao;
  final CryptoService _cryptoService;

  ExportService({
    required NotesDao notesDao,
    required VaultDao vaultDao,
    required CryptoService cryptoService,
  })  : _notesDao = notesDao,
        _vaultDao = vaultDao,
        _cryptoService = cryptoService;

  /// Export notes to an encrypted JSON file
  /// 
  /// Requirements: 12.1, 12.2, 12.3, 12.4
  /// 
  /// Returns the path to the exported file or an error message
  Future<Result<String, String>> exportNotes({
    required List<int> dataKey,
    bool shareFile = true,
  }) async {
    try {
      // Get all non-deleted notes (Requirement 12.1)
      final notes = await _notesDao.getAllNotes();
      
      // Serialize to JSON (Requirement 12.1)
      final notesJson = notes.map((note) => note.toJson()).toList();
      final exportData = {
        'type': 'notes',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': notesJson,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Encrypt the entire export file using DataKey (Requirement 12.3)
      final encryptResult = await _cryptoService.encryptString(
        plaintext: jsonString,
        keyBytes: dataKey,
      );
      
      if (encryptResult.isErr) {
        return Err('Failed to encrypt export data: ${encryptResult.error}');
      }
      
      // Save to file (Requirement 12.4)
      final filePath = await _saveToFile(
        content: encryptResult.value,
        fileName: 'notes_export_${DateTime.now().millisecondsSinceEpoch}.enc',
        shareFile: shareFile,
      );
      
      return filePath;
    } catch (e) {
      return Err('Export failed: $e');
    }
  }

  /// Export vault items to an encrypted JSON file
  /// 
  /// Requirements: 12.2, 12.3, 12.4
  /// 
  /// Returns the path to the exported file or an error message
  Future<Result<String, String>> exportVault({
    required List<int> dataKey,
    bool shareFile = true,
  }) async {
    try {
      // Get all non-deleted vault items (Requirement 12.2)
      // Items are already encrypted in the database
      final vaultItems = await _vaultDao.getAllVaultItems();
      
      // Serialize to JSON, keeping encrypted state (Requirement 12.2)
      final vaultJson = vaultItems.map((item) => item.toJson()).toList();
      final exportData = {
        'type': 'vault',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': vaultJson,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Encrypt the entire export file using DataKey (Requirement 12.3)
      final encryptResult = await _cryptoService.encryptString(
        plaintext: jsonString,
        keyBytes: dataKey,
      );
      
      if (encryptResult.isErr) {
        return Err('Failed to encrypt export data: ${encryptResult.error}');
      }
      
      // Save to file (Requirement 12.4)
      final filePath = await _saveToFile(
        content: encryptResult.value,
        fileName: 'vault_export_${DateTime.now().millisecondsSinceEpoch}.enc',
        shareFile: shareFile,
      );
      
      return filePath;
    } catch (e) {
      return Err('Export failed: $e');
    }
  }

  /// Export both notes and vault to a single encrypted file
  /// 
  /// Requirements: 12.1, 12.2, 12.3, 12.4
  /// 
  /// Returns the path to the exported file or an error message
  Future<Result<String, String>> exportAll({
    required List<int> dataKey,
    bool shareFile = true,
  }) async {
    try {
      // Get all non-deleted notes and vault items
      final notes = await _notesDao.getAllNotes();
      final vaultItems = await _vaultDao.getAllVaultItems();
      
      // Serialize to JSON
      final notesJson = notes.map((note) => note.toJson()).toList();
      final vaultJson = vaultItems.map((item) => item.toJson()).toList();
      
      final exportData = {
        'type': 'all',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'notes': notesJson,
        'vault': vaultJson,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Encrypt the entire export file using DataKey
      final encryptResult = await _cryptoService.encryptString(
        plaintext: jsonString,
        keyBytes: dataKey,
      );
      
      if (encryptResult.isErr) {
        return Err('Failed to encrypt export data: ${encryptResult.error}');
      }
      
      // Save to file
      final filePath = await _saveToFile(
        content: encryptResult.value,
        fileName: 'full_export_${DateTime.now().millisecondsSinceEpoch}.enc',
        shareFile: shareFile,
      );
      
      return filePath;
    } catch (e) {
      return Err('Export failed: $e');
    }
  }

  /// Save encrypted content to a file and optionally share it
  /// 
  /// Requirement 12.4: Integration with share_plus or file_picker
  Future<Result<String, String>> _saveToFile({
    required String content,
    required String fileName,
    required bool shareFile,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Write encrypted content to file
      final file = File(filePath);
      await file.writeAsString(content);
      
      if (shareFile) {
        // Use share_plus to let user choose where to save
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Encrypted Notebook Export',
        );
        
        if (result.status == ShareResultStatus.success) {
          return Ok(filePath);
        } else {
          return Err('User cancelled share operation');
        }
      } else {
        // For testing or when not sharing, just return the temp file path
        return Ok(filePath);
      }
    } catch (e) {
      return Err('Failed to save file: $e');
    }
  }
}
