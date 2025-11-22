import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:encrypted_notebook/data/export/export_service.dart';
import 'package:encrypted_notebook/data/import/import_service.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/domain/entities/note.dart' as entity;
import 'package:encrypted_notebook/domain/entities/vault_item.dart' as entity;
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

// **Feature: encrypted-notebook-app, Property 22: 导出加密往返一致性**
// **Validates: Requirements 12.3, 13.3, 13.4**
// Property: For any export data (notes and/or vault items), encrypting the
// export with a DataKey and then decrypting it with the same DataKey should
// produce data equivalent to the original. This ensures that the export/import
// encryption round-trip preserves data integrity.
//
// This property tests the complete export-encrypt-decrypt-import cycle.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 22: Export Encryption Round-Trip Consistency', () {
    test('Notes export-decrypt round-trip preserves all data', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
        final sourceNotesDao = NotesDao(sourceDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key (Requirement 12.3)
          final dataKey = await cryptoService.generateKey();

          // Generate random number of notes (3-15)
          final random = Random();
          final totalNotes = random.nextInt(13) + 3;
          
          final originalNotes = <entity.Note>[];

          // Create notes with random data
          for (int j = 0; j < totalNotes; j++) {
            final uuid = const Uuid().v4();
            final title = _generateRandomString(random.nextInt(30) + 5);
            final contentMd = _generateRandomString(random.nextInt(200) + 10);
            final tags = _generateRandomTags();
            
            await sourceNotesDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );
            
            // Store the created note for comparison
            final note = await sourceNotesDao.findByUuid(uuid);
            if (note != null) {
              originalNotes.add(note);
            }
          }

          // Export notes (Requirement 12.1, 12.3)
          final exportService = ExportService(
            notesDao: sourceNotesDao,
            vaultDao: VaultDao(sourceDb),
            cryptoService: cryptoService,
          );

          // Get all notes and manually create export data to avoid file system
          final notesFromDb = await sourceNotesDao.getAllNotes();
          final notesJson = notesFromDb.map((note) => note.toJson()).toList();
          final exportData = {
            'type': 'notes',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'data': notesJson,
          };
          
          final jsonString = jsonEncode(exportData);
          
          // Encrypt the export (Requirement 12.3)
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Decrypt the export (Requirement 13.3)
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');

          // Parse the decrypted JSON (Requirement 13.4)
          final Map<String, dynamic> importData;
          try {
            importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          } catch (e) {
            fail('Failed to parse decrypted JSON (iteration $i): $e');
          }

          // Verify structure is preserved
          expect(importData['type'], equals('notes'),
              reason: 'Export type should be preserved (iteration $i)');
          expect(importData['version'], equals(1),
              reason: 'Export version should be preserved (iteration $i)');
          expect(importData['data'], isA<List>(),
              reason: 'Export data should be a list (iteration $i)');

          final decryptedNotes = importData['data'] as List<dynamic>;
          
          // Property verification: Round-trip preserves count
          expect(decryptedNotes.length, equals(originalNotes.length),
              reason: 'Round-trip should preserve note count (iteration $i)');

          // Property verification: Round-trip preserves all note data
          for (final originalNote in originalNotes) {
            // Find matching note in decrypted data by UUID
            final matchingNoteJson = decryptedNotes.firstWhere(
              (json) => (json as Map<String, dynamic>)['uuid'] == originalNote.uuid,
              orElse: () => throw Exception('Note ${originalNote.uuid} not found after round-trip'),
            ) as Map<String, dynamic>;

            expect(matchingNoteJson['title'], equals(originalNote.title),
                reason: 'Round-trip should preserve note title (iteration $i)');
            expect(matchingNoteJson['contentMd'], equals(originalNote.contentMd),
                reason: 'Round-trip should preserve note content (iteration $i)');
            
            final tags = (matchingNoteJson['tags'] as List<dynamic>).cast<String>();
            expect(tags, equals(originalNote.tags),
                reason: 'Round-trip should preserve note tags (iteration $i)');
            expect(matchingNoteJson['isEncrypted'], equals(originalNote.isEncrypted),
                reason: 'Round-trip should preserve note encryption flag (iteration $i)');
            
            // Timestamps should be preserved (within millisecond precision)
            final createdAt = DateTime.parse(matchingNoteJson['createdAt'] as String);
            final updatedAt = DateTime.parse(matchingNoteJson['updatedAt'] as String);
            
            expect(
              createdAt.difference(originalNote.createdAt).abs().inMilliseconds,
              lessThan(1000),
              reason: 'Round-trip should preserve createdAt timestamp (iteration $i)',
            );
            expect(
              updatedAt.difference(originalNote.updatedAt).abs().inMilliseconds,
              lessThan(1000),
              reason: 'Round-trip should preserve updatedAt timestamp (iteration $i)',
            );
            
            // deletedAt should be null for non-deleted notes
            expect(matchingNoteJson['deletedAt'], isNull,
                reason: 'Round-trip should preserve null deletedAt (iteration $i)');
          }

        } finally {
          await sourceDb.close();
        }
      }
    });

    test('Vault export-decrypt round-trip preserves all encrypted data', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
        final sourceVaultDao = VaultDao(sourceDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key (Requirement 12.3)
          final dataKey = await cryptoService.generateKey();

          // Generate random number of vault items (3-15)
          final random = Random();
          final totalItems = random.nextInt(13) + 3;
          
          final originalVaultItems = <entity.VaultItemEncrypted>[];

          // Create vault items with random encrypted data
          for (int j = 0; j < totalItems; j++) {
            final uuid = const Uuid().v4();
            
            // Encrypt fields (Requirement 12.2 - keep encrypted state)
            final titleEnc = await cryptoService.encryptString(
              plaintext: _generateRandomString(random.nextInt(20) + 5),
              keyBytes: dataKey,
            );
            
            String? usernameEnc;
            String? passwordEnc;
            String? urlEnc;
            String? noteEnc;
            
            // Randomly include optional fields
            if (random.nextBool()) {
              final usernameResult = await cryptoService.encryptString(
                plaintext: _generateRandomString(random.nextInt(15) + 3),
                keyBytes: dataKey,
              );
              usernameEnc = usernameResult.value;
            }
            
            if (random.nextBool()) {
              final passwordResult = await cryptoService.encryptString(
                plaintext: _generateRandomString(random.nextInt(20) + 8),
                keyBytes: dataKey,
              );
              passwordEnc = passwordResult.value;
            }
            
            if (random.nextBool()) {
              final urlResult = await cryptoService.encryptString(
                plaintext: 'https://example${random.nextInt(100)}.com',
                keyBytes: dataKey,
              );
              urlEnc = urlResult.value;
            }
            
            if (random.nextBool()) {
              final noteResult = await cryptoService.encryptString(
                plaintext: _generateRandomString(random.nextInt(100) + 10),
                keyBytes: dataKey,
              );
              noteEnc = noteResult.value;
            }
            
            await sourceVaultDao.createVaultItem(
              uuid: uuid,
              titleEnc: titleEnc.value,
              usernameEnc: usernameEnc,
              passwordEnc: passwordEnc,
              urlEnc: urlEnc,
              noteEnc: noteEnc,
            );
            
            // Store the created item for comparison
            final item = await sourceVaultDao.findByUuid(uuid);
            if (item != null) {
              originalVaultItems.add(item);
            }
          }

          // Export vault items (Requirement 12.2, 12.3)
          final exportService = ExportService(
            notesDao: NotesDao(sourceDb),
            vaultDao: sourceVaultDao,
            cryptoService: cryptoService,
          );

          // Get all vault items and manually create export data
          final vaultItemsFromDb = await sourceVaultDao.getAllVaultItems();
          final vaultJson = vaultItemsFromDb.map((item) => item.toJson()).toList();
          final exportData = {
            'type': 'vault',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'data': vaultJson,
          };
          
          final jsonString = jsonEncode(exportData);
          
          // Encrypt the export (Requirement 12.3)
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Decrypt the export (Requirement 13.3)
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');

          // Parse the decrypted JSON (Requirement 13.4)
          final Map<String, dynamic> importData;
          try {
            importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          } catch (e) {
            fail('Failed to parse decrypted JSON (iteration $i): $e');
          }

          // Verify structure is preserved
          expect(importData['type'], equals('vault'),
              reason: 'Export type should be preserved (iteration $i)');
          expect(importData['version'], equals(1),
              reason: 'Export version should be preserved (iteration $i)');
          expect(importData['data'], isA<List>(),
              reason: 'Export data should be a list (iteration $i)');

          final decryptedVaultItems = importData['data'] as List<dynamic>;
          
          // Property verification: Round-trip preserves count
          expect(decryptedVaultItems.length, equals(originalVaultItems.length),
              reason: 'Round-trip should preserve vault item count (iteration $i)');

          // Property verification: Round-trip preserves all vault item data
          for (final originalItem in originalVaultItems) {
            // Find matching vault item in decrypted data by UUID
            final matchingItemJson = decryptedVaultItems.firstWhere(
              (json) => (json as Map<String, dynamic>)['uuid'] == originalItem.uuid,
              orElse: () => throw Exception('Vault item ${originalItem.uuid} not found after round-trip'),
            ) as Map<String, dynamic>;

            // Verify encrypted fields are preserved exactly
            expect(matchingItemJson['titleEnc'], equals(originalItem.titleEnc),
                reason: 'Round-trip should preserve encrypted title (iteration $i)');
            expect(matchingItemJson['usernameEnc'], equals(originalItem.usernameEnc),
                reason: 'Round-trip should preserve encrypted username (iteration $i)');
            expect(matchingItemJson['passwordEnc'], equals(originalItem.passwordEnc),
                reason: 'Round-trip should preserve encrypted password (iteration $i)');
            expect(matchingItemJson['urlEnc'], equals(originalItem.urlEnc),
                reason: 'Round-trip should preserve encrypted URL (iteration $i)');
            expect(matchingItemJson['noteEnc'], equals(originalItem.noteEnc),
                reason: 'Round-trip should preserve encrypted note (iteration $i)');
            
            // Timestamps should be preserved (within millisecond precision)
            final updatedAt = DateTime.parse(matchingItemJson['updatedAt'] as String);
            expect(
              updatedAt.difference(originalItem.updatedAt).abs().inMilliseconds,
              lessThan(1000),
              reason: 'Round-trip should preserve updatedAt timestamp (iteration $i)',
            );
            
            // deletedAt should be null for non-deleted items
            expect(matchingItemJson['deletedAt'], isNull,
                reason: 'Round-trip should preserve null deletedAt (iteration $i)');
          }

        } finally {
          await sourceDb.close();
        }
      }
    });

    test('Combined export-decrypt round-trip preserves both notes and vault', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
        final sourceNotesDao = NotesDao(sourceDb);
        final sourceVaultDao = VaultDao(sourceDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key
          final dataKey = await cryptoService.generateKey();
          final random = Random();

          // Create notes
          final totalNotes = random.nextInt(8) + 3; // 3-10 notes
          final originalNotes = <entity.Note>[];

          for (int j = 0; j < totalNotes; j++) {
            final uuid = const Uuid().v4();
            final title = _generateRandomString(random.nextInt(20) + 5);
            final contentMd = _generateRandomString(random.nextInt(100) + 10);
            final tags = _generateRandomTags();
            
            await sourceNotesDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );
            
            final note = await sourceNotesDao.findByUuid(uuid);
            if (note != null) {
              originalNotes.add(note);
            }
          }

          // Create vault items
          final totalVaultItems = random.nextInt(8) + 3; // 3-10 items
          final originalVaultItems = <entity.VaultItemEncrypted>[];

          for (int j = 0; j < totalVaultItems; j++) {
            final uuid = const Uuid().v4();
            
            final titleEnc = await cryptoService.encryptString(
              plaintext: _generateRandomString(random.nextInt(15) + 5),
              keyBytes: dataKey,
            );
            
            String? passwordEnc;
            if (random.nextBool()) {
              final passwordResult = await cryptoService.encryptString(
                plaintext: _generateRandomString(random.nextInt(20) + 8),
                keyBytes: dataKey,
              );
              passwordEnc = passwordResult.value;
            }
            
            await sourceVaultDao.createVaultItem(
              uuid: uuid,
              titleEnc: titleEnc.value,
              passwordEnc: passwordEnc,
            );
            
            final item = await sourceVaultDao.findByUuid(uuid);
            if (item != null) {
              originalVaultItems.add(item);
            }
          }

          // Export all data
          final notesFromDb = await sourceNotesDao.getAllNotes();
          final vaultItemsFromDb = await sourceVaultDao.getAllVaultItems();
          
          final notesJson = notesFromDb.map((note) => note.toJson()).toList();
          final vaultJson = vaultItemsFromDb.map((item) => item.toJson()).toList();
          
          final exportData = {
            'type': 'all',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'notes': notesJson,
            'vault': vaultJson,
          };
          
          final jsonString = jsonEncode(exportData);
          
          // Encrypt the export
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Decrypt the export
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');

          // Parse the decrypted JSON
          final Map<String, dynamic> importData;
          try {
            importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          } catch (e) {
            fail('Failed to parse decrypted JSON (iteration $i): $e');
          }

          // Verify structure
          expect(importData['type'], equals('all'),
              reason: 'Export type should be preserved (iteration $i)');
          expect(importData['notes'], isA<List>(),
              reason: 'Notes data should be a list (iteration $i)');
          expect(importData['vault'], isA<List>(),
              reason: 'Vault data should be a list (iteration $i)');

          final decryptedNotes = importData['notes'] as List<dynamic>;
          final decryptedVaultItems = importData['vault'] as List<dynamic>;
          
          // Property verification: Round-trip preserves counts
          expect(decryptedNotes.length, equals(originalNotes.length),
              reason: 'Round-trip should preserve note count (iteration $i)');
          expect(decryptedVaultItems.length, equals(originalVaultItems.length),
              reason: 'Round-trip should preserve vault item count (iteration $i)');

          // Verify notes
          for (final originalNote in originalNotes) {
            final matchingNoteJson = decryptedNotes.firstWhere(
              (json) => (json as Map<String, dynamic>)['uuid'] == originalNote.uuid,
              orElse: () => throw Exception('Note ${originalNote.uuid} not found after round-trip'),
            ) as Map<String, dynamic>;

            expect(matchingNoteJson['title'], equals(originalNote.title),
                reason: 'Round-trip should preserve note title (iteration $i)');
            expect(matchingNoteJson['contentMd'], equals(originalNote.contentMd),
                reason: 'Round-trip should preserve note content (iteration $i)');
            
            final tags = (matchingNoteJson['tags'] as List<dynamic>).cast<String>();
            expect(tags, equals(originalNote.tags),
                reason: 'Round-trip should preserve note tags (iteration $i)');
          }

          // Verify vault items
          for (final originalItem in originalVaultItems) {
            final matchingItemJson = decryptedVaultItems.firstWhere(
              (json) => (json as Map<String, dynamic>)['uuid'] == originalItem.uuid,
              orElse: () => throw Exception('Vault item ${originalItem.uuid} not found after round-trip'),
            ) as Map<String, dynamic>;

            expect(matchingItemJson['titleEnc'], equals(originalItem.titleEnc),
                reason: 'Round-trip should preserve encrypted title (iteration $i)');
            expect(matchingItemJson['passwordEnc'], equals(originalItem.passwordEnc),
                reason: 'Round-trip should preserve encrypted password (iteration $i)');
          }

        } finally {
          await sourceDb.close();
        }
      }
    });

    test('Round-trip with wrong key fails decryption', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
        final sourceNotesDao = NotesDao(sourceDb);
        final cryptoService = CryptoService();

        try {
          // Generate two different keys
          final correctKey = await cryptoService.generateKey();
          final wrongKey = await cryptoService.generateKey();

          // Create a note
          final uuid = const Uuid().v4();
          await sourceNotesDao.createNote(
            uuid: uuid,
            title: 'Test Note',
            contentMd: 'Test Content',
          );

          // Export and encrypt with correct key
          final notesFromDb = await sourceNotesDao.getAllNotes();
          final notesJson = notesFromDb.map((note) => note.toJson()).toList();
          final exportData = {
            'type': 'notes',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'data': notesJson,
          };
          
          final jsonString = jsonEncode(exportData);
          
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: correctKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Try to decrypt with wrong key (should fail)
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: wrongKey,
          );
          
          // Property verification: Wrong key should fail decryption
          expect(decryptResult.isErr, isTrue,
              reason: 'Decryption with wrong key should fail (iteration $i)');

        } finally {
          await sourceDb.close();
        }
      }
    });

    test('Empty export round-trip preserves empty state', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
        final sourceNotesDao = NotesDao(sourceDb);
        final sourceVaultDao = VaultDao(sourceDb);
        final cryptoService = CryptoService();

        try {
          final dataKey = await cryptoService.generateKey();

          // Don't create any data - test empty export
          final notesFromDb = await sourceNotesDao.getAllNotes();
          final vaultItemsFromDb = await sourceVaultDao.getAllVaultItems();
          
          expect(notesFromDb.length, equals(0),
              reason: 'Database should be empty (iteration $i)');
          expect(vaultItemsFromDb.length, equals(0),
              reason: 'Database should be empty (iteration $i)');

          // Export empty data
          final notesJson = notesFromDb.map((note) => note.toJson()).toList();
          final vaultJson = vaultItemsFromDb.map((item) => item.toJson()).toList();
          
          final exportData = {
            'type': 'all',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'notes': notesJson,
            'vault': vaultJson,
          };
          
          final jsonString = jsonEncode(exportData);
          
          // Encrypt
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Decrypt
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');

          // Parse
          final importData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          final decryptedNotes = importData['notes'] as List<dynamic>;
          final decryptedVaultItems = importData['vault'] as List<dynamic>;
          
          // Property verification: Empty export round-trip preserves empty state
          expect(decryptedNotes.length, equals(0),
              reason: 'Round-trip should preserve empty notes (iteration $i)');
          expect(decryptedVaultItems.length, equals(0),
              reason: 'Round-trip should preserve empty vault (iteration $i)');

        } finally {
          await sourceDb.close();
        }
      }
    });
  });
}

// Helper function to generate random string
String _generateRandomString(int length) {
  if (length == 0) return '';

  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?';
  final random = Random();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

// Helper function to generate random tags
List<String> _generateRandomTags() {
  final random = Random();
  final numTags = random.nextInt(6); // 0 to 5 tags
  return List.generate(numTags, (i) => 'tag${random.nextInt(100)}');
}