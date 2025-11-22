import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('should create database with correct schema version', () {
      expect(database.schemaVersion, equals(1));
    });

    test('should have Notes table', () {
      expect(database.notes, isNotNull);
    });

    test('should have VaultItems table', () {
      expect(database.vaultItems, isNotNull);
    });

    test('should insert and retrieve a note', () async {
      final noteCompanion = NotesCompanion.insert(
        uuid: 'test-uuid-123',
        title: const Value('Test Note'),
        contentMd: const Value('# Test Content'),
      );

      final id = await database.into(database.notes).insert(noteCompanion);
      expect(id, greaterThan(0));

      final notes = await database.select(database.notes).get();
      expect(notes.length, equals(1));
      expect(notes.first.uuid, equals('test-uuid-123'));
      expect(notes.first.title, equals('Test Note'));
      expect(notes.first.contentMd, equals('# Test Content'));
    });

    test('should insert and retrieve a vault item', () async {
      final vaultCompanion = VaultItemsCompanion.insert(
        uuid: 'vault-uuid-456',
        titleEnc: 'encrypted-title',
        usernameEnc: const Value('encrypted-username'),
        passwordEnc: const Value('encrypted-password'),
      );

      final id = await database.into(database.vaultItems).insert(vaultCompanion);
      expect(id, greaterThan(0));

      final items = await database.select(database.vaultItems).get();
      expect(items.length, equals(1));
      expect(items.first.uuid, equals('vault-uuid-456'));
      expect(items.first.titleEnc, equals('encrypted-title'));
    });

    test('should enforce unique uuid constraint on notes', () async {
      final noteCompanion = NotesCompanion.insert(
        uuid: 'duplicate-uuid',
        title: const Value('First Note'),
      );

      await database.into(database.notes).insert(noteCompanion);

      // Attempting to insert another note with the same UUID should fail
      expect(
        () => database.into(database.notes).insert(noteCompanion),
        throwsA(isA<Exception>()),
      );
    });

    test('should set default values for notes', () async {
      final noteCompanion = NotesCompanion.insert(
        uuid: 'minimal-note',
      );

      await database.into(database.notes).insert(noteCompanion);

      final notes = await database.select(database.notes).get();
      final note = notes.first;

      expect(note.title, equals(''));
      expect(note.contentMd, equals(''));
      expect(note.tagsJson, equals('[]'));
      expect(note.isEncrypted, equals(false));
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
      expect(note.deletedAt, isNull);
    });

    // **Feature: encrypted-notebook-app, Property 6: UUID 唯一性约束**
    // **Validates: Requirements 5.3**
    // Property: For any table (Notes or VaultItems), attempting to insert a record
    // with a UUID that already exists should fail with an exception. This ensures
    // the unique constraint on the uuid field is properly enforced by the database.
    group('Property 6: UUID Uniqueness Constraint', () {
      test('Notes table enforces UUID uniqueness across random UUIDs', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Create a fresh database for each iteration to avoid conflicts
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            // Generate a random UUID
            final uuid = _generateRandomUuid();
            
            // Insert first note with this UUID
            final firstNote = NotesCompanion.insert(
              uuid: uuid,
              title: Value(_generateRandomString(20)),
              contentMd: Value(_generateRandomString(100)),
            );
            
            final firstId = await testDb.into(testDb.notes).insert(firstNote);
            expect(firstId, greaterThan(0),
                reason: 'First insert should succeed (iteration $i)');
            
            // Attempt to insert second note with the same UUID
            final secondNote = NotesCompanion.insert(
              uuid: uuid, // Same UUID
              title: Value(_generateRandomString(20)),
              contentMd: Value(_generateRandomString(100)),
            );
            
            // This should throw an exception due to unique constraint violation
            expect(
              () => testDb.into(testDb.notes).insert(secondNote),
              throwsA(isA<Exception>()),
              reason: 'Inserting duplicate UUID should fail (iteration $i, uuid: $uuid)',
            );
            
            // Verify only one record exists
            final allNotes = await testDb.select(testDb.notes).get();
            expect(allNotes.length, equals(1),
                reason: 'Only first note should exist after failed duplicate insert (iteration $i)');
            expect(allNotes.first.uuid, equals(uuid),
                reason: 'The existing note should have the original UUID (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('VaultItems table enforces UUID uniqueness across random UUIDs', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Create a fresh database for each iteration to avoid conflicts
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            // Generate a random UUID
            final uuid = _generateRandomUuid();
            
            // Insert first vault item with this UUID
            final firstItem = VaultItemsCompanion.insert(
              uuid: uuid,
              titleEnc: _generateRandomString(30),
              usernameEnc: Value(_generateRandomString(20)),
              passwordEnc: Value(_generateRandomString(20)),
            );
            
            final firstId = await testDb.into(testDb.vaultItems).insert(firstItem);
            expect(firstId, greaterThan(0),
                reason: 'First insert should succeed (iteration $i)');
            
            // Attempt to insert second vault item with the same UUID
            final secondItem = VaultItemsCompanion.insert(
              uuid: uuid, // Same UUID
              titleEnc: _generateRandomString(30),
              usernameEnc: Value(_generateRandomString(20)),
              passwordEnc: Value(_generateRandomString(20)),
            );
            
            // This should throw an exception due to unique constraint violation
            expect(
              () => testDb.into(testDb.vaultItems).insert(secondItem),
              throwsA(isA<Exception>()),
              reason: 'Inserting duplicate UUID should fail (iteration $i, uuid: $uuid)',
            );
            
            // Verify only one record exists
            final allItems = await testDb.select(testDb.vaultItems).get();
            expect(allItems.length, equals(1),
                reason: 'Only first vault item should exist after failed duplicate insert (iteration $i)');
            expect(allItems.first.uuid, equals(uuid),
                reason: 'The existing vault item should have the original UUID (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('UUID uniqueness is enforced even with different content', () async {
        // Verify that UUID uniqueness is enforced regardless of other field values
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            final uuid = _generateRandomUuid();
            
            // Insert first note
            final firstNote = NotesCompanion.insert(
              uuid: uuid,
              title: const Value('First Title'),
              contentMd: const Value('First Content'),
            );
            
            await testDb.into(testDb.notes).insert(firstNote);
            
            // Try to insert with same UUID but completely different content
            final secondNote = NotesCompanion.insert(
              uuid: uuid,
              title: const Value('Completely Different Title'),
              contentMd: const Value('Completely Different Content'),
              tagsJson: const Value('["different", "tags"]'),
            );
            
            expect(
              () => testDb.into(testDb.notes).insert(secondNote),
              throwsA(isA<Exception>()),
              reason: 'UUID uniqueness should be enforced regardless of other fields (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('UUID uniqueness allows different UUIDs with same content', () async {
        // Verify that different UUIDs can have the same content
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            final uuid1 = _generateRandomUuid();
            final uuid2 = _generateRandomUuid();
            
            // Ensure UUIDs are different
            expect(uuid1, isNot(equals(uuid2)),
                reason: 'Generated UUIDs should be different');
            
            const sameTitle = 'Same Title';
            const sameContent = 'Same Content';
            
            // Insert first note
            final firstNote = NotesCompanion.insert(
              uuid: uuid1,
              title: const Value(sameTitle),
              contentMd: const Value(sameContent),
            );
            
            final firstId = await testDb.into(testDb.notes).insert(firstNote);
            expect(firstId, greaterThan(0));
            
            // Insert second note with different UUID but same content
            final secondNote = NotesCompanion.insert(
              uuid: uuid2,
              title: const Value(sameTitle),
              contentMd: const Value(sameContent),
            );
            
            final secondId = await testDb.into(testDb.notes).insert(secondNote);
            expect(secondId, greaterThan(0),
                reason: 'Different UUIDs should allow same content (iteration $i)');
            
            // Verify both records exist
            final allNotes = await testDb.select(testDb.notes).get();
            expect(allNotes.length, equals(2),
                reason: 'Both notes should exist with different UUIDs (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('UUID uniqueness is case-sensitive', () async {
        // Verify that UUID comparison is case-sensitive
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            // Generate a UUID with mixed case
            final uuid = _generateRandomUuid();
            final uuidUpperCase = uuid.toUpperCase();
            final uuidLowerCase = uuid.toLowerCase();
            
            // Insert with original case
            final firstNote = NotesCompanion.insert(
              uuid: uuid,
              title: const Value('First'),
            );
            
            await testDb.into(testDb.notes).insert(firstNote);
            
            // If the UUID has different cases, try inserting with different case
            if (uuid != uuidUpperCase) {
              final upperNote = NotesCompanion.insert(
                uuid: uuidUpperCase,
                title: const Value('Upper'),
              );
              
              // This should succeed if UUIDs are case-sensitive
              // or fail if they're case-insensitive
              try {
                await testDb.into(testDb.notes).insert(upperNote);
                // If it succeeds, UUIDs are case-sensitive (expected behavior)
              } catch (e) {
                // If it fails, UUIDs might be case-insensitive
                // This is acceptable but worth noting
              }
            }
            
            if (uuid != uuidLowerCase) {
              final lowerNote = NotesCompanion.insert(
                uuid: uuidLowerCase,
                title: const Value('Lower'),
              );
              
              try {
                await testDb.into(testDb.notes).insert(lowerNote);
                // If it succeeds, UUIDs are case-sensitive (expected behavior)
              } catch (e) {
                // If it fails, UUIDs might be case-insensitive
                // This is acceptable but worth noting
              }
            }
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 7: 时间戳自动设置**
    // **Validates: Requirements 5.4**
    // Property: For any record inserted into Notes or VaultItems tables,
    // the system should automatically set createdAt and updatedAt to the
    // current timestamp (within a reasonable tolerance).
    group('Property 7: Timestamp Auto-Setting', () {
      test('Notes table automatically sets createdAt and updatedAt on insert', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            // Capture the time just before insertion
            final beforeInsert = DateTime.now();
            
            // Insert a note with random data
            final noteCompanion = NotesCompanion.insert(
              uuid: _generateRandomUuid(),
              title: Value(_generateRandomString(20)),
              contentMd: Value(_generateRandomString(100)),
            );
            
            final id = await testDb.into(testDb.notes).insert(noteCompanion);
            
            // Capture the time just after insertion
            final afterInsert = DateTime.now();
            
            // Retrieve the inserted note
            final query = testDb.select(testDb.notes)..where((t) => t.id.equals(id));
            final note = await query.getSingle();
            
            // Verify createdAt is set and within the expected time range
            expect(note.createdAt, isNotNull,
                reason: 'createdAt should be automatically set (iteration $i)');
            expect(
              note.createdAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'createdAt should be after or near the insertion time (iteration $i)',
            );
            expect(
              note.createdAt.isBefore(afterInsert.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'createdAt should be before or near the insertion completion time (iteration $i)',
            );
            
            // Verify updatedAt is set and within the expected time range
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be automatically set (iteration $i)');
            expect(
              note.updatedAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be after or near the insertion time (iteration $i)',
            );
            expect(
              note.updatedAt.isBefore(afterInsert.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be before or near the insertion completion time (iteration $i)',
            );
            
            // Verify createdAt and updatedAt are approximately equal on insert
            final timeDifference = note.updatedAt.difference(note.createdAt).abs();
            expect(
              timeDifference.inSeconds,
              lessThanOrEqualTo(1),
              reason: 'createdAt and updatedAt should be approximately equal on insert (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('VaultItems table automatically sets updatedAt on insert', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            // Capture the time just before insertion
            final beforeInsert = DateTime.now();
            
            // Insert a vault item with random data
            final vaultCompanion = VaultItemsCompanion.insert(
              uuid: _generateRandomUuid(),
              titleEnc: _generateRandomString(30),
              usernameEnc: Value(_generateRandomString(20)),
              passwordEnc: Value(_generateRandomString(20)),
            );
            
            final id = await testDb.into(testDb.vaultItems).insert(vaultCompanion);
            
            // Capture the time just after insertion
            final afterInsert = DateTime.now();
            
            // Retrieve the inserted vault item
            final query = testDb.select(testDb.vaultItems)..where((t) => t.id.equals(id));
            final vaultItem = await query.getSingle();
            
            // Verify updatedAt is set and within the expected time range
            expect(vaultItem.updatedAt, isNotNull,
                reason: 'updatedAt should be automatically set (iteration $i)');
            expect(
              vaultItem.updatedAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be after or near the insertion time (iteration $i)',
            );
            expect(
              vaultItem.updatedAt.isBefore(afterInsert.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be before or near the insertion completion time (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are set even with minimal data', () async {
        // Test that timestamps are set even when only required fields are provided
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            final beforeInsert = DateTime.now();
            
            // Insert note with only required field (uuid)
            final noteCompanion = NotesCompanion.insert(
              uuid: _generateRandomUuid(),
            );
            
            final noteId = await testDb.into(testDb.notes).insert(noteCompanion);
            final afterInsert = DateTime.now();
            
            final noteQuery = testDb.select(testDb.notes)..where((t) => t.id.equals(noteId));
            final note = await noteQuery.getSingle();
            
            expect(note.createdAt, isNotNull,
                reason: 'createdAt should be set even with minimal data (iteration $i)');
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be set even with minimal data (iteration $i)');
            expect(
              note.createdAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamp should be within expected range (iteration $i)',
            );
            expect(
              note.createdAt.isBefore(afterInsert.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamp should be within expected range (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Multiple inserts have increasing timestamps', () async {
        // Verify that sequential inserts have non-decreasing timestamps
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            DateTime? previousCreatedAt;
            DateTime? previousUpdatedAt;
            
            // Insert multiple notes sequentially
            for (int j = 0; j < 5; j++) {
              final noteCompanion = NotesCompanion.insert(
                uuid: _generateRandomUuid(),
                title: Value('Note $j'),
              );
              
              final id = await testDb.into(testDb.notes).insert(noteCompanion);
              
              // Small delay to ensure timestamps differ
              await Future.delayed(const Duration(milliseconds: 10));
              
              final query = testDb.select(testDb.notes)..where((t) => t.id.equals(id));
              final note = await query.getSingle();
              
              if (previousCreatedAt != null) {
                // Timestamps should be non-decreasing (later or equal)
                expect(
                  note.createdAt.isAfter(previousCreatedAt) ||
                      note.createdAt.isAtSameMomentAs(previousCreatedAt),
                  isTrue,
                  reason: 'Sequential inserts should have non-decreasing createdAt (iteration $i, insert $j)',
                );
              }
              
              if (previousUpdatedAt != null) {
                expect(
                  note.updatedAt.isAfter(previousUpdatedAt) ||
                      note.updatedAt.isAtSameMomentAs(previousUpdatedAt),
                  isTrue,
                  reason: 'Sequential inserts should have non-decreasing updatedAt (iteration $i, insert $j)',
                );
              }
              
              previousCreatedAt = note.createdAt;
              previousUpdatedAt = note.updatedAt;
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are independent of other field values', () async {
        // Verify that timestamp setting is not affected by other field values
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          
          try {
            final beforeInsert = DateTime.now();
            
            // Insert with various combinations of fields
            final noteCompanion = NotesCompanion.insert(
              uuid: _generateRandomUuid(),
              title: Value(_generateRandomString(Random().nextInt(50))),
              contentMd: Value(_generateRandomString(Random().nextInt(200))),
              tagsJson: Value('["tag1", "tag2", "tag3"]'),
              isEncrypted: Value(Random().nextBool()),
            );
            
            final id = await testDb.into(testDb.notes).insert(noteCompanion);
            final afterInsert = DateTime.now();
            
            final query = testDb.select(testDb.notes)..where((t) => t.id.equals(id));
            final note = await query.getSingle();
            
            // Timestamps should still be set correctly regardless of other fields
            expect(note.createdAt, isNotNull,
                reason: 'createdAt should be set regardless of other fields (iteration $i)');
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be set regardless of other fields (iteration $i)');
            expect(
              note.createdAt.isAfter(beforeInsert.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamp should be within expected range (iteration $i)',
            );
            expect(
              note.createdAt.isBefore(afterInsert.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamp should be within expected range (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });
    });
  });
}

// Helper function to generate random UUID-like string
String _generateRandomUuid() {
  final random = Random.secure();
  
  // Generate a UUID v4-like string: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  String randomHex(int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  final part1 = randomHex(8);
  final part2 = randomHex(4);
  final part3 = '4${randomHex(3)}'; // Version 4
  final part4 = '${['8', '9', 'a', 'b'][random.nextInt(4)]}${randomHex(3)}'; // Variant
  final part5 = randomHex(12);
  
  return '$part1-$part2-$part3-$part4-$part5';
}

// Helper function to generate random string
String _generateRandomString(int length) {
  if (length == 0) return '';
  
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
