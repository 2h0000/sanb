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
import 'offline_sync_eventual_consistency_test.mocks.dart';

/// **Feature: encrypted-notebook-app, Property 26: Offline Sync Eventual Consistency**
/// 
/// Property: For any sequence of offline operations followed by network recovery,
/// the system SHALL eventually reach a consistent state where:
/// - All offline changes are pushed to Firestore
/// - Conflicts are resolved using LWW (Last Write Wins) strategy
/// - Both local and remote data converge to the same state
/// 
/// **Validates: Requirements 14.3, 14.4**
/// 
/// This property verifies that:
/// - Network recovery triggers automatic sync of offline changes
/// - LWW conflict resolution is applied correctly
/// - System reaches eventual consistency after network restoration
void main() {
  group('Property 26: Offline Sync Eventual Consistency', () {
    late AppDatabase database;
    late NotesDao notesDao;
    late VaultDao vaultDao;
    late MockFirebaseClient mockFirebaseClient;
    late SyncService syncService;
    const uuid = Uuid();

    setUp(() {
      // Create in-memory database
      database = AppDatabase.forTesting(NativeDatabase.memory());
      notesDao = NotesDao(database);
      vaultDao = VaultDao(database);
      
      // Create mocks
      mockFirebaseClient = MockFirebaseClient();
      
      // Create services
      syncService = SyncService(
        firebaseClient: mockFirebaseClient,
        notesDao: notesDao,
        vaultDao: vaultDao,
      );
    });

    tearDown() async {
      await syncService.stopSync();
      await database.close();
    };
    });

    test('Property: Offline changes are pushed when sync starts', () async {
      const testUid = 'test-user-123';
      
      // Generate random test cases
      final testCases = List.generate(100, (i) {
        return {
          'uuid': uuid.v4(),
          'title': 'Offline Note $i - ${uuid.v4().substring(0, 8)}',
          'contentMd': 'Content created offline $i\n\n${uuid.v4()}',
          'tags': i % 3 == 0 ? ['offline', 'tag$i'] : i % 2 == 0 ? ['offline'] : <String>[],
        };
      });

      // Property: For any set of offline operations, they should be pushed when sync starts
      for (final testCase in testCases) {
        // Track pushed notes
        final pushedNotes = <String, Map<String, dynamic>>{};
        when(mockFirebaseClient.pushNote(any, any)).thenAnswer((invocation) async {
          final noteData = invocation.positionalArguments[1] as Map<String, dynamic>;
          pushedNotes[noteData['uuid'] as String] = noteData;
        });
        
        // Setup Firebase streams
        final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        when(mockFirebaseClient.currentUserId).thenReturn(testUid);
        when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
        when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
        when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});
        
        // Create note while "offline" (before sync starts)
        final noteUuid = testCase['uuid'] as String;
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['title'] as String,
          contentMd: testCase['contentMd'] as String,
          tags: testCase['tags'] as List<String>,
        );
        
        // Verify note exists locally
        final localNote = await notesDao.findByUuid(noteUuid);
        expect(localNote, isNotNull, reason: 'Note should be created locally while offline');
        
        // Start sync (simulates network recovery)
        await syncService.startSync(testUid);
        
        // Wait for sync to process
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify: Note should be pushed to Firestore after sync starts
        expect(pushedNotes.containsKey(noteUuid), isTrue,
            reason: 'Note should be pushed to Firestore when sync starts');
        
        final pushedNote = pushedNotes[noteUuid]!;
        expect(pushedNote['title'], equals(testCase['title']),
            reason: 'Pushed note title should match');
        expect(pushedNote['contentMd'], equals(testCase['contentMd']),
            reason: 'Pushed note content should match');
        
        // Cleanup
        await syncService.stopSync();
        await notesController.close();
        await vaultController.close();
      }
    });

    test('Property: LWW conflict resolution with remote updates', () async {
      const testUid = 'test-user-123';
      
      // Generate random test cases with conflicts
      final testCases = List.generate(100, (i) {
        final noteUuid = uuid.v4();
        
        return {
          'uuid': noteUuid,
          'localTitle': 'Local Version $i',
          'localContent': 'Local content $i',
          'remoteTitle': 'Remote Version $i',
          'remoteContent': 'Remote content $i',
          'remoteIsNewer': i % 2 == 0, // Alternate between remote newer and local newer
        };
      });

      // Property: For any conflict, LWW should keep the version with later timestamp
      for (final testCase in testCases) {
        // Setup Firebase
        final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        when(mockFirebaseClient.currentUserId).thenReturn(testUid);
        when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
        when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
        when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
        when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});
        
        // Create local version
        final noteUuid = testCase['uuid'] as String;
        
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['localTitle'] as String,
          contentMd: testCase['localContent'] as String,
          tags: ['local'],
        );
        
        // Get local note's timestamp
        final localNote = await notesDao.findByUuid(noteUuid);
        expect(localNote, isNotNull);
        final localTime = localNote!.updatedAt;
        
        // Start sync
        await syncService.startSync(testUid);
        
        // Create remote timestamp based on test case
        final remoteIsNewer = testCase['remoteIsNewer'] as bool;
        final remoteTime = remoteIsNewer 
            ? localTime.add(const Duration(seconds: 10))
            : localTime.subtract(const Duration(seconds: 10));
        
        // Send remote note via Firestore snapshot
        final remoteNote = {
          'uuid': noteUuid,
          'title': testCase['remoteTitle'] as String,
          'contentMd': testCase['remoteContent'] as String,
          'tagsJson': '["remote"]',
          'isEncrypted': false,
          'createdAt': Timestamp.fromDate(remoteTime.subtract(const Duration(hours: 1))),
          'updatedAt': Timestamp.fromDate(remoteTime),
          'deletedAt': null,
        };
        
        final mockSnapshot = _createMockQuerySnapshot([remoteNote]);
        notesController.add(mockSnapshot);
        
        // Wait for sync to process
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify: The version with later timestamp should win
        final finalNote = await notesDao.findByUuid(noteUuid);
        expect(finalNote, isNotNull);
        
        if (remoteIsNewer) {
          // Remote should win
          expect(finalNote!.title, equals(testCase['remoteTitle']),
              reason: 'Remote version should win when remote timestamp is later');
          expect(finalNote.tags, contains('remote'),
              reason: 'Remote tags should be preserved');
        } else {
          // Local should win
          expect(finalNote!.title, equals(testCase['localTitle']),
              reason: 'Local version should win when local timestamp is later');
          expect(finalNote.tags, contains('local'),
              reason: 'Local tags should be preserved');
        }
        
        // Cleanup
        await syncService.stopSync();
        await notesController.close();
        await vaultController.close();
      }
    });

    test('Property: Multiple offline operations converge to consistent state', () async {
      const testUid = 'test-user-123';
      
      // Generate random sequences of operations
      final sequences = List.generate(50, (seqNum) {
        final operations = <Map<String, dynamic>>[];
        final noteUuids = <String>[];
        
        // Create 5 notes offline
        for (int i = 0; i < 5; i++) {
          final noteUuid = uuid.v4();
          noteUuids.add(noteUuid);
          operations.add({
            'type': 'create',
            'uuid': noteUuid,
            'title': 'Seq$seqNum Note$i',
            'contentMd': 'Content $i',
            'tags': <String>['seq$seqNum'],
          });
        }
        
        // Update 2 notes offline
        for (int i = 0; i < 2; i++) {
          operations.add({
            'type': 'update',
            'uuid': noteUuids[i],
            'title': 'Seq$seqNum Updated$i',
            'contentMd': 'Updated content $i',
            'tags': <String>['seq$seqNum', 'updated'],
          });
        }
        
        // Delete 1 note offline
        operations.add({
          'type': 'delete',
          'uuid': noteUuids[4],
        });
        
        return {
          'operations': operations,
          'noteUuids': noteUuids,
        };
      });

      // Property: For any sequence of offline operations, system should reach consistent state
      for (final sequence in sequences) {
        // Track all pushed notes
        final pushedNotes = <String, Map<String, dynamic>>{};
        when(mockFirebaseClient.pushNote(any, any)).thenAnswer((invocation) async {
          final noteData = invocation.positionalArguments[1] as Map<String, dynamic>;
          pushedNotes[noteData['uuid'] as String] = noteData;
        });
        
        // Setup Firebase
        final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        when(mockFirebaseClient.currentUserId).thenReturn(testUid);
        when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
        when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
        when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});
        
        // Execute all operations offline
        final operations = sequence['operations'] as List<Map<String, dynamic>>;
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
        
        // Start sync (simulates network recovery)
        await syncService.startSync(testUid);
        
        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify: All operations should be reflected in pushed data
        final noteUuids = sequence['noteUuids'] as List<String>;
        
        // All created notes should be pushed
        for (final noteUuid in noteUuids) {
          expect(pushedNotes.containsKey(noteUuid), isTrue,
              reason: 'All notes should be pushed after sync starts');
        }
        
        // Updated notes should have updated content
        final updatedNote0 = pushedNotes[noteUuids[0]];
        expect(updatedNote0?['title'], contains('Updated'),
            reason: 'Updated note should have updated title');
        
        // Deleted note should have deletedAt set
        final deletedNote = pushedNotes[noteUuids[4]];
        expect(deletedNote?['deletedAt'], isNotNull,
            reason: 'Deleted note should have deletedAt timestamp');
        
        // Verify local state matches what was pushed
        for (final noteUuid in noteUuids) {
          final localNote = await notesDao.findByUuid(noteUuid);
          final pushedNote = pushedNotes[noteUuid];
          
          if (localNote != null && pushedNote != null) {
            expect(localNote.title, equals(pushedNote['title']),
                reason: 'Local and pushed titles should match');
            expect(localNote.contentMd, equals(pushedNote['contentMd']),
                reason: 'Local and pushed content should match');
          }
        }
        
        // Cleanup
        await syncService.stopSync();
        await notesController.close();
        await vaultController.close();
      }
    });

    test('Property: Eventual consistency with concurrent offline changes', () async {
      const testUid = 'test-user-123';
      
      // Generate test cases with concurrent modifications
      final testCases = List.generate(50, (i) {
        final noteUuid = uuid.v4();
        return {
          'uuid': noteUuid,
          'device1Title': 'Device1 Title $i',
          'device1Content': 'Device1 content $i',
          'device2Title': 'Device2 Title $i',
          'device2Content': 'Device2 content $i',
        };
      });

      // Property: For any concurrent offline changes, system should converge to consistent state
      for (final testCase in testCases) {
        // Setup Firebase
        final notesController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        final vaultController = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
        when(mockFirebaseClient.currentUserId).thenReturn(testUid);
        when(mockFirebaseClient.watchNotes(testUid)).thenAnswer((_) => notesController.stream);
        when(mockFirebaseClient.watchVault(testUid)).thenAnswer((_) => vaultController.stream);
        when(mockFirebaseClient.pushNote(any, any)).thenAnswer((_) async => {});
        when(mockFirebaseClient.pushVaultItem(any, any)).thenAnswer((_) async => {});
        
        // Simulate device 1 creating note offline
        final noteUuid = testCase['uuid'] as String;
        await notesDao.createNote(
          uuid: noteUuid,
          title: testCase['device1Title'] as String,
          contentMd: testCase['device1Content'] as String,
          tags: ['device1'],
        );
        
        final device1Note = await notesDao.findByUuid(noteUuid);
        expect(device1Note, isNotNull);
        final device1Time = device1Note!.updatedAt;
        
        // Start sync
        await syncService.startSync(testUid);
        
        // Simulate device 2's version arriving from Firestore (created slightly later)
        final device2Time = device1Time.add(const Duration(seconds: 5));
        final device2Note = {
          'uuid': noteUuid,
          'title': testCase['device2Title'] as String,
          'contentMd': testCase['device2Content'] as String,
          'tagsJson': '["device2"]',
          'isEncrypted': false,
          'createdAt': Timestamp.fromDate(device2Time.subtract(const Duration(minutes: 1))),
          'updatedAt': Timestamp.fromDate(device2Time),
          'deletedAt': null,
        };
        
        final mockSnapshot = _createMockQuerySnapshot([device2Note]);
        notesController.add(mockSnapshot);
        
        // Wait for sync to process
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Verify: Device 2's version should win (later timestamp)
        final finalNote = await notesDao.findByUuid(noteUuid);
        expect(finalNote, isNotNull);
        expect(finalNote!.title, equals(testCase['device2Title']),
            reason: 'Device 2 version should win due to later timestamp');
        expect(finalNote.tags, contains('device2'),
            reason: 'Device 2 tags should be preserved');
        
        // Verify system reached consistent state (no conflicts)
        final allNotes = await notesDao.getAllNotes();
        final notesWithUuid = allNotes.where((n) => n.uuid.startsWith(noteUuid)).toList();
        
        // Should have exactly 1 note (no conflict copies if timestamps differ)
        expect(notesWithUuid.length, equals(1),
            reason: 'Should have exactly one note after LWW resolution');
        
        // Cleanup
        await syncService.stopSync();
        await notesController.close();
        await vaultController.close();
      }
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
