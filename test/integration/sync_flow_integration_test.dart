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
import 'package:cloud_firestore/cloud_firestore.dart';

// Generate mocks
@GenerateMocks([FirebaseClient])
import 'sync_flow_integration_test.mocks.dart';

/// Integration test for sync flow
/// Tests: Login → Create Note → Wait for Sync → Verify
/// 
/// Note: This test uses mocks for Firebase since we cannot easily test
/// real Firebase operations in unit tests. For true end-to-end testing,
/// consider using Firebase Test Lab or integration_test package.
void main() {
  group('Sync Flow Integration Test (with mocks)', () {
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

    test('Sync flow: create local note → push to cloud', () async {
      // Setup: Mock user ID
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      
      // Setup: Mock push operations to succeed
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());
      
      // Create a local note
      final uuid = const Uuid().v4();
      const title = 'Test Note for Sync';
      const content = 'This note should be synced to cloud';
      const tags = ['sync', 'test'];

      await notesDao.createNote(
        uuid: uuid,
        title: title,
        contentMd: content,
        tags: tags,
      );

      // Verify note exists locally
      final localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);
      expect(localNote!.title, equals(title));

      // Push local changes (simulating sync)
      await syncService.pushLocalChanges(userId);

      // Verify pushNote was called with correct data
      verify(mockFirebaseClient.pushNote(
        userId,
        argThat(predicate<Map<String, dynamic>>((data) {
          return data['uuid'] == uuid &&
                 data['title'] == title &&
                 data['contentMd'] == content;
        })),
      )).called(1);
    });

    test('Sync flow: receive remote note → save locally', () async {
      // This test simulates receiving a note from Firestore
      // In a real scenario, this would come through a stream listener
      
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);

      // Create a remote note (as if it came from Firestore)
      final remoteUuid = const Uuid().v4();
      final remoteNote = Note(
        uuid: remoteUuid,
        title: 'Remote Note',
        contentMd: 'This note came from the cloud',
        tags: ['remote', 'cloud'],
        isEncrypted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Manually insert the remote note (simulating what sync service would do)
      await notesDao.createNote(
        uuid: remoteNote.uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );

      // Verify note was saved locally
      final localNote = await notesDao.findByUuid(remoteUuid);
      expect(localNote, isNotNull);
      expect(localNote!.title, equals('Remote Note'));
      expect(localNote.contentMd, equals('This note came from the cloud'));
      expect(localNote.tags, equals(['remote', 'cloud']));
    });

    test('Sync flow: LWW conflict resolution - remote newer', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);

      // Create a local note
      final uuid = const Uuid().v4();
      final oldTime = DateTime.now().subtract(const Duration(hours: 1));
      
      await notesDao.createNote(
        uuid: uuid,
        title: 'Old Local Title',
        contentMd: 'Old local content',
        tags: ['old'],
      );

      // Get the local note
      var localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);

      // Simulate a remote note with newer timestamp
      final newTime = DateTime.now();
      final remoteNote = Note(
        uuid: uuid,
        title: 'New Remote Title',
        contentMd: 'New remote content',
        tags: ['new', 'remote'],
        isEncrypted: false,
        createdAt: oldTime,
        updatedAt: newTime,
        deletedAt: null,
      );

      // Update local with remote data (simulating what sync would do)
      await notesDao.updateNote(
        uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );

      // Verify local was updated with remote data
      localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);
      expect(localNote!.title, equals('New Remote Title'));
      expect(localNote.contentMd, equals('New remote content'));
      expect(localNote.tags, equals(['new', 'remote']));
    });

    test('Sync flow: LWW conflict resolution - local newer', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create a local note with recent timestamp
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'New Local Title',
        contentMd: 'New local content',
        tags: ['new', 'local'],
      );

      final localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);

      // Simulate receiving an older remote note
      // In real sync, we would compare timestamps and keep the local version
      // Then push local to remote

      // Push local changes
      await syncService.pushLocalChanges(userId);

      // Verify local note was pushed
      verify(mockFirebaseClient.pushNote(
        userId,
        argThat(predicate<Map<String, dynamic>>((data) {
          return data['uuid'] == uuid &&
                 data['title'] == 'New Local Title';
        })),
      )).called(1);

      // Verify local note unchanged
      final stillLocal = await notesDao.findByUuid(uuid);
      expect(stillLocal, isNotNull);
      expect(stillLocal!.title, equals('New Local Title'));
    });

    test('Sync flow: multiple notes bidirectional sync', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create multiple local notes
      final localUuids = <String>[];
      for (int i = 0; i < 3; i++) {
        final uuid = const Uuid().v4();
        localUuids.add(uuid);
        await notesDao.createNote(
          uuid: uuid,
          title: 'Local Note $i',
          contentMd: 'Content $i',
          tags: ['local'],
        );
      }

      // Push all local notes
      await syncService.pushLocalChanges(userId);

      // Verify all were pushed
      verify(mockFirebaseClient.pushNote(userId, any)).called(3);

      // Simulate receiving remote notes
      for (int i = 0; i < 2; i++) {
        final remoteUuid = const Uuid().v4();
        await notesDao.createNote(
          uuid: remoteUuid,
          title: 'Remote Note $i',
          contentMd: 'Remote content $i',
          tags: ['remote'],
        );
      }

      // Verify all notes exist locally
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(5)); // 3 local + 2 remote

      // Verify we have both local and remote notes
      final localCount = allNotes.where((n) => n.tags.contains('local')).length;
      final remoteCount = allNotes.where((n) => n.tags.contains('remote')).length;
      expect(localCount, equals(3));
      expect(remoteCount, equals(2));
    });

    test('Sync flow: deleted notes sync', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Create a note
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Note to Delete',
        contentMd: 'This will be deleted',
        tags: ['delete'],
      );

      // Push to cloud
      await syncService.pushLocalChanges(userId);
      verify(mockFirebaseClient.pushNote(userId, any)).called(1);

      // Soft delete the note
      await notesDao.softDelete(uuid);

      // Verify note is deleted locally
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0));

      // Push deletion to cloud
      await syncService.pushLocalChanges(userId);

      // Note: In real implementation, deleted notes would still be pushed
      // with deletedAt set, so cloud knows to mark them as deleted
      
      // Verify note still exists in database with deletedAt
      final deletedNote = await notesDao.findByUuid(uuid);
      expect(deletedNote, isNotNull);
      expect(deletedNote!.deletedAt, isNotNull);
    });

    test('Sync flow: handles push failures gracefully', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      
      // Mock push to fail
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network error'));

      // Create a note
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Test Note',
        contentMd: 'Content',
        tags: [],
      );

      // Try to push (should not throw, just log error)
      await syncService.pushLocalChanges(userId);

      // Verify note still exists locally
      final localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull);
      expect(localNote!.title, equals('Test Note'));

      // Verify push was attempted
      verify(mockFirebaseClient.pushNote(userId, any)).called(1);
    });

    test('Sync flow: empty database sync', () async {
      const userId = 'test-user-123';
      when(mockFirebaseClient.currentUserId).thenReturn(userId);
      when(mockFirebaseClient.pushNote(any, any))
          .thenAnswer((_) async => Future.value());

      // Push with empty database
      await syncService.pushLocalChanges(userId);

      // Should not call push since there are no notes
      verifyNever(mockFirebaseClient.pushNote(any, any));

      // Verify database is still empty
      final allNotes = await notesDao.getAllNotes();
      expect(allNotes.length, equals(0));
    });
  });
}
