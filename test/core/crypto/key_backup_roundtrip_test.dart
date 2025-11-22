import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/key_manager.dart';
import 'package:encrypted_notebook/core/crypto/key_backup_service.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'key_backup_roundtrip_test.mocks.dart';

@GenerateMocks([FirebaseClient])
void main() {
  late KeyManager keyManager;
  late MockFirebaseClient mockFirebaseClient;
  late KeyBackupService keyBackupService;

  setUp(() {
    // Setup mock for flutter_secure_storage
    FlutterSecureStorage.setMockInitialValues({});
    keyManager = KeyManager();
    mockFirebaseClient = MockFirebaseClient();
    keyBackupService = KeyBackupService(
      keyManager: keyManager,
      firebaseClient: mockFirebaseClient,
    );
  });

  // **Feature: encrypted-notebook-app, Property 19: 密钥备份往返一致性**
  // **Validates: Requirements 9.1, 9.2, 9.3**
  // Property: For any master password, after backing up key parameters to
  // Firestore and then downloading/restoring them, the user should be able to
  // unlock with the same master password and get the same dataKey
  group('Property 19: Key Backup Round-Trip Consistency', () {
    test('backing up then restoring key params preserves dataKey', () async {
      // Run the property test with multiple random inputs
      const numTests = 20;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random master password (8-32 characters)
        final passwordLength = 8 + (i % 25);
        final masterPassword = _generateRandomString(passwordLength);

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Create first KeyManager and initialize with master password
        final keyManager1 = KeyManager();
        final initResult = await keyManager1.initializeWithMasterPassword(
          masterPassword,
        );

        expect(initResult.isOk, true,
            reason: 'Initialization should succeed for password: "$masterPassword" (iteration $i)');

        // Get the original dataKey
        final dataKey1Result = await keyManager1.unlockDataKey(masterPassword);

        expect(dataKey1Result.isOk, true,
            reason: 'First unlock should succeed (iteration $i)');

        final originalDataKey = dataKey1Result.value;

        expect(originalDataKey.length, equals(32),
            reason: 'DataKey should be 32 bytes (iteration $i)');

        // Get key parameters for backup
        final paramsResult = await keyManager1.getKeyParams();

        expect(paramsResult.isOk, true,
            reason: 'Getting key params should succeed (iteration $i)');

        final keyParams = paramsResult.value;

        // Verify key params have required fields
        expect(keyParams.containsKey('kdfSalt'), true,
            reason: 'Key params should contain kdfSalt (iteration $i)');
        expect(keyParams.containsKey('kdfIterations'), true,
            reason: 'Key params should contain kdfIterations (iteration $i)');
        expect(keyParams.containsKey('wrappedDataKey'), true,
            reason: 'Key params should contain wrappedDataKey (iteration $i)');

        // Simulate backup to Firestore (mock will store the params)
        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // Backup key params
        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        final backupResult = await keyBackupService1.backupKeyParams(uid);

        expect(backupResult.isOk, true,
            reason: 'Backup should succeed (iteration $i)');

        expect(storedParams, isNotNull,
            reason: 'Params should be stored in mock (iteration $i)');

        // Verify stored params match original params
        expect(storedParams!['kdfSalt'], equals(keyParams['kdfSalt']),
            reason: 'Stored kdfSalt should match original (iteration $i)');
        expect(storedParams!['kdfIterations'], equals(keyParams['kdfIterations']),
            reason: 'Stored kdfIterations should match original (iteration $i)');
        expect(storedParams!['wrappedDataKey'], equals(keyParams['wrappedDataKey']),
            reason: 'Stored wrappedDataKey should match original (iteration $i)');

        // Simulate new device: clear local storage
        FlutterSecureStorage.setMockInitialValues({});

        // Create second KeyManager (simulating new device)
        final keyManager2 = KeyManager();

        // Verify it's not initialized
        final isInit = await keyManager2.isInitialized();
        expect(isInit, false,
            reason: 'New device should not be initialized (iteration $i)');

        // Simulate download from Firestore
        when(mockFirebaseClient.downloadKeyParams(uid))
            .thenAnswer((_) async => storedParams);

        // Download and restore key params
        final keyBackupService2 = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        final downloadResult = await keyBackupService2.downloadAndRestoreKeyParams(uid);

        expect(downloadResult.isOk, true,
            reason: 'Download and restore should succeed (iteration $i)');

        // Verify second KeyManager is now initialized
        final isInit2 = await keyManager2.isInitialized();
        expect(isInit2, true,
            reason: 'KeyManager should be initialized after restore (iteration $i)');

        // Unlock with the same master password on the "new device"
        final dataKey2Result = await keyManager2.unlockDataKey(masterPassword);

        expect(dataKey2Result.isOk, true,
            reason: 'Unlock on new device should succeed (iteration $i)');

        final restoredDataKey = dataKey2Result.value;

        expect(restoredDataKey.length, equals(32),
            reason: 'Restored dataKey should be 32 bytes (iteration $i)');

        // The restored dataKey should match the original dataKey
        expect(restoredDataKey, equals(originalDataKey),
            reason: 'Round-trip backup/restore should preserve dataKey for password: "$masterPassword" (iteration $i)');
      }
    });

    test('wrong password fails to unlock after restore', () async {
      // Test that using a different password fails to unlock after restore
      const numTests = 10;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate two different passwords
        final correctPassword = _generateRandomString(10 + i);
        final wrongPassword = _generateRandomString(10 + i + 1);

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize with correct password
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(correctPassword);

        // Get key params
        final paramsResult = await keyManager1.getKeyParams();
        expect(paramsResult.isOk, true);
        final keyParams = paramsResult.value;

        // Simulate backup
        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService1.backupKeyParams(uid);

        // Simulate new device
        FlutterSecureStorage.setMockInitialValues({});

        // Create second KeyManager
        final keyManager2 = KeyManager();

        // Simulate download
        when(mockFirebaseClient.downloadKeyParams(uid))
            .thenAnswer((_) async => storedParams);

        // Download and restore
        final keyBackupService2 = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService2.downloadAndRestoreKeyParams(uid);

        // Try to unlock with wrong password (should fail)
        final unlockResult = await keyManager2.unlockDataKey(wrongPassword);

        expect(unlockResult.isErr, true,
            reason: 'Unlock with wrong password should fail after restore (iteration $i)');
      }
    });

    test('full unlockOnNewDevice workflow preserves dataKey', () async {
      // Test the complete new device unlock workflow
      const numTests = 10;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random password
        final masterPassword = _generateRandomString(12 + (i % 20));

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize on first device
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(masterPassword);

        // Get original dataKey
        final dataKey1Result = await keyManager1.unlockDataKey(masterPassword);
        expect(dataKey1Result.isOk, true);
        final originalDataKey = dataKey1Result.value;

        // Backup
        final paramsResult = await keyManager1.getKeyParams();
        expect(paramsResult.isOk, true);
        final keyParams = paramsResult.value;

        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService1.backupKeyParams(uid);

        // Simulate new device
        FlutterSecureStorage.setMockInitialValues({});

        // Create second KeyManager
        final keyManager2 = KeyManager();

        // Setup mock for download
        when(mockFirebaseClient.downloadKeyParams(uid))
            .thenAnswer((_) async => storedParams);

        // Use unlockOnNewDevice workflow
        final keyBackupService2 = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        final unlockResult = await keyBackupService2.unlockOnNewDevice(
          uid: uid,
          masterPassword: masterPassword,
        );

        expect(unlockResult.isOk, true,
            reason: 'unlockOnNewDevice should succeed (iteration $i)');

        final restoredDataKey = unlockResult.value;

        // The restored dataKey should match the original
        expect(restoredDataKey, equals(originalDataKey),
            reason: 'unlockOnNewDevice should preserve dataKey (iteration $i)');
      }
    });

    test('initializeAndBackup workflow preserves dataKey', () async {
      // Test the initialize and backup workflow
      const numTests = 10;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random password
        final masterPassword = _generateRandomString(12 + (i % 20));

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Setup mock
        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // Use initializeAndBackup
        final keyManager1 = KeyManager();
        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        final initResult = await keyBackupService1.initializeAndBackup(
          uid: uid,
          masterPassword: masterPassword,
        );

        expect(initResult.isOk, true,
            reason: 'initializeAndBackup should succeed (iteration $i)');

        // Get dataKey from first device
        final dataKey1Result = await keyManager1.unlockDataKey(masterPassword);
        expect(dataKey1Result.isOk, true);
        final originalDataKey = dataKey1Result.value;

        // Simulate new device
        FlutterSecureStorage.setMockInitialValues({});

        // Create second KeyManager
        final keyManager2 = KeyManager();

        // Setup mock for download
        when(mockFirebaseClient.downloadKeyParams(uid))
            .thenAnswer((_) async => storedParams);

        // Download and restore
        final keyBackupService2 = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService2.downloadAndRestoreKeyParams(uid);

        // Unlock on new device
        final dataKey2Result = await keyManager2.unlockDataKey(masterPassword);
        expect(dataKey2Result.isOk, true);
        final restoredDataKey = dataKey2Result.value;

        // DataKeys should match
        expect(restoredDataKey, equals(originalDataKey),
            reason: 'initializeAndBackup workflow should preserve dataKey (iteration $i)');
      }
    });

    test('changeMasterPasswordAndBackup workflow preserves dataKey', () async {
      // Test that changing password and backing up preserves dataKey
      const numTests = 10;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random passwords
        final oldPassword = _generateRandomString(10 + i);
        final newPassword = _generateRandomString(10 + i + 1);

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize with old password
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(oldPassword);

        // Get original dataKey
        final dataKey1Result = await keyManager1.unlockDataKey(oldPassword);
        expect(dataKey1Result.isOk, true);
        final originalDataKey = dataKey1Result.value;

        // Setup mock
        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // Change password and backup
        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        final changeResult = await keyBackupService1.changeMasterPasswordAndBackup(
          uid: uid,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

        expect(changeResult.isOk, true,
            reason: 'changeMasterPasswordAndBackup should succeed (iteration $i)');

        // Verify dataKey is still the same with new password
        final dataKey2Result = await keyManager1.unlockDataKey(newPassword);
        expect(dataKey2Result.isOk, true);
        final dataKeyAfterChange = dataKey2Result.value;

        expect(dataKeyAfterChange, equals(originalDataKey),
            reason: 'DataKey should remain same after password change (iteration $i)');

        // Simulate new device
        FlutterSecureStorage.setMockInitialValues({});

        // Create second KeyManager
        final keyManager2 = KeyManager();

        // Setup mock for download
        when(mockFirebaseClient.downloadKeyParams(uid))
            .thenAnswer((_) async => storedParams);

        // Download and restore
        final keyBackupService2 = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService2.downloadAndRestoreKeyParams(uid);

        // Unlock with new password on new device
        final dataKey3Result = await keyManager2.unlockDataKey(newPassword);
        expect(dataKey3Result.isOk, true);
        final restoredDataKey = dataKey3Result.value;

        // DataKey should match original
        expect(restoredDataKey, equals(originalDataKey),
            reason: 'changeMasterPasswordAndBackup workflow should preserve dataKey (iteration $i)');

        // Old password should not work
        final oldPasswordResult = await keyManager2.unlockDataKey(oldPassword);
        expect(oldPasswordResult.isErr, true,
            reason: 'Old password should not work after change (iteration $i)');
      }
    });

    test('backup params contain all required fields', () async {
      // Verify that backed up params contain all required fields
      const numTests = 10;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random password
        final masterPassword = _generateRandomString(12 + (i % 20));

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(masterPassword);

        // Setup mock to capture params
        Map<String, dynamic>? storedParams;
        when(mockFirebaseClient.uploadKeyParams(uid, any))
            .thenAnswer((invocation) async {
          storedParams = invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // Backup
        final keyBackupService1 = KeyBackupService(
          keyManager: keyManager1,
          firebaseClient: mockFirebaseClient,
        );

        await keyBackupService1.backupKeyParams(uid);

        // Verify all required fields are present
        expect(storedParams, isNotNull,
            reason: 'Params should be stored (iteration $i)');

        expect(storedParams!.containsKey('kdfSalt'), true,
            reason: 'Backed up params should contain kdfSalt (iteration $i)');
        expect(storedParams!.containsKey('kdfIterations'), true,
            reason: 'Backed up params should contain kdfIterations (iteration $i)');
        expect(storedParams!.containsKey('wrappedDataKey'), true,
            reason: 'Backed up params should contain wrappedDataKey (iteration $i)');

        // Verify field values are valid
        expect(storedParams!['kdfSalt'], isNotEmpty,
            reason: 'kdfSalt should not be empty (iteration $i)');
        expect(storedParams!['kdfIterations'], equals(210000),
            reason: 'kdfIterations should be 210000 (iteration $i)');
        expect(storedParams!['wrappedDataKey'], isNotEmpty,
            reason: 'wrappedDataKey should not be empty (iteration $i)');
      }
    });

    test('restore fails gracefully with missing params', () async {
      // Test that restore fails gracefully when params are missing
      FlutterSecureStorage.setMockInitialValues({});

      final keyManager = KeyManager();
      final uid = 'user_test';

      // Test with null params
      when(mockFirebaseClient.downloadKeyParams(uid))
          .thenAnswer((_) async => null);

      final keyBackupService = KeyBackupService(
        keyManager: keyManager,
        firebaseClient: mockFirebaseClient,
      );

      final result1 = await keyBackupService.downloadAndRestoreKeyParams(uid);

      expect(result1.isErr, true,
          reason: 'Restore should fail when no params found in cloud');

      // Test with incomplete params (missing kdfSalt)
      when(mockFirebaseClient.downloadKeyParams(uid))
          .thenAnswer((_) async => {
                'kdfIterations': 210000,
                'wrappedDataKey': 'test',
              });

      final result2 = await keyBackupService.downloadAndRestoreKeyParams(uid);

      expect(result2.isErr, true,
          reason: 'Restore should fail when kdfSalt is missing');

      // Test with incomplete params (missing kdfIterations)
      when(mockFirebaseClient.downloadKeyParams(uid))
          .thenAnswer((_) async => {
                'kdfSalt': 'test',
                'wrappedDataKey': 'test',
              });

      final result3 = await keyBackupService.downloadAndRestoreKeyParams(uid);

      expect(result3.isErr, true,
          reason: 'Restore should fail when kdfIterations is missing');

      // Test with incomplete params (missing wrappedDataKey)
      when(mockFirebaseClient.downloadKeyParams(uid))
          .thenAnswer((_) async => {
                'kdfSalt': 'test',
                'kdfIterations': 210000,
              });

      final result4 = await keyBackupService.downloadAndRestoreKeyParams(uid);

      expect(result4.isErr, true,
          reason: 'Restore should fail when wrappedDataKey is missing');
    });
  });
}

// Helper function to generate random string
String _generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
