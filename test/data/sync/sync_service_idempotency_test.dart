import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

// **Feature: encrypted-notebook-app, Property 15: 同步上行幂等性**
// **Validates: Requirements 6.2, 6.5**
// Property: For any note or vault item, serializing the same data to JSON
// multiple times should result in identical output. This ensures that
// sync operations are idempotent - pushing the same data multiple times
// will result in the same Firestore state without causing data corruption
// or duplication.

void main() {
  group('Property 15: Sync Uplink Idempotency', () {
    test('Serializing the same note multiple times produces identical JSON', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        // Create a fresh database for each iteration
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          // Generate random note data
          final uuid = const Uuid().v4();
          final title = _generateRandomString(Random().nextInt(50) + 1);
          final contentMd = _generateRandomString(Random().nextInt(200) + 1);
          final tags = _generateRandomTags();

          // Create the note in local database
          await testDao.createNote(
            uuid: uuid,
            title: title,
            contentMd: contentMd,
            tags: tags,
          );

          // Get the note from database
          final note = await testDao.findByUuid(uuid);
          expect(note, isNotNull,
              reason: 'Note should exist in database (iteration $i)');

          // Serialize the same note multiple times (2-5 times)
          final numSerializations = Random().nextInt(4) + 2;
          final serializedData = <Map<String, dynamic>>[];

          for (int j = 0; j < numSerializations; j++) {
            final json = note!.toJson();
            serializedData.add(json);
          }

          // Verify that all serializations are identical
          expect(serializedData.length, equals(numSerializations),
              reason: 'Should have $numSerializations serializations (iteration $i)');

          for (int j = 1; j < serializedData.length; j++) {
            expect(_mapsAreEqual(serializedData[0], serializedData[j]), isTrue,
                reason: 'Serialization $j should be identical to first (iteration $i)');
          }

          // Verify the serialized data matches the original note
          final firstSerialization = serializedData[0];
          expect(firstSerialization['uuid'], equals(uuid),
              reason: 'Serialized UUID should match (iteration $i)');
          expect(firstSerialization['title'], equals(title),
              reason: 'Serialized title should match (iteration $i)');
          expect(firstSerialization['contentMd'], equals(contentMd),
              reason: 'Serialized content should match (iteration $i)');
        } finally {
          await testDb.close();
        }
      }
    });

    test('Serializing soft-deleted note multiple times maintains deletedAt consistency', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          // Create a note
          final uuid = const Uuid().v4();
          await testDao.createNote(
            uuid: uuid,
            title: _generateRandomString(20),
            contentMd: _generateRandomString(100),
            tags: _generateRandomTags(),
          );

          // Soft delete the note
          await testDao.softDelete(uuid);

          // Get the deleted note
          final deletedNote = await testDao.findByUuid(uuid);
          expect(deletedNote, isNotNull,
              reason: 'Deleted note should still exist (iteration $i)');
          expect(deletedNote!.deletedAt, isNotNull,
              reason: 'deletedAt should be set (iteration $i)');

          // Serialize the deleted note multiple times
          final numSerializations = Random().nextInt(4) + 2;
          final serializedData = <Map<String, dynamic>>[];

          for (int j = 0; j < numSerializations; j++) {
            final json = deletedNote.toJson();
            serializedData.add(json);
          }

          // Verify all serializations have the same deletedAt timestamp
          expect(serializedData.length, equals(numSerializations),
              reason: 'Should have $numSerializations serializations (iteration $i)');

          final firstDeletedAt = serializedData[0]['deletedAt'];
          expect(firstDeletedAt, isNotNull,
              reason: 'First serialization should have deletedAt (iteration $i)');

          for (int j = 1; j < serializedData.length; j++) {
            expect(serializedData[j]['deletedAt'], equals(firstDeletedAt),
                reason: 'deletedAt should be consistent across serializations (iteration $i)');
            expect(_mapsAreEqual(serializedData[0], serializedData[j]), isTrue,
                reason: 'All serializations should be identical (iteration $i)');
          }
        } finally {
          await testDb.close();
        }
      }
    });

    test('Serializing vault item multiple times results in identical encrypted state', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testVaultDao = VaultDao(testDb);

        try {
          // Generate random vault item data (encrypted)
          final uuid = const Uuid().v4();
          final titleEnc = _generateRandomEncryptedString();
          final usernameEnc = _generateRandomEncryptedString();
          final passwordEnc = _generateRandomEncryptedString();
          final urlEnc = _generateRandomEncryptedString();
          final noteEnc = _generateRandomEncryptedString();

          // Create the vault item in local database
          await testVaultDao.createVaultItem(
            uuid: uuid,
            titleEnc: titleEnc,
            usernameEnc: usernameEnc,
            passwordEnc: passwordEnc,
            urlEnc: urlEnc,
            noteEnc: noteEnc,
          );

          // Get the vault item from database
          final vaultItem = await testVaultDao.findByUuid(uuid);
          expect(vaultItem, isNotNull,
              reason: 'Vault item should exist in database (iteration $i)');

          // Serialize the same vault item multiple times
          final numSerializations = Random().nextInt(4) + 2;
          final serializedData = <Map<String, dynamic>>[];

          for (int j = 0; j < numSerializations; j++) {
            final json = vaultItem!.toJson();
            serializedData.add(json);
          }

          // Verify that all serializations are identical
          expect(serializedData.length, equals(numSerializations),
              reason: 'Should have $numSerializations serializations (iteration $i)');

          for (int j = 1; j < serializedData.length; j++) {
            expect(_mapsAreEqual(serializedData[0], serializedData[j]), isTrue,
                reason: 'Serialization $j should be identical to first (iteration $i)');
          }

          // Verify the encrypted fields remain unchanged
          final firstSerialization = serializedData[0];
          expect(firstSerialization['uuid'], equals(uuid),
              reason: 'Serialized UUID should match (iteration $i)');
          expect(firstSerialization['titleEnc'], equals(titleEnc),
              reason: 'Serialized titleEnc should match (iteration $i)');
          expect(firstSerialization['passwordEnc'], equals(passwordEnc),
              reason: 'Serialized passwordEnc should match (iteration $i)');
        } finally {
          await testDb.close();
        }
      }
    });

    test('Serializing updated note maintains consistency after each update', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create initial note
          await testDao.createNote(
            uuid: uuid,
            title: 'Initial Title',
            contentMd: 'Initial Content',
            tags: ['tag1'],
          );

          var note = await testDao.findByUuid(uuid);
          expect(note, isNotNull);

          // Serialize initial state multiple times
          final initialSerializations = <Map<String, dynamic>>[];
          for (int j = 0; j < 3; j++) {
            initialSerializations.add(note!.toJson());
          }

          // Verify initial serializations are identical
          for (int j = 1; j < initialSerializations.length; j++) {
            expect(_mapsAreEqual(initialSerializations[0], initialSerializations[j]), isTrue,
                reason: 'Initial serializations should be identical (iteration $i)');
          }

          // Update the note
          await testDao.updateNote(
            uuid,
            title: 'Updated Title',
            contentMd: 'Updated Content',
            tags: ['tag1', 'tag2'],
          );

          note = await testDao.findByUuid(uuid);

          // Serialize updated state multiple times
          final numSerializations = Random().nextInt(3) + 2;
          final updatedSerializations = <Map<String, dynamic>>[];
          for (int j = 0; j < numSerializations; j++) {
            updatedSerializations.add(note!.toJson());
          }

          // Verify all updated serializations are identical
          for (int j = 1; j < updatedSerializations.length; j++) {
            expect(_mapsAreEqual(updatedSerializations[0], updatedSerializations[j]), isTrue,
                reason: 'Updated serializations should be identical (iteration $i)');
          }

          // Verify the updated state is different from initial
          expect(updatedSerializations[0]['title'], equals('Updated Title'),
              reason: 'Updated title should be serialized (iteration $i)');
          expect(updatedSerializations[0]['contentMd'], equals('Updated Content'),
              reason: 'Updated content should be serialized (iteration $i)');
          expect(updatedSerializations[0]['title'], isNot(equals(initialSerializations[0]['title'])),
              reason: 'Updated state should differ from initial (iteration $i)');
        } finally {
          await testDb.close();
        }
      }
    });

    test('Idempotency holds for notes with empty fields', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create note with empty fields
          await testDao.createNote(
            uuid: uuid,
            title: '',
            contentMd: '',
            tags: [],
          );

          final note = await testDao.findByUuid(uuid);
          expect(note, isNotNull);

          // Serialize multiple times
          final numSerializations = Random().nextInt(4) + 2;
          final serializedData = <Map<String, dynamic>>[];
          for (int j = 0; j < numSerializations; j++) {
            serializedData.add(note!.toJson());
          }

          // Verify idempotency
          expect(serializedData.length, equals(numSerializations));
          for (int j = 1; j < serializedData.length; j++) {
            expect(_mapsAreEqual(serializedData[0], serializedData[j]), isTrue,
                reason: 'Empty field serializations should be identical (iteration $i)');
          }
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

// Helper function to generate random encrypted string (simulating encrypted data)
String _generateRandomEncryptedString() {
  final random = Random();
  final nonce = _generateRandomBase64(16);
  final cipher = _generateRandomBase64(random.nextInt(100) + 20);
  final mac = _generateRandomBase64(16);
  return '$nonce:$cipher:$mac';
}

// Helper function to generate random base64-like string
String _generateRandomBase64(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  final random = Random();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

// Helper function to compare two maps for equality
bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) return false;
  
  for (final key in map1.keys) {
    if (!map2.containsKey(key)) return false;
    
    final value1 = map1[key];
    final value2 = map2[key];
    
    // Handle different types
    if (value1 is Map && value2 is Map) {
      if (!_mapsAreEqual(value1 as Map<String, dynamic>, value2 as Map<String, dynamic>)) {
        return false;
      }
    } else if (value1 is List && value2 is List) {
      if (value1.length != value2.length) return false;
      for (int i = 0; i < value1.length; i++) {
        if (value1[i] != value2[i]) return false;
      }
    } else if (value1 != value2) {
      return false;
    }
  }
  
  return true;
}
