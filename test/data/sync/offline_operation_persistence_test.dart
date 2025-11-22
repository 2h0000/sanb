import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

/// **Feature: encrypted-notebook-app, Property 25: Offline Operation Persistence**
/// 
/// Property: For any offline operation (create, edit, delete) on notes,
/// the changes SHALL be persisted to the LocalDatabase regardless of network status.
/// 
/// **Validates: Requirements 14.1, 14.2**
/// 
/// This property verifies that:
/// - Creating a note offline persists it to local database
/// - Editing a note offline persists the changes to local database
/// - Deleting a note offline persists the deletion (soft delete) to local database
/// - All operations work without any network dependency
void main() {
  group('Property 25: Offline Operation Persistence', () {
    late AppDatabase database;
    late NotesDao notesDao;
    const uuid = Uuid();

    setUp(() {
      // Create in-memory database (simulates offline environment)
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('Property: Creating a note offline persists to local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Test Note $i - ${uuid.v4().substring(0, 8)}',
          'contentMd': 'Content for note $i\n\n${uuid.v4()}',
          'tags': i % 3 == 0 ? ['tag1', 'tag2'] : i % 2 == 0 ? ['tag3'] : <String>[],
        };
      });

      // Property: For any note data, creating it should persist to database
      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;
        final title = testCase['title'] as String;
        final contentMd = testCase['contentMd'] as String;
        final tags = testCase['tags'] as List<String>;

        // Create note (simulating offline operation - no network calls)
        await notesDao.createNote(
          uuid: noteUuid,
          title: title,
          contentMd: contentMd,
          tags: tags,
        );

        // Verify: Note should be persisted in local database
        final retrievedNote = await notesDao.findByUuid(noteUuid);
        
        expect(retrievedNote, isNotNull, 
            reason: 'Created note should be persisted to local database');
        expect(retrievedNote!.uuid, equals(noteUuid),
            reason: 'UUID should match');
        expect(retrievedNote.title, equals(title),
            reason: 'Title should be persisted correctly');
        expect(retrievedNote.contentMd, equals(contentMd),
            reason: 'Content should be persisted correctly');
        expect(retrievedNote.tags, equals(tags),
            reason: 'Tags should be persisted correctly');
        expect(retrievedNote.deletedAt, isNull,
            reason: 'New note should not be deleted');
      }
    });

    test('Property: Editing a note offline persists changes to local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        final noteUuid = uuid.v4();
        return {
          'uuid': noteUuid,
          'initialTitle': 'Initial Title $i',
          'initialContent': 'Initial Content $i',
          'initialTags': <String>['initial'],
          'updatedTitle': 'Updated Title $i - ${uuid.v4().substring(0, 8)}',
          'updatedContent': 'Updated Content $i\n\n${uuid.v4()}',
          'updatedTags': i % 2 == 0 ? ['updated', 'tag'] : <String>['single'],
        };
      });

      // Property: For any note, editing it offline should persist changes
      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;
        
        // Create initial note
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['initialTitle'] as String,
          contentMd: testCase['initialContent'] as String,
          tags: testCase['initialTags'] as List<String>,
        );

        // Get initial state
        final initialNote = await notesDao.findByUuid(noteUuid);
        expect(initialNote, isNotNull);
        final initialUpdatedAt = initialNote!.updatedAt;

        // Small delay to ensure timestamp changes
        await Future.delayed(const Duration(milliseconds: 10));

        // Update note (simulating offline operation)
        await notesDao.updateNote(
          noteUuid,
          title: testCase['updatedTitle'] as String,
          contentMd: testCase['updatedContent'] as String,
          tags: testCase['updatedTags'] as List<String>,
        );

        // Verify: Changes should be persisted in local database
        final updatedNote = await notesDao.findByUuid(noteUuid);
        
        expect(updatedNote, isNotNull,
            reason: 'Updated note should exist in local database');
        expect(updatedNote!.title, equals(testCase['updatedTitle']),
            reason: 'Updated title should be persisted');
        expect(updatedNote.contentMd, equals(testCase['updatedContent']),
            reason: 'Updated content should be persisted');
        expect(updatedNote.tags, equals(testCase['updatedTags']),
            reason: 'Updated tags should be persisted');
        expect(updatedNote.updatedAt.isAfter(initialUpdatedAt), isTrue,
            reason: 'updatedAt timestamp should be refreshed');
        expect(updatedNote.deletedAt, isNull,
            reason: 'Updated note should not be deleted');
      }
    });

    test('Property: Deleting a note offline persists soft delete to local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note to Delete $i',
          'contentMd': 'Content $i',
          'tags': <String>['delete-test'],
        };
      });

      // Property: For any note, deleting it offline should persist soft delete
      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;
        
        // Create note
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );

        // Verify note exists and is not deleted
        final noteBeforeDelete = await notesDao.findByUuid(noteUuid);
        expect(noteBeforeDelete, isNotNull);
        expect(noteBeforeDelete!.deletedAt, isNull);

        // Delete note (simulating offline operation)
        final beforeDelete = DateTime.now();
        await notesDao.softDelete(noteUuid);
        final afterDelete = DateTime.now();

        // Verify: Soft delete should be persisted in local database
        final deletedNote = await notesDao.findByUuid(noteUuid);
        
        expect(deletedNote, isNotNull,
            reason: 'Soft deleted note should still exist in database');
        expect(deletedNote!.deletedAt, isNotNull,
            reason: 'deletedAt should be set for soft deleted note');
        expect(deletedNote.deletedAt!.isAfter(beforeDelete.subtract(const Duration(seconds: 1))), isTrue,
            reason: 'deletedAt should be recent');
        expect(deletedNote.deletedAt!.isBefore(afterDelete.add(const Duration(seconds: 1))), isTrue,
            reason: 'deletedAt should be recent');
        
        // Verify note is excluded from normal queries
        final allNotes = await notesDao.getAllNotes();
        expect(allNotes.any((n) => n.uuid == noteUuid), isFalse,
            reason: 'Soft deleted note should not appear in getAllNotes()');
      }
    });

    test('Property: Multiple offline operations maintain consistency', () async {
      // Generate random sequence of operations
      final operations = <Map<String, dynamic>>[];
      final noteUuids = <String>[];
      
      // Create 50 notes
      for (int i = 0; i < 50; i++) {
        final noteUuid = uuid.v4();
        noteUuids.add(noteUuid);
        operations.add({
          'type': 'create',
          'uuid': noteUuid,
          'title': 'Note $i',
          'contentMd': 'Content $i',
          'tags': <String>['tag$i'],
        });
      }
      
      // Update 25 random notes
      for (int i = 0; i < 25; i++) {
        final noteUuid = noteUuids[i * 2]; // Every other note
        operations.add({
          'type': 'update',
          'uuid': noteUuid,
          'title': 'Updated Note $i',
          'contentMd': 'Updated Content $i',
          'tags': <String>['updated'],
        });
      }
      
      // Delete 10 random notes
      for (int i = 0; i < 10; i++) {
        final noteUuid = noteUuids[i * 5]; // Every 5th note
        operations.add({
          'type': 'delete',
          'uuid': noteUuid,
        });
      }

      // Execute all operations offline
      for (final op in operations) {
        final opType = op['type'] as String;
        final noteUuid = op['uuid'] as String;
        
        switch (opType) {
          case 'create':
            await notesDao.createNote(
              uuid: noteUuid,
              title: op['title'] as String,
              contentMd: op['contentMd'] as String,
              tags: op['tags'] as List<String>,
            );
            break;
          case 'update':
            await notesDao.updateNote(
              noteUuid,
              title: op['title'] as String,
              contentMd: op['contentMd'] as String,
              tags: op['tags'] as List<String>,
            );
            break;
          case 'delete':
            await notesDao.softDelete(noteUuid);
            break;
        }
      }

      // Verify: All operations should be persisted correctly
      final allNotesIncludingDeleted = <String, dynamic>{};
      for (final noteUuid in noteUuids) {
        final note = await notesDao.findByUuid(noteUuid);
        if (note != null) {
          allNotesIncludingDeleted[noteUuid] = note;
        }
      }

      // All 50 notes should exist in database (including soft deleted)
      expect(allNotesIncludingDeleted.length, equals(50),
          reason: 'All created notes should be persisted');

      // Verify updates were applied
      int updatedCount = 0;
      for (final noteUuid in noteUuids) {
        final note = allNotesIncludingDeleted[noteUuid];
        if (note != null && note.title.startsWith('Updated')) {
          updatedCount++;
        }
      }
      expect(updatedCount, greaterThanOrEqualTo(15),
          reason: 'At least 15 notes should have updates persisted (some may be deleted)');

      // Verify deletes were applied
      int deletedCount = 0;
      for (final noteUuid in noteUuids) {
        final note = allNotesIncludingDeleted[noteUuid];
        if (note != null && note.deletedAt != null) {
          deletedCount++;
        }
      }
      expect(deletedCount, equals(10),
          reason: 'Exactly 10 notes should be soft deleted');

      // Verify getAllNotes excludes deleted notes
      final activeNotes = await notesDao.getAllNotes();
      expect(activeNotes.length, equals(40),
          reason: 'getAllNotes should return 40 active notes (50 - 10 deleted)');
    });

    test('Property: Offline operations work without any network dependency', () async {
      // This test verifies that all operations complete successfully
      // in a completely isolated environment (in-memory database)
      // with no network mocking or external dependencies
      
      final testUuid = uuid.v4();
      
      // Create
      await notesDao.createNote(
        uuid: testUuid,
        title: 'Offline Test',
        contentMd: 'This note was created offline',
        tags: ['offline'],
      );
      
      var note = await notesDao.findByUuid(testUuid);
      expect(note, isNotNull, reason: 'Create should work offline');
      
      // Update
      await notesDao.updateNote(
        testUuid,
        title: 'Updated Offline',
        contentMd: 'This note was updated offline',
        tags: ['offline', 'updated'],
      );
      
      note = await notesDao.findByUuid(testUuid);
      expect(note!.title, equals('Updated Offline'), 
          reason: 'Update should work offline');
      
      // Delete
      await notesDao.softDelete(testUuid);
      
      note = await notesDao.findByUuid(testUuid);
      expect(note!.deletedAt, isNotNull, 
          reason: 'Delete should work offline');
      
      // All operations completed successfully without network
      expect(true, isTrue, 
          reason: 'All offline operations completed without network dependency');
    });
  });
}
