import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

// **Feature: encrypted-notebook-app, Property 21: 导出包含所有未删除记录**
// **Validates: Requirements 12.1, 12.2**
// Property: For any database state with a mix of deleted and non-deleted
// notes and vault items, exporting should include exactly all non-deleted
// records and exclude all deleted records. This ensures that exports
// accurately represent the current active data set.
//
// Note: This test verifies the export logic by directly testing the DAO
// methods and serialization, avoiding file system operations that require
// platform plugins not available in unit tests.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 21: Export Contains All Non-Deleted Records', () {
    test('Notes DAO getAllNotes returns only non-deleted notes', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key
          final dataKey = await cryptoService.generateKey();

          // Generate random number of notes (5-20)
          final random = Random();
          final totalNotes = random.nextInt(16) + 5;
          
          // Randomly decide how many to delete (0 to totalNotes-1)
          final numToDelete = random.nextInt(totalNotes);
          
          final createdUuids = <String>[];
          final deletedUuids = <String>{};

          // Create notes
          for (int j = 0; j < totalNotes; j++) {
            final uuid = const Uuid().v4();
            createdUuids.add(uuid);
            
            await testDao.createNote(
              uuid: uuid,
              title: _generateRandomString(random.nextInt(30) + 5),
              contentMd: _generateRandomString(random.nextInt(200) + 10),
              tags: _generateRandomTags(),
            );
          }

          // Randomly select notes to delete
          final shuffled = List<String>.from(createdUuids)..shuffle(random);
          for (int j = 0; j < numToDelete; j++) {
            final uuidToDelete = shuffled[j];
            await testDao.softDelete(uuidToDelete);
            deletedUuids.add(uuidToDelete);
          }

          // Calculate expected non-deleted count
          final expectedNonDeletedCount = totalNotes - numToDelete;

          // Get all notes (this is what export uses - Requirement 12.1)
          final allNotesInDb = await testDao.getAllNotes();
          
          // Property verification: getAllNotes returns exactly non-deleted count
          expect(allNotesInDb.length, equals(expectedNonDeletedCount),
              reason: 'getAllNotes should return $expectedNonDeletedCount non-deleted notes (iteration $i)');

          // Serialize to JSON (this is what export does - Requirement 12.1)
          final notesJson = allNotesInDb.map((note) => note.toJson()).toList();
          
          // Verify serialized count matches
          expect(notesJson.length, equals(expectedNonDeletedCount),
              reason: 'Serialized notes should have $expectedNonDeletedCount items (iteration $i)');

          // Verify no deleted notes are in the result
          final returnedUuids = allNotesInDb.map((note) => note.uuid).toSet();

          for (final deletedUuid in deletedUuids) {
            expect(returnedUuids.contains(deletedUuid), isFalse,
                reason: 'Deleted note $deletedUuid should not be in getAllNotes result (iteration $i)');
          }

          // Verify all non-deleted notes are in the result
          for (final uuid in createdUuids) {
            if (!deletedUuids.contains(uuid)) {
              expect(returnedUuids.contains(uuid), isTrue,
                  reason: 'Non-deleted note $uuid should be in getAllNotes result (iteration $i)');
            }
          }

          // Verify all returned notes have null deletedAt
          for (final note in allNotesInDb) {
            expect(note.deletedAt, isNull,
                reason: 'All returned notes should have null deletedAt (iteration $i)');
          }

          // Encrypt the export data (simulating Requirement 12.3)
          final exportData = {
            'type': 'notes',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'data': notesJson,
          };
          
          final jsonString = jsonEncode(exportData);
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Verify we can decrypt and get the same data back
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');
          
          final decryptedData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          final decryptedNotes = decryptedData['data'] as List<dynamic>;
          
          expect(decryptedNotes.length, equals(expectedNonDeletedCount),
              reason: 'Decrypted export should have $expectedNonDeletedCount notes (iteration $i)');

        } finally {
          await testDb.close();
        }
      }
    });

    test('Vault DAO getAllVaultItems returns only non-deleted items', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testVaultDao = VaultDao(testDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key
          final dataKey = await cryptoService.generateKey();

          // Generate random number of vault items (5-20)
          final random = Random();
          final totalItems = random.nextInt(16) + 5;
          
          // Randomly decide how many to delete (0 to totalItems-1)
          final numToDelete = random.nextInt(totalItems);
          
          final createdUuids = <String>[];
          final deletedUuids = <String>{};

          // Create vault items
          for (int j = 0; j < totalItems; j++) {
            final uuid = const Uuid().v4();
            createdUuids.add(uuid);
            
            // Create encrypted fields
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
            
            await testVaultDao.createVaultItem(
              uuid: uuid,
              titleEnc: titleEnc.value,
              usernameEnc: usernameEnc,
              passwordEnc: passwordEnc,
              urlEnc: urlEnc,
              noteEnc: noteEnc,
            );
          }

          // Randomly select items to delete
          final shuffled = List<String>.from(createdUuids)..shuffle(random);
          for (int j = 0; j < numToDelete; j++) {
            final uuidToDelete = shuffled[j];
            await testVaultDao.softDelete(uuidToDelete);
            deletedUuids.add(uuidToDelete);
          }

          // Calculate expected non-deleted count
          final expectedNonDeletedCount = totalItems - numToDelete;

          // Get all vault items (this is what export uses - Requirement 12.2)
          final allItemsInDb = await testVaultDao.getAllVaultItems();
          
          // Property verification: getAllVaultItems returns exactly non-deleted count
          expect(allItemsInDb.length, equals(expectedNonDeletedCount),
              reason: 'getAllVaultItems should return $expectedNonDeletedCount non-deleted items (iteration $i)');

          // Serialize to JSON keeping encrypted state (this is what export does - Requirement 12.2)
          final vaultJson = allItemsInDb.map((item) => item.toJson()).toList();
          
          // Verify serialized count matches
          expect(vaultJson.length, equals(expectedNonDeletedCount),
              reason: 'Serialized vault items should have $expectedNonDeletedCount items (iteration $i)');

          // Verify no deleted items are in the result
          final returnedUuids = allItemsInDb.map((item) => item.uuid).toSet();

          for (final deletedUuid in deletedUuids) {
            expect(returnedUuids.contains(deletedUuid), isFalse,
                reason: 'Deleted vault item $deletedUuid should not be in getAllVaultItems result (iteration $i)');
          }

          // Verify all non-deleted items are in the result
          for (final uuid in createdUuids) {
            if (!deletedUuids.contains(uuid)) {
              expect(returnedUuids.contains(uuid), isTrue,
                  reason: 'Non-deleted vault item $uuid should be in getAllVaultItems result (iteration $i)');
            }
          }

          // Verify all returned items have null deletedAt
          for (final item in allItemsInDb) {
            expect(item.deletedAt, isNull,
                reason: 'All returned vault items should have null deletedAt (iteration $i)');
          }

          // Verify items remain encrypted in serialized form
          for (final itemJson in vaultJson) {
            final titleEnc = itemJson['titleEnc'] as String;
            expect(titleEnc.contains(':'), isTrue,
                reason: 'Vault items should remain encrypted in export (iteration $i)');
          }

          // Encrypt the export data (simulating Requirement 12.3)
          final exportData = {
            'type': 'vault',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'data': vaultJson,
          };
          
          final jsonString = jsonEncode(exportData);
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Verify we can decrypt and get the same data back
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');
          
          final decryptedData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          final decryptedItems = decryptedData['data'] as List<dynamic>;
          
          expect(decryptedItems.length, equals(expectedNonDeletedCount),
              reason: 'Decrypted export should have $expectedNonDeletedCount vault items (iteration $i)');

        } finally {
          await testDb.close();
        }
      }
    });

    test('Combined export includes all non-deleted notes and vault items', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testNotesDao = NotesDao(testDb);
        final testVaultDao = VaultDao(testDb);
        final cryptoService = CryptoService();

        try {
          // Generate a test data key
          final dataKey = await cryptoService.generateKey();
          final random = Random();

          // Create notes
          final totalNotes = random.nextInt(11) + 5; // 5-15 notes
          final numNotesToDelete = random.nextInt(totalNotes);
          final noteUuids = <String>[];
          final deletedNoteUuids = <String>{};

          for (int j = 0; j < totalNotes; j++) {
            final uuid = const Uuid().v4();
            noteUuids.add(uuid);
            
            await testNotesDao.createNote(
              uuid: uuid,
              title: _generateRandomString(random.nextInt(20) + 5),
              contentMd: _generateRandomString(random.nextInt(100) + 10),
              tags: _generateRandomTags(),
            );
          }

          // Delete some notes
          final shuffledNotes = List<String>.from(noteUuids)..shuffle(random);
          for (int j = 0; j < numNotesToDelete; j++) {
            await testNotesDao.softDelete(shuffledNotes[j]);
            deletedNoteUuids.add(shuffledNotes[j]);
          }

          // Create vault items
          final totalVaultItems = random.nextInt(11) + 5; // 5-15 items
          final numVaultToDelete = random.nextInt(totalVaultItems);
          final vaultUuids = <String>[];
          final deletedVaultUuids = <String>{};

          for (int j = 0; j < totalVaultItems; j++) {
            final uuid = const Uuid().v4();
            vaultUuids.add(uuid);
            
            final titleEnc = await cryptoService.encryptString(
              plaintext: _generateRandomString(random.nextInt(15) + 5),
              keyBytes: dataKey,
            );
            
            await testVaultDao.createVaultItem(
              uuid: uuid,
              titleEnc: titleEnc.value,
            );
          }

          // Delete some vault items
          final shuffledVault = List<String>.from(vaultUuids)..shuffle(random);
          for (int j = 0; j < numVaultToDelete; j++) {
            await testVaultDao.softDelete(shuffledVault[j]);
            deletedVaultUuids.add(shuffledVault[j]);
          }

          // Calculate expected counts
          final expectedNotesCount = totalNotes - numNotesToDelete;
          final expectedVaultCount = totalVaultItems - numVaultToDelete;

          // Get all notes and vault items (this is what exportAll uses)
          final allNotes = await testNotesDao.getAllNotes();
          final allVaultItems = await testVaultDao.getAllVaultItems();

          // Property verification: DAO methods return exactly non-deleted counts
          expect(allNotes.length, equals(expectedNotesCount),
              reason: 'getAllNotes should return $expectedNotesCount non-deleted notes (iteration $i)');
          expect(allVaultItems.length, equals(expectedVaultCount),
              reason: 'getAllVaultItems should return $expectedVaultCount non-deleted items (iteration $i)');

          // Serialize both (this is what exportAll does)
          final notesJson = allNotes.map((note) => note.toJson()).toList();
          final vaultJson = allVaultItems.map((item) => item.toJson()).toList();

          // Verify no deleted notes in result
          final returnedNoteUuids = allNotes.map((note) => note.uuid).toSet();
          
          for (final deletedUuid in deletedNoteUuids) {
            expect(returnedNoteUuids.contains(deletedUuid), isFalse,
                reason: 'Deleted note should not be in getAllNotes result (iteration $i)');
          }

          // Verify all non-deleted notes in result
          for (final uuid in noteUuids) {
            if (!deletedNoteUuids.contains(uuid)) {
              expect(returnedNoteUuids.contains(uuid), isTrue,
                  reason: 'Non-deleted note should be in getAllNotes result (iteration $i)');
            }
          }

          // Verify no deleted vault items in result
          final returnedVaultUuids = allVaultItems.map((item) => item.uuid).toSet();
          
          for (final deletedUuid in deletedVaultUuids) {
            expect(returnedVaultUuids.contains(deletedUuid), isFalse,
                reason: 'Deleted vault item should not be in getAllVaultItems result (iteration $i)');
          }

          // Verify all non-deleted vault items in result
          for (final uuid in vaultUuids) {
            if (!deletedVaultUuids.contains(uuid)) {
              expect(returnedVaultUuids.contains(uuid), isTrue,
                  reason: 'Non-deleted vault item should be in getAllVaultItems result (iteration $i)');
            }
          }

          // Encrypt the combined export data (simulating exportAll)
          final exportData = {
            'type': 'all',
            'version': 1,
            'exportedAt': DateTime.now().toIso8601String(),
            'notes': notesJson,
            'vault': vaultJson,
          };
          
          final jsonString = jsonEncode(exportData);
          final encryptResult = await cryptoService.encryptString(
            plaintext: jsonString,
            keyBytes: dataKey,
          );
          
          expect(encryptResult.isOk, isTrue,
              reason: 'Encryption should succeed (iteration $i)');

          // Verify we can decrypt and get the same data back
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: dataKey,
          );
          
          expect(decryptResult.isOk, isTrue,
              reason: 'Decryption should succeed (iteration $i)');
          
          final decryptedData = jsonDecode(decryptResult.value) as Map<String, dynamic>;
          final decryptedNotes = decryptedData['notes'] as List<dynamic>;
          final decryptedVault = decryptedData['vault'] as List<dynamic>;
          
          expect(decryptedNotes.length, equals(expectedNotesCount),
              reason: 'Decrypted export should have $expectedNotesCount notes (iteration $i)');
          expect(decryptedVault.length, equals(expectedVaultCount),
              reason: 'Decrypted export should have $expectedVaultCount vault items (iteration $i)');

        } finally {
          await testDb.close();
        }
      }
    });

    test('DAO methods return empty arrays when all records are deleted', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testNotesDao = NotesDao(testDb);
        final testVaultDao = VaultDao(testDb);
        final cryptoService = CryptoService();

        try {
          final dataKey = await cryptoService.generateKey();
          final random = Random();

          // Create and delete all notes
          final numNotes = random.nextInt(6) + 3; // 3-8 notes
          for (int j = 0; j < numNotes; j++) {
            final uuid = const Uuid().v4();
            await testNotesDao.createNote(
              uuid: uuid,
              title: _generateRandomString(10),
              contentMd: _generateRandomString(50),
            );
            await testNotesDao.softDelete(uuid);
          }

          // Create and delete all vault items
          final numVault = random.nextInt(6) + 3; // 3-8 items
          for (int j = 0; j < numVault; j++) {
            final uuid = const Uuid().v4();
            final titleEnc = await cryptoService.encryptString(
              plaintext: _generateRandomString(10),
              keyBytes: dataKey,
            );
            await testVaultDao.createVaultItem(
              uuid: uuid,
              titleEnc: titleEnc.value,
            );
            await testVaultDao.softDelete(uuid);
          }

          // Get all (should be empty)
          final allNotes = await testNotesDao.getAllNotes();
          final allVaultItems = await testVaultDao.getAllVaultItems();

          // Property verification: empty results when all deleted
          expect(allNotes.length, equals(0),
              reason: 'getAllNotes should return 0 notes when all deleted (iteration $i)');
          expect(allVaultItems.length, equals(0),
              reason: 'getAllVaultItems should return 0 items when all deleted (iteration $i)');

          // Verify export would be empty
          final notesJson = allNotes.map((note) => note.toJson()).toList();
          final vaultJson = allVaultItems.map((item) => item.toJson()).toList();
          
          expect(notesJson.length, equals(0),
              reason: 'Serialized notes should be empty when all deleted (iteration $i)');
          expect(vaultJson.length, equals(0),
              reason: 'Serialized vault items should be empty when all deleted (iteration $i)');

        } finally {
          await testDb.close();
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
