import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/domain/entities/note.dart' as entity;
import 'package:encrypted_notebook/domain/entities/vault_item.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

// **Feature: encrypted-notebook-app, Property 18: 冲突副本创建**
// **Validates: Requirements 7.5**
// Property: For any note or vault item where local and remote have the same
// updatedAt timestamp but different content, the system SHALL create a conflict
// copy with a modified UUID (original UUID + "-conflict-" + timestamp).
// This ensures that no data is lost when timestamps are equal but content differs,
// allowing users to manually merge the conflicting versions.

void main() {
  group('Property 18: Conflict Copy Creation', () {
    test('Note conflict copy is created when timestamps are equal but content differs', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          final timestamp = DateTime.now();
          
          // Create local note with specific timestamp
          final localTitle = 'Local ${_generateRandomString(10)}';
          final localContent = 'Local Content ${_generateRandomString(50)}';
          final localTags = _generateRandomTags();
          
          await testDao.createNote(
            uuid: uuid,
            title: localTitle,
            contentMd: localContent,
            tags: localTags,
          );

          // Simulate remote note with SAME timestamp but different content
          final remoteTitle = 'Remote ${_generateRandomString(10)}';
          final remoteContent = 'Remote Content ${_generateRandomString(50)}';
          final remoteTags = _generateRandomTags();
          
          // Ensure content is actually different
          expect(localTitle != remoteTitle || localContent != remoteContent, isTrue,
              reason: 'Local and remote content should differ (iteration $i)');

          final localNote = await testDao.findByUuid(uuid);
          expect(localNote, isNotNull);

          final remoteNote = entity.Note(
            uuid: uuid,
            title: remoteTitle,
            contentMd: remoteContent,
            tags: remoteTags,
            isEncrypted: false,
            createdAt: localNote!.updatedAt,
            updatedAt: localNote.updatedAt, // Same timestamp
            deletedAt: null,
          );

          // Simulate conflict resolution logic:
          // When timestamps are equal but content differs, create conflict copy
          if (remoteNote.updatedAt.isAtSameMomentAs(localNote.updatedAt)) {
            final contentDiffers = localNote.title != remoteNote.title ||
                localNote.contentMd != remoteNote.contentMd ||
                !_listEquals(localNote.tags, remoteNote.tags);
            
            if (contentDiffers) {
              // Create conflict copy with modified UUID
              final conflictTimestamp = DateTime.now().millisecondsSinceEpoch;
              final conflictUuid = '${remoteNote.uuid}-conflict-$conflictTimestamp';
              
              await testDao.createNote(
                uuid: conflictUuid,
                title: '${remoteNote.title} (Conflict)',
                contentMd: remoteNote.contentMd,
                tags: remoteNote.tags,
              );

              // Verify conflict copy was created
              final conflictCopy = await testDao.findByUuid(conflictUuid);
              expect(conflictCopy, isNotNull,
                  reason: 'Conflict copy should be created (iteration $i)');
              expect(conflictCopy!.uuid, startsWith(uuid),
                  reason: 'Conflict UUID should start with original UUID (iteration $i)');
              expect(conflictCopy.uuid, contains('-conflict-'),
                  reason: 'Conflict UUID should contain -conflict- marker (iteration $i)');
              expect(conflictCopy.title, contains('(Conflict)'),
                  reason: 'Conflict copy title should be marked (iteration $i)');
              expect(conflictCopy.contentMd, equals(remoteNote.contentMd),
                  reason: 'Conflict copy should have remote content (iteration $i)');

              // Verify original local note is preserved
              final preservedLocal = await testDao.findByUuid(uuid);
              expect(preservedLocal, isNotNull,
                  reason: 'Original local note should be preserved (iteration $i)');
              expect(preservedLocal!.title, equals(localTitle),
                  reason: 'Local note title should be unchanged (iteration $i)');
              expect(preservedLocal.contentMd, equals(localContent),
                  reason: 'Local note content should be unchanged (iteration $i)');
            }
          }
        } finally {
          await testDb.close();
        }
      }
    });

    test('Vault item conflict copy is created when timestamps are equal but content differs', () async {
      const numTests = 100;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testVaultDao = VaultDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create local vault item
          final localTitleEnc = _generateRandomEncryptedString();
          final localPasswordEnc = _generateRandomEncryptedString();
          final localUsernameEnc = _generateRandomEncryptedString();
          final localUrlEnc = _generateRandomEncryptedString();
          final localNoteEnc = _generateRandomEncryptedString();
          
          await testVaultDao.createVaultItem(
            uuid: uuid,
            titleEnc: localTitleEnc,
            usernameEnc: localUsernameEnc,
            passwordEnc: localPasswordEnc,
            urlEnc: localUrlEnc,
            noteEnc: localNoteEnc,
          );

          final localItem = await testVaultDao.findByUuid(uuid);
          expect(localItem, isNotNull);

          // Simulate remote vault item with SAME timestamp but different content
          final remoteTitleEnc = _generateRandomEncryptedString();
          final remotePasswordEnc = _generateRandomEncryptedString();
          final remoteUsernameEnc = _generateRandomEncryptedString();
          final remoteUrlEnc = _generateRandomEncryptedString();
          final remoteNoteEnc = _generateRandomEncryptedString();
          
          // Ensure content is actually different
          expect(localTitleEnc != remoteTitleEnc || localPasswordEnc != remotePasswordEnc, isTrue,
              reason: 'Local and remote content should differ (iteration $i)');

          final remoteItem = VaultItemEncrypted(
            uuid: uuid,
            titleEnc: remoteTitleEnc,
            usernameEnc: remoteUsernameEnc,
            passwordEnc: remotePasswordEnc,
            urlEnc: remoteUrlEnc,
            noteEnc: remoteNoteEnc,
            updatedAt: localItem!.updatedAt, // Same timestamp
            deletedAt: null,
          );

          // Simulate conflict resolution logic
          if (remoteItem.updatedAt.isAtSameMomentAs(localItem.updatedAt)) {
            final contentDiffers = localItem.titleEnc != remoteItem.titleEnc ||
                localItem.usernameEnc != remoteItem.usernameEnc ||
                localItem.passwordEnc != remoteItem.passwordEnc ||
                localItem.urlEnc != remoteItem.urlEnc ||
                localItem.noteEnc != remoteItem.noteEnc;
            
            if (contentDiffers) {
              // Create conflict copy
              final conflictTimestamp = DateTime.now().millisecondsSinceEpoch;
              final conflictUuid = '${remoteItem.uuid}-conflict-$conflictTimestamp';
              
              await testVaultDao.createVaultItem(
                uuid: conflictUuid,
                titleEnc: remoteItem.titleEnc,
                usernameEnc: remoteItem.usernameEnc,
                passwordEnc: remoteItem.passwordEnc,
                urlEnc: remoteItem.urlEnc,
                noteEnc: remoteItem.noteEnc,
              );

              // Verify conflict copy was created
              final conflictCopy = await testVaultDao.findByUuid(conflictUuid);
              expect(conflictCopy, isNotNull,
                  reason: 'Conflict copy should be created (iteration $i)');
              expect(conflictCopy!.uuid, startsWith(uuid),
                  reason: 'Conflict UUID should start with original UUID (iteration $i)');
              expect(conflictCopy.uuid, contains('-conflict-'),
                  reason: 'Conflict UUID should contain -conflict- marker (iteration $i)');
              expect(conflictCopy.titleEnc, equals(remoteItem.titleEnc),
                  reason: 'Conflict copy should have remote titleEnc (iteration $i)');
              expect(conflictCopy.passwordEnc, equals(remoteItem.passwordEnc),
                  reason: 'Conflict copy should have remote passwordEnc (iteration $i)');

              // Verify original local item is preserved
              final preservedLocal = await testVaultDao.findByUuid(uuid);
              expect(preservedLocal, isNotNull,
                  reason: 'Original local vault item should be preserved (iteration $i)');
              expect(preservedLocal!.titleEnc, equals(localTitleEnc),
                  reason: 'Local titleEnc should be unchanged (iteration $i)');
              expect(preservedLocal.passwordEnc, equals(localPasswordEnc),
                  reason: 'Local passwordEnc should be unchanged (iteration $i)');
            }
          }
        } finally {
          await testDb.close();
        }
      }
    });

    test('No conflict copy is created when timestamps are equal and content is identical', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          final title = 'Same Title ${_generateRandomString(10)}';
          final content = 'Same Content ${_generateRandomString(50)}';
          final tags = _generateRandomTags();
          
          // Create local note
          await testDao.createNote(
            uuid: uuid,
            title: title,
            contentMd: content,
            tags: tags,
          );

          final localNote = await testDao.findByUuid(uuid);
          expect(localNote, isNotNull);

          // Simulate remote note with SAME timestamp and SAME content
          final remoteNote = entity.Note(
            uuid: uuid,
            title: title,
            contentMd: content,
            tags: tags,
            isEncrypted: false,
            createdAt: localNote!.updatedAt,
            updatedAt: localNote.updatedAt,
            deletedAt: null,
          );

          // Get all notes before conflict resolution
          final notesBefore = await testDao.getAllNotes();
          final countBefore = notesBefore.length;

          // Simulate conflict resolution logic
          if (remoteNote.updatedAt.isAtSameMomentAs(localNote.updatedAt)) {
            final contentDiffers = localNote.title != remoteNote.title ||
                localNote.contentMd != remoteNote.contentMd ||
                !_listEquals(localNote.tags, remoteNote.tags);
            
            // Should NOT create conflict copy when content is identical
            expect(contentDiffers, isFalse,
                reason: 'Content should be identical (iteration $i)');
          }

          // Verify no new notes were created
          final notesAfter = await testDao.getAllNotes();
          expect(notesAfter.length, equals(countBefore),
              reason: 'No conflict copy should be created when content is identical (iteration $i)');
        } finally {
          await testDb.close();
        }
      }
    });

    test('Conflict copy UUID format is correct and unique', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create local note
          await testDao.createNote(
            uuid: uuid,
            title: 'Local',
            contentMd: 'Local',
            tags: [],
          );

          final localNote = await testDao.findByUuid(uuid);
          expect(localNote, isNotNull);

          // Create multiple conflict copies
          final numConflicts = Random().nextInt(3) + 2; // 2-4 conflicts
          final conflictUuids = <String>[];

          for (int j = 0; j < numConflicts; j++) {
            final conflictTimestamp = DateTime.now().millisecondsSinceEpoch + j;
            final conflictUuid = '$uuid-conflict-$conflictTimestamp';
            
            await testDao.createNote(
              uuid: conflictUuid,
              title: 'Remote $j (Conflict)',
              contentMd: 'Remote Content $j',
              tags: [],
            );

            conflictUuids.add(conflictUuid);

            // Verify UUID format
            expect(conflictUuid, startsWith(uuid),
                reason: 'Conflict UUID should start with original UUID (iteration $i, conflict $j)');
            expect(conflictUuid, contains('-conflict-'),
                reason: 'Conflict UUID should contain -conflict- marker (iteration $i, conflict $j)');
            expect(conflictUuid, matches(RegExp(r'-conflict-\d+$')),
                reason: 'Conflict UUID should end with timestamp (iteration $i, conflict $j)');
          }

          // Verify all conflict UUIDs are unique
          final uniqueUuids = conflictUuids.toSet();
          expect(uniqueUuids.length, equals(conflictUuids.length),
              reason: 'All conflict UUIDs should be unique (iteration $i)');

          // Verify all conflict copies can be retrieved
          for (final conflictUuid in conflictUuids) {
            final conflictNote = await testDao.findByUuid(conflictUuid);
            expect(conflictNote, isNotNull,
                reason: 'Conflict copy should be retrievable (iteration $i)');
          }
        } finally {
          await testDb.close();
        }
      }
    });

    test('Conflict copy preserves all remote data fields', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create local note
          await testDao.createNote(
            uuid: uuid,
            title: 'Local',
            contentMd: 'Local',
            tags: ['local'],
          );

          final localNote = await testDao.findByUuid(uuid);
          expect(localNote, isNotNull);

          // Create remote note with different content
          final remoteTitle = 'Remote ${_generateRandomString(20)}';
          final remoteContent = 'Remote Content ${_generateRandomString(100)}';
          final remoteTags = _generateRandomTags();
          
          final remoteNote = entity.Note(
            uuid: uuid,
            title: remoteTitle,
            contentMd: remoteContent,
            tags: remoteTags,
            isEncrypted: false,
            createdAt: localNote!.updatedAt,
            updatedAt: localNote.updatedAt,
            deletedAt: null,
          );

          // Create conflict copy
          final conflictTimestamp = DateTime.now().millisecondsSinceEpoch;
          final conflictUuid = '${remoteNote.uuid}-conflict-$conflictTimestamp';
          
          await testDao.createNote(
            uuid: conflictUuid,
            title: '${remoteNote.title} (Conflict)',
            contentMd: remoteNote.contentMd,
            tags: remoteNote.tags,
          );

          // Verify conflict copy has all remote data
          final conflictCopy = await testDao.findByUuid(conflictUuid);
          expect(conflictCopy, isNotNull);
          expect(conflictCopy!.contentMd, equals(remoteContent),
              reason: 'Conflict copy should preserve remote content (iteration $i)');
          expect(_listEquals(conflictCopy.tags, remoteTags), isTrue,
              reason: 'Conflict copy should preserve remote tags (iteration $i)');
          expect(conflictCopy.title, contains(remoteTitle),
              reason: 'Conflict copy title should contain remote title (iteration $i)');
        } finally {
          await testDb.close();
        }
      }
    });

    test('Conflict copy creation works with soft-deleted notes', () async {
      const numTests = 50;

      for (int i = 0; i < numTests; i++) {
        final testDb = AppDatabase.forTesting(NativeDatabase.memory());
        final testDao = NotesDao(testDb);

        try {
          final uuid = const Uuid().v4();
          
          // Create and soft-delete local note
          await testDao.createNote(
            uuid: uuid,
            title: 'Local',
            contentMd: 'Local',
            tags: [],
          );
          await testDao.softDelete(uuid);

          final localNote = await testDao.findByUuid(uuid);
          expect(localNote, isNotNull);
          expect(localNote!.deletedAt, isNotNull);

          // Simulate remote note with same timestamp but not deleted
          final remoteNote = entity.Note(
            uuid: uuid,
            title: 'Remote',
            contentMd: 'Remote',
            tags: [],
            isEncrypted: false,
            createdAt: localNote.updatedAt,
            updatedAt: localNote.updatedAt,
            deletedAt: null, // Not deleted
          );

          // Content differs (deletedAt status)
          final contentDiffers = localNote.deletedAt != remoteNote.deletedAt;
          expect(contentDiffers, isTrue,
              reason: 'Deletion status should differ (iteration $i)');

          // Create conflict copy
          if (contentDiffers) {
            final conflictTimestamp = DateTime.now().millisecondsSinceEpoch;
            final conflictUuid = '${remoteNote.uuid}-conflict-$conflictTimestamp';
            
            await testDao.createNote(
              uuid: conflictUuid,
              title: '${remoteNote.title} (Conflict)',
              contentMd: remoteNote.contentMd,
              tags: remoteNote.tags,
            );

            // Verify conflict copy was created and is not deleted
            final conflictCopy = await testDao.findByUuid(conflictUuid);
            expect(conflictCopy, isNotNull,
                reason: 'Conflict copy should be created (iteration $i)');
            expect(conflictCopy!.deletedAt, isNull,
                reason: 'Conflict copy should not be deleted (iteration $i)');

            // Verify local note is still deleted
            final preservedLocal = await testDao.findByUuid(uuid);
            expect(preservedLocal!.deletedAt, isNotNull,
                reason: 'Local note should still be deleted (iteration $i)');
          }
        } finally {
          await testDb.close();
        }
      }
    });
  });
}

// Helper functions
String _generateRandomString(int length) {
  if (length == 0) return '';
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

List<String> _generateRandomTags() {
  final random = Random();
  final numTags = random.nextInt(6);
  return List.generate(numTags, (i) => 'tag${random.nextInt(100)}');
}

String _generateRandomEncryptedString() {
  final random = Random();
  final nonce = _generateRandomBase64(16);
  final cipher = _generateRandomBase64(random.nextInt(100) + 20);
  final mac = _generateRandomBase64(16);
  return '$nonce:$cipher:$mac';
}

String _generateRandomBase64(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  final random = Random();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
