import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/data/sync/sync_service.dart';
import 'package:encrypted_notebook/domain/entities/note.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

// **Feature: encrypted-notebook-app, Property 16: 同步下行一致性**
// **Validates: Requirements 7.1, 7.2**
// Property: For any remote update from Firestore, when the system receives
// the update, it should be correctly written to the local database with all
// fields preserved. This ensures downlink sync maintains data consistency.

void main() {
  group('Property 16: Sync Downlink Consistency', () {
    test('Remote note updates are correctly written to local database', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        // Create fresh instances for each iteration
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);
        final fakeFirestore = FakeFirebaseFirestore();
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final uid = mockAuth.currentUser!.uid;

        try {
          // Generate random note data
          final uuid = const Uuid().v4();
          final title = _generateRandomString(Random().nextInt(50) + 1);
          final contentMd = _generateRandomString(Random().nextInt(200) + 1);
          final tags = _generateRandomTags();
          final now = DateTime.now();

          // Create a note document in Firestore (simulating remote update)
          final noteData = {
            'uuid': uuid,
            'title': title,
            'contentMd': contentMd,
            'tags': tags,
            'isEncrypted': false,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'deletedAt': null,
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('notes')
              .doc(uuid)
              .set(noteData);

          // Create FirebaseClient with fake instances
          final firebaseClient = FirebaseClient.forTesting(
            firestore: fakeFirestore,
            auth: mockAuth,
          );

          // Create SyncService
          final syncService = SyncService(
            firebaseClient: firebaseClient,
            notesDao: testDao,
            vaultDao: VaultDao(testDb),
          );

          // Start sync and wait for the remote update to be processed
          await syncService.startSync(uid);
          
          // Give some time for the stream to process
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify the note was written to local database
          final localNote = await testDao.findByUuid(uuid);
          
          expect(localNote, isNotNull,
              reason: 'Remote note should be written to local database (iteration $i)');
          
          if (localNote != null) {
            expect(localNote.uuid, equals(uuid),
                reason: 'UUID should match (iteration $i)');
            expect(localNote.title, equals(title),
                reason: 'Title should match (iteration $i)');
            expect(localNote.contentMd, equals(contentMd),
                reason: 'Content should match (iteration $i)');
            expect(localNote.tags, equals(tags),
                reason: 'Tags should match (iteration $i)');
            expect(localNote.isEncrypted, equals(false),
                reason: 'isEncrypted should match (iteration $i)');
            expect(localNote.deletedAt, isNull,
                reason: 'deletedAt should be null (iteration $i)');
          }

          await syncService.stopSync();
        } finally {
          await testDb.close();
        }
      }
    });

    test('Remote vault item updates are correctly written to local database', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testVaultDao = VaultDao(testDb);
        final fakeFirestore = FakeFirebaseFirestore();
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final uid = mockAuth.currentUser!.uid;

        try {
          // Generate random vault item data (encrypted)
          final uuid = const Uuid().v4();
          final titleEnc = _generateRandomEncryptedString();
          final usernameEnc = _generateRandomEncryptedString();
          final passwordEnc = _generateRandomEncryptedString();
          final urlEnc = _generateRandomEncryptedString();
          final noteEnc = _generateRandomEncryptedString();
          final now = DateTime.now();

          // Create a vault item document in Firestore
          final vaultData = {
            'uuid': uuid,
            'titleEnc': titleEnc,
            'usernameEnc': usernameEnc,
            'passwordEnc': passwordEnc,
            'urlEnc': urlEnc,
            'noteEnc': noteEnc,
            'updatedAt': Timestamp.fromDate(now),
            'deletedAt': null,
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('vault')
              .doc(uuid)
              .set(vaultData);

          // Create FirebaseClient with fake instances
          final firebaseClient = FirebaseClient.forTesting(
            firestore: fakeFirestore,
            auth: mockAuth,
          );

          // Create SyncService
          final syncService = SyncService(
            firebaseClient: firebaseClient,
            notesDao: NotesDao(testDb),
            vaultDao: testVaultDao,
          );

          // Start sync and wait for the remote update to be processed
          await syncService.startSync(uid);
          
          // Give some time for the stream to process
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify the vault item was written to local database
          final localItem = await testVaultDao.findByUuid(uuid);
          
          expect(localItem, isNotNull,
              reason: 'Remote vault item should be written to local database (iteration $i)');
          
          if (localItem != null) {
            expect(localItem.uuid, equals(uuid),
                reason: 'UUID should match (iteration $i)');
            expect(localItem.titleEnc, equals(titleEnc),
                reason: 'Encrypted title should match (iteration $i)');
            expect(localItem.usernameEnc, equals(usernameEnc),
                reason: 'Encrypted username should match (iteration $i)');
            expect(localItem.passwordEnc, equals(passwordEnc),
                reason: 'Encrypted password should match (iteration $i)');
            expect(localItem.urlEnc, equals(urlEnc),
                reason: 'Encrypted URL should match (iteration $i)');
            expect(localItem.noteEnc, equals(noteEnc),
                reason: 'Encrypted note should match (iteration $i)');
            expect(localItem.deletedAt, isNull,
                reason: 'deletedAt should be null (iteration $i)');
          }

          await syncService.stopSync();
        } finally {
          await testDb.close();
        }
      }
    });

    test('Remote note updates with soft delete are correctly synced', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);
        final fakeFirestore = FakeFirebaseFirestore();
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final uid = mockAuth.currentUser!.uid;

        try {
          final uuid = const Uuid().v4();
          final title = _generateRandomString(20);
          final contentMd = _generateRandomString(100);
          final tags = _generateRandomTags();
          final now = DateTime.now();
          final deletedAt = now.add(const Duration(hours: 1));

          // Create a soft-deleted note in Firestore
          final noteData = {
            'uuid': uuid,
            'title': title,
            'contentMd': contentMd,
            'tags': tags,
            'isEncrypted': false,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(deletedAt),
            'deletedAt': Timestamp.fromDate(deletedAt),
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('notes')
              .doc(uuid)
              .set(noteData);

          final firebaseClient = FirebaseClient.forTesting(
            firestore: fakeFirestore,
            auth: mockAuth,
          );

          final syncService = SyncService(
            firebaseClient: firebaseClient,
            notesDao: testDao,
            vaultDao: VaultDao(testDb),
          );

          await syncService.startSync(uid);
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify the soft-deleted note was synced
          final localNote = await testDao.findByUuid(uuid);
          
          expect(localNote, isNotNull,
              reason: 'Soft-deleted note should be synced (iteration $i)');
          
          if (localNote != null) {
            expect(localNote.deletedAt, isNotNull,
                reason: 'deletedAt should be set (iteration $i)');
            expect(localNote.title, equals(title),
                reason: 'Title should be preserved (iteration $i)');
            expect(localNote.contentMd, equals(contentMd),
                reason: 'Content should be preserved (iteration $i)');
          }

          await syncService.stopSync();
        } finally {
          await testDb.close();
        }
      }
    });

    test('Multiple remote updates are processed in order', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);
        final fakeFirestore = FakeFirebaseFirestore();
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final uid = mockAuth.currentUser!.uid;

        try {
          final uuid = const Uuid().v4();
          final baseTime = DateTime.now();

          // Create initial note
          final initialData = {
            'uuid': uuid,
            'title': 'Version 1',
            'contentMd': 'Content 1',
            'tags': <String>[],
            'isEncrypted': false,
            'createdAt': Timestamp.fromDate(baseTime),
            'updatedAt': Timestamp.fromDate(baseTime),
            'deletedAt': null,
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('notes')
              .doc(uuid)
              .set(initialData);

          final firebaseClient = FirebaseClient.forTesting(
            firestore: fakeFirestore,
            auth: mockAuth,
          );

          final syncService = SyncService(
            firebaseClient: firebaseClient,
            notesDao: testDao,
            vaultDao: VaultDao(testDb),
          );

          await syncService.startSync(uid);
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify initial version
          var localNote = await testDao.findByUuid(uuid);
          expect(localNote?.title, equals('Version 1'),
              reason: 'Initial version should be synced (iteration $i)');

          // Update the note remotely
          final updatedTime = baseTime.add(const Duration(seconds: 1));
          final updatedData = {
            'uuid': uuid,
            'title': 'Version 2',
            'contentMd': 'Content 2',
            'tags': ['updated'],
            'isEncrypted': false,
            'createdAt': Timestamp.fromDate(baseTime),
            'updatedAt': Timestamp.fromDate(updatedTime),
            'deletedAt': null,
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('notes')
              .doc(uuid)
              .set(updatedData);

          await Future.delayed(const Duration(milliseconds: 100));

          // Verify updated version
          localNote = await testDao.findByUuid(uuid);
          expect(localNote?.title, equals('Version 2'),
              reason: 'Updated version should be synced (iteration $i)');
          expect(localNote?.contentMd, equals('Content 2'),
              reason: 'Updated content should be synced (iteration $i)');
          expect(localNote?.tags, equals(['updated']),
              reason: 'Updated tags should be synced (iteration $i)');

          await syncService.stopSync();
        } finally {
          await testDb.close();
        }
      }
    });

    test('Downlink sync preserves all field types correctly', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);
        final fakeFirestore = FakeFirebaseFirestore();
        final mockAuth = MockFirebaseAuth(signedIn: true);
        final uid = mockAuth.currentUser!.uid;

        try {
          final uuid = const Uuid().v4();
          
          // Test with various field combinations
          final hasEmptyTitle = Random().nextBool();
          final hasEmptyContent = Random().nextBool();
          final hasEmptyTags = Random().nextBool();
          
          final title = hasEmptyTitle ? '' : _generateRandomString(20);
          final contentMd = hasEmptyContent ? '' : _generateRandomString(100);
          final tags = hasEmptyTags ? <String>[] : _generateRandomTags();
          final now = DateTime.now();

          final noteData = {
            'uuid': uuid,
            'title': title,
            'contentMd': contentMd,
            'tags': tags,
            'isEncrypted': false,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'deletedAt': null,
          };

          await fakeFirestore
              .collection('users')
              .doc(uid)
              .collection('notes')
              .doc(uuid)
              .set(noteData);

          final firebaseClient = FirebaseClient.forTesting(
            firestore: fakeFirestore,
            auth: mockAuth,
          );

          final syncService = SyncService(
            firebaseClient: firebaseClient,
            notesDao: testDao,
            vaultDao: VaultDao(testDb),
          );

          await syncService.startSync(uid);
     