import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:encrypted_notebook/core/crypto/key_manager.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart' as entity;
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration test for the complete vault flow
/// Tests: Set Master Password → Create Entry → Unlock → View → Edit
/// 
/// This test validates the entire lifecycle of vault operations including
/// encryption, decryption, and key management.
void main() {
  group('Vault Complete Flow Integration Test', () {
    late AppDatabase database;
    late VaultDao vaultDao;
    late CryptoService cryptoService;
    late KeyManager keyManager;

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      vaultDao = VaultDao(database);
      cryptoService = CryptoService();
      keyManager = KeyManager();
      
      // Configure FlutterSecureStorage for testing
      FlutterSecureStorage.setMockInitialValues({});
    });

    tearDown(() async {
      await database.close();
    });

    test('Complete vault flow: setup → create → unlock → view → edit', () async {
      // ========== STEP 1: SET MASTER PASSWORD ==========
      const masterPassword = 'TestMasterPassword123!';
      
      // Initialize key manager with master password
      await keyManager.initializeWithMasterPassword(masterPassword);
      
      // Verify initialization
      final isInitialized = await keyManager.isInitialized();
      expect(isInitialized, isTrue, reason: 'Key manager should be initialized');

      // ========== STEP 2: UNLOCK VAULT (GET DATA KEY) ==========
      final dataKeyResult = await keyManager.unlockDataKey(masterPassword);
      expect(dataKeyResult.isOk, isTrue, reason: 'Should unlock data key with correct password');
      final dataKey = dataKeyResult.value;
      expect(dataKey.length, equals(32), reason: 'Data key should be 32 bytes');

      // ========== STEP 3: CREATE VAULT ENTRY ==========
      final uuid = const Uuid().v4();
      const title = 'Test Account';
      const username = 'testuser@example.com';
      const password = 'SecurePassword123!';
      const url = 'https://example.com';
      const note = 'This is a test vault entry';

      // Create vault item entity
      final vaultItem = entity.VaultItem(
        uuid: uuid,
        title: title,
        username: username,
        password: password,
        url: url,
        note: note,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Encrypt the vault item
      final encryptedResult = await vaultItem.encrypt(cryptoService, dataKey);
      expect(encryptedResult.isOk, isTrue);
      final encryptedItem = encryptedResult.value;
      
      // Verify encryption happened (ciphertext should be different from plaintext)
      expect(encryptedItem.titleEnc, isNot(equals(title)));
      expect(encryptedItem.usernameEnc, isNot(equals(username)));
      expect(encryptedItem.passwordEnc, isNot(equals(password)));

      // Store encrypted item in database
      final itemId = await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
        usernameEnc: encryptedItem.usernameEnc,
        passwordEnc: encryptedItem.passwordEnc,
        urlEnc: encryptedItem.urlEnc,
        noteEnc: encryptedItem.noteEnc,
      );

      expect(itemId, greaterThan(0), reason: 'Vault item should be created with valid ID');

      // ========== STEP 4: VIEW VAULT ENTRY (DECRYPT) ==========
      // Retrieve encrypted item from database
      final retrievedEncrypted = await vaultDao.findByUuid(uuid);
      expect(retrievedEncrypted, isNotNull, reason: 'Should retrieve encrypted item');

      // Decrypt the item
      final decryptedResult = await retrievedEncrypted!.decrypt(cryptoService, dataKey);
      expect(decryptedResult.isOk, isTrue);
      final decryptedItem = decryptedResult.value;
      
      // Verify decrypted data matches original
      expect(decryptedItem.uuid, equals(uuid));
      expect(decryptedItem.title, equals(title));
      expect(decryptedItem.username, equals(username));
      expect(decryptedItem.password, equals(password));
      expect(decryptedItem.url, equals(url));
      expect(decryptedItem.note, equals(note));

      // ========== STEP 5: EDIT VAULT ENTRY ==========
      const updatedTitle = 'Updated Test Account';
      const updatedUsername = 'newemail@example.com';
      const updatedPassword = 'NewSecurePassword456!';

      // Create updated vault item
      final updatedItem = entity.VaultItem(
        uuid: uuid,
        title: updatedTitle,
        username: updatedUsername,
        password: updatedPassword,
        url: url,
        note: note,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Encrypt updated item
      final updatedEncryptedResult = await updatedItem.encrypt(cryptoService, dataKey);
      expect(updatedEncryptedResult.isOk, isTrue);
      final updatedEncrypted = updatedEncryptedResult.value;

      // Update in database
      final updateCount = await vaultDao.updateVaultItem(
        uuid,
        titleEnc: updatedEncrypted.titleEnc,
        usernameEnc: updatedEncrypted.usernameEnc,
        passwordEnc: updatedEncrypted.passwordEnc,
        urlEnc: updatedEncrypted.urlEnc,
        noteEnc: updatedEncrypted.noteEnc,
      );

      expect(updateCount, equals(1), reason: 'Should update exactly one item');

      // Retrieve and decrypt updated item
      final retrievedUpdated = await vaultDao.findByUuid(uuid);
      expect(retrievedUpdated, isNotNull);
      
      final decryptedUpdatedResult = await retrievedUpdated!.decrypt(cryptoService, dataKey);
      expect(decryptedUpdatedResult.isOk, isTrue);
      final decryptedUpdated = decryptedUpdatedResult.value;
      
      // Verify updated data
      expect(decryptedUpdated.title, equals(updatedTitle));
      expect(decryptedUpdated.username, equals(updatedUsername));
      expect(decryptedUpdated.password, equals(updatedPassword));
      expect(decryptedUpdated.url, equals(url));
      expect(decryptedUpdated.note, equals(note));

      // ========== STEP 6: VERIFY WRONG PASSWORD FAILS ==========
      try {
        await keyManager.unlockDataKey('WrongPassword');
        fail('Should throw exception with wrong password');
      } catch (e) {
        // Expected to fail
        expect(e, isNotNull);
      }

      // ========== STEP 7: DELETE VAULT ENTRY ==========
      final deleteCount = await vaultDao.softDelete(uuid);
      expect(deleteCount, equals(1), reason: 'Should delete exactly one item');

      // Verify item no longer in active list
      final allItems = await vaultDao.getAllVaultItems();
      expect(allItems.length, equals(0), reason: 'Deleted item should not appear in active list');

      // Verify item still exists with deletedAt set
      final deletedItem = await vaultDao.findByUuid(uuid);
      expect(deletedItem, isNotNull, reason: 'Deleted item should still exist');
      expect(deletedItem!.deletedAt, isNotNull, reason: 'Deleted item should have deletedAt set');
    });

    test('Multiple vault entries with different encryption', () async {
      const masterPassword = 'TestPassword123!';
      await keyManager.initializeWithMasterPassword(masterPassword);
      final dataKeyResult = await keyManager.unlockDataKey(masterPassword);
      expect(dataKeyResult.isOk, isTrue);
      final dataKey = dataKeyResult.value;

      // Create multiple vault entries
      final entries = <entity.VaultItem>[];
      for (int i = 0; i < 5; i++) {
        final item = entity.VaultItem(
          uuid: const Uuid().v4(),
          title: 'Account $i',
          username: 'user$i@example.com',
          password: 'Password$i!',
          url: 'https://example$i.com',
          note: 'Note for account $i',
          updatedAt: DateTime.now(),
          deletedAt: null,
        );
        entries.add(item);

        // Encrypt and store
        final encryptedResult = await item.encrypt(cryptoService, dataKey);
        expect(encryptedResult.isOk, isTrue);
        final encrypted = encryptedResult.value;
        await vaultDao.createVaultItem(
          uuid: encrypted.uuid,
          titleEnc: encrypted.titleEnc,
          usernameEnc: encrypted.usernameEnc,
          passwordEnc: encrypted.passwordEnc,
          urlEnc: encrypted.urlEnc,
          noteEnc: encrypted.noteEnc,
        );
      }

      // Verify all entries exist
      final allItems = await vaultDao.getAllVaultItems();
      expect(allItems.length, equals(5));

      // Decrypt and verify each entry
      for (int i = 0; i < 5; i++) {
        final encrypted = await vaultDao.findByUuid(entries[i].uuid);
        expect(encrypted, isNotNull);
        
        final decryptedResult = await encrypted!.decrypt(cryptoService, dataKey);
        expect(decryptedResult.isOk, isTrue);
        final decrypted = decryptedResult.value;
        expect(decrypted.title, equals('Account $i'));
        expect(decrypted.username, equals('user$i@example.com'));
        expect(decrypted.password, equals('Password$i!'));
      }

      // Update one entry
      final updatedItem = entity.VaultItem(
        uuid: entries[2].uuid,
        title: 'Updated Account 2',
        username: 'updated2@example.com',
        password: 'UpdatedPassword2!',
        url: entries[2].url,
        note: entries[2].note,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      final updatedEncryptedResult = await updatedItem.encrypt(cryptoService, dataKey);
      expect(updatedEncryptedResult.isOk, isTrue);
      final updatedEncrypted = updatedEncryptedResult.value;
      await vaultDao.updateVaultItem(
        entries[2].uuid,
        titleEnc: updatedEncrypted.titleEnc,
        usernameEnc: updatedEncrypted.usernameEnc,
        passwordEnc: updatedEncrypted.passwordEnc,
      );

      // Verify update
      final retrieved = await vaultDao.findByUuid(entries[2].uuid);
      final decryptedResult = await retrieved!.decrypt(cryptoService, dataKey);
      expect(decryptedResult.isOk, isTrue);
      final decrypted = decryptedResult.value;
      expect(decrypted.title, equals('Updated Account 2'));
      expect(decrypted.username, equals('updated2@example.com'));

      // Delete some entries
      await vaultDao.softDelete(entries[0].uuid);
      await vaultDao.softDelete(entries[4].uuid);

      // Verify correct count
      final remainingItems = await vaultDao.getAllVaultItems();
      expect(remainingItems.length, equals(3));
    });

    test('Vault flow with special characters and empty fields', () async {
      const masterPassword = 'TestPassword123!';
      await keyManager.initializeWithMasterPassword(masterPassword);
      final dataKeyResult = await keyManager.unlockDataKey(masterPassword);
      expect(dataKeyResult.isOk, isTrue);
      final dataKey = dataKeyResult.value;

      // Create entry with special characters
      final specialItem = entity.VaultItem(
        uuid: const Uuid().v4(),
        title: 'Special: 你好 😀 "quotes" \'apostrophe\'',
        username: 'user@例え.com',
        password: r'P@ssw0rd!#$%^&*()',
        url: 'https://例え.com/path?query=value&other=值',
        note: 'Note with\nnewlines\tand\ttabs\nand 特殊字符',
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Encrypt and store
      final encryptedResult = await specialItem.encrypt(cryptoService, dataKey);
      expect(encryptedResult.isOk, isTrue);
      final encrypted = encryptedResult.value;
      await vaultDao.createVaultItem(
        uuid: encrypted.uuid,
        titleEnc: encrypted.titleEnc,
        usernameEnc: encrypted.usernameEnc,
        passwordEnc: encrypted.passwordEnc,
        urlEnc: encrypted.urlEnc,
        noteEnc: encrypted.noteEnc,
      );

      // Retrieve and decrypt
      final retrieved = await vaultDao.findByUuid(specialItem.uuid);
      final decryptedResult = await retrieved!.decrypt(cryptoService, dataKey);
      expect(decryptedResult.isOk, isTrue);
      final decrypted = decryptedResult.value;

      // Verify special characters preserved
      expect(decrypted.title, equals(specialItem.title));
      expect(decrypted.username, equals(specialItem.username));
      expect(decrypted.password, equals(specialItem.password));
      expect(decrypted.url, equals(specialItem.url));
      expect(decrypted.note, equals(specialItem.note));

      // Create entry with some null fields
      final partialItem = entity.VaultItem(
        uuid: const Uuid().v4(),
        title: 'Partial Entry',
        username: null,
        password: 'OnlyPassword',
        url: null,
        note: null,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      final partialEncryptedResult = await partialItem.encrypt(cryptoService, dataKey);
      expect(partialEncryptedResult.isOk, isTrue);
      final partialEncrypted = partialEncryptedResult.value;
      await vaultDao.createVaultItem(
        uuid: partialEncrypted.uuid,
        titleEnc: partialEncrypted.titleEnc,
        usernameEnc: partialEncrypted.usernameEnc,
        passwordEnc: partialEncrypted.passwordEnc,
        urlEnc: partialEncrypted.urlEnc,
        noteEnc: partialEncrypted.noteEnc,
      );

      // Retrieve and verify null fields
      final retrievedPartial = await vaultDao.findByUuid(partialItem.uuid);
      final decryptedPartialResult = await retrievedPartial!.decrypt(cryptoService, dataKey);
      expect(decryptedPartialResult.isOk, isTrue);
      final decryptedPartial = decryptedPartialResult.value;
      
      expect(decryptedPartial.title, equals('Partial Entry'));
      expect(decryptedPartial.username, isNull);
      expect(decryptedPartial.password, equals('OnlyPassword'));
      expect(decryptedPartial.url, isNull);
      expect(decryptedPartial.note, isNull);
    });

    test('Change master password and verify re-encryption', () async {
      // Initialize with first password
      const oldPassword = 'OldPassword123!';
      await keyManager.initializeWithMasterPassword(oldPassword);
      var dataKeyResult = await keyManager.unlockDataKey(oldPassword);
      expect(dataKeyResult.isOk, isTrue);
      var dataKey = dataKeyResult.value;

      // Create a vault entry
      final item = entity.VaultItem(
        uuid: const Uuid().v4(),
        title: 'Test Entry',
        username: 'user@example.com',
        password: 'EntryPassword',
        url: null,
        note: null,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      final encryptedResult = await item.encrypt(cryptoService, dataKey);
      expect(encryptedResult.isOk, isTrue);
      final encrypted = encryptedResult.value;
      await vaultDao.createVaultItem(
        uuid: encrypted.uuid,
        titleEnc: encrypted.titleEnc,
        usernameEnc: encrypted.usernameEnc,
        passwordEnc: encrypted.passwordEnc,
        urlEnc: encrypted.urlEnc,
        noteEnc: encrypted.noteEnc,
      );

      // Change master password
      const newPassword = 'NewPassword456!';
      await keyManager.changeMasterPassword(oldPassword, newPassword);

      // Old password should no longer work
      try {
        await keyManager.unlockDataKey(oldPassword);
        fail('Old password should not work after change');
      } catch (e) {
        // Expected
      }

      // New password should work
      dataKeyResult = await keyManager.unlockDataKey(newPassword);
      expect(dataKeyResult.isOk, isTrue);
      dataKey = dataKeyResult.value;
      expect(dataKey.length, equals(32));

      // Should still be able to decrypt existing entries
      final retrieved = await vaultDao.findByUuid(item.uuid);
      final decryptedResult = await retrieved!.decrypt(cryptoService, dataKey);
      expect(decryptedResult.isOk, isTrue);
      final decrypted = decryptedResult.value;
      
      expect(decrypted.title, equals('Test Entry'));
      expect(decrypted.username, equals('user@example.com'));
      expect(decrypted.password, equals('EntryPassword'));
    });
  });
}
