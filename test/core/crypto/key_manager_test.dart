import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/key_manager.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';

void main() {
  late KeyManager keyManager;

  setUp(() {
    // Setup mock for flutter_secure_storage
    FlutterSecureStorage.setMockInitialValues({});
    keyManager = KeyManager();
  });

  group('KeyManager', () {
    test('should not be initialized initially', () async {
      final isInit = await keyManager.isInitialized();
      expect(isInit, false);
    });

    test('should initialize with master password', () async {
      const masterPassword = 'MySecurePassword123!';

      final result = await keyManager.initializeWithMasterPassword(
        masterPassword,
      );

      expect(result.isOk, true);

      final isInit = await keyManager.isInitialized();
      expect(isInit, true);
    });

    test('should fail to initialize twice', () async {
      const masterPassword = 'MySecurePassword123!';

      // First initialization
      await keyManager.initializeWithMasterPassword(masterPassword);

      // Second initialization should fail
      final result = await keyManager.initializeWithMasterPassword(
        masterPassword,
      );

      expect(result.isErr, true);
      expect(result.error, contains('already initialized'));
    });

    test('should unlock with correct master password', () async {
      const masterPassword = 'MySecurePassword123!';

      // Initialize
      await keyManager.initializeWithMasterPassword(masterPassword);

      // Unlock
      final unlockResult = await keyManager.unlockDataKey(masterPassword);

      expect(unlockResult.isOk, true);
      expect(unlockResult.value.length, 32); // 32-byte dataKey
    });

    test('should fail to unlock with wrong password', () async {
      const correctPassword = 'CorrectPassword123!';
      const wrongPassword = 'WrongPassword456!';

      // Initialize
      await keyManager.initializeWithMasterPassword(correctPassword);

      // Try to unlock with wrong password
      final unlockResult = await keyManager.unlockDataKey(wrongPassword);

      expect(unlockResult.isErr, true);
      expect(unlockResult.error, contains('Incorrect master password'));
    });

    test('should return same dataKey for same password', () async {
      const masterPassword = 'MySecurePassword123!';

      // Initialize
      await keyManager.initializeWithMasterPassword(masterPassword);

      // Unlock twice
      final unlock1 = await keyManager.unlockDataKey(masterPassword);
      final unlock2 = await keyManager.unlockDataKey(masterPassword);

      expect(unlock1.isOk, true);
      expect(unlock2.isOk, true);
      expect(unlock1.value, equals(unlock2.value));
    });

    test('should change master password successfully', () async {
      const oldPassword = 'OldPassword123!';
      const newPassword = 'NewPassword456!';

      // Initialize with old password
      await keyManager.initializeWithMasterPassword(oldPassword);

      // Get dataKey with old password
      final dataKey1 = await keyManager.unlockDataKey(oldPassword);
      expect(dataKey1.isOk, true);

      // Change password
      final changeResult = await keyManager.changeMasterPassword(
        oldPassword,
        newPassword,
      );
      expect(changeResult.isOk, true);

      // Old password should no longer work
      final unlockOld = await keyManager.unlockDataKey(oldPassword);
      expect(unlockOld.isErr, true);

      // New password should work
      final dataKey2 = await keyManager.unlockDataKey(newPassword);
      expect(dataKey2.isOk, true);

      // DataKey should remain the same
      expect(dataKey1.value, equals(dataKey2.value));
    });

    test('should fail to change password with wrong old password', () async {
      const correctPassword = 'CorrectPassword123!';
      const wrongPassword = 'WrongPassword456!';
      const newPassword = 'NewPassword789!';

      // Initialize
      await keyManager.initializeWithMasterPassword(correctPassword);

      // Try to change with wrong old password
      final result = await keyManager.changeMasterPassword(
        wrongPassword,
        newPassword,
      );

      expect(result.isErr, true);
    });

    test('should get key parameters', () async {
      const masterPassword = 'MySecurePassword123!';

      // Initialize
      await keyManager.initializeWithMasterPassword(masterPassword);

      // Get key params
      final paramsResult = await keyManager.getKeyParams();

      expect(paramsResult.isOk, true);
      final params = paramsResult.value;

      expect(params.containsKey('kdfSalt'), true);
      expect(params.containsKey('kdfIterations'), true);
      expect(params.containsKey('wrappedDataKey'), true);
      expect(params['kdfIterations'], 210000);
    });

    test('should restore key parameters', () async {
      const masterPassword = 'MySecurePassword123!';

      // Initialize first manager
      final manager1 = KeyManager();
      await manager1.initializeWithMasterPassword(masterPassword);

      // Get key params
      final paramsResult = await manager1.getKeyParams();
      expect(paramsResult.isOk, true);
      final params = paramsResult.value;

      // Get dataKey from first manager
      final dataKey1Result = await manager1.unlockDataKey(masterPassword);
      expect(dataKey1Result.isOk, true);

      // Create second manager and restore params
      final manager2 = KeyManager();
      final restoreResult = await manager2.restoreKeyParams(params);
      expect(restoreResult.isOk, true);

      // Unlock with second manager
      final dataKey2Result = await manager2.unlockDataKey(masterPassword);
      expect(dataKey2Result.isOk, true);

      // DataKeys should match
      expect(dataKey1Result.value, equals(dataKey2Result.value));
    });

    test('should clear all keys', () async {
      const masterPassword = 'MySecurePassword123!';

      // Initialize
      await keyManager.initializeWithMasterPassword(masterPassword);
      expect(await keyManager.isInitialized(), true);

      // Clear
      await keyManager.clearAllKeys();

      // Should no longer be initialized
      expect(await keyManager.isInitialized(), false);
    });

    // **Feature: encrypted-notebook-app, Property 8: 密钥派生确定性**
    // **Validates: Requirements 3.2**
    // Property: For any master password and salt, deriving the password key
    // multiple times with the same inputs should produce identical results
    group('Property 8: Key Derivation Determinism', () {
      test('deriving password key with same inputs produces same output', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random master password (8-32 characters)
          final passwordLength = 8 + (i % 25);
          final masterPassword = _generateRandomString(passwordLength);
          
          // Generate random salt (16 bytes as per spec)
          final salt = _generateRandomBytes(16);
          
          // Derive password key twice with same inputs
          final key1 = await _derivePasswordKey(masterPassword, salt, 210000);
          final key2 = await _derivePasswordKey(masterPassword, salt, 210000);
          
          // Keys should be identical
          expect(key1, equals(key2),
              reason: 'Key derivation should be deterministic for password: "$masterPassword"');
          
          // Keys should be 32 bytes (256 bits)
          expect(key1.length, equals(32),
              reason: 'Derived key should be 32 bytes');
        }
      });

      test('different passwords produce different keys', () async {
        final salt = _generateRandomBytes(16);
        
        // Test with multiple password pairs
        const numTests = 50;
        for (int i = 0; i < numTests; i++) {
          final password1 = _generateRandomString(10 + i);
          final password2 = _generateRandomString(10 + i + 1);
          
          final key1 = await _derivePasswordKey(password1, salt, 210000);
          final key2 = await _derivePasswordKey(password2, salt, 210000);
          
          // Different passwords should produce different keys
          expect(key1, isNot(equals(key2)),
              reason: 'Different passwords should produce different keys');
        }
      });

      test('different salts produce different keys', () async {
        const masterPassword = 'TestPassword123!';
        
        // Test with multiple salt pairs
        const numTests = 50;
        for (int i = 0; i < numTests; i++) {
          final salt1 = _generateRandomBytes(16);
          final salt2 = _generateRandomBytes(16);
          
          final key1 = await _derivePasswordKey(masterPassword, salt1, 210000);
          final key2 = await _derivePasswordKey(masterPassword, salt2, 210000);
          
          // Different salts should produce different keys
          expect(key1, isNot(equals(key2)),
              reason: 'Different salts should produce different keys');
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 9: 密钥包裹往返一致性**
    // **Validates: Requirements 3.3, 3.5**
    // Property: For any master password and dataKey, wrapping the dataKey with
    // a passwordKey derived from the master password, then unwrapping it with
    // the same master password should return the original dataKey
    group('Property 9: Key Wrapping Round-Trip Consistency', () {
      test('wrapping then unwrapping dataKey returns original', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random master password (8-32 characters)
          final passwordLength = 8 + (i % 25);
          final masterPassword = _generateRandomString(passwordLength);
          
          // Generate random 32-byte dataKey
          final originalDataKey = _generateRandomBytes(32);
          
          // Generate random salt (16 bytes as per spec)
          final salt = _generateRandomBytes(16);
          
          // Derive passwordKey from master password
          final passwordKey = await _derivePasswordKey(masterPassword, salt, 210000);
          
          // Wrap the dataKey using CryptoService
          final crypto = CryptoService();
          final wrapResult = await crypto.encryptString(
            plaintext: base64.encode(originalDataKey),
            keyBytes: passwordKey,
          );
          
          expect(wrapResult.isOk, true,
              reason: 'Wrapping dataKey should succeed');
          
          final wrappedDataKey = wrapResult.value;
          
          // Unwrap the dataKey
          final unwrapResult = await crypto.decryptString(
            cipherAll: wrappedDataKey,
            keyBytes: passwordKey,
          );
          
          expect(unwrapResult.isOk, true,
              reason: 'Unwrapping dataKey should succeed');
          
          final recoveredDataKey = base64.decode(unwrapResult.value);
          
          // The recovered dataKey should match the original
          expect(recoveredDataKey, equals(originalDataKey),
              reason: 'Round-trip wrapping/unwrapping should preserve dataKey for password: "$masterPassword"');
          
          // Verify length is still 32 bytes
          expect(recoveredDataKey.length, equals(32),
              reason: 'Recovered dataKey should be 32 bytes');
        }
      });

      test('wrong password fails to unwrap dataKey', () async {
        // Test that using a different password fails to unwrap
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Generate two different passwords
          final password1 = _generateRandomString(10 + i);
          final password2 = _generateRandomString(10 + i + 1);
          
          // Generate random dataKey
          final originalDataKey = _generateRandomBytes(32);
          
          // Generate salt
          final salt = _generateRandomBytes(16);
          
          // Derive passwordKey from first password
          final passwordKey1 = await _derivePasswordKey(password1, salt, 210000);
          
          // Wrap with first password
          final crypto = CryptoService();
          final wrapResult = await crypto.encryptString(
            plaintext: base64.encode(originalDataKey),
            keyBytes: passwordKey1,
          );
          
          expect(wrapResult.isOk, true);
          final wrappedDataKey = wrapResult.value;
          
          // Try to unwrap with second password (should fail)
          final passwordKey2 = await _derivePasswordKey(password2, salt, 210000);
          final unwrapResult = await crypto.decryptString(
            cipherAll: wrappedDataKey,
            keyBytes: passwordKey2,
          );
          
          // Should fail to decrypt with wrong password
          expect(unwrapResult.isErr, true,
              reason: 'Unwrapping with wrong password should fail');
        }
      });

      test('full KeyManager round-trip preserves dataKey', () async {
        // Test the full KeyManager workflow
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Clear storage for each test
          FlutterSecureStorage.setMockInitialValues({});
          
          // Generate random password
          final masterPassword = _generateRandomString(12 + (i % 20));
          
          // Initialize KeyManager
          final keyManager = KeyManager();
          final initResult = await keyManager.initializeWithMasterPassword(masterPassword);
          
          expect(initResult.isOk, true,
              reason: 'Initialization should succeed');
          
          // Unlock to get the dataKey
          final unlockResult1 = await keyManager.unlockDataKey(masterPassword);
          
          expect(unlockResult1.isOk, true,
              reason: 'First unlock should succeed');
          
          final dataKey1 = unlockResult1.value;
          
          // Unlock again to verify consistency
          final unlockResult2 = await keyManager.unlockDataKey(masterPassword);
          
          expect(unlockResult2.isOk, true,
              reason: 'Second unlock should succeed');
          
          final dataKey2 = unlockResult2.value;
          
          // Both unlocks should return the same dataKey
          expect(dataKey1, equals(dataKey2),
              reason: 'Multiple unlocks with same password should return same dataKey');
          
          // DataKey should be 32 bytes
          expect(dataKey1.length, equals(32),
              reason: 'DataKey should be 32 bytes');
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 10: 密钥参数完整性**
    // **Validates: Requirements 3.4**
    // Property: For any master password, after initialization, all required key
    // parameters (wrappedDataKey, salt, iterations, and nonce) should be stored
    // in secure storage
    group('Property 10: Key Parameter Integrity', () {
      test('all required key parameters are stored after initialization', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Clear storage for each test
          FlutterSecureStorage.setMockInitialValues({});
          
          // Generate random master password (8-32 characters)
          final passwordLength = 8 + (i % 25);
          final masterPassword = _generateRandomString(passwordLength);
          
          // Initialize KeyManager
          final keyManager = KeyManager();
          final initResult = await keyManager.initializeWithMasterPassword(masterPassword);
          
          expect(initResult.isOk, true,
              reason: 'Initialization should succeed for password: "$masterPassword"');
          
          // Get key parameters
          final paramsResult = await keyManager.getKeyParams();
          
          expect(paramsResult.isOk, true,
              reason: 'Getting key params should succeed');
          
          final params = paramsResult.value;
          
          // Verify all required parameters are present
          expect(params.containsKey('kdfSalt'), true,
              reason: 'kdfSalt should be stored');
          expect(params.containsKey('kdfIterations'), true,
              reason: 'kdfIterations should be stored');
          expect(params.containsKey('wrappedDataKey'), true,
              reason: 'wrappedDataKey should be stored');
          
          // Verify kdfSalt is not empty and is valid base64
          final kdfSalt = params['kdfSalt'] as String;
          expect(kdfSalt.isNotEmpty, true,
              reason: 'kdfSalt should not be empty');
          
          // Decode to verify it's valid base64 and correct length (16 bytes)
          final saltBytes = base64.decode(kdfSalt);
          expect(saltBytes.length, equals(16),
              reason: 'kdfSalt should be 16 bytes');
          
          // Verify kdfIterations is correct
          final kdfIterations = params['kdfIterations'] as int;
          expect(kdfIterations, equals(210000),
              reason: 'kdfIterations should be 210000 as per spec');
          
          // Verify wrappedDataKey is not empty and has correct format (nonce:cipher:mac)
          final wrappedDataKey = params['wrappedDataKey'] as String;
          expect(wrappedDataKey.isNotEmpty, true,
              reason: 'wrappedDataKey should not be empty');
          
          final parts = wrappedDataKey.split(':');
          expect(parts.length, equals(3),
              reason: 'wrappedDataKey should have format nonce:cipher:mac');
          
          // Verify each part is valid base64
          for (int j = 0; j < parts.length; j++) {
            expect(() => base64.decode(parts[j]), returnsNormally,
                reason: 'Part $j of wrappedDataKey should be valid base64');
          }
          
          // Verify nonce is 12 bytes (AES-GCM standard)
          final nonceBytes = base64.decode(parts[0]);
          expect(nonceBytes.length, equals(12),
              reason: 'Nonce should be 12 bytes for AES-GCM');
          
          // Verify we can successfully unlock with the stored parameters
          final unlockResult = await keyManager.unlockDataKey(masterPassword);
          expect(unlockResult.isOk, true,
              reason: 'Should be able to unlock with stored parameters');
          
          final dataKey = unlockResult.value;
          expect(dataKey.length, equals(32),
              reason: 'Unlocked dataKey should be 32 bytes');
        }
      });

      test('key parameters persist across KeyManager instances', () async {
        // Test that parameters stored by one instance can be read by another
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Clear storage for each test
          FlutterSecureStorage.setMockInitialValues({});
          
          // Generate random password
          final masterPassword = _generateRandomString(12 + (i % 20));
          
          // Initialize with first instance
          final keyManager1 = KeyManager();
          final initResult = await keyManager1.initializeWithMasterPassword(masterPassword);
          expect(initResult.isOk, true);
          
          // Get parameters from first instance
          final params1Result = await keyManager1.getKeyParams();
          expect(params1Result.isOk, true);
          final params1 = params1Result.value;
          
          // Create second instance and verify it can read the same parameters
          final keyManager2 = KeyManager();
          final params2Result = await keyManager2.getKeyParams();
          expect(params2Result.isOk, true);
          final params2 = params2Result.value;
          
          // Parameters should match
          expect(params2['kdfSalt'], equals(params1['kdfSalt']),
              reason: 'kdfSalt should persist across instances');
          expect(params2['kdfIterations'], equals(params1['kdfIterations']),
              reason: 'kdfIterations should persist across instances');
          expect(params2['wrappedDataKey'], equals(params1['wrappedDataKey']),
              reason: 'wrappedDataKey should persist across instances');
          
          // Both instances should be able to unlock with the same password
          final unlock1 = await keyManager1.unlockDataKey(masterPassword);
          final unlock2 = await keyManager2.unlockDataKey(masterPassword);
          
          expect(unlock1.isOk, true);
          expect(unlock2.isOk, true);
          expect(unlock1.value, equals(unlock2.value),
              reason: 'Both instances should unlock to the same dataKey');
        }
      });

      test('parameters are complete after password change', () async {
        // Test that all parameters remain complete after changing password
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Clear storage for each test
          FlutterSecureStorage.setMockInitialValues({});
          
          // Generate random passwords
          final oldPassword = _generateRandomString(10 + i);
          final newPassword = _generateRandomString(10 + i + 1);
          
          // Initialize
          final keyManager = KeyManager();
          await keyManager.initializeWithMasterPassword(oldPassword);
          
          // Get original dataKey
          final dataKey1Result = await keyManager.unlockDataKey(oldPassword);
          expect(dataKey1Result.isOk, true);
          final dataKey1 = dataKey1Result.value;
          
          // Change password
          final changeResult = await keyManager.changeMasterPassword(
            oldPassword,
            newPassword,
          );
          expect(changeResult.isOk, true);
          
          // Get parameters after password change
          final paramsResult = await keyManager.getKeyParams();
          expect(paramsResult.isOk, true);
          final params = paramsResult.value;
          
          // Verify all required parameters are still present
          expect(params.containsKey('kdfSalt'), true,
              reason: 'kdfSalt should be present after password change');
          expect(params.containsKey('kdfIterations'), true,
              reason: 'kdfIterations should be present after password change');
          expect(params.containsKey('wrappedDataKey'), true,
              reason: 'wrappedDataKey should be present after password change');
          
          // Verify parameters are valid
          final kdfSalt = params['kdfSalt'] as String;
          final saltBytes = base64.decode(kdfSalt);
          expect(saltBytes.length, equals(16),
              reason: 'kdfSalt should still be 16 bytes after password change');
          
          expect(params['kdfIterations'], equals(210000),
              reason: 'kdfIterations should remain 210000 after password change');
          
          final wrappedDataKey = params['wrappedDataKey'] as String;
          final parts = wrappedDataKey.split(':');
          expect(parts.length, equals(3),
              reason: 'wrappedDataKey should still have correct format after password change');
          
          // Verify we can unlock with new password and get same dataKey
          final dataKey2Result = await keyManager.unlockDataKey(newPassword);
          expect(dataKey2Result.isOk, true);
          final dataKey2 = dataKey2Result.value;
          
          expect(dataKey1, equals(dataKey2),
              reason: 'DataKey should remain the same after password change');
        }
      });

      test('missing parameters prevent unlock', () async {
        // Test that if any parameter is missing, unlock fails gracefully
        const masterPassword = 'TestPassword123!';
        
        // Initialize normally
        FlutterSecureStorage.setMockInitialValues({});
        final keyManager = KeyManager();
        await keyManager.initializeWithMasterPassword(masterPassword);
        
        // Verify normal unlock works
        final normalUnlock = await keyManager.unlockDataKey(masterPassword);
        expect(normalUnlock.isOk, true);
        
        // Test with missing wrappedDataKey
        FlutterSecureStorage.setMockInitialValues({
          'kdf_salt': 'dGVzdHNhbHQxMjM0NTY=',
          'kdf_iterations': '210000',
        });
        final keyManager2 = KeyManager();
        final unlock2 = await keyManager2.unlockDataKey(masterPassword);
        expect(unlock2.isErr, true,
            reason: 'Unlock should fail when wrappedDataKey is missing');
        
        // Test with missing salt
        FlutterSecureStorage.setMockInitialValues({
          'wrapped_data_key': 'dGVzdA==:dGVzdA==:dGVzdA==',
          'kdf_iterations': '210000',
        });
        final keyManager3 = KeyManager();
        final unlock3 = await keyManager3.unlockDataKey(masterPassword);
        expect(unlock3.isErr, true,
            reason: 'Unlock should fail when kdfSalt is missing');
        
        // Test with missing iterations
        FlutterSecureStorage.setMockInitialValues({
          'wrapped_data_key': 'dGVzdA==:dGVzdA==:dGVzdA==',
          'kdf_salt': 'dGVzdHNhbHQxMjM0NTY=',
        });
        final keyManager4 = KeyManager();
        final unlock4 = await keyManager4.unlockDataKey(masterPassword);
        expect(unlock4.isErr, true,
            reason: 'Unlock should fail when kdfIterations is missing');
      });
    });
  });
}

// Helper function to derive password key (mirrors KeyManager's private method)
Future<List<int>> _derivePasswordKey(
  String masterPassword,
  List<int> salt,
  int iterations,
) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );

  final passwordBytes = utf8.encode(masterPassword);
  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(passwordBytes),
    nonce: salt,
  );

  return await secretKey.extractBytes();
}

// Helper function to generate random bytes
List<int> _generateRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

// Helper function to generate random string
String _generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
