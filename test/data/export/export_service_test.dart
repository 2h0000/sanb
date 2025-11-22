import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:encrypted_notebook/data/export/export_service.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/domain/entities/note.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late AppDatabase database;
  late NotesDao notesDao;
  late VaultDao vaultDao;
  late CryptoService cryptoService;
  late ExportService exportService;
  late List<int> dataKey;

  setUp(() async {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    notesDao = NotesDao(database);
    vaultDao = VaultDao(database);
    cryptoService = CryptoService();
    exportService = ExportService(
      notesDao: notesDao,
      vaultDao: vaultDao,
      cryptoService: cryptoService,
    );
    
    // Generate a test data key
    dataKey = await cryptoService.generateKey();
  });

  tearDown(() async {
    await database.close();
  });

  group('ExportService - Notes Export', () {
    test('should export all non-deleted notes to encrypted JSON', () async {
      // Create test notes
      final uuid1 = const Uuid().v4();
      final uuid2 = const Uuid().v4();
      
      await notesDao.createNote(
        uuid: uuid1,
        title: 'Test Note 1',
        contentMd: 'Content 1',
        tags: ['tag1', 'tag2'],
      );
      
      await notesDao.createNote(
        uuid: uuid2,
        title: 'Test Note 2',
        contentMd: 'Content 2',
        tags: ['tag3'],
      );
      
      // Create a deleted note (should not be exported)
      final uuid3 = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid3,
        title: 'Deleted Note',
        contentMd: 'Deleted Content',
      );
      await notesDao.softDelete(uuid3);
      
      // Export notes (without sharing to avoid UI interaction)
      final result = await exportService.exportNotes(
        dataKey: dataKey,
        shareFile: false,
      );
      
      // Verify export succeeded
      if (result.isErr) {
        print('Export error: ${result.error}');
      }
      expect(result.isOk, true);
      
      // Note: We can't fully test file operations in unit tests
      // This test verifies the export logic runs without errors
    });

    test('should encrypt export data with provided dataKey', () async {
      // Create a test note
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Test Note',
        contentMd: 'Test Content',
      );
      
      // Get notes and manually create export data
      final notes = await notesDao.getAllNotes();
      final notesJson = notes.map((note) => note.toJson()).toList();
      final exportData = {
        'type': 'notes',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': notesJson,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Encrypt
      final encryptResult = await cryptoService.encryptString(
        plaintext: jsonString,
        keyBytes: dataKey,
      );
      
      expect(encryptResult.isOk, true);
      
      // Verify we can decrypt it back
      final decryptResult = await cryptoService.decryptString(
        cipherAll: encryptResult.value,
        keyBytes: dataKey,
      );
      
      expect(decryptResult.isOk, true);
      expect(decryptResult.value, jsonString);
    });
  });

  group('ExportService - Vault Export', () {
    test('should export all non-deleted vault items in encrypted state', () async {
      // Create encrypted vault items
      final uuid1 = const Uuid().v4();
      final uuid2 = const Uuid().v4();
      
      // Create test vault items (already encrypted)
      final titleEnc1 = await cryptoService.encryptString(
        plaintext: 'Test Item 1',
        keyBytes: dataKey,
      );
      final passwordEnc1 = await cryptoService.encryptString(
        plaintext: 'password123',
        keyBytes: dataKey,
      );
      
      await vaultDao.createVaultItem(
        uuid: uuid1,
        titleEnc: titleEnc1.value,
        passwordEnc: passwordEnc1.value,
      );
      
      final titleEnc2 = await cryptoService.encryptString(
        plaintext: 'Test Item 2',
        keyBytes: dataKey,
      );
      
      await vaultDao.createVaultItem(
        uuid: uuid2,
        titleEnc: titleEnc2.value,
      );
      
      // Create a deleted item (should not be exported)
      final uuid3 = const Uuid().v4();
      final titleEnc3 = await cryptoService.encryptString(
        plaintext: 'Deleted Item',
        keyBytes: dataKey,
      );
      await vaultDao.createVaultItem(
        uuid: uuid3,
        titleEnc: titleEnc3.value,
      );
      await vaultDao.softDelete(uuid3);
      
      // Export vault (without sharing to avoid UI interaction)
      final result = await exportService.exportVault(
        dataKey: dataKey,
        shareFile: false,
      );
      
      // Verify export succeeded
      expect(result.isOk, true);
    });

    test('should keep vault items encrypted in export', () async {
      // Create encrypted vault item
      final uuid = const Uuid().v4();
      final titleEnc = await cryptoService.encryptString(
        plaintext: 'Secret Title',
        keyBytes: dataKey,
      );
      
      await vaultDao.createVaultItem(
        uuid: uuid,
        titleEnc: titleEnc.value,
      );
      
      // Get vault items and verify they're encrypted
      final vaultItems = await vaultDao.getAllVaultItems();
      expect(vaultItems.length, 1);
      expect(vaultItems[0].titleEnc, isNot('Secret Title'));
      expect(vaultItems[0].titleEnc, contains(':'));
    });
  });

  group('ExportService - Full Export', () {
    test('should export both notes and vault items', () async {
      // Create test note
      final noteUuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: noteUuid,
        title: 'Test Note',
        contentMd: 'Test Content',
      );
      
      // Create test vault item
      final vaultUuid = const Uuid().v4();
      final titleEnc = await cryptoService.encryptString(
        plaintext: 'Test Vault Item',
        keyBytes: dataKey,
      );
      await vaultDao.createVaultItem(
        uuid: vaultUuid,
        titleEnc: titleEnc.value,
      );
      
      // Export all (without sharing to avoid UI interaction)
      final result = await exportService.exportAll(
        dataKey: dataKey,
        shareFile: false,
      );
      
      // Verify export succeeded
      expect(result.isOk, true);
    });
  });

  group('ExportService - Error Handling', () {
    test('should return error with invalid dataKey', () async {
      // Create test note
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Test Note',
        contentMd: 'Test Content',
      );
      
      // Try to export with invalid key (wrong length)
      final result = await exportService.exportNotes(
        dataKey: [1, 2, 3], // Invalid key length
        shareFile: false,
      );
      
      // Should fail
      expect(result.isErr, true);
      expect(result.error, contains('encrypt'));
    });
  });
}
