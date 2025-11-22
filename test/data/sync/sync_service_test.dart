import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:encrypted_notebook/data/sync/sync_service.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([FirebaseClient])
import 'sync_service_test.mocks.dart';

void main() {
  group('SyncService - Edge Cases', () {
    late AppDatabase database;
    late NotesDao notesDao;
    late VaultDao vaultDao;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
      vaultDao = VaultDao(database);
    });

    tearDown(() async {
      await database.close();
    });

    // Test: First sync with empty local database
    // Validates: Requirement 6.4
    test('First sync with empty local database should pull all remote data', () async {
      const testUid = 'test-user-123';
      
      // Create mock Firebase client and sync service
      final mockFirebaseClient = MockFirebaseClient();
      final syncService = SyncService(
        firebaseClient: mockFirebaseClient,
        notesDao: notesDao,
        vaultDao: vaultDao,
      );
      
      // Setup: Mock Firebase to return some remote notes
      final remoteNotes = [
        {
          'uuid': const Uuid().v4(),
          'title': 'Remote Note 1',
          'contentMd': 'Content 1',
          'tagsJson': '["tag1"]',
          'isEncrypted': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'deletedAt': null,
        },
        {
          'uuid': const Uuid().v4(),
          'title': 'Remote Note 2',
          'contentMd': 'Content 2',
          'tagsJson': '["tag2"]',
          'isEncrypted': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'deletedAt': null,
        },
      ];

      // Create a stream controller to simulate Firestore snapshots
      final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
      when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
      when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
      when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});

      // Verify local database is empty
      final initialNotes = await notesDao.getAllNotes();
      expect(initialNotes, isEmpty, reason: 'Local database should be empty initially');

      // Start sync
      await syncService.startSync(testUid);
      expect(syncService.isRunning, isTrue);

      // Simulate Firestore sending initial snapshot
      final mockSnapshot = _createMockQuerySnapshot(remoteNotes);
      notesController.add(mockSnapshot);

      // Wait for sync to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify notes were inserted into local database
      final localNotes = await notesDao.getAllNotes();
      expect(localNotes.length, equals(2), reason: 'Should have 2 notes after first sync');
      expect(localNotes.any((n) => n.title == 'Remote Note 1'), isTrue);
      expect(localNotes.any((n) => n.title == 'Remote Note 2'), isTrue);

      // Cleanup
      await syncService.stopSync();
      await notesController.close();
      await vaultController.close();
    });

    // Test: Push failure retry behavior
    // Validates: Requirement 6.4
    test('Push failure should be handled gracefully without throwing', () async {
      const testUid = 'test-user-123';
      
      // Create a local note
      final uuid = const Uuid().v4();
      await notesDao.createNote(
        uuid: uuid,
        title: 'Test Note',
        contentMd: 'Test Content',
        tags: ['test'],
      );

      // Mock Firebase to throw an error on push
      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network error'));

      // Push should not throw even when Firebase fails
      await expectLater(
        syncService.pushLocalChanges(testUid),
        completes,
        reason: 'pushLocalChanges should complete even when individual pushes fail',
      );

      // Verify the note still exists locally
      final localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull, reason: 'Note should still exist locally after push failure');
    });

    // Test: Receiving remote deletion
    // Validates: Requirement 6.4
    test('Receiving remote deletion should update local deletedAt field', () async {
      const testUid = 'test-user-123';
      final uuid = const Uuid().v4();
      
      // Create a local note
      await notesDao.createNote(
        uuid: uuid,
        title: 'Test Note',
        contentMd: 'Test Content',
        tags: [],
      );

      // Setup mock Firebase
      final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
      when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
      when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
      when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});

      // Start sync
      await syncService.startSync(testUid);

      // Simulate receiving a remote deletion
      final deletedAt = DateTime.now();
      final remoteDeletedNote = {
        'uuid': uuid,
        'title': 'Test Note',
        'contentMd': 'Test Content',
        'tagsJson': '[]',
        'isEncrypted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.fromDate(deletedAt),
        'deletedAt': Timestamp.fromDate(deletedAt),
      };

      final mockSnapshot = _createMockQuerySnapshot([remoteDeletedNote]);
      notesController.add(mockSnapshot);

      // Wait for sync to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify local note is marked as deleted
      final localNote = await notesDao.findByUuid(uuid);
      expect(localNote, isNotNull, reason: 'Note should still exist (soft delete)');
      expect(localNote!.deletedAt, isNotNull, reason: 'deletedAt should be set');

      // Cleanup
      await notesController.close();
      await vaultController.close();
    });

    // Test: Handling malformed remote data
    // Validates: Requirement 6.4
    test('Malformed remote data should be handled gracefully without crashing', () async {
      const testUid = 'test-user-123';
      
      // Setup mock Firebase
      final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
      when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
      when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
      when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});

      // Start sync
      await syncService.startSync(testUid);

      // Simulate receiving malformed data (missing required fields)
      final malformedNotes = [
        {
          'uuid': const Uuid().v4(),
          // Missing title, contentMd, etc.
          'updatedAt': Timestamp.now(),
        },
        {
          // Missing uuid
          'title': 'Invalid Note',
          'contentMd': 'Content',
          'updatedAt': Timestamp.now(),
        },
      ];

      final mockSnapshot = _createMockQuerySnapshot(malformedNotes);
      
      // This should not throw - sync service should handle errors gracefully
      await expectLater(
        () async {
          notesController.add(mockSnapshot);
          await Future.delayed(const Duration(milliseconds: 100));
        }(),
        completes,
        reason: 'Sync should handle malformed data without crashing',
      );

      // Verify database is still functional
      final localNotes = await notesDao.getAllNotes();
      expect(localNotes, isNotNull, reason: 'Database should still be accessible');

      // Cleanup
      await notesController.close();
      await vaultController.close();
    });

    // Test: Multiple push failures don't corrupt state
    test('Multiple consecutive push failures should not corrupt local state', () async {
      const testUid = 'test-user-123';
      
      // Create multiple local notes
      final uuids = <String>[];
      for (int i = 0; i < 5; i++) {
        final uuid = const Uuid().v4();
        uuids.add(uuid);
        await notesDao.createNote(
          uuid: uuid,
          title: 'Note $i',
          contentMd: 'Content $i',
          tags: ['tag$i'],
        );
      }

      // Mock Firebase to always fail
      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.pushNote(any, any))
          .thenThrow(Exception('Network error'));

      // Try to push multiple times
      for (int i = 0; i < 3; i++) {
        await syncService.pushLocalChanges(testUid);
      }

      // Verify all notes still exist locally with correct data
      for (int i = 0; i < uuids.length; i++) {
        final note = await notesDao.findByUuid(uuids[i]);
        expect(note, isNotNull, reason: 'Note $i should exist');
        expect(note!.title, equals('Note $i'), reason: 'Note $i title should be unchanged');
        expect(note.contentMd, equals('Content $i'), reason: 'Note $i content should be unchanged');
      }
    });

    // Test: Empty remote snapshot handling
    test('Empty remote snapshot should not affect local data', () async {
      const testUid = 'test-user-123';
      
      // Create local notes
      await notesDao.createNote(
        uuid: const Uuid().v4(),
        title: 'Local Note',
        contentMd: 'Local Content',
        tags: [],
      );

      // Setup mock Firebase
      final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
      when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
      when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
      when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});

      // Get initial count
      final initialNotes = await notesDao.getAllNotes();
      final initialCount = initialNotes.length;

      // Start sync
      await syncService.startSync(testUid);

      // Send empty snapshot
      final emptySnapshot = _createMockQuerySnapshot([]);
      notesController.add(emptySnapshot);

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify local data is unchanged
      final finalNotes = await notesDao.getAllNotes();
      expect(finalNotes.length, equals(initialCount), 
          reason: 'Local note count should be unchanged');

      // Cleanup
      await notesController.close();
      await vaultController.close();
    });

    // Test: Vault item with missing optional fields
    test('Vault item with null optional fields should sync correctly', () async {
      const testUid = 'test-user-123';
      final uuid = const Uuid().v4();
      
      // Setup mock Firebase
      final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>();

      when(mockFirebaseClient.currentUserId).thenReturn(testUid);
      when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
      when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
      when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
      when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});

      // Start sync
      await syncService.startSync(testUid);

      // Simulate receiving vault item with only required fields
      final remoteVaultItem = {
        'uuid': uuid,
        'titleEnc': 'encrypted:title:mac',
        'usernameEnc': null,
        'passwordEnc': null,
        'urlEnc': null,
        'noteEnc': null,
        'updatedAt': Timestamp.now(),
        'deletedAt': null,
      };

      final mockSnapshot = _createMockQuerySnapshot([remoteVaultItem]);
      vaultController.add(mockSnapshot);

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify vault item was created with null optional fields
      final localItem = await vaultDao.findByUuid(uuid);
      expect(localItem, isNotNull, reason: 'Vault item should be created');
      expect(localItem!.titleEnc, equals('encrypted:title:mac'));
      expect(localItem.usernameEnc, isNull);
      expect(localItem.passwordEnc, isNull);

      // Cleanup
      await notesController.close();
      await vaultController.close();
    });
  });
}

// Helper function to create mock QuerySnapshot
QuerySnapshot<Map<String, dynamic>> _createMockQuerySnapshot(
  List<Map<String, dynamic>> documents,
) {
  final mockSnapshot = MockQuerySnapshot();
  final mockDocChanges = <DocumentChange<Map<String, dynamic>>>[];
  final mockDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  for (final docData in documents) {
    final mockDoc = MockQueryDocumentSnapshot();
    when(mockDoc.exists).thenReturn(true);
    when(mockDoc.data()).thenReturn(docData);
    when(mockDoc.id).thenReturn(docData['uuid'] as String? ?? 'unknown');

    final mockChange = MockDocumentChange();
    when(mockChange.doc).thenReturn(mockDoc);
    when(mockChange.type).thenReturn(DocumentChangeType.added);

    mockDocChanges.add(mockChange);
    mockDocs.add(mockDoc);
  }

  when(mockSnapshot.docChanges).thenReturn(mockDocChanges);
  when(mockSnapshot.docs).thenReturn(mockDocs);

  return mockSnapshot;
}

// Additional mock classes
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockDocumentChange extends Mock implements DocumentChange<Map<String, dynamic>> {}
