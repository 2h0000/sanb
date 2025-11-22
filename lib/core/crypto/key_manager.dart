import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/result.dart';
import 'crypto_service.dart';

/// Manages master password, key derivation, and key wrapping
class KeyManager {
  final _storage = const FlutterSecureStorage();
  final _crypto = CryptoService();
  
  // Storage keys
  static const _keyWrappedDataKey = 'wrapped_data_key';
  static const _keyKdfSalt = 'kdf_salt';
  static const _keyKdfIterations = 'kdf_iterations';
  static const _keyWrapNonce = 'wrap_nonce';

  // KDF parameters
  static const int kdfIterations = 210000;
  static const int kdfKeyLength = 256; // bits

  /// Initializes the vault with a master password
  /// 
  /// This generates a random dataKey, derives a passwordKey from the master password,
  /// and wraps the dataKey with the passwordKey.
  /// 
  /// Parameters:
  /// - [masterPassword]: The user's master password
  /// 
  /// Returns: Result indicating success or error
  Future<Result<void, String>> initializeWithMasterPassword(
    String masterPassword,
  ) async {
    try {
      // Check if already initialized
      final isInit = await isInitialized();
      if (isInit) {
        return const Err('Vault is already initialized');
      }

      // Generate random 32-byte dataKey
      final dataKey = await _crypto.generateKey();

      // Generate random 16-byte salt
      final salt = _generateRandomBytes(16);

      // Derive passwordKey from master password using PBKDF2
      final passwordKeyResult = await _derivePasswordKey(
        masterPassword,
        salt,
        kdfIterations,
      );

      if (passwordKeyResult.isErr) {
        return Err(passwordKeyResult.error);
      }

      final passwordKey = passwordKeyResult.value;

      // Wrap dataKey with passwordKey using AES-GCM
      final wrappedResult = await _crypto.encryptString(
        plaintext: base64.encode(dataKey),
        keyBytes: passwordKey,
      );

      if (wrappedResult.isErr) {
        return Err('Failed to wrap data key: ${wrappedResult.error}');
      }

      final wrappedDataKey = wrappedResult.value;

      // Store all parameters in secure storage
      await _storage.write(key: _keyWrappedDataKey, value: wrappedDataKey);
      await _storage.write(key: _keyKdfSalt, value: base64.encode(salt));
      await _storage.write(key: _keyKdfIterations, value: kdfIterations.toString());

      return const Ok(null);
    } catch (e) {
      return Err('Initialization failed: $e');
    }
  }

  /// Unlocks the vault and retrieves the dataKey
  /// 
  /// Parameters:
  /// - [masterPassword]: The user's master password
  /// 
  /// Returns: Result containing the 32-byte dataKey or an error
  Future<Result<List<int>, String>> unlockDataKey(
    String masterPassword,
  ) async {
    try {
      // Check if initialized
      final isInit = await isInitialized();
      if (!isInit) {
        return const Err('Vault is not initialized');
      }

      // Retrieve stored parameters
      final wrappedDataKey = await _storage.read(key: _keyWrappedDataKey);
      final saltB64 = await _storage.read(key: _keyKdfSalt);
      final iterationsStr = await _storage.read(key: _keyKdfIterations);

      if (wrappedDataKey == null || saltB64 == null || iterationsStr == null) {
        return const Err('Missing key parameters in storage');
      }

      final salt = base64.decode(saltB64);
      final iterations = int.parse(iterationsStr);

      // Derive passwordKey from master password
      final passwordKeyResult = await _derivePasswordKey(
        masterPassword,
        salt,
        iterations,
      );

      if (passwordKeyResult.isErr) {
        return Err(passwordKeyResult.error);
      }

      final passwordKey = passwordKeyResult.value;

      // Unwrap dataKey
      final unwrappedResult = await _crypto.decryptString(
        cipherAll: wrappedDataKey,
        keyBytes: passwordKey,
      );

      if (unwrappedResult.isErr) {
        return const Err('Incorrect master password');
      }

      final dataKey = base64.decode(unwrappedResult.value);

      if (dataKey.length != 32) {
        return const Err('Invalid data key length');
      }

      return Ok(dataKey);
    } catch (e) {
      return Err('Unlock failed: $e');
    }
  }

  /// Checks if the vault has been initialized
  Future<bool> isInitialized() async {
    final wrappedDataKey = await _storage.read(key: _keyWrappedDataKey);
    return wrappedDataKey != null;
  }

  /// Changes the master password
  /// 
  /// This re-wraps the existing dataKey with a new passwordKey derived from
  /// the new master password.
  /// 
  /// Parameters:
  /// - [oldPassword]: The current master password
  /// - [newPassword]: The new master password
  /// 
  /// Returns: Result indicating success or error
  Future<Result<void, String>> changeMasterPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // First unlock with old password to get dataKey
      final unlockResult = await unlockDataKey(oldPassword);
      if (unlockResult.isErr) {
        return Err('Failed to verify old password: ${unlockResult.error}');
      }

      final dataKey = unlockResult.value;

      // Generate new salt
      final newSalt = _generateRandomBytes(16);

      // Derive new passwordKey
      final newPasswordKeyResult = await _derivePasswordKey(
        newPassword,
        newSalt,
        kdfIterations,
      );

      if (newPasswordKeyResult.isErr) {
        return Err(newPasswordKeyResult.error);
      }

      final newPasswordKey = newPasswordKeyResult.value;

      // Wrap dataKey with new passwordKey
      final wrappedResult = await _crypto.encryptString(
        plaintext: base64.encode(dataKey),
        keyBytes: newPasswordKey,
      );

      if (wrappedResult.isErr) {
        return Err('Failed to wrap data key: ${wrappedResult.error}');
      }

      final newWrappedDataKey = wrappedResult.value;

      // Update storage
      await _storage.write(key: _keyWrappedDataKey, value: newWrappedDataKey);
      await _storage.write(key: _keyKdfSalt, value: base64.encode(newSalt));

      return const Ok(null);
    } catch (e) {
      return Err('Password change failed: $e');
    }
  }

  /// Retrieves the key parameters for backup/sync
  /// 
  /// Returns: Map containing kdfSalt, kdfIterations, wrappedDataKey, and wrapNonce
  Future<Result<Map<String, dynamic>, String>> getKeyParams() async {
    try {
      final isInit = await isInitialized();
      if (!isInit) {
        return const Err('Vault is not initialized');
      }

      final wrappedDataKey = await _storage.read(key: _keyWrappedDataKey);
      final saltB64 = await _storage.read(key: _keyKdfSalt);
      final iterationsStr = await _storage.read(key: _keyKdfIterations);

      if (wrappedDataKey == null || saltB64 == null || iterationsStr == null) {
        return const Err('Missing key parameters');
      }

      return Ok({
        'kdfSalt': saltB64,
        'kdfIterations': int.parse(iterationsStr),
        'wrappedDataKey': wrappedDataKey,
      });
    } catch (e) {
      return Err('Failed to get key params: $e');
    }
  }

  /// Restores key parameters from backup/sync
  /// 
  /// Parameters:
  /// - [params]: Map containing kdfSalt, kdfIterations, and wrappedDataKey
  /// 
  /// Returns: Result indicating success or error
  Future<Result<void, String>> restoreKeyParams(
    Map<String, dynamic> params,
  ) async {
    try {
      final kdfSalt = params['kdfSalt'] as String?;
      final kdfIterations = params['kdfIterations'] as int?;
      final wrappedDataKey = params['wrappedDataKey'] as String?;

      if (kdfSalt == null || kdfIterations == null || wrappedDataKey == null) {
        return const Err('Invalid key parameters');
      }

      // Store parameters
      await _storage.write(key: _keyWrappedDataKey, value: wrappedDataKey);
      await _storage.write(key: _keyKdfSalt, value: kdfSalt);
      await _storage.write(key: _keyKdfIterations, value: kdfIterations.toString());

      return const Ok(null);
    } catch (e) {
      return Err('Failed to restore key params: $e');
    }
  }

  /// Clears all stored key data (for logout/reset)
  Future<void> clearAllKeys() async {
    await _storage.delete(key: _keyWrappedDataKey);
    await _storage.delete(key: _keyKdfSalt);
    await _storage.delete(key: _keyKdfIterations);
    await _storage.delete(key: _keyWrapNonce);
  }

  // Private helper methods

  /// Derives a passwordKey from master password using PBKDF2-HMAC-SHA256
  Future<Result<List<int>, String>> _derivePasswordKey(
    String masterPassword,
    List<int> salt,
    int iterations,
  ) async {
    try {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: kdfKeyLength,
      );

      final passwordBytes = utf8.encode(masterPassword);
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      );

      final keyBytes = await secretKey.extractBytes();
      return Ok(keyBytes);
    } catch (e) {
      return Err('Key derivation failed: $e');
    }
  }

  /// Generates random bytes
  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
