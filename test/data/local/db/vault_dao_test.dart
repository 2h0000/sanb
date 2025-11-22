import 'package:drift/native.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart' as entity;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase database;
  late VaultDao vaultDao;
  late CryptoService cryptoService;
  late List<int> dataKey;

  setUp(() async {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    vaultDao = VaultDao(database);
    cryptoService = CryptoService();
    
    // Generate a test data key
    dataKey = await cryptoService.generateKey();
  });

  tearDown(() async {
    await database.close();
  });

  group('VaultDao CRUD Operations', () {
    test('should create and retrieve encrypted vault item', () async {
      // Create a plain vault item
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'Test Account',
        username: 'testuser@example.com',
        password: 'SecurePassword123!',
        url: 'https://example.com',
        note: 'Test note',
        updatedAt: DateTime.now(),
      );

      // Encrypt the item
      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      expect(encryptResult.isOk, isTrue);
      final encryptedItem = encryptResult.value;

      // Store in database
      final id = await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
        usernameEnc: encryptedItem.usernameEnc,
        passwordEnc: encryptedItem.passwordEnc,
        urlEnc: encryptedItem.urlEnc,
        noteEnc: encryptedItem.noteEnc,
      );

      expect(id, greaterThan(0));

      // Retrieve from database
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);
      expect(retrieved!.uuid, equals(uuid));

      // Decrypt and verify
      final decryptResult = await retrieved.decrypt(cryptoService, dataKey);
      expect(decryptResult.isOk, isTrue);
      final decryptedItem = decryptResult.value;

      expect(decryptedItem.title, equals('Test Account'));
      expect(decryptedItem.username, equals('testuser@example.com'));
      expect(decryptedItem.password, equals('SecurePassword123!'));
      expect(decryptedItem.url, equals('https://example.com'));
      expect(decryptedItem.note, equals('Test note'));
    });

    test('should update vault item', () async {
      // Create initial item
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'Original Title',
        username: 'original@example.com',
        password: 'OriginalPass',
        updatedAt: DateTime.now(),
      );

      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encryptedItem = encryptResult.value;

      await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
        usernameEnc: encryptedItem.usernameEnc,
        passwordEnc: encryptedItem.passwordEnc,
      );

      // Update with new values
      final updatedPlain = entity.VaultItem(
        uuid: uuid,
        title: 'Updated Title',
        username: 'updated@example.com',
        password: 'UpdatedPass',
        updatedAt: DateTime.now(),
      );

      final updatedEncryptResult = await updatedPlain.encrypt(cryptoService, dataKey);
      final updatedEncrypted = updatedEncryptResult.value;

      final rowsAffected = await vaultDao.updateVaultItem(
        uuid,
        titleEnc: updatedEncrypted.titleEnc,
        usernameEnc: updatedEncrypted.usernameEnc,
        passwordEnc: updatedEncrypted.passwordEnc,
      );

      expect(rowsAffected, equals(1));

      // Verify update
      final retrieved = await vaultDao.findByUuid(uuid);
      final decryptResult = await retrieved!.decrypt(cryptoService, dataKey);
      final decrypted = decryptResult.value;

      expect(decrypted.title, equals('Updated Title'));
      expect(decrypted.username, equals('updated@example.com'));
      expect(decrypted.password, equals('UpdatedPass'));
    });

    test('should soft delete vault item', () async {
      // Create item
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'To Delete',
        updatedAt: DateTime.now(),
      );

      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encryptedItem = encryptResult.value;

      await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
      );

      // Soft delete
      final rowsAffected = await vaultDao.softDelete(uuid);
      expect(rowsAffected, equals(1));

      // Verify it's not in the active list
      final allItems = await vaultDao.getAllVaultItems();
      expect(allItems.any((item) => item.uuid == uuid), isFalse);

      // But still exists in database
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);
      expect(retrieved!.deletedAt, isNotNull);
    });

    test('should get all non-deleted vault items', () async {
      // Create multiple items
      for (int i = 0; i < 3; i++) {
        final uuid = const Uuid().v4();
        final plainItem = entity.VaultItem(
          uuid: uuid,
          title: 'Item $i',
          updatedAt: DateTime.now(),
        );

        final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
        final encryptedItem = encryptResult.value;

        await vaultDao.createVaultItem(
          uuid: encryptedItem.uuid,
          titleEnc: encryptedItem.titleEnc,
        );
      }

      // Get all items
      final allItems = await vaultDao.getAllVaultItems();
      expect(allItems.length, equals(3));
    });

    test('should handle items with null optional fields', () async {
      // Create item with only required fields
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'Minimal Item',
        updatedAt: DateTime.now(),
      );

      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encryptedItem = encryptResult.value;

      await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
      );

      // Retrieve and decrypt
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);
      expect(retrieved!.usernameEnc, isNull);
      expect(retrieved.passwordEnc, isNull);
      expect(retrieved.urlEnc, isNull);
      expect(retrieved.noteEnc, isNull);

      final decryptResult = await retrieved.decrypt(cryptoService, dataKey);
      final decrypted = decryptResult.value;

      expect(decrypted.title, equals('Minimal Item'));
      expect(decrypted.username, isNull);
      expect(decrypted.password, isNull);
      expect(decrypted.url, isNull);
      expect(decrypted.note, isNull);
    });
  });

  group('VaultItem Encryption/Decryption', () {
    test('should encrypt and decrypt vault item correctly', () async {
      final plainItem = entity.VaultItem(
        uuid: const Uuid().v4(),
        title: 'Test Title',
        username: 'testuser',
        password: 'testpass',
        url: 'https://test.com',
        note: 'Test note',
        updatedAt: DateTime.now(),
      );

      // Encrypt
      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      expect(encryptResult.isOk, isTrue);
      final encrypted = encryptResult.value;

      // Verify encrypted fields are different from plain
      expect(encrypted.titleEnc, isNot(equals(plainItem.title)));
      expect(encrypted.usernameEnc, isNot(equals(plainItem.username)));
      expect(encrypted.passwordEnc, isNot(equals(plainItem.password)));

      // Decrypt
      final decryptResult = await encrypted.decrypt(cryptoService, dataKey);
      expect(decryptResult.isOk, isTrue);
      final decrypted = decryptResult.value;

      // Verify decrypted matches original
      expect(decrypted.uuid, equals(plainItem.uuid));
      expect(decrypted.title, equals(plainItem.title));
      expect(decrypted.username, equals(plainItem.username));
      expect(decrypted.password, equals(plainItem.password));
      expect(decrypted.url, equals(plainItem.url));
      expect(decrypted.note, equals(plainItem.note));
    });

    test('should fail decryption with wrong key', () async {
      final plainItem = entity.VaultItem(
        uuid: const Uuid().v4(),
        title: 'Secret',
        password: 'password123',
        updatedAt: DateTime.now(),
      );

      // Encrypt with one key
      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encrypted = encryptResult.value;

      // Try to decrypt with different key
      final wrongKey = await cryptoService.generateKey();
      final decryptResult = await encrypted.decrypt(cryptoService, wrongKey);

      expect(decryptResult.isErr, isTrue);
      expect(decryptResult.error, contains('Failed to decrypt'));
    });
  });

  group('VaultDao Edge Cases', () {
    test('should update partial fields only', () async {
      // Create initial item with all fields
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'Original Title',
        username: 'original@example.com',
        password: 'OriginalPass123',
        url: 'https://original.com',
        note: 'Original note',
        updatedAt: DateTime.now(),
      );

      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encryptedItem = encryptResult.value;

      await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
        usernameEnc: encryptedItem.usernameEnc,
        passwordEnc: encryptedItem.passwordEnc,
        urlEnc: encryptedItem.urlEnc,
        noteEnc: encryptedItem.noteEnc,
      );

      // Update only password field
      final newPassword = 'NewPassword456';
      final passwordEncResult = await cryptoService.encryptString(
        plaintext: newPassword,
        keyBytes: dataKey,
      );

      final rowsAffected = await vaultDao.updateVaultItem(
        uuid,
        passwordEnc: passwordEncResult.value,
      );

      expect(rowsAffected, equals(1));

      // Verify only password changed, other fields remain the same
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);

      final decryptResult = await retrieved!.decrypt(cryptoService, dataKey);
      final decrypted = decryptResult.value;

      expect(decrypted.title, equals('Original Title'));
      expect(decrypted.username, equals('original@example.com'));
      expect(decrypted.password, equals(newPassword)); // Changed
      expect(decrypted.url, equals('https://original.com'));
      expect(decrypted.note, equals('Original note'));
    });

    test('should return null when querying non-existent UUID', () async {
      // Query with a UUID that doesn't exist
      final nonExistentUuid = const Uuid().v4();
      final result = await vaultDao.findByUuid(nonExistentUuid);

      expect(result, isNull);
    });

    test('should return 0 rows affected when updating non-existent UUID', () async {
      // Try to update an item that doesn't exist
      final nonExistentUuid = const Uuid().v4();
      final titleEncResult = await cryptoService.encryptString(
        plaintext: 'Some Title',
        keyBytes: dataKey,
      );

      final rowsAffected = await vaultDao.updateVaultItem(
        nonExistentUuid,
        titleEnc: titleEncResult.value,
      );

      expect(rowsAffected, equals(0));
    });

    test('should return 0 rows affected when soft deleting non-existent UUID', () async {
      // Try to soft delete an item that doesn't exist
      final nonExistentUuid = const Uuid().v4();
      final rowsAffected = await vaultDao.softDelete(nonExistentUuid);

      expect(rowsAffected, equals(0));
    });

    test('should handle decryption failure with corrupted data', () async {
      // Create an item with valid encryption
      final uuid = const Uuid().v4();
      final plainItem = entity.VaultItem(
        uuid: uuid,
        title: 'Test Item',
        password: 'TestPassword',
        updatedAt: DateTime.now(),
      );

      final encryptResult = await plainItem.encrypt(cryptoService, dataKey);
      final encryptedItem = encryptResult.value;

      await vaultDao.createVaultItem(
        uuid: encryptedItem.uuid,
        titleEnc: encryptedItem.titleEnc,
        passwordEnc: encryptedItem.passwordEnc,
      );

      // Retrieve the item
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);

      // Try to decrypt with wrong key
      final wrongKey = await cryptoService.generateKey();
      final decryptResult = await retrieved!.decrypt(cryptoService, wrongKey);

      // Should fail gracefully with error
      expect(decryptResult.isErr, isTrue);
      expect(decryptResult.error, contains('Failed to decrypt'));
    });

    test('should handle decryption failure with malformed encrypted data', () async {
      // Create an encrypted item with malformed data
      final uuid = const Uuid().v4();
      
      // Create item with invalid encrypted format (not base64 or wrong format)
      final malformedEncrypted = entity.VaultItemEncrypted(
        uuid: uuid,
        titleEnc: 'invalid:encrypted:data',
        passwordEnc: 'also:invalid',
        updatedAt: DateTime.now(),
      );

      // Manually insert into database (bypassing normal encryption)
      await vaultDao.createVaultItem(
        uuid: malformedEncrypted.uuid,
        titleEnc: malformedEncrypted.titleEnc,
        passwordEnc: malformedEncrypted.passwordEnc,
      );

      // Retrieve and try to decrypt
      final retrieved = await vaultDao.findByUuid(uuid);
      expect(retrieved, isNotNull);

      final decryptResult = await retrieved!.decrypt(cryptoService, dataKey);

      // Should fail with error
      expect(decryptResult.isErr, isTrue);
      expect(decryptResult.error, contains('Failed to decrypt'));
    });
  });
}
