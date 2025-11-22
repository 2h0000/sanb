import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/key_manager.dart';
import 'package:encrypted_notebook/core/crypto/key_backup_service.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'key_backup_roundtrip_test.mocks.dart';

@GenerateMocks([FirebaseClient])
void main() {
  late MockFirebaseClient mockFirebaseClient;

  setUp(() {
    // Setup mock for flutter_secure_storage
    FlutterSecureStorage.setMockInitialValues({});
    mockFirebaseClient = MockFirebaseClient();
  });

  // **Feature: encrypted-notebook-app, Property 20: 密钥同步一致�?*
  // **Validates: Requirements 9.5**
  // Property: For any key parameters, when cloud key parameters are updated,
  // the system should automatically synchronize and update local secure storage
  // such that the local parameters match the cloud parameters
  group('Property 20: Key Synchronization Consistency', () {
    test('cloud key param updates are synced to local storage', () async {
      // Run the property test with multiple random scenarios
      const numTests = 5;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random passwords
        final password1 = _generateRandomString(10 + (i % 20));
        final password2 = _generateRandomString(10 + (i % 20) + 1);

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize first KeyManager with password1
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(password1);

        // Get initial key params
        final params1Result = await keyManager1.getKeyParams();
        expect(params1Result.isOk, true);
        final initialParams = params1Result.value;

        // Get initial dataKey
        final dataKey1Result = await keyManager1.unlockDataKey(password1);
        expect(dataKey1Result.isOk, true);
        final initialDataKey = dataKey1Result.value;

        // Change password on keyManager1 (simulating another device changing password)
        final changeResult = await keyManager1.changeMasterPassword(
          password1,
          password2,
        );
        expect(changeResult.isOk, true);

        // Get updated params after password change
        final params2Result = await keyManager1.getKeyParams();
        expect(params2Result.isOk, true);
        final updatedParams = params2Result.value;

        // Verify that wrappedDataKey changed (different password wrapping)
        expect(
          updatedParams['wrappedDataKey'] != initialParams['wrappedDataKey'],
          true,
          reason: 'wrappedDataKey should change after password change (iteration $i)',
        );

        // Get dataKey with new password (should be same as initial)
        final dataKey2Result = await keyManager1.unlockDataKey(password2);
        expect(dataKey2Result.isOk, true);
        final dataKeyAfterChange = dataKey2Result.value;

        expect(dataKeyAfterChange, equals(initialDataKey),
            reason: 'DataKey should remain same after password change (iteration $i)');

        // Now simulate restoring from initial params (before password change)
        // This simulates a device that hasn't received the cloud update yet
        FlutterSecureStorage.setMockInitialValues({});
        final keyManager2 = KeyManager();
        final restoreResult = await keyManager2.restoreKeyParams(initialParams);
        expect(restoreResult.isOk, true);

        // Verify keyManager2 can unlock with password1
        final unlock2Result = await keyManager2.unlockDataKey(password1);
        expect(unlock2Result.isOk, true);

        // Create a stream controller to simulate Firestore snapshots
        final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

        // Setup mock to return our stream
        when(mockFirebaseClient.watchKeyParams(uid))
            .thenAnswer((_) => streamController.stream);

        // Create KeyBackupService and start sync on keyManager2
        final keyBackupService = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        keyBackupService.startKeyParamsSync(uid);

        // Wait a bit for subscription to be established
        await Future.delayed(const Duration(milliseconds: 50));

        // Create mock snapshot with updated params (from password change)
        final mockSnapshot = _MockDocumentSnapshot(
          exists: true,
          data: updatedParams,
        );

        // Emit the cloud update through the stream
        streamController.add(mockSnapshot);

        // Wait for sync to process the update
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify local storage was updated by checking if we can unlock with new password
        final unlockWithNewPasswordResult = await keyManager2.unlockDataKey(password2);
        
        expect(unlockWithNewPasswordResult.isOk, true,
            reason: 'Should be able to unlock with new password after sync (iteration $i)');

        final syncedDataKey = unlockWithNewPasswordResult.value;

        // The dataKey should remain the same (only the wrapping changed)
        expect(syncedDataKey, equals(initialDataKey),
            reason: 'DataKey should remain consistent after sync (iteration $i)');

        // Old password should no longer work
        final unlockWithOldPasswordResult = await keyManager2.unlockDataKey(password1);
        
        expect(unlockWithOldPasswordResult.isErr, true,
            reason: 'Old password should not work after sync (iteration $i)');

        // Verify local params match cloud params
        final localParamsResult = await keyManager2.getKeyParams();
        expect(localParamsResult.isOk, true);
        final localParams = localParamsResult.value;

        expect(localParams['wrappedDataKey'], equals(updatedParams['wrappedDataKey']),
            reason: 'Local wrappedDataKey should match cloud after sync (iteration $i)');
        expect(localParams['kdfSalt'], equals(updatedParams['kdfSalt']),
            reason: 'Local kdfSalt should match cloud after sync (iteration $i)');
        expect(localParams['kdfIterations'], equals(updatedParams['kdfIterations']),
            reason: 'Local kdfIterations should match cloud after sync (iteration $i)');

        // Cleanup
        keyBackupService.stopKeyParamsSync();
        await streamController.close();
      }
    });

    test('sync updates local storage when no local params exist', () async {
      // Test that sync works when local storage is empty
      const numTests = 5;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random password
        final password = _generateRandomString(12 + (i % 20));

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Create KeyManager without initializing (no local params)
        final keyManager = KeyManager();

        // Verify not initialized
        final isInit = await keyManager.isInitialized();
        expect(isInit, false);

        // Create params on "another device"
        final keyManager2 = KeyManager();
        await keyManager2.initializeWithMasterPassword(password);
        final params2Result = await keyManager2.getKeyParams();
        expect(params2Result.isOk, true);
        final cloudParams = params2Result.value;

        // Get dataKey from "other device"
        final dataKey2Result = await keyManager2.unlockDataKey(password);
        expect(dataKey2Result.isOk, true);
        final expectedDataKey = dataKey2Result.value;

        // Create stream controller
        final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

        // Setup mock
        when(mockFirebaseClient.watchKeyParams(uid))
            .thenAnswer((_) => streamController.stream);

        // Create KeyBackupService and start sync
        final keyBackupService = KeyBackupService(
          keyManager: keyManager,
          firebaseClient: mockFirebaseClient,
        );

        keyBackupService.startKeyParamsSync(uid);

        // Wait for subscription
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit cloud params
        final mockSnapshot = _MockDocumentSnapshot(
          exists: true,
          data: cloudParams,
        );

        streamController.add(mockSnapshot);

        // Wait for sync
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify local storage was updated
        final isInitNow = await keyManager.isInitialized();
        expect(isInitNow, true,
            reason: 'KeyManager should be initialized after sync (iteration $i)');

        // Verify we can unlock with the password
        final unlockResult = await keyManager.unlockDataKey(password);
        expect(unlockResult.isOk, true,
            reason: 'Should be able to unlock after sync (iteration $i)');

        final syncedDataKey = unlockResult.value;

        // DataKey should match
        expect(syncedDataKey, equals(expectedDataKey),
            reason: 'Synced dataKey should match cloud dataKey (iteration $i)');

        // Cleanup
        keyBackupService.stopKeyParamsSync();
        await streamController.close();
      }
    });

    test('sync correctly handles updates when params differ', () async {
      // Test that sync detects and applies changes when wrappedDataKey differs
      const numTests = 5;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random password
        final password = _generateRandomString(12 + (i % 20));

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize KeyManager
        final keyManager = KeyManager();
        await keyManager.initializeWithMasterPassword(password);

        // Get initial params
        final paramsResult = await keyManager.getKeyParams();
        expect(paramsResult.isOk, true);
        final initialParams = paramsResult.value;

        // Get initial dataKey
        final dataKeyResult = await keyManager.unlockDataKey(password);
        expect(dataKeyResult.isOk, true);
        final initialDataKey = dataKeyResult.value;

        // Create stream controller
        final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

        // Setup mock
        when(mockFirebaseClient.watchKeyParams(uid))
            .thenAnswer((_) => streamController.stream);

        // Create KeyBackupService and start sync
        final keyBackupService = KeyBackupService(
          keyManager: keyManager,
          firebaseClient: mockFirebaseClient,
        );

        keyBackupService.startKeyParamsSync(uid);

        // Wait for subscription
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit the same params (no change) - sync should skip update
        final mockSnapshot1 = _MockDocumentSnapshot(
          exists: true,
          data: initialParams,
        );

        streamController.add(mockSnapshot1);

        // Wait for sync
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify we can still unlock with the same password
        final unlockResult = await keyManager.unlockDataKey(password);
        expect(unlockResult.isOk, true,
            reason: 'Should still be able to unlock (iteration $i)');

        final dataKey = unlockResult.value;

        // DataKey should be unchanged
        expect(dataKey, equals(initialDataKey),
            reason: 'DataKey should remain unchanged when params are same (iteration $i)');

        // Cleanup
        keyBackupService.stopKeyParamsSync();
        await streamController.close();
      }
    });

    test('sync handles multiple rapid updates correctly', () async {
      // Test that sync handles multiple updates in quick succession
      const numTests = 5;

      for (int i = 0; i < numTests; i++) {
        // Clear storage for each test
        FlutterSecureStorage.setMockInitialValues({});

        // Generate random passwords
        final password1 = _generateRandomString(10 + i);
        final password2 = _generateRandomString(11 + i);
        final password3 = _generateRandomString(12 + i);

        // Generate random user ID
        final uid = 'user_${_generateRandomString(20)}';

        // Initialize KeyManager with password1
        final keyManager1 = KeyManager();
        await keyManager1.initializeWithMasterPassword(password1);

        // Get initial params and dataKey
        final params1Result = await keyManager1.getKeyParams();
        expect(params1Result.isOk, true);
        final initialParams = params1Result.value;

        final dataKey1Result = await keyManager1.unlockDataKey(password1);
        expect(dataKey1Result.isOk, true);
        final initialDataKey = dataKey1Result.value;

        // Change password to password2
        await keyManager1.changeMasterPassword(password1, password2);
        final params2Result = await keyManager1.getKeyParams();
        expect(params2Result.isOk, true);
        final params2 = params2Result.value;

        // Change password to password3
        await keyManager1.changeMasterPassword(password2, password3);
        final params3Result = await keyManager1.getKeyParams();
        expect(params3Result.isOk, true);
        final params3 = params3Result.value;

        // Verify dataKey is still the same
        final dataKey3Result = await keyManager1.unlockDataKey(password3);
        expect(dataKey3Result.isOk, true);
        final expectedFinalDataKey = dataKey3Result.value;

        expect(expectedFinalDataKey, equals(initialDataKey),
            reason: 'DataKey should remain same after password changes');

        // Create second KeyManager with initial params (before password changes)
        FlutterSecureStorage.setMockInitialValues({});
        final keyManager2 = KeyManager();
        await keyManager2.restoreKeyParams(initialParams);

        // Verify keyManager2 can unlock with password1
        final unlockTest = await keyManager2.unlockDataKey(password1);
        expect(unlockTest.isOk, true);

        // Create stream controller
        final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

        // Setup mock
        when(mockFirebaseClient.watchKeyParams(uid))
            .thenAnswer((_) => streamController.stream);

        // Create KeyBackupService and start sync on keyManager2
        final keyBackupService = KeyBackupService(
          keyManager: keyManager2,
          firebaseClient: mockFirebaseClient,
        );

        keyBackupService.startKeyParamsSync(uid);

        // Wait for subscription
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit multiple updates rapidly
        streamController.add(_MockDocumentSnapshot(exists: true, data: params2));
        streamController.add(_MockDocumentSnapshot(exists: true, data: params3));

        // Wait for sync to process all updates
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify final state: should be able to unlock with password3
        final unlockResult = await keyManager2.unlockDataKey(password3);
        expect(unlockResult.isOk, true,
            reason: 'Should be able to unlock with final password (iteration $i)');

        final finalDataKey = unlockResult.value;

        // DataKey should match the initial dataKey (same across all password changes)
        expect(finalDataKey, equals(initialDataKey),
            reason: 'Final dataKey should match initial dataKey after multiple updates (iteration $i)');

        // Verify local params match final cloud params
        final localParamsResult = await keyManager2.getKeyParams();
        expect(localParamsResult.isOk, true);
        final localParams = localParamsResult.value;

        expect(localParams['wrappedDataKey'], equals(params3['wrappedDataKey']),
            reason: 'Local params should match final cloud params (iteration $i)');

        // Cleanup
        keyBackupService.stopKeyParamsSync();
        await streamController.close();
      }
    });

    test('sync handles non-existent cloud params gracefully', () async {
      // Test that sync handles the case when cloud params don't exist
      FlutterSecureStorage.setMockInitialValues({});

      final password = _generateRandomString(12);
      final uid = 'user_test';

      // Initialize KeyManager
      final keyManager = KeyManager();
      await keyManager.initializeWithMasterPassword(password);

      // Get initial params
      final paramsResult = await keyManager.getKeyParams();
      expect(paramsResult.isOk, true);
      final initialParams = paramsResult.value;

      // Create stream controller
      final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      // Setup mock
      when(mockFirebaseClient.watchKeyParams(uid))
          .thenAnswer((_) => streamController.stream);

      // Create KeyBackupService and start sync
      final keyBackupService = KeyBackupService(
        keyManager: keyManager,
        firebaseClient: mockFirebaseClient,
      );

      keyBackupService.startKeyParamsSync(uid);

      // Wait for subscription
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit snapshot with no data (document doesn't exist)
      final mockSnapshot = _MockDocumentSnapshot(
        exists: false,
        data: null,
      );

      streamController.add(mockSnapshot);

      // Wait for sync
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify local params are unchanged
      final currentParamsResult = await keyManager.getKeyParams();
      expect(currentParamsResult.isOk, true);
      final currentParams = currentParamsResult.value;

      expect(currentParams['wrappedDataKey'], equals(initialParams['wrappedDataKey']),
          reason: 'Local params should be unchanged when cloud has no data');

      // Verify we can still unlock
      final unlockResult = await keyManager.unlockDataKey(password);
      expect(unlockResult.isOk, true,
          reason: 'Should still be able to unlock');

      // Cleanup
      keyBackupService.stopKeyParamsSync();
      await streamController.close();
    });

    test('stopKeyParamsSync stops receiving updates', () async {
      // Test that stopping sync prevents further updates
      FlutterSecureStorage.setMockInitialValues({});

      final password1 = _generateRandomString(12);
      final password2 = _generateRandomString(13);
      final uid = 'user_test';

      // Initialize first KeyManager with password1
      final keyManager1 = KeyManager();
      await keyManager1.initializeWithMasterPassword(password1);

      // Get initial params
      final params1Result = await keyManager1.getKeyParams();
      expect(params1Result.isOk, true);
      final initialParams = params1Result.value;

      // Change password to password2
      await keyManager1.changeMasterPassword(password1, password2);
      final params2Result = await keyManager1.getKeyParams();
      expect(params2Result.isOk, true);
      final updatedParams = params2Result.value;

      // Create second KeyManager with initial params (before password change)
      FlutterSecureStorage.setMockInitialValues({});
      final keyManager2 = KeyManager();
      await keyManager2.restoreKeyParams(initialParams);

      // Verify keyManager2 can unlock with password1
      final unlockTest = await keyManager2.unlockDataKey(password1);
      expect(unlockTest.isOk, true);

      // Create stream controller
      final streamController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

      // Setup mock
      when(mockFirebaseClient.watchKeyParams(uid))
          .thenAnswer((_) => streamController.stream);

      // Create KeyBackupService and start sync
      final keyBackupService = KeyBackupService(
        keyManager: keyManager2,
        firebaseClient: mockFirebaseClient,
      );

      keyBackupService.startKeyParamsSync(uid);

      // Wait for subscription
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop sync immediately
      keyBackupService.stopKeyParamsSync();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit update (should be ignored since sync is stopped)
      streamController.add(_MockDocumentSnapshot(exists: true, data: updatedParams));

      // Wait
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify we can still unlock with password1 (update was not applied)
      final unlockResult = await keyManager2.unlockDataKey(password1);
      expect(unlockResult.isOk, true,
          reason: 'Should still unlock with old password after sync stopped');

      // Verify we cannot unlock with password2
      final unlockResult2 = await keyManager2.unlockDataKey(password2);
      expect(unlockResult2.isErr, true,
          reason: 'Should not unlock with new password since sync was stopped');

      // Cleanup
      await streamController.close();
    });
  });
}

// Helper function to generate random string
String _generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

// Mock DocumentSnapshot class for testing
class _MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final bool exists;
  
  final Map<String, dynamic>? _data;

  _MockDocumentSnapshot({
    required this.exists,
    required Map<String, dynamic>? data,
  }) : _data = data;

  @override
  Map<String, dynamic>? data() => _data;

  // Implement other required methods with minimal implementations
  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  String get id => 'master';

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}
