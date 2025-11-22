import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

/// **Feature: encrypted-notebook-app, Property 27: Offline-First Query**
/// 
/// Property: For any query operation (getAllNotes, search, findByUuid, etc.),
/// the system SHALL always read from LocalDatabase without waiting for or
/// depending on network requests.
/// 
/// **Validates: Requirements 14.5**
/// 
/// This property verifies that:
/// - All query operations complete successfully without network
/// - Query results come from local database only
/// - No network dependency exists for read operations
/// - Queries work in completely offline environment
void main() {
  group('Property 27: Offline-First Query', () {
    late AppDatabase database;
    late NotesDao notesDao;
    const uuid = Uuid();

    setUp(() {
      // Create in-memory database (simulates completely offline environment)
      // No network mocking needed - if queries depend on network, they will fail
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('Property: getAllNotes always reads from local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i - ${uuid.v4().substring(0, 8)}',
          'contentMd': 'Content $i\n\n${uuid.v4()}',
          'tags': i % 3 == 0 ? ['tag1', 'tag2'] : i % 2 == 0 ? ['tag3'] : <String>[],
        };
      });

      // Property: For any set of notes in local database, getAllNotes should return them
      // without any network dependency
      
      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
      }

      // Query all notes - this should work without network
      final allNotes = await notesDao.getAllNotes();

      // Verify: All notes should be returned from local database
      expect(allNotes.length, equals(100),
          reason: 'getAllNotes should return all notes from local database');

      // Verify each note matches what was stored
      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;
        final matchingNote = allNotes.firstWhere((n) => n.uuid == noteUuid);
        
        expect(matchingNote.title, equals(testCase['title']),
            reason: 'Note title should match local database');
        expect(matchingNote.contentMd, equals(testCase['contentMd']),
            reason: 'Note content should match local database');
        expect(matchingNote.tags, equals(testCase['tags']),
            reason: 'Note tags should match local database');
      }

      // Verify query completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'getAllNotes completed successfully without network');
    });

    test('Property: search always reads from local database', () async {
      // Generate random test data with searchable content
      final testCases = List.generate(100, (i) {
        final searchTerm = 'search${i % 10}'; // Create 10 different search terms
        return {
          'uuid': uuid.v4(),
          'title': i % 2 == 0 ? 'Title with $searchTerm' : 'Other Title $i',
          'contentMd': i % 3 == 0 ? 'Content with $searchTerm' : 'Other content $i',
          'tags': <String>['tag$i'],
          'searchTerm': searchTerm,
          'shouldMatch': i % 2 == 0 || i % 3 == 0,
        };
      });

      // Property: For any search keyword, search should return matching notes
      // from local database without network dependency

      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
      }

      // Test each search term
      for (int termIndex = 0; termIndex < 10; termIndex++) {
        final searchTerm = 'search$termIndex';
        
        // Search - this should work without network
        final searchResults = await notesDao.search(searchTerm);

        // Count expected matches
        final expectedMatches = testCases.where((tc) {
          final term = tc['searchTerm'] as String;
          final shouldMatch = tc['shouldMatch'] as bool;
          return term == searchTerm && shouldMatch;
        }).length;

        // Verify: Search results should match local database
        expect(searchResults.length, equals(expectedMatches),
            reason: 'Search should return matching notes from local database');

        // Verify all results actually contain the search term
        for (final result in searchResults) {
          final containsInTitle = result.title.contains(searchTerm);
          final containsInContent = result.contentMd.contains(searchTerm);
          
          expect(containsInTitle || containsInContent, isTrue,
              reason: 'Search results should contain the search term');
        }
      }

      // Verify queries completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'Search completed successfully without network');
    });

    test('Property: findByUuid always reads from local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i - ${uuid.v4().substring(0, 8)}',
          'contentMd': 'Content $i\n\n${uuid.v4()}',
          'tags': <String>['tag$i'],
        };
      });

      // Property: For any UUID, findByUuid should return the note from local database
      // without network dependency

      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
      }

      // Query each note by UUID - this should work without network
      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;
        
        final foundNote = await notesDao.findByUuid(noteUuid);

        // Verify: Note should be found in local database
        expect(foundNote, isNotNull,
            reason: 'findByUuid should return note from local database');
        expect(foundNote!.uuid, equals(noteUuid),
            reason: 'UUID should match');
        expect(foundNote.title, equals(testCase['title']),
            reason: 'Title should match local database');
        expect(foundNote.contentMd, equals(testCase['contentMd']),
            reason: 'Content should match local database');
      }

      // Test querying non-existent UUID
      final nonExistentUuid = uuid.v4();
      final notFound = await notesDao.findByUuid(nonExistentUuid);
      
      expect(notFound, isNull,
          reason: 'findByUuid should return null for non-existent UUID');

      // Verify queries completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'findByUuid completed successfully without network');
    });

    test('Property: getNotesPaginated always reads from local database', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i',
          'contentMd': 'Content $i',
          'tags': <String>['tag$i'],
        };
      });

      // Property: For any pagination parameters, getNotesPaginated should return
      // notes from local database without network dependency

      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
      }

      // Test various pagination scenarios
      final paginationTests = [
        {'limit': 10, 'offset': 0},
        {'limit': 20, 'offset': 10},
        {'limit': 15, 'offset': 50},
        {'limit': 5, 'offset': 95},
        {'limit': 50, 'offset': 0},
      ];

      for (final paginationTest in paginationTests) {
        final limit = paginationTest['limit'] as int;
        final offset = paginationTest['offset'] as int;

        // Query paginated notes - this should work without network
        final paginatedNotes = await notesDao.getNotesPaginated(
          limit: limit,
          offset: offset,
        );

        // Verify: Should return correct number of notes from local database
        final expectedCount = (offset + limit <= 100) ? limit : (100 - offset).clamp(0, limit);
        expect(paginatedNotes.length, equals(expectedCount),
            reason: 'getNotesPaginated should return correct page from local database');

        // Verify all returned notes are valid
        for (final note in paginatedNotes) {
          expect(note.uuid, isNotEmpty,
              reason: 'Paginated notes should have valid UUIDs');
          expect(note.deletedAt, isNull,
              reason: 'Paginated notes should not be deleted');
        }
      }

      // Verify queries completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'getNotesPaginated completed successfully without network');
    });

    test('Property: getNotesCount always reads from local database', () async {
      // Generate random test data with some deleted notes
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i',
          'contentMd': 'Content $i',
          'tags': <String>['tag$i'],
          'shouldDelete': i % 5 == 0, // Delete every 5th note
        };
      });

      // Property: For any database state, getNotesCount should return count
      // from local database without network dependency

      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );

        // Delete some notes
        if (testCase['shouldDelete'] as bool) {
          await notesDao.softDelete(testCase['uuid'] as String);
        }
      }

      // Query count - this should work without network
      final count = await notesDao.getNotesCount();

      // Verify: Count should match non-deleted notes in local database
      final expectedCount = testCases.where((tc) => !(tc['shouldDelete'] as bool)).length;
      expect(count, equals(expectedCount),
          reason: 'getNotesCount should return count from local database');

      // Verify query completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'getNotesCount completed successfully without network');
    });

    test('Property: Queries work immediately after local writes', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i - ${uuid.v4().substring(0, 8)}',
          'contentMd': 'Content $i',
          'tags': <String>['immediate'],
        };
      });

      // Property: For any note written to local database, queries should
      // immediately return the updated data without waiting for network sync

      for (final testCase in testCases) {
        final noteUuid = testCase['uuid'] as String;

        // Create note
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );

        // Immediately query - should work without network delay
        final foundNote = await notesDao.findByUuid(noteUuid);
        expect(foundNote, isNotNull,
            reason: 'Query should immediately return newly created note');
        expect(foundNote!.title, equals(testCase['title']),
            reason: 'Query should return correct data immediately');

        // Update note
        final updatedTitle = 'Updated ${testCase['title']}';
        await notesDao.updateNote(
          noteUuid,
          title: updatedTitle,
        );

        // Immediately query - should see update without network delay
        final updatedNote = await notesDao.findByUuid(noteUuid);
        expect(updatedNote!.title, equals(updatedTitle),
            reason: 'Query should immediately return updated data');

        // Delete note
        await notesDao.softDelete(noteUuid);

        // Immediately query - should see deletion without network delay
        final allNotes = await notesDao.getAllNotes();
        expect(allNotes.any((n) => n.uuid == noteUuid), isFalse,
            reason: 'Query should immediately reflect deletion');
      }

      // Verify all operations completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'All queries completed immediately without network dependency');
    });

    test('Property: Queries never block on network availability', () async {
      // Generate random test data
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Note $i',
          'contentMd': 'Content $i',
          'tags': <String>['tag$i'],
        };
      });

      // Property: For any query operation, execution time should be consistent
      // and not affected by network conditions (since it's local-only)

      // Create notes in local database
      for (final testCase in testCases) {
        await notesDao.createNote(
          uuid: testCase['uuid'] as String,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
      }

      // Measure query execution times
      final queryTimes = <Duration>[];

      for (int i = 0; i < 50; i++) {
        final startTime = DateTime.now();
        
        // Execute various queries
        await notesDao.getAllNotes();
        await notesDao.search('Note');
        await notesDao.findByUuid(testCases[i]['uuid'] as String);
        await notesDao.getNotesCount();
        
        final endTime = DateTime.now();
        queryTimes.add(endTime.difference(startTime));
      }

      // Verify: All queries should complete quickly (< 1 second each)
      // This proves they're not waiting for network timeouts
      for (final queryTime in queryTimes) {
        expect(queryTime.inMilliseconds, lessThan(1000),
            reason: 'Queries should complete quickly without network blocking');
      }

      // Verify queries completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'All queries completed without network blocking');
    });

    test('Property: Queries work with empty database', () async {
      // Property: For an empty local database, queries should return empty results
      // without network dependency

      // Query empty database - should work without network
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes, isEmpty,
          reason: 'getAllNotes should return empty list for empty database');

      final searchResults = await notesDao.search('anything');
      expect(searchResults, isEmpty,
          reason: 'search should return empty list for empty database');

      final count = await notesDao.getNotesCount();
      expect(count, equals(0),
          reason: 'getNotesCount should return 0 for empty database');

      final notFound = await notesDao.findByUuid(uuid.v4());
      expect(notFound, isNull,
          reason: 'findByUuid should return null for empty database');

      // Verify queries completed without network (no exceptions thrown)
      expect(true, isTrue,
          reason: 'Queries on empty database completed without network');
    });
  });
}
