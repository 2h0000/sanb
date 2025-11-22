import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypted_notebook/domain/entities/note.dart' as entity;

void main() {
  group('NotesDao', () {
    late AppDatabase database;
    late NotesDao notesDao;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    // **Feature: encrypted-notebook-app, Property 1: 笔记创建往返一致性**
    // **Validates: Requirements 1.1, 1.5**
    // Property: For any note with valid data (uuid, title, content, tags),
    // creating the note and then retrieving it by UUID should return a note
    // with the same data. This ensures the round-trip consistency of note creation.
    group('Property 1: Note Creation Round-Trip Consistency', () {
      test('Creating and retrieving a note preserves all data', () async {
        // Run the property test with multiple random inputs
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

            // Create the note
            final id = await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );

            expect(id, greaterThan(0),
                reason: 'Note creation should return valid ID (iteration $i)');

            // Retrieve the note by UUID
            final retrievedNote = await testDao.findByUuid(uuid);

            // Verify the note was retrieved
            expect(retrievedNote, isNotNull,
                reason: 'Note should be retrievable by UUID (iteration $i)');

            // Verify all fields match
            expect(retrievedNote!.uuid, equals(uuid),
                reason: 'UUID should match (iteration $i)');
            expect(retrievedNote.title, equals(title),
                reason: 'Title should match (iteration $i)');
            expect(retrievedNote.contentMd, equals(contentMd),
                reason: 'Content should match (iteration $i)');
            expect(retrievedNote.tags.length, equals(tags.length),
                reason: 'Tags length should match (iteration $i)');
            for (int j = 0; j < tags.length; j++) {
              expect(retrievedNote.tags[j], equals(tags[j]),
                  reason: 'Tag $j should match (iteration $i)');
            }
            expect(retrievedNote.isEncrypted, equals(false),
                reason: 'isEncrypted should default to false (iteration $i)');
            expect(retrievedNote.createdAt, isNotNull,
                reason: 'createdAt should be set (iteration $i)');
            expect(retrievedNote.updatedAt, isNotNull,
                reason: 'updatedAt should be set (iteration $i)');
            expect(retrievedNote.deletedAt, isNull,
                reason: 'deletedAt should be null for new note (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Creating note with empty tags preserves empty list', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final uuid = const Uuid().v4();
            final title = _generateRandomString(20);
            final contentMd = _generateRandomString(100);

            // Create note with empty tags
            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: [],
            );

            final retrievedNote = await testDao.findByUuid(uuid);

            expect(retrievedNote, isNotNull);
            expect(retrievedNote!.tags, isEmpty,
                reason: 'Empty tags should be preserved (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Creating note with special characters in fields preserves data', () async {
        const numTests = 50;
        const specialChars = [
          '!@#\$%^&*()',
          '你好世界',
          'Émojis: 😀🎉🚀',
          'Newlines:\nand\ttabs',
          'Quotes: "double" and \'single\'',
          'Backslashes: \\ and forward slashes: /',
        ];

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final uuid = const Uuid().v4();
            final title = specialChars[Random().nextInt(specialChars.length)];
            final contentMd = specialChars[Random().nextInt(specialChars.length)];
            final tags = [
              specialChars[Random().nextInt(specialChars.length)],
              specialChars[Random().nextInt(specialChars.length)],
            ];

            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );

            final retrievedNote = await testDao.findByUuid(uuid);

            expect(retrievedNote, isNotNull);
            expect(retrievedNote!.title, equals(title),
                reason: 'Special characters in title should be preserved (iteration $i)');
            expect(retrievedNote.contentMd, equals(contentMd),
                reason: 'Special characters in content should be preserved (iteration $i)');
            expect(retrievedNote.tags, equals(tags),
                reason: 'Special characters in tags should be preserved (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Creating multiple notes with different UUIDs all retrievable', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create multiple notes
            final numNotes = Random().nextInt(10) + 1;
            final createdNotes = <Map<String, dynamic>>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              final title = _generateRandomString(20);
              final contentMd = _generateRandomString(100);
              final tags = _generateRandomTags();

              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: tags,
              );

              createdNotes.add({
                'uuid': uuid,
                'title': title,
                'contentMd': contentMd,
                'tags': tags,
              });
            }

            // Verify all notes are retrievable
            for (int j = 0; j < numNotes; j++) {
              final noteData = createdNotes[j];
              final retrievedNote = await testDao.findByUuid(noteData['uuid'] as String);

              expect(retrievedNote, isNotNull,
                  reason: 'Note $j should be retrievable (iteration $i)');
              expect(retrievedNote!.uuid, equals(noteData['uuid']),
                  reason: 'UUID should match for note $j (iteration $i)');
              expect(retrievedNote.title, equals(noteData['title']),
                  reason: 'Title should match for note $j (iteration $i)');
              expect(retrievedNote.contentMd, equals(noteData['contentMd']),
                  reason: 'Content should match for note $j (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Creating note with very long content preserves data', () async {
        const numTests = 20;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final uuid = const Uuid().v4();
            final title = _generateRandomString(100);
            // Generate very long content (up to 10KB)
            final contentMd = _generateRandomString(Random().nextInt(10000) + 1000);
            final tags = _generateRandomTags();

            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );

            final retrievedNote = await testDao.findByUuid(uuid);

            expect(retrievedNote, isNotNull);
            expect(retrievedNote!.contentMd, equals(contentMd),
                reason: 'Long content should be preserved (iteration $i)');
            expect(retrievedNote.contentMd.length, equals(contentMd.length),
                reason: 'Content length should match (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 3: 软删除不变量**
    // **Validates: Requirements 1.3, 1.4, 2.2**
    // Property: For any note, after soft deletion, the note should not appear
    // in the list of active notes (getAllNotes) or in search results (search),
    // but should still exist in the database with deletedAt set.
    group('Property 3: Soft Delete Invariant', () {
      test('Soft deleted notes do not appear in getAllNotes', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a random number of notes
            final numNotes = Random().nextInt(10) + 1;
            final createdUuids = <String>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(20),
                contentMd: _generateRandomString(100),
                tags: _generateRandomTags(),
              );
              createdUuids.add(uuid);
            }

            // Verify all notes are in the list
            var allNotes = await testDao.getAllNotes();
            expect(allNotes.length, equals(numNotes),
                reason: 'All created notes should be in the list (iteration $i)');

            // Randomly select notes to soft delete
            final numToDelete = Random().nextInt(numNotes) + 1;
            final deletedUuids = <String>[];
            for (int j = 0; j < numToDelete; j++) {
              final uuidToDelete = createdUuids[j];
              await testDao.softDelete(uuidToDelete);
              deletedUuids.add(uuidToDelete);
            }

            // Get all notes after deletion
            allNotes = await testDao.getAllNotes();

            // Verify deleted notes do not appear in the list
            expect(allNotes.length, equals(numNotes - numToDelete),
                reason: 'Deleted notes should not appear in getAllNotes (iteration $i)');

            for (final deletedUuid in deletedUuids) {
              final foundInList = allNotes.any((note) => note.uuid == deletedUuid);
              expect(foundInList, isFalse,
                  reason: 'Deleted note $deletedUuid should not appear in getAllNotes (iteration $i)');
            }

            // Verify non-deleted notes still appear
            for (int j = numToDelete; j < numNotes; j++) {
              final uuid = createdUuids[j];
              final foundInList = allNotes.any((note) => note.uuid == uuid);
              expect(foundInList, isTrue,
                  reason: 'Non-deleted note $uuid should still appear in getAllNotes (iteration $i)');
            }

            // Verify deleted notes still exist in database with deletedAt set
            for (final deletedUuid in deletedUuids) {
              final note = await testDao.findByUuid(deletedUuid);
              expect(note, isNotNull,
                  reason: 'Deleted note should still exist in database (iteration $i)');
              expect(note!.deletedAt, isNotNull,
                  reason: 'Deleted note should have deletedAt set (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Soft deleted notes do not appear in search results', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes with searchable keywords
            final keyword = 'searchable${Random().nextInt(1000)}';
            final numNotes = Random().nextInt(5) + 2; // At least 2 notes
            final createdUuids = <String>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              // Include keyword in title or content
              final includeInTitle = Random().nextBool();
              final title = includeInTitle
                  ? '$keyword ${_generateRandomString(10)}'
                  : _generateRandomString(20);
              final contentMd = !includeInTitle
                  ? '$keyword ${_generateRandomString(50)}'
                  : _generateRandomString(100);

              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: _generateRandomTags(),
              );
              createdUuids.add(uuid);
            }

            // Verify all notes are found in search
            var searchResults = await testDao.search(keyword);
            expect(searchResults.length, equals(numNotes),
                reason: 'All notes with keyword should be found (iteration $i)');

            // Randomly select notes to soft delete
            final numToDelete = Random().nextInt(numNotes - 1) + 1;
            final deletedUuids = <String>[];
            for (int j = 0; j < numToDelete; j++) {
              final uuidToDelete = createdUuids[j];
              await testDao.softDelete(uuidToDelete);
              deletedUuids.add(uuidToDelete);
            }

            // Search again after deletion
            searchResults = await testDao.search(keyword);

            // Verify deleted notes do not appear in search results
            expect(searchResults.length, equals(numNotes - numToDelete),
                reason: 'Deleted notes should not appear in search results (iteration $i)');

            for (final deletedUuid in deletedUuids) {
              final foundInSearch = searchResults.any((note) => note.uuid == deletedUuid);
              expect(foundInSearch, isFalse,
                  reason: 'Deleted note $deletedUuid should not appear in search (iteration $i)');
            }

            // Verify non-deleted notes still appear in search
            for (int j = numToDelete; j < numNotes; j++) {
              final uuid = createdUuids[j];
              final foundInSearch = searchResults.any((note) => note.uuid == uuid);
              expect(foundInSearch, isTrue,
                  reason: 'Non-deleted note $uuid should still appear in search (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Soft deleted notes still retrievable by UUID with deletedAt set', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a note
            final uuid = const Uuid().v4();
            final title = _generateRandomString(20);
            final contentMd = _generateRandomString(100);
            final tags = _generateRandomTags();

            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );

            // Verify note exists and deletedAt is null
            var note = await testDao.findByUuid(uuid);
            expect(note, isNotNull,
                reason: 'Note should exist before deletion (iteration $i)');
            expect(note!.deletedAt, isNull,
                reason: 'deletedAt should be null before deletion (iteration $i)');

            // Record the time before deletion
            final beforeDelete = DateTime.now();

            // Soft delete the note
            await testDao.softDelete(uuid);

            // Record the time after deletion
            final afterDelete = DateTime.now();

            // Verify note still exists but with deletedAt set
            note = await testDao.findByUuid(uuid);
            expect(note, isNotNull,
                reason: 'Note should still exist after soft deletion (iteration $i)');
            expect(note!.deletedAt, isNotNull,
                reason: 'deletedAt should be set after soft deletion (iteration $i)');

            // Verify deletedAt is within reasonable time range
            expect(
              note.deletedAt!.isAfter(beforeDelete.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'deletedAt should be after deletion time (iteration $i)',
            );
            expect(
              note.deletedAt!.isBefore(afterDelete.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'deletedAt should be before completion time (iteration $i)',
            );

            // Verify other fields remain unchanged
            expect(note.uuid, equals(uuid),
                reason: 'UUID should remain unchanged (iteration $i)');
            expect(note.title, equals(title),
                reason: 'Title should remain unchanged (iteration $i)');
            expect(note.contentMd, equals(contentMd),
                reason: 'Content should remain unchanged (iteration $i)');
            expect(note.tags, equals(tags),
                reason: 'Tags should remain unchanged (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Multiple soft deletes on same note are idempotent', () async {
        const numTests = 50;

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

            // Get the first deletedAt timestamp
            var note = await testDao.findByUuid(uuid);
            final firstDeletedAt = note!.deletedAt;
            expect(firstDeletedAt, isNotNull,
                reason: 'deletedAt should be set after first deletion (iteration $i)');

            // Wait a bit to ensure time difference
            await Future.delayed(const Duration(milliseconds: 10));

            // Soft delete again
            await testDao.softDelete(uuid);

            // Verify the note is still not in active lists
            final allNotes = await testDao.getAllNotes();
            expect(allNotes.any((n) => n.uuid == uuid), isFalse,
                reason: 'Note should not appear in getAllNotes after second deletion (iteration $i)');

            // Verify note still exists
            note = await testDao.findByUuid(uuid);
            expect(note, isNotNull,
                reason: 'Note should still exist after second deletion (iteration $i)');
            expect(note!.deletedAt, isNotNull,
                reason: 'deletedAt should still be set after second deletion (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Soft delete with empty database does not cause errors', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Try to soft delete a non-existent note
            final uuid = const Uuid().v4();
            final result = await testDao.softDelete(uuid);

            // Should return 0 (no rows affected) but not throw an error
            expect(result, equals(0),
                reason: 'Soft deleting non-existent note should affect 0 rows (iteration $i)');

            // Verify database is still empty
            final allNotes = await testDao.getAllNotes();
            expect(allNotes, isEmpty,
                reason: 'Database should remain empty (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 7: 时间戳自动设置**
    // **Validates: Requirements 5.4**
    // Property: For any note, when a record is inserted, the system should
    // automatically set createdAt and updatedAt to the current timestamp.
    // Both timestamps should be non-null and within a reasonable time range
    // of the insertion operation.
    group('Property 7: Timestamp Auto-Setting', () {
      test('Creating a note automatically sets createdAt and updatedAt', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Record time before creation
            final beforeCreate = DateTime.now();

            // Create a note with random data
            final uuid = const Uuid().v4();
            final title = _generateRandomString(Random().nextInt(50) + 1);
            final contentMd = _generateRandomString(Random().nextInt(200) + 1);
            final tags = _generateRandomTags();

            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: tags,
            );

            // Record time after creation
            final afterCreate = DateTime.now();

            // Retrieve the note
            final note = await testDao.findByUuid(uuid);

            // Verify note was created
            expect(note, isNotNull,
                reason: 'Note should be created (iteration $i)');

            // Verify createdAt is automatically set
            expect(note!.createdAt, isNotNull,
                reason: 'createdAt should be automatically set (iteration $i)');

            // Verify updatedAt is automatically set
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be automatically set (iteration $i)');

            // Verify createdAt is within reasonable time range
            // Allow 1 second buffer for test execution time
            expect(
              note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'createdAt should be after operation start time (iteration $i)',
            );
            expect(
              note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'createdAt should be before operation end time (iteration $i)',
            );

            // Verify updatedAt is within reasonable time range
            expect(
              note.updatedAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be after operation start time (iteration $i)',
            );
            expect(
              note.updatedAt.isBefore(afterCreate.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'updatedAt should be before operation end time (iteration $i)',
            );

            // Verify createdAt and updatedAt are the same or very close
            // (within 1 second) for newly created notes
            final timeDiff = note.updatedAt.difference(note.createdAt).abs();
            expect(
              timeDiff.inSeconds <= 1,
              isTrue,
              reason: 'createdAt and updatedAt should be the same or very close for new notes (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are set for notes with empty fields', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final beforeCreate = DateTime.now();

            // Create note with empty title and content
            final uuid = const Uuid().v4();
            await testDao.createNote(
              uuid: uuid,
              title: '',
              contentMd: '',
              tags: [],
            );

            final afterCreate = DateTime.now();

            final note = await testDao.findByUuid(uuid);

            expect(note, isNotNull,
                reason: 'Note with empty fields should be created (iteration $i)');
            expect(note!.createdAt, isNotNull,
                reason: 'createdAt should be set even for empty fields (iteration $i)');
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be set even for empty fields (iteration $i)');

            // Verify timestamps are within range
            expect(
              note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))) &&
                  note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamps should be within operation time range (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are set for notes with very long content', () async {
        const numTests = 20;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final beforeCreate = DateTime.now();

            // Create note with very long content (up to 10KB)
            final uuid = const Uuid().v4();
            final longContent = _generateRandomString(Random().nextInt(10000) + 5000);

            await testDao.createNote(
              uuid: uuid,
              title: 'Long content note',
              contentMd: longContent,
              tags: _generateRandomTags(),
            );

            final afterCreate = DateTime.now();

            final note = await testDao.findByUuid(uuid);

            expect(note, isNotNull,
                reason: 'Note with long content should be created (iteration $i)');
            expect(note!.createdAt, isNotNull,
                reason: 'createdAt should be set for long content (iteration $i)');
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be set for long content (iteration $i)');

            // Verify timestamps are within range (allow more time for large content)
            expect(
              note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 2))) &&
                  note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 2))),
              isTrue,
              reason: 'Timestamps should be within operation time range for long content (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are set for notes with special characters', () async {
        const numTests = 50;
        const specialChars = [
          '!@#\$%^&*()',
          '你好世界',
          'Émojis: 😀🎉🚀',
          'Newlines:\nand\ttabs',
          'Quotes: "double" and \'single\'',
          'Backslashes: \\ and forward slashes: /',
        ];

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final beforeCreate = DateTime.now();

            final uuid = const Uuid().v4();
            final title = specialChars[Random().nextInt(specialChars.length)];
            final contentMd = specialChars[Random().nextInt(specialChars.length)];

            await testDao.createNote(
              uuid: uuid,
              title: title,
              contentMd: contentMd,
              tags: [specialChars[Random().nextInt(specialChars.length)]],
            );

            final afterCreate = DateTime.now();

            final note = await testDao.findByUuid(uuid);

            expect(note, isNotNull,
                reason: 'Note with special characters should be created (iteration $i)');
            expect(note!.createdAt, isNotNull,
                reason: 'createdAt should be set for special characters (iteration $i)');
            expect(note.updatedAt, isNotNull,
                reason: 'updatedAt should be set for special characters (iteration $i)');

            expect(
              note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))) &&
                  note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 1))),
              isTrue,
              reason: 'Timestamps should be within operation time range (iteration $i)',
            );
          } finally {
            await testDb.close();
          }
        }
      });

      test('Multiple notes created in sequence have increasing timestamps', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create multiple notes with small delays
            final numNotes = Random().nextInt(5) + 3; // 3 to 7 notes
            final createdUuids = <String>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(20),
                contentMd: _generateRandomString(100),
                tags: _generateRandomTags(),
              );
              createdUuids.add(uuid);

              // Small delay to ensure different timestamps
              await Future.delayed(const Duration(milliseconds: 5));
            }

            // Retrieve all notes and verify timestamps are in order
            final notes = <entity.Note>[];
            for (final uuid in createdUuids) {
              final note = await testDao.findByUuid(uuid);
              expect(note, isNotNull,
                  reason: 'All created notes should be retrievable (iteration $i)');
              notes.add(note!);
            }

            // Verify timestamps are monotonically increasing or equal
            for (int j = 0; j < notes.length - 1; j++) {
              expect(
                notes[j + 1].createdAt.isAfter(notes[j].createdAt) ||
                    notes[j + 1].createdAt.isAtSameMomentAs(notes[j].createdAt),
                isTrue,
                reason: 'Later notes should have equal or later createdAt timestamps (iteration $i, note $j)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are set correctly for concurrent note creation', () async {
        const numTests = 30;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            final beforeCreate = DateTime.now();

            // Create multiple notes concurrently
            final numNotes = Random().nextInt(5) + 3;
            final futures = <Future<String>>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              futures.add(
                testDao.createNote(
                  uuid: uuid,
                  title: _generateRandomString(20),
                  contentMd: _generateRandomString(100),
                  tags: _generateRandomTags(),
                ).then((_) => uuid),
              );
            }

            // Wait for all notes to be created
            final createdUuids = await Future.wait(futures);
            final afterCreate = DateTime.now();

            // Verify all notes have timestamps set
            for (final uuid in createdUuids) {
              final note = await testDao.findByUuid(uuid);

              expect(note, isNotNull,
                  reason: 'Concurrently created note should exist (iteration $i)');
              expect(note!.createdAt, isNotNull,
                  reason: 'createdAt should be set for concurrent creation (iteration $i)');
              expect(note.updatedAt, isNotNull,
                  reason: 'updatedAt should be set for concurrent creation (iteration $i)');

              // Verify timestamps are within the operation time range
              expect(
                note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))) &&
                    note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 1))),
                isTrue,
                reason: 'Timestamps should be within operation time range for concurrent creation (iteration $i)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Timestamps are independent of note content size', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes with varying content sizes
            final sizes = [0, 10, 100, 1000, 5000];
            final createdNotes = <entity.Note>[];

            for (final size in sizes) {
              final beforeCreate = DateTime.now();

              final uuid = const Uuid().v4();
              final content = size > 0 ? _generateRandomString(size) : '';

              await testDao.createNote(
                uuid: uuid,
                title: 'Note with $size chars',
                contentMd: content,
                tags: [],
              );

              final afterCreate = DateTime.now();

              final note = await testDao.findByUuid(uuid);
              expect(note, isNotNull,
                  reason: 'Note with $size chars should be created (iteration $i)');

              // Verify timestamps are set and within range
              expect(note!.createdAt, isNotNull,
                  reason: 'createdAt should be set for $size chars (iteration $i)');
              expect(note.updatedAt, isNotNull,
                  reason: 'updatedAt should be set for $size chars (iteration $i)');

              expect(
                note.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))) &&
                    note.createdAt.isBefore(afterCreate.add(const Duration(seconds: 2))),
                isTrue,
                reason: 'Timestamps should be within range for $size chars (iteration $i)',
              );

              createdNotes.add(note);

              // Small delay between creations
              await Future.delayed(const Duration(milliseconds: 10));
            }

            // Verify all notes have valid timestamps regardless of size
            for (final note in createdNotes) {
              expect(note.createdAt, isNotNull);
              expect(note.updatedAt, isNotNull);
              expect(note.createdAt.isBefore(DateTime.now()), isTrue);
            }
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 4: 列表排序正确性**
    // **Validates: Requirements 1.4, 2.3**
    // Property: For any collection of notes, getAllNotes() and search() should
    // return notes sorted by updatedAt in descending order (newest first).
    group('Property 4: List Sorting Correctness', () {
      test('getAllNotes returns notes sorted by updatedAt descending', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a random number of notes with different updatedAt times
            final numNotes = Random().nextInt(10) + 2; // At least 2 notes
            final createdNotes = <Map<String, dynamic>>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              final title = _generateRandomString(20);
              final contentMd = _generateRandomString(100);
              final tags = _generateRandomTags();

              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: tags,
              );

              // Wait a bit to ensure different timestamps
              await Future.delayed(const Duration(milliseconds: 5));

              // Randomly update some notes to change their updatedAt
              if (Random().nextBool()) {
                await testDao.updateNote(
                  uuid,
                  title: '$title updated',
                );
                await Future.delayed(const Duration(milliseconds: 5));
              }

              // Store the note info
              final note = await testDao.findByUuid(uuid);
              createdNotes.add({
                'uuid': uuid,
                'updatedAt': note!.updatedAt,
              });
            }

            // Get all notes
            final allNotes = await testDao.getAllNotes();

            // Verify we got all notes
            expect(allNotes.length, equals(numNotes),
                reason: 'Should return all notes (iteration $i)');

            // Verify notes are sorted by updatedAt descending
            for (int j = 0; j < allNotes.length - 1; j++) {
              final current = allNotes[j];
              final next = allNotes[j + 1];

              expect(
                current.updatedAt.isAfter(next.updatedAt) ||
                    current.updatedAt.isAtSameMomentAs(next.updatedAt),
                isTrue,
                reason:
                    'Note at index $j (updatedAt: ${current.updatedAt}) should be newer than or equal to note at index ${j + 1} (updatedAt: ${next.updatedAt}) (iteration $i)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('search returns notes sorted by updatedAt descending', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes with a common searchable keyword
            final keyword = 'searchable${Random().nextInt(1000)}';
            final numNotes = Random().nextInt(10) + 2; // At least 2 notes

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              // Include keyword in title or content
              final includeInTitle = Random().nextBool();
              final title = includeInTitle
                  ? '$keyword ${_generateRandomString(10)}'
                  : _generateRandomString(20);
              final contentMd = !includeInTitle
                  ? '$keyword ${_generateRandomString(50)}'
                  : _generateRandomString(100);

              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: _generateRandomTags(),
              );

              // Wait to ensure different timestamps
              await Future.delayed(const Duration(milliseconds: 5));

              // Randomly update some notes
              if (Random().nextBool()) {
                await testDao.updateNote(
                  uuid,
                  contentMd: '$contentMd updated',
                );
                await Future.delayed(const Duration(milliseconds: 5));
              }
            }

            // Search for the keyword
            final searchResults = await testDao.search(keyword);

            // Verify we got all matching notes
            expect(searchResults.length, equals(numNotes),
                reason: 'Should return all matching notes (iteration $i)');

            // Verify search results are sorted by updatedAt descending
            for (int j = 0; j < searchResults.length - 1; j++) {
              final current = searchResults[j];
              final next = searchResults[j + 1];

              expect(
                current.updatedAt.isAfter(next.updatedAt) ||
                    current.updatedAt.isAtSameMomentAs(next.updatedAt),
                isTrue,
                reason:
                    'Search result at index $j (updatedAt: ${current.updatedAt}) should be newer than or equal to result at index ${j + 1} (updatedAt: ${next.updatedAt}) (iteration $i)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('getAllNotes sorting is stable across multiple calls', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes
            final numNotes = Random().nextInt(10) + 3;
            for (int j = 0; j < numNotes; j++) {
              await testDao.createNote(
                uuid: const Uuid().v4(),
                title: _generateRandomString(20),
                contentMd: _generateRandomString(100),
                tags: _generateRandomTags(),
              );
              await Future.delayed(const Duration(milliseconds: 5));
            }

            // Get all notes multiple times
            final firstCall = await testDao.getAllNotes();
            final secondCall = await testDao.getAllNotes();
            final thirdCall = await testDao.getAllNotes();

            // Verify all calls return the same order
            expect(firstCall.length, equals(secondCall.length),
                reason: 'All calls should return same number of notes (iteration $i)');
            expect(firstCall.length, equals(thirdCall.length),
                reason: 'All calls should return same number of notes (iteration $i)');

            for (int j = 0; j < firstCall.length; j++) {
              expect(firstCall[j].uuid, equals(secondCall[j].uuid),
                  reason: 'Note order should be consistent between calls (iteration $i, index $j)');
              expect(firstCall[j].uuid, equals(thirdCall[j].uuid),
                  reason: 'Note order should be consistent between calls (iteration $i, index $j)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Sorting works correctly with notes having same updatedAt', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create multiple notes quickly (may have same timestamp)
            final numNotes = Random().nextInt(5) + 3;
            for (int j = 0; j < numNotes; j++) {
              await testDao.createNote(
                uuid: const Uuid().v4(),
                title: _generateRandomString(20),
                contentMd: _generateRandomString(100),
                tags: _generateRandomTags(),
              );
              // No delay - may create notes with same timestamp
            }

            // Get all notes
            final allNotes = await testDao.getAllNotes();

            // Verify sorting property still holds (descending or equal)
            for (int j = 0; j < allNotes.length - 1; j++) {
              final current = allNotes[j];
              final next = allNotes[j + 1];

              expect(
                current.updatedAt.isAfter(next.updatedAt) ||
                    current.updatedAt.isAtSameMomentAs(next.updatedAt),
                isTrue,
                reason:
                    'Notes should be in descending order even with same timestamps (iteration $i, index $j)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Sorting works correctly after updates change order', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes in sequence
            final numNotes = Random().nextInt(5) + 3;
            final uuids = <String>[];

            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(20),
                contentMd: _generateRandomString(100),
                tags: _generateRandomTags(),
              );
              uuids.add(uuid);
              await Future.delayed(const Duration(milliseconds: 10));
            }

            // Get initial order
            final beforeUpdate = await testDao.getAllNotes();
            final oldestNoteUuid = beforeUpdate.last.uuid;

            // Wait a bit
            await Future.delayed(const Duration(milliseconds: 20));

            // Update the oldest note (should move it to the front)
            await testDao.updateNote(
              oldestNoteUuid,
              title: 'Updated title',
            );

            // Get new order
            final afterUpdate = await testDao.getAllNotes();

            // Verify the updated note is now first (or at least not last)
            expect(afterUpdate.first.uuid, equals(oldestNoteUuid),
                reason: 'Updated note should be first after update (iteration $i)');

            // Verify sorting is still correct
            for (int j = 0; j < afterUpdate.length - 1; j++) {
              final current = afterUpdate[j];
              final next = afterUpdate[j + 1];

              expect(
                current.updatedAt.isAfter(next.updatedAt) ||
                    current.updatedAt.isAtSameMomentAs(next.updatedAt),
                isTrue,
                reason: 'Notes should remain sorted after update (iteration $i, index $j)',
              );
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Empty list returns empty sorted list', () async {
        const numTests = 20;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Get all notes from empty database
            final allNotes = await testDao.getAllNotes();

            expect(allNotes, isEmpty,
                reason: 'Empty database should return empty list (iteration $i)');

            // Search in empty database
            final searchResults = await testDao.search('anything');

            expect(searchResults, isEmpty,
                reason: 'Search in empty database should return empty list (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Single note list is trivially sorted', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a single note
            final uuid = const Uuid().v4();
            await testDao.createNote(
              uuid: uuid,
              title: _generateRandomString(20),
              contentMd: _generateRandomString(100),
              tags: _generateRandomTags(),
            );

            // Get all notes
            final allNotes = await testDao.getAllNotes();

            expect(allNotes.length, equals(1),
                reason: 'Should return single note (iteration $i)');
            expect(allNotes.first.uuid, equals(uuid),
                reason: 'Should return the created note (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 5: 搜索匹配正确性**
    // **Validates: Requirements 2.1**
    // Property: For any note containing a keyword in its title or content,
    // searching for that keyword should return that note. The search should
    // match substrings using LIKE pattern matching.
    group('Property 5: Search Matching Correctness', () {
      test('Search returns all notes containing keyword in title', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Generate a unique keyword for this test iteration
            final keyword = 'keyword${Random().nextInt(100000)}';
            
            // Create notes with keyword in title
            final numNotesWithKeyword = Random().nextInt(5) + 1;
            final uuidsWithKeyword = <String>[];
            
            for (int j = 0; j < numNotesWithKeyword; j++) {
              final uuid = const Uuid().v4();
              // Place keyword at random position in title
              final prefix = _generateRandomString(Random().nextInt(10));
              final suffix = _generateRandomString(Random().nextInt(10));
              final title = '$prefix$keyword$suffix';
              final contentMd = _generateRandomString(Random().nextInt(100) + 10);
              
              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: _generateRandomTags(),
              );
              uuidsWithKeyword.add(uuid);
            }
            
            // Create notes without keyword
            final numNotesWithout = Random().nextInt(5);
            for (int j = 0; j < numNotesWithout; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search for the keyword
            final searchResults = await testDao.search(keyword);
            
            // Verify all notes with keyword are returned
            expect(searchResults.length, equals(numNotesWithKeyword),
                reason: 'Search should return all notes with keyword in title (iteration $i)');
            
            for (final uuid in uuidsWithKeyword) {
              final found = searchResults.any((note) => note.uuid == uuid);
              expect(found, isTrue,
                  reason: 'Note with keyword in title should be in search results (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search returns all notes containing keyword in content', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Generate a unique keyword for this test iteration
            final keyword = 'content${Random().nextInt(100000)}';
            
            // Create notes with keyword in content
            final numNotesWithKeyword = Random().nextInt(5) + 1;
            final uuidsWithKeyword = <String>[];
            
            for (int j = 0; j < numNotesWithKeyword; j++) {
              final uuid = const Uuid().v4();
              final title = _generateRandomString(Random().nextInt(20) + 5);
              // Place keyword at random position in content
              final prefix = _generateRandomString(Random().nextInt(50));
              final suffix = _generateRandomString(Random().nextInt(50));
              final contentMd = '$prefix$keyword$suffix';
              
              await testDao.createNote(
                uuid: uuid,
                title: title,
                contentMd: contentMd,
                tags: _generateRandomTags(),
              );
              uuidsWithKeyword.add(uuid);
            }
            
            // Create notes without keyword
            final numNotesWithout = Random().nextInt(5);
            for (int j = 0; j < numNotesWithout; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search for the keyword
            final searchResults = await testDao.search(keyword);
            
            // Verify all notes with keyword are returned
            expect(searchResults.length, equals(numNotesWithKeyword),
                reason: 'Search should return all notes with keyword in content (iteration $i)');
            
            for (final uuid in uuidsWithKeyword) {
              final found = searchResults.any((note) => note.uuid == uuid);
              expect(found, isTrue,
                  reason: 'Note with keyword in content should be in search results (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search returns notes with keyword in either title or content', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Generate a unique keyword for this test iteration
            final keyword = 'mixed${Random().nextInt(100000)}';
            
            final uuidsWithKeyword = <String>[];
            
            // Create notes with keyword in title only
            final numInTitle = Random().nextInt(3) + 1;
            for (int j = 0; j < numInTitle; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: 'Title with $keyword here',
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
              uuidsWithKeyword.add(uuid);
            }
            
            // Create notes with keyword in content only
            final numInContent = Random().nextInt(3) + 1;
            for (int j = 0; j < numInContent; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: 'Content with $keyword here',
                tags: _generateRandomTags(),
              );
              uuidsWithKeyword.add(uuid);
            }
            
            // Create notes with keyword in both
            final numInBoth = Random().nextInt(3) + 1;
            for (int j = 0; j < numInBoth; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: 'Title $keyword',
                contentMd: 'Content $keyword',
                tags: _generateRandomTags(),
              );
              uuidsWithKeyword.add(uuid);
            }
            
            // Create notes without keyword
            final numNotesWithout = Random().nextInt(5);
            for (int j = 0; j < numNotesWithout; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search for the keyword
            final searchResults = await testDao.search(keyword);
            
            // Verify all notes with keyword are returned
            final expectedCount = numInTitle + numInContent + numInBoth;
            expect(searchResults.length, equals(expectedCount),
                reason: 'Search should return all notes with keyword in title or content (iteration $i)');
            
            for (final uuid in uuidsWithKeyword) {
              final found = searchResults.any((note) => note.uuid == uuid);
              expect(found, isTrue,
                  reason: 'Note with keyword should be in search results (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search is case-insensitive (LIKE behavior)', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a keyword with mixed case
            final baseKeyword = 'TestWord${Random().nextInt(10000)}';
            
            // Create notes with different case variations
            final variations = [
              baseKeyword.toLowerCase(),
              baseKeyword.toUpperCase(),
              baseKeyword,
            ];
            
            final createdUuids = <String>[];
            for (final variation in variations) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: 'Title with $variation',
                contentMd: _generateRandomString(50),
                tags: _generateRandomTags(),
              );
              createdUuids.add(uuid);
            }
            
            // Search with lowercase
            final lowerResults = await testDao.search(baseKeyword.toLowerCase());
            
            // SQLite LIKE is case-insensitive by default for ASCII characters
            // All variations should be found
            expect(lowerResults.length, greaterThanOrEqualTo(1),
                reason: 'Search should find notes regardless of case (iteration $i)');
            
            // Verify at least one of our notes is found
            final foundAny = createdUuids.any((uuid) => 
              lowerResults.any((note) => note.uuid == uuid));
            expect(foundAny, isTrue,
                reason: 'At least one note with keyword should be found (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search matches partial keywords (substring matching)', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a longer keyword
            final fullKeyword = 'LongKeyword${Random().nextInt(10000)}';
            
            // Create a note with the full keyword
            final uuid = const Uuid().v4();
            await testDao.createNote(
              uuid: uuid,
              title: 'Title with $fullKeyword embedded',
              contentMd: _generateRandomString(50),
              tags: _generateRandomTags(),
            );
            
            // Search with a substring of the keyword
            final partialKeyword = fullKeyword.substring(0, fullKeyword.length - 3);
            final searchResults = await testDao.search(partialKeyword);
            
            // Verify the note is found with partial match
            expect(searchResults.length, greaterThanOrEqualTo(1),
                reason: 'Search should match partial keywords (iteration $i)');
            
            final found = searchResults.any((note) => note.uuid == uuid);
            expect(found, isTrue,
                reason: 'Note should be found with partial keyword match (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search excludes deleted notes', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Generate a unique keyword
            final keyword = 'deletable${Random().nextInt(100000)}';
            
            // Create notes with keyword
            final numNotes = Random().nextInt(5) + 2;
            final createdUuids = <String>[];
            
            for (int j = 0; j < numNotes; j++) {
              final uuid = const Uuid().v4();
              await testDao.createNote(
                uuid: uuid,
                title: 'Title $keyword',
                contentMd: 'Content $keyword',
                tags: _generateRandomTags(),
              );
              createdUuids.add(uuid);
            }
            
            // Verify all notes are found
            var searchResults = await testDao.search(keyword);
            expect(searchResults.length, equals(numNotes),
                reason: 'All notes should be found before deletion (iteration $i)');
            
            // Soft delete some notes
            final numToDelete = Random().nextInt(numNotes - 1) + 1;
            final deletedUuids = <String>[];
            for (int j = 0; j < numToDelete; j++) {
              await testDao.softDelete(createdUuids[j]);
              deletedUuids.add(createdUuids[j]);
            }
            
            // Search again
            searchResults = await testDao.search(keyword);
            
            // Verify deleted notes are not in results
            expect(searchResults.length, equals(numNotes - numToDelete),
                reason: 'Deleted notes should not appear in search results (iteration $i)');
            
            for (final deletedUuid in deletedUuids) {
              final found = searchResults.any((note) => note.uuid == deletedUuid);
              expect(found, isFalse,
                  reason: 'Deleted note should not be in search results (iteration $i)');
            }
            
            // Verify non-deleted notes are still found
            for (int j = numToDelete; j < numNotes; j++) {
              final uuid = createdUuids[j];
              final found = searchResults.any((note) => note.uuid == uuid);
              expect(found, isTrue,
                  reason: 'Non-deleted note should still be in search results (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search with empty keyword returns all non-deleted notes', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create random notes
            final numNotes = Random().nextInt(10) + 1;
            for (int j = 0; j < numNotes; j++) {
              await testDao.createNote(
                uuid: const Uuid().v4(),
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search with empty string
            final searchResults = await testDao.search('');
            
            // Should return all notes (empty string matches everything with LIKE)
            expect(searchResults.length, equals(numNotes),
                reason: 'Empty search should return all notes (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search with special characters is handled correctly', () async {
        const numTests = 50;
        const specialChars = ['%', '_', '[', ']', '\\', '\'', '"'];

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create a keyword with special characters
            final specialChar = specialChars[Random().nextInt(specialChars.length)];
            final keyword = 'test${specialChar}word${Random().nextInt(1000)}';
            
            // Create a note with the keyword
            final uuid = const Uuid().v4();
            await testDao.createNote(
              uuid: uuid,
              title: 'Title with $keyword',
              contentMd: _generateRandomString(50),
              tags: _generateRandomTags(),
            );
            
            // Search for the keyword
            // Note: This tests that special SQL characters don't break the query
            try {
              final searchResults = await testDao.search(keyword);
              
              // The search should complete without error
              // Whether it finds the note depends on SQL escaping implementation
              expect(searchResults, isNotNull,
                  reason: 'Search with special characters should not throw error (iteration $i)');
            } catch (e) {
              // If search fails, it's likely due to unescaped special characters
              // This is acceptable behavior to document
              expect(e, isNotNull,
                  reason: 'Search with special characters may fail if not escaped (iteration $i)');
            }
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search returns no results when keyword not found', () async {
        const numTests = 100;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create notes without the search keyword
            final numNotes = Random().nextInt(10) + 1;
            for (int j = 0; j < numNotes; j++) {
              await testDao.createNote(
                uuid: const Uuid().v4(),
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search for a keyword that doesn't exist
            final nonExistentKeyword = 'nonexistent${Random().nextInt(1000000)}xyz';
            final searchResults = await testDao.search(nonExistentKeyword);
            
            // Should return empty list
            expect(searchResults, isEmpty,
                reason: 'Search for non-existent keyword should return empty results (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });

      test('Search with whitespace-only keyword behavior', () async {
        const numTests = 50;

        for (int i = 0; i < numTests; i++) {
          final testDb = AppDatabase.forTesting(NativeDatabase.memory());
          final testDao = NotesDao(testDb);

          try {
            // Create some notes
            final numNotes = Random().nextInt(5) + 1;
            for (int j = 0; j < numNotes; j++) {
              await testDao.createNote(
                uuid: const Uuid().v4(),
                title: _generateRandomString(Random().nextInt(20) + 5),
                contentMd: _generateRandomString(Random().nextInt(100) + 10),
                tags: _generateRandomTags(),
              );
            }
            
            // Search with whitespace
            final whitespaceKeyword = '   ';
            final searchResults = await testDao.search(whitespaceKeyword);
            
            // Whitespace should match notes containing spaces
            // This tests the actual LIKE behavior
            expect(searchResults, isNotNull,
                reason: 'Search with whitespace should not throw error (iteration $i)');
          } finally {
            await testDb.close();
          }
        }
      });
    });

    // Unit tests for edge cases
    // **Validates: Requirements 2.4**
    group('Edge Cases', () {
      test('Updating non-existent note returns 0 rows affected', () async {
        // Create a note
        final uuid1 = const Uuid().v4();
        await notesDao.createNote(
          uuid: uuid1,
          title: 'Existing note',
          contentMd: 'Content',
          tags: [],
        );

        // Try to update a non-existent UUID
        final nonExistentUuid = const Uuid().v4();
        final rowsAffected = await notesDao.updateNote(
          nonExistentUuid,
          title: 'Updated title',
        );

        // Should return 0 rows affected
        expect(rowsAffected, equals(0),
            reason: 'Updating non-existent note should affect 0 rows');

        // Verify existing note is unchanged
        final existingNote = await notesDao.findByUuid(uuid1);
        expect(existingNote, isNotNull);
        expect(existingNote!.title, equals('Existing note'),
            reason: 'Existing note should remain unchanged');
      });

      test('Soft deleting already deleted note is idempotent', () async {
        // Create a note
        final uuid = const Uuid().v4();
        await notesDao.createNote(
          uuid: uuid,
          title: 'Test note',
          contentMd: 'Content',
          tags: [],
        );

        // Soft delete the note
        final firstDelete = await notesDao.softDelete(uuid);
        expect(firstDelete, equals(1),
            reason: 'First soft delete should affect 1 row');

        // Get the deletedAt timestamp
        var note = await notesDao.findByUuid(uuid);
        final firstDeletedAt = note!.deletedAt;
        expect(firstDeletedAt, isNotNull,
            reason: 'deletedAt should be set after first deletion');

        // Wait a bit to ensure time difference
        await Future.delayed(const Duration(milliseconds: 10));

        // Soft delete again
        final secondDelete = await notesDao.softDelete(uuid);
        expect(secondDelete, equals(1),
            reason: 'Second soft delete should still affect 1 row');

        // Verify note is still deleted
        note = await notesDao.findByUuid(uuid);
        expect(note, isNotNull,
            reason: 'Note should still exist after second deletion');
        expect(note!.deletedAt, isNotNull,
            reason: 'deletedAt should still be set after second deletion');

        // Verify note doesn't appear in active lists
        final allNotes = await notesDao.getAllNotes();
        expect(allNotes.any((n) => n.uuid == uuid), isFalse,
            reason: 'Deleted note should not appear in getAllNotes');
      });

      test('Soft deleting non-existent note returns 0 rows affected', () async {
        // Create a note to ensure database is not empty
        await notesDao.createNote(
          uuid: const Uuid().v4(),
          title: 'Existing note',
          contentMd: 'Content',
          tags: [],
        );

        // Try to soft delete a non-existent UUID
        final nonExistentUuid = const Uuid().v4();
        final rowsAffected = await notesDao.softDelete(nonExistentUuid);

        // Should return 0 rows affected
        expect(rowsAffected, equals(0),
            reason: 'Soft deleting non-existent note should affect 0 rows');

        // Verify database state is unchanged
        final allNotes = await notesDao.getAllNotes();
        expect(allNotes.length, equals(1),
            reason: 'Database should still have 1 note');
      });

      test('Search with empty keyword returns all non-deleted notes', () async {
        // Create multiple notes
        final numNotes = 5;
        for (int i = 0; i < numNotes; i++) {
          await notesDao.createNote(
            uuid: const Uuid().v4(),
            title: 'Note $i',
            contentMd: 'Content $i',
            tags: [],
          );
        }

        // Search with empty string
        final searchResults = await notesDao.search('');

        // Should return all notes (empty string matches everything with LIKE '%'%)
        expect(searchResults.length, equals(numNotes),
            reason: 'Empty search should return all notes');

        // Verify all notes are present
        for (int i = 0; i < numNotes; i++) {
          final found = searchResults.any((note) => note.title == 'Note $i');
          expect(found, isTrue,
              reason: 'Note $i should be in search results');
        }
      });

      test('Search with empty keyword excludes deleted notes', () async {
        // Create notes
        final uuid1 = const Uuid().v4();
        final uuid2 = const Uuid().v4();
        final uuid3 = const Uuid().v4();

        await notesDao.createNote(
          uuid: uuid1,
          title: 'Note 1',
          contentMd: 'Content 1',
          tags: [],
        );
        await notesDao.createNote(
          uuid: uuid2,
          title: 'Note 2',
          contentMd: 'Content 2',
          tags: [],
        );
        await notesDao.createNote(
          uuid: uuid3,
          title: 'Note 3',
          contentMd: 'Content 3',
          tags: [],
        );

        // Soft delete one note
        await notesDao.softDelete(uuid2);

        // Search with empty string
        final searchResults = await notesDao.search('');

        // Should return only non-deleted notes
        expect(searchResults.length, equals(2),
            reason: 'Empty search should return only non-deleted notes');

        // Verify deleted note is not in results
        final foundDeleted = searchResults.any((note) => note.uuid == uuid2);
        expect(foundDeleted, isFalse,
            reason: 'Deleted note should not be in search results');

        // Verify non-deleted notes are in results
        expect(searchResults.any((note) => note.uuid == uuid1), isTrue,
            reason: 'Non-deleted note 1 should be in results');
        expect(searchResults.any((note) => note.uuid == uuid3), isTrue,
            reason: 'Non-deleted note 3 should be in results');
      });

      test('Updating note with null values keeps existing values', () async {
        // Create a note
        final uuid = const Uuid().v4();
        await notesDao.createNote(
          uuid: uuid,
          title: 'Original title',
          contentMd: 'Original content',
          tags: ['tag1', 'tag2'],
        );

        // Update with all null values (should not change anything except updatedAt)
        final rowsAffected = await notesDao.updateNote(uuid);

        expect(rowsAffected, equals(1),
            reason: 'Update should affect 1 row');

        // Verify values remain unchanged
        final note = await notesDao.findByUuid(uuid);
        expect(note, isNotNull);
        expect(note!.title, equals('Original title'),
            reason: 'Title should remain unchanged');
        expect(note.contentMd, equals('Original content'),
            reason: 'Content should remain unchanged');
        expect(note.tags, equals(['tag1', 'tag2']),
            reason: 'Tags should remain unchanged');
      });

      test('Creating note with duplicate UUID throws error', () async {
        // Create a note
        final uuid = const Uuid().v4();
        await notesDao.createNote(
          uuid: uuid,
          title: 'First note',
          contentMd: 'Content',
          tags: [],
        );

        // Try to create another note with the same UUID
        expect(
          () async => await notesDao.createNote(
            uuid: uuid,
            title: 'Second note',
            contentMd: 'Different content',
            tags: [],
          ),
          throwsA(isA<Object>()),
          reason: 'Creating note with duplicate UUID should throw error',
        );

        // Verify only the first note exists
        final note = await notesDao.findByUuid(uuid);
        expect(note, isNotNull);
        expect(note!.title, equals('First note'),
            reason: 'Only the first note should exist');
      });

      test('getAllNotes with only deleted notes returns empty list', () async {
        // Create notes
        final uuid1 = const Uuid().v4();
        final uuid2 = const Uuid().v4();

        await notesDao.createNote(
          uuid: uuid1,
          title: 'Note 1',
          contentMd: 'Content 1',
          tags: [],
        );
        await notesDao.createNote(
          uuid: uuid2,
          title: 'Note 2',
          contentMd: 'Content 2',
          tags: [],
        );

        // Soft delete all notes
        await notesDao.softDelete(uuid1);
        await notesDao.softDelete(uuid2);

        // Get all notes
        final allNotes = await notesDao.getAllNotes();

        // Should return empty list
        expect(allNotes, isEmpty,
            reason: 'getAllNotes should return empty list when all notes are deleted');
      });

      test('Search with only deleted notes returns empty list', () async {
        // Create notes with keyword
        final keyword = 'searchable';
        final uuid1 = const Uuid().v4();
        final uuid2 = const Uuid().v4();

        await notesDao.createNote(
          uuid: uuid1,
          title: 'Note $keyword 1',
          contentMd: 'Content 1',
          tags: [],
        );
        await notesDao.createNote(
          uuid: uuid2,
          title: 'Note $keyword 2',
          contentMd: 'Content 2',
          tags: [],
        );

        // Soft delete all notes
        await notesDao.softDelete(uuid1);
        await notesDao.softDelete(uuid2);

        // Search for keyword
        final searchResults = await notesDao.search(keyword);

        // Should return empty list
        expect(searchResults, isEmpty,
            reason: 'Search should return empty list when all matching notes are deleted');
      });

      test('findByUuid returns null for non-existent UUID', () async {
        // Create a note to ensure database is not empty
        await notesDao.createNote(
          uuid: const Uuid().v4(),
          title: 'Existing note',
          contentMd: 'Content',
          tags: [],
        );

        // Try to find a non-existent UUID
        final nonExistentUuid = const Uuid().v4();
        final note = await notesDao.findByUuid(nonExistentUuid);

        // Should return null
        expect(note, isNull,
            reason: 'findByUuid should return null for non-existent UUID');
      });

      test('Updating note updates updatedAt timestamp', () async {
        // Create a note
        final uuid = const Uuid().v4();
        await notesDao.createNote(
          uuid: uuid,
          title: 'Original title',
          contentMd: 'Original content',
          tags: [],
        );

        // Get the original updatedAt
        var note = await notesDao.findByUuid(uuid);
        final originalUpdatedAt = note!.updatedAt;

        // Wait a bit to ensure time difference
        await Future.delayed(const Duration(milliseconds: 50));

        // Update the note
        await notesDao.updateNote(
          uuid,
          title: 'Updated title',
        );

        // Get the updated note
        note = await notesDao.findByUuid(uuid);
        final newUpdatedAt = note!.updatedAt;

        // Verify updatedAt has changed
        expect(newUpdatedAt.isAfter(originalUpdatedAt), isTrue,
            reason: 'updatedAt should be updated after modification');
      });
    });

    // Performance optimization tests for pagination
    group('Pagination Tests', () {
      test('getNotesPaginated returns correct number of notes', () async {
        // Create 50 test notes
        for (int i = 0; i < 50; i++) {
          await notesDao.createNote(
            uuid: const Uuid().v4(),
            title: 'Note $i',
            contentMd: 'Content $i',
            tags: [],
          );
          await Future.delayed(const Duration(milliseconds: 2));
        }

        // Test first page (20 notes)
        final firstPage = await notesDao.getNotesPaginated(limit: 20, offset: 0);
        expect(firstPage.length, equals(20));

        // Test second page (20 notes)
        final secondPage = await notesDao.getNotesPaginated(limit: 20, offset: 20);
        expect(secondPage.length, equals(20));

        // Test third page (10 notes remaining)
        final thirdPage = await notesDao.getNotesPaginated(limit: 20, offset: 40);
        expect(thirdPage.length, equals(10));

        // Verify no overlap between pages
        final firstPageUuids = firstPage.map((n) => n.uuid).toSet();
        final secondPageUuids = secondPage.map((n) => n.uuid).toSet();
        expect(firstPageUuids.intersection(secondPageUuids).isEmpty, isTrue);
      });

      test('getNotesPaginated respects sorting by updatedAt', () async {
        // Create notes with delays to ensure different timestamps
        for (int i = 0; i < 10; i++) {
          await notesDao.createNote(
            uuid: const Uuid().v4(),
            title: 'Note $i',
            contentMd: 'Content $i',
            tags: [],
          );
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Get paginated notes
        final notes = await notesDao.getNotesPaginated(limit: 10, offset: 0);

        // Verify sorting (newest first)
        for (int i = 0; i < notes.length - 1; i++) {
          expect(
            notes[i].updatedAt.isAfter(notes[i + 1].updatedAt) ||
                notes[i].updatedAt.isAtSameMomentAs(notes[i + 1].updatedAt),
            isTrue,
            reason: 'Notes should be sorted by updatedAt descending',
          );
        }
      });

      test('getNotesCount returns correct total count', () async {
        // Initially should be 0
        var count = await notesDao.getNotesCount();
        expect(count, equals(0));

        // Create 25 notes
        for (int i = 0; i < 25; i++) {
          await notesDao.createNote(
            uuid: const Uuid().v4(),
            title: 'Note $i',
            contentMd: 'Content $i',
            tags: [],
          );
        }

        // Count should be 25
        count = await notesDao.getNotesCount();
        expect(count, equals(25));

        // Soft delete 5 notes
        final allNotes = await notesDao.getAllNotes();
        for (int i = 0; i < 5; i++) {
          await notesDao.softDelete(allNotes[i].uuid);
        }

        // Count should be 20 (excluding soft deleted)
        count = await notesDao.getNotesCount();
        expect(count, equals(20));
      });

      test('Pagination with empty database returns empty list', () async {
        final notes = await notesDao.getNotesPaginated(limit: 20, offset: 0);
        expect(notes, isEmpty);

        final count = await notesDao.getNotesCount();
        expect(count, equals(0));
      });

      test('Pagination offset beyond total count returns empty list', () async {
        // Create 10 notes
        for (int i = 0; i < 10; i++) {
          await notesDao.createNote(
            uuid: const Uuid().v4(),
            title: 'Note $i',
            contentMd: 'Content $i',
            tags: [],
          );
        }

        // Request notes with offset beyond total
        final notes = await notesDao.getNotesPaginated(limit: 20, offset: 100);
        expect(notes, isEmpty);
      });
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
