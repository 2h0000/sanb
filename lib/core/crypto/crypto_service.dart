import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../utils/result.dart';

/// Service for AES-GCM encryption and decryption operations
class CryptoService {
  final _algo = AesGcm.with256bits();

  /// Encrypts a string using AES-256-GCM
  /// 
  /// Returns a string in the format "nonce:cipher:mac" (all Base64 encoded)
  /// 
  /// Parameters:
  /// - [plaintext]: The string to encrypt
  /// - [keyBytes]: 32-byte encryption key
  /// 
  /// Returns: Result containing the encrypted string or an error message
  Future<Result<String, String>> encryptString({
    required String plaintext,
    required List<int> keyBytes,
  }) async {
    try {
      if (keyBytes.length != 32) {
        return const Err('Key must be 32 bytes for AES-256');
      }

      // Convert plaintext to bytes
      final plaintextBytes = utf8.encode(plaintext);

      // Create secret key
      final secretKey = SecretKey(keyBytes);

      // Encrypt
      final secretBox = await _algo.encrypt(
        plaintextBytes,
        secretKey: secretKey,
      );

      // Extract components
      final nonce = secretBox.nonce;
      final cipherText = secretBox.cipherText;
      final mac = secretBox.mac.bytes;

      // Encode to Base64
      final nonceB64 = base64.encode(nonce);
      final cipherB64 = base64.encode(cipherText);
      final macB64 = base64.encode(mac);

      // Return in format "nonce:cipher:mac"
      return Ok('$nonceB64:$cipherB64:$macB64');
    } catch (e) {
      return Err('Encryption failed: $e');
    }
  }

  /// Decrypts a string using AES-256-GCM
  /// 
  /// Parameters:
  /// - [cipherAll]: Encrypted string in format "nonce:cipher:mac" (Base64 encoded)
  /// - [keyBytes]: 32-byte decryption key
  /// 
  /// Returns: Result containing the decrypted plaintext or an error message
  Future<Result<String, String>> decryptString({
    required String cipherAll,
    required List<int> keyBytes,
  }) async {
    try {
      if (keyBytes.length != 32) {
        return const Err('Key must be 32 bytes for AES-256');
      }

      // Split the cipher string
      final parts = cipherAll.split(':');
      if (parts.length != 3) {
        return const Err('Invalid cipher format. Expected "nonce:cipher:mac"');
      }

      // Decode from Base64
      final nonce = base64.decode(parts[0]);
      final cipherText = base64.decode(parts[1]);
      final mac = base64.decode(parts[2]);

      // Create secret key
      final secretKey = SecretKey(keyBytes);

      // Create SecretBox
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      );

      // Decrypt
      final decryptedBytes = await _algo.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      // Convert to string
      final plaintext = utf8.decode(decryptedBytes);

      return Ok(plaintext);
    } catch (e) {
      return Err('Decryption failed: $e');
    }
  }

  /// Generates a random 32-byte key suitable for AES-256
  Future<List<int>> generateKey() async {
    final secretKey = await _algo.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    return keyBytes;
  }

  /// Generates a random nonce (12 bytes for AES-GCM)
  List<int> generateNonce() {
    return _algo.newNonce();
  }
}
