import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

/// Integration test for the complete notes flow
/// Tests: Create → Edit → Search → Delete
/// 
/// This test validates the entire lifecycle of a note from creation to deletion,
/// ensuring all operations work together correctly.
void main() {
  group('Notes Complete Flow Integration Test', () {
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

    test('Complete notes flow: create → edit → search → delete', () async {
      // ========== STEP 1: CREATE NOTE ==========
      final uuid = const Uuid().v4();
      const initialTitle = 'Integration Test Note';
      const initialContent = 'This is the initial content for testing';
      const initialTags = ['test', 'integration'];

      // Create the note
      final noteId = await notesDao.createNote(
        uuid: uuid,
        title: initialTitle,
        contentMd: initialContent,
        tags: initialTags,
      );

      expect(noteId, greaterThan(0), reason: 'Note should be created with valid ID');

      // Verify note was created correctly
      var note = await notesDao.findByUuid(uuid);
      expect(note, isNotNull, reason: 'Created note should be retrievable');
      expect(note!.uuid, equals(uuid));
      expect(note.title, equals(initialTitle));
      expect(note.contentMd, equals(initialContent));
      expect(note.tags, equals(initialTags));
      expect(note.deletedAt, isNull, reason: 'New note should not be deleted');

      // Verify note appears in list
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(1), reason: 'Should have exactly one note');
      expect(allNotes.first.uuid, equals(uuid));

      // ========== STEP 2: EDIT NOTE ==========
      const updatedTitle = 'Updated Integration Test Note';
      const updatedContent = 'This content has been updated during the test';
      const updatedTags = ['test', 'integration', 'updated'];

      // Wait a bit to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 50));

      // Update the note
      final updateCount = await notesDao.updateNote(
        uuid,
        title: updatedTitle,
        contentMd: updatedContent,
        tags: updatedTags,
      );

      expect(updateCount, equals(1), reason: 'Should update exactly one note');

      // Verify note was updated correctly
      note = await notesDao.findByUuid(uuid);
      expect(note, isNotNull, reason: 'Updated note should be retrievable');
      expect(note!.title, equals(updatedTitle));
      expect(note.contentMd, equals(updatedContent));
      expect(note.tags, equals(updatedTags));
      expect(
        note.updatedAt.isAfter(note.createdAt),
        isTrue,
        reason: 'updatedAt should be after createdAt',
      );

      // ========== STEP 3: SEARCH NOTE ==========
      // Search by title keyword
      var searchResults = await notesDao.search('Updated');
      expect(searchResults.length, equals(1), reason: 'Should find note by title keyword');
      expect(searchResults.first.uuid, equals(uuid));

      // Search by content keyword
      searchResults = await notesDao.search('updated during');
      expect(searchResults.length, equals(1), reason: 'Should find note by content keyword');
      expect(searchResults.first.uuid, equals(uuid));

      // Search by tag (tags are in JSON, so this might not match)
      // But we can search for a word that appears in title or content
      searchResults = await notesDao.search('Integration');
      expect(searchResults.length, equals(1), reason: 'Should find note by common keyword');

      // Search with non-matching keyword
      searchResults = await notesDao.search('nonexistent');
      expect(searchResults.length, equals(0), reason: 'Should not find note with non-matching keyword');

      // ========== STEP 4: DELETE NOTE ==========
      // Soft delete the note
      final deleteCount = await notesDao.softDelete(uuid);
      expect(deleteCount, equals(1), reason: 'Should delete exactly one note');

      // Verify note no longer appears in active list
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0), reason: 'Deleted note should not appear in active list');

      // Verify note no longer appears in search results
      searchResults = await notesDao.search('Updated');
      expect(searchResults.length, equals(0), reason: 'Deleted note should not appear in search');

      // Verify note still exists in database with deletedAt set
      note = await notesDao.findByUuid(uuid);
      expect(note, isNotNull, reason: 'Deleted note should still exist in database');
      expect(note!.deletedAt, isNotNull, reason: 'Deleted note should have deletedAt set');
      expect(note.title, equals(updatedTitle), reason: 'Deleted note should preserve data');
      expect(note.contentMd, equals(updatedContent), reason: 'Deleted note should preserve data');
    });

    test('Multiple notes flow with interleaved operations', () async {
      // Create multiple notes
      final note1Uuid = const Uuid().v4();
      final note2Uuid = const Uuid().v4();
      final note3Uuid = const Uuid().v4();

      await notesDao.createNote(
        uuid: note1Uuid,
        title: 'First Note',
        contentMd: 'Content of first note',
        tags: ['first'],
      );

      await notesDao.createNote(
        uuid: note2Uuid,
        title: 'Second Note',
        contentMd: 'Content of second note',
        tags: ['second'],
      );

      await notesDao.createNote(
        uuid: note3Uuid,
        title: 'Third Note',
        contentMd: 'Content of third note',
        tags: ['third'],
      );

      // Verify all notes exist
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(3), reason: 'Should have three notes');

      // Edit the second note
      await notesDao.updateNote(
        note2Uuid,
        title: 'Updated Second Note',
        contentMd: 'Updated content of second note',
      );

      // Search should find the updated note
      var searchResults = await notesDao.search('Updated Second');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.uuid, equals(note2Uuid));

      // Delete the first note
      await notesDao.softDelete(note1Uuid);

      // Verify only two notes remain
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(2), reason: 'Should have two active notes after deletion');
      expect(allNotes.any((n) => n.uuid == note1Uuid), isFalse);
      expect(allNotes.any((n) => n.uuid == note2Uuid), isTrue);
      expect(allNotes.any((n) => n.uuid == note3Uuid), isTrue);

      // Search should not find deleted note
      searchResults = await notesDao.search('First');
      expect(searchResults.length, equals(0), reason: 'Should not find deleted note');

      // Edit the third note
      await notesDao.updateNote(
        note3Uuid,
        title: 'Modified Third Note',
      );

      // Search should find the modified note
      searchResults = await notesDao.search('Modified');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.uuid, equals(note3Uuid));

      // Delete remaining notes
      await notesDao.softDelete(note2Uuid);
      await notesDao.softDelete(note3Uuid);

      // Verify no active notes remain
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0), reason: 'Should have no active notes');

      // But all notes should still exist in database
      final note1 = await notesDao.findByUuid(note1Uuid);
      final note2 = await notesDao.findByUuid(note2Uuid);
      final note3 = await notesDao.findByUuid(note3Uuid);
      expect(note1, isNotNull);
      expect(note2, isNotNull);
      expect(note3, isNotNull);
      expect(note1!.deletedAt, isNotNull);
      expect(note2!.deletedAt, isNotNull);
      expect(note3!.deletedAt, isNotNull);
    });

    test('Notes flow with empty and special content', () async {
      // Create note with empty content
      final emptyUuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: emptyUuid,
        title: '',
        contentMd: '',
        tags: [],
      );

      var note = await notesDao.findByUuid(emptyUuid);
      expect(note, isNotNull);
      expect(note!.title, equals(''));
      expect(note.contentMd, equals(''));
      expect(note.tags, isEmpty);

      // Update with special characters
      await notesDao.updateNote(
        emptyUuid,
        title: 'Special: 你好 😀 "quotes" \'apostrophe\'',
        contentMd: 'Content with\nnewlines\tand\ttabs',
        tags: ['tag-with-dash', 'tag_with_underscore', '标签'],
      );

      note = await notesDao.findByUuid(emptyUuid);
      expect(note, isNotNull);
      expect(note!.title, contains('你好'));
      expect(note.title, contains('😀'));
      expect(note.contentMd, contains('\n'));
      expect(note.contentMd, contains('\t'));
      expect(note.tags.length, equals(3));

      // Search with special characters
      var searchResults = await notesDao.search('你好');
      expect(searchResults.length, equals(1));

      // Delete and verify
      await notesDao.softDelete(emptyUuid);
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0));
    });

    test('Notes flow with concurrent-like operations', () async {
      // Create multiple notes rapidly
      final uuids = <String>[];
      for (int i = 0; i < 10; i++) {
        final uuid = const Uuid().v4();
        uuids.add(uuid);
        await notesDao.createNote(
          uuid: uuid,
          title: 'Note $i',
          contentMd: 'Content $i',
          tags: ['tag$i'],
        );
      }

      // Verify all created
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(10));

      // Update all notes
      for (int i = 0; i < 10; i++) {
        await notesDao.updateNote(
          uuids[i],
          title: 'Updated Note $i',
        );
      }

      // Verify all updated
      for (int i = 0; i < 10; i++) {
        final note = await notesDao.findByUuid(uuids[i]);
        expect(note, isNotNull);
        expect(note!.title, equals('Updated Note $i'));
      }

      // Delete half of them
      for (int i = 0; i < 5; i++) {
        await notesDao.softDelete(uuids[i]);
      }

      // Verify correct count
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(5));

      // Search should only find active notes
      var searchResults = await notesDao.search('Updated');
      expect(searchResults.length, equals(5));

      // Delete remaining
      for (int i = 5; i < 10; i++) {
        await notesDao.softDelete(uuids[i]);
      }

      // Verify all deleted
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0));
    });
  });
}
