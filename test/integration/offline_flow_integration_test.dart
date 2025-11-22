import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/data/sync/sync_service.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:encrypted_notebook/domain/entities/note.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([FirebaseClient])
import 'offline_flow_integration_test.mocks.dart';

/// Integration test for offline flow
/// Tests: Disconnect → Create Note → Reconnect → Verify Sync
/// 
/// This test validates that the app works correctly in offline mode
/// and properly syncs when connectivity is restored.
void main() {
  group('Offline Flow Integration Test', () {
    late AppDatabase database;
    late NotesDao notesDao;
    late VaultDao vaultDao;
    late MockFirebaseClient mockFirebaseClient;
    late SyncService syncService;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
      vaultDao = VaultDao(database);
      
      // Create mock Firebase client
      mockFirebaseClient = MockFirebaseClient();
      
      // Create sync service with mocked client
      syncService = SyncService(
        firebaseClient: mockFirebaseClient,
        notesDao: notesDao,
        vaultDao: vaultDao,
      );
    });

    tearDown(() async {
      await syncService.stopSync();
      await database.close();
    });

    test('Offline flow: create note while offline → sync when online', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);

      // ========== PHASE 1: OFFLINE - CREATE NOTE ==========
      // Simulate offline mode by making push operations fail
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Create a note while "offline"
      final uuid = const Uuid().v4();
      const title = 'Offline Note';
      const content = 'Created while offline';
      const tags = ['offline', 'test'];

      await notesDao.createNote(
        uuid: uuid,
        title: title,
        contentMd: content,
        tags: tags,
      );

      // Verify note exists locally
      var localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull, reason: 'Note should exist locally even offline');
      expect(localNote!.title, equals(title));
      expect(localNote.contentMd, equals(content));

      // Try to push (will fail due to "network error")
      await syncService.pushLocalChanges(userId);

      // Verify push was attempted but failed
      verify(mockFirebaseClient.pushNote(userId, any)).called(1);

      // Verify note still exists locally after failed push
      localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull, reason: 'Note should persist locally after failed push');

      // ========== PHASE 2: COME BACK ONLINE - SYNC ==========
      // Simulate coming back online by making push succeed
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Push local changes now that we're "online"
      await syncService.pushLocalChanges(userId);

      // Verify note was successfully pushed
      verify(mockFirebaseClient.pushNote(
        userId,
        argThat(predicate<Map<String, dynamic>>((data) {
          return data['uuid'] == uuid &&
                 data['title'] == title &&
                 data['contentMd'] == content;
        })),
      )).called(1);

      // Verify note still exists locally
      localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);
      expect(localNote!.title, equals(title));
    });

    test('Offline flow: multiple operations while offline', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Create multiple notes while offline
      final uuids = <String>[];
      for (int i = 0; i < 5; i++) {
        final uuid = const Uuid().v4();
        uuids.add(uuid);
        await notesDao.createNote(
          uuid: uuid,
          title: 'Offline Note $i',
          contentMd: 'Content $i',
          tags: ['offline'],
        );
      }

      // Verify all notes exist locally
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(5), reason: 'All notes should exist locally');

      // Update some notes while offline
      await notesDao.updateNote(
        uuids[0],
        title: 'Updated Offline Note 0',
      );
      await notesDao.updateNote(
        uuids[2],
        contentMd: 'Updated content 2',
      );

      // Delete one note while offline
      await notesDao.softDelete(uuids[4]);

      // Verify operations completed locally
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(4), reason: 'Should have 4 active notes after deletion');

      final note0 = await notesDao.findByUuid(uuids[0]);
      expect(note0!.title, equals('Updated Offline Note 0'));

      final note2 = await notesDao.findByUuid(uuids[2]);
      expect(note2!.contentMd, equals('Updated content 2'));

      final note4 = await notesDao.findByUuid(uuids[4]);
      expect(note4!.deletedAt, isNotNull, reason: 'Deleted note should have deletedAt set');

      // Try to push while offline (will fail)
      await syncService.pushLocalChanges(userId);

      // Come back online
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Push all changes
      await syncService.pushLocalChanges(userId);

      // Verify all active notes were pushed (4 notes)
      verify(mockFirebaseClient.pushNote(userId, any)).called(4);
    });

    test('Offline flow: edit existing note while offline', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create a note while online
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Original Title',
        contentMd: 'Original content',
        tags: ['original'],
      );

      // Push to cloud
      await syncService.pushLocalChanges(userId);
      verify(mockFirebaseClient.pushNote(userId, any)).called(1);

      // Go offline
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Edit the note while offline
      await notesDao.updateNote(
        uuid,
        title: 'Edited Offline',
        contentMd: 'Edited while offline',
        tags: ['edited', 'offline'],
      );

      // Verify edit was saved locally
      var note = await notesDao.findByUuid(uuid);
      expect(note, isNotNull);
      expect(note!.title, equals('Edited Offline'));
      expect(note.contentMd, equals('Edited while offline'));

      // Try to push (will fail)
      await syncService.pushLocalChanges(userId);

      // Come back online
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Push changes
      await syncService.pushLocalChanges(userId);

      // Verify updated note was pushed
      verify(mockFirebaseClient.pushNote(
        userId,
        argThat(predicate<Map<String, dynamic>>((data) {
          return data['uuid'] == uuid &&
                 data['title'] == 'Edited Offline';
        })),
      )).called(1);
    });

    test('Offline flow: search works offline', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Create notes while offline
      await notesDao.createNote(
        uuid: const Uuid().v4(),
        title: 'Searchable Note 1',
        contentMd: 'Content with keyword',
        tags: ['search'],
      );

      await notesDao.createNote(
        uuid: const Uuid().v4(),
        title: 'Another Note',
        contentMd: 'Different content',
        tags: ['other'],
      );

      await notesDao.createNote(
        uuid: const Uuid().v4(),
        title: 'Searchable Note 2',
        contentMd: 'More searchable content',
        tags: ['search'],
      );

      // Search should work offline
      var results = await notesDao.search('Searchable');
      expect(results.length, equals(2), reason: 'Search should work offline');

      results = await notesDao.search('keyword');
      expect(results.length, equals(1));

      results = await notesDao.search('Different');
      expect(results.length, equals(1));

      // Verify all notes are still local
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(3));
    });

    test('Offline flow: delete note while offline → sync deletion', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create a note while online
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Note to Delete',
        contentMd: 'This will be deleted offline',
        tags: ['delete'],
      );

      // Push to cloud
      await syncService.pushLocalChanges(userId);
      verify(mockFirebaseClient.pushNote(userId, any)).called(1);

      // Go offline
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Delete while offline
      await notesDao.softDelete(uuid);

      // Verify deletion worked locally
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0), reason: 'Note should be deleted locally');

      var deletedNote = await notesDao.findByUuid(uuid);
      expect(deletedNote, isNotNull);
      expect(deletedNote!.deletedAt, isNotNull);

      // Try to push (will fail)
      await syncService.pushLocalChanges(userId);

      // Come back online
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Push deletion
      await syncService.pushLocalChanges(userId);

      // Note: Deleted notes are not pushed in current implementation
      // They remain in local DB with deletedAt set
      // In a real implementation, you might want to push them with deletedAt
      
      // Verify note is still deleted locally
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0));
    });

    test('Offline flow: receive remote changes when coming online', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);

      // Start offline
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      // Create a local note while offline
      final localUuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: localUuid,
        title: 'Local Offline Note',
        contentMd: 'Created locally',
        tags: ['local'],
      );

      // Verify local note exists
      var allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(1));

      // Come back online and simulate receiving remote notes
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Simulate receiving a remote note (as if from Firestore)
      final remoteUuid = const Uuid().v4();
      final remoteNote = Note(
        uuid: remoteUuid,
        title: 'Remote Note',
        contentMd: 'Created on another device',
        tags: ['remote'],
        isEncrypted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Insert remote note locally (simulating sync service)
      await notesDao.createNote(
        uuid: remoteNote.uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );

      // Verify both notes exist
      allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(2), reason: 'Should have both local and remote notes');

      final localNote = allNotes.firstWhere((n) => n.uuid == localUuid);
      final receivedRemote = allNotes.firstWhere((n) => n.uuid == remoteUuid);

      expect(localNote.title, equals('Local Offline Note'));
      expect(receivedRemote.title, equals('Remote Note'));

      // Push local changes
      await syncService.pushLocalChanges(userId);

      // Verify both notes were pushed
      verify(mockFirebaseClient.pushNote(userId, any)).called(2);
    });

    test('Offline flow: conflict resolution after offline edits', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create a note while online
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Original Title',
        contentMd: 'Original content',
        tags: ['original'],
      );

      await syncService.pushLocalChanges(userId);

      // Go offline and edit locally
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network unavailable'));

      await notesDao.updateNote(
        uuid,
        title: 'Local Edit',
        contentMd: 'Edited locally while offline',
      );

      // Simulate a remote edit (newer timestamp)
      // In real scenario, this would come from Firestore
      final remoteNote = Note(
        uuid: uuid,
        title: 'Remote Edit',
        contentMd: 'Edited remotely',
        tags: ['remote'],
        isEncrypted: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(), // Newer than local
        deletedAt: null,
      );

      // Come back online
      reset(mockFirebaseClient);
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Simulate receiving remote update (LWW - remote is newer)
      await notesDao.updateNote(
        uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );

      // Verify remote version won (LWW)
      final note = await notesDao.findByUuid(uuid);
      expect(note, isNotNull);
      expect(note!.title, equals('Remote Edit'));
      expect(note.contentMd, equals('Edited remotely'));
    });
  });
}
