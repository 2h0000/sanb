import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('CryptoService', () {
    test('should generate a 32-byte key', () async {
      final key = await cryptoService.generateKey();
      expect(key.length, 32);
    });

    test('should encrypt and decrypt a string successfully', () async {
      const plaintext = 'Hello, World!';
      final key = await cryptoService.generateKey();

      // Encrypt
      final encryptResult = await cryptoService.encryptString(
        plaintext: plaintext,
        keyBytes: key,
      );

      expect(encryptResult.isOk, true);
      final ciphertext = encryptResult.value;

      // Verify format (nonce:cipher:mac)
      expect(ciphertext.split(':').length, 3);

      // Decrypt
      final decryptResult = await cryptoService.decryptString(
        cipherAll: ciphertext,
        keyBytes: key,
      );

      expect(decryptResult.isOk, true);
      expect(decryptResult.value, plaintext);
    });

    test('should fail to encrypt with invalid key length', () async {
      const plaintext = 'Test';
      final invalidKey = List<int>.filled(16, 0); // Wrong length

      final result = await cryptoService.encryptString(
        plaintext: plaintext,
        keyBytes: invalidKey,
      );

      expect(result.isErr, true);
      expect(result.error, contains('32 bytes'));
    });

    test('should fail to decrypt with wrong key', () async {
      const plaintext = 'Secret message';
      final key1 = await cryptoService.generateKey();
      final key2 = await cryptoService.generateKey();

      // Encrypt with key1
      final encryptResult = await cryptoService.encryptString(
        plaintext: plaintext,
        keyBytes: key1,
      );

      expect(encryptResult.isOk, true);

      // Try to decrypt with key2
      final decryptResult = await cryptoService.decryptString(
        cipherAll: encryptResult.value,
        keyBytes: key2,
      );

      expect(decryptResult.isErr, true);
    });

    test('should fail to decrypt with invalid format', () async {
      final key = await cryptoService.generateKey();

      final result = await cryptoService.decryptString(
        cipherAll: 'invalid:format',
        keyBytes: key,
      );

      expect(result.isErr, true);
    });

    test('should handle empty string encryption', () async {
      const plaintext = '';
      final key = await cryptoService.generateKey();

      final encryptResult = await cryptoService.encryptString(
        plaintext: plaintext,
        keyBytes: key,
      );

      expect(encryptResult.isOk, true);

      final decryptResult = await cryptoService.decryptString(
        cipherAll: encryptResult.value,
        keyBytes: key,
      );

      expect(decryptResult.isOk, true);
      expect(decryptResult.value, plaintext);
    });

    test('should handle special characters', () async {
      const plaintext = '你好世界! 🔐 Special chars: @#\$%^&*()';
      final key = await cryptoService.generateKey();

      final encryptResult = await cryptoService.encryptString(
        plaintext: plaintext,
        keyBytes: key,
      );

      expect(encryptResult.isOk, true);

      final decryptResult = await cryptoService.decryptString(
        cipherAll: encryptResult.value,
        keyBytes: key,
      );

      expect(decryptResult.isOk, true);
      expect(decryptResult.value, plaintext);
    });

    // Edge case tests for Requirements 3.6, 4.5
    group('Edge Case Tests', () {
      test('should handle very long strings (10KB)', () async {
        // Test with 10,000 character string
        final plaintext = 'A' * 10000;
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
        expect(decryptResult.value.length, 10000);
      });

      test('should handle very long strings (100KB)', () async {
        // Test with 100,000 character string
        final plaintext = 'B' * 100000;
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
        expect(decryptResult.value.length, 100000);
      });

      test('should handle very long strings (1MB)', () async {
        // Test with 1,000,000 character string
        final plaintext = 'C' * 1000000;
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
        expect(decryptResult.value.length, 1000000);
      });

      test('should reject key with length 0', () async {
        const plaintext = 'Test';
        final invalidKey = <int>[];

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 1', () async {
        const plaintext = 'Test';
        final invalidKey = [42];

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 16 (AES-128 size)', () async {
        const plaintext = 'Test';
        final invalidKey = List<int>.filled(16, 0);

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 24 (AES-192 size)', () async {
        const plaintext = 'Test';
        final invalidKey = List<int>.filled(24, 0);

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 31 (one byte short)', () async {
        const plaintext = 'Test';
        final invalidKey = List<int>.filled(31, 0);

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 33 (one byte over)', () async {
        const plaintext = 'Test';
        final invalidKey = List<int>.filled(33, 0);

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject key with length 64 (double size)', () async {
        const plaintext = 'Test';
        final invalidKey = List<int>.filled(64, 0);

        final result = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should reject invalid key length during decryption', () async {
        const ciphertext = 'nonce:cipher:mac';
        final invalidKey = List<int>.filled(16, 0);

        final result = await cryptoService.decryptString(
          cipherAll: ciphertext,
          keyBytes: invalidKey,
        );

        expect(result.isErr, true);
        expect(result.error, contains('32 bytes'));
      });

      test('should handle newline characters', () async {
        const plaintext = 'Line 1\nLine 2\nLine 3\n';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle tab characters', () async {
        const plaintext = 'Column1\tColumn2\tColumn3';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle carriage return characters', () async {
        const plaintext = 'Line 1\r\nLine 2\r\nLine 3';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle null byte characters', () async {
        const plaintext = 'Before\x00After';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle all ASCII control characters', () async {
        // Test with all control characters (0x00-0x1F)
        final controlChars = List.generate(32, (i) => String.fromCharCode(i)).join();
        final plaintext = 'Start${controlChars}End';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle mixed Unicode characters', () async {
        const plaintext = 'English 中文 日本語 한국어 العربية עברית Ελληνικά';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle emoji sequences', () async {
        const plaintext = '👨‍👩‍👧‍👦 👍🏽 🏳️‍🌈 🇺🇸';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle JSON-like strings', () async {
        const plaintext = '{"name":"John","age":30,"city":"New York","nested":{"key":"value"}}';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle XML-like strings', () async {
        const plaintext = '<?xml version="1.0"?><root><item>value</item></root>';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle strings with many colons', () async {
        const plaintext = 'colon:separated:values:with:many:colons:::';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle strings with Base64-like content', () async {
        const plaintext = 'SGVsbG8gV29ybGQh+/=';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle repeated characters', () async {
        const plaintext = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle single character', () async {
        const plaintext = 'X';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle whitespace-only strings', () async {
        const plaintext = '     ';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle strings with only newlines', () async {
        const plaintext = '\n\n\n\n';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle password-like strings with special characters', () async {
        const plaintext = 'P@ssw0rd!#\$%^&*()_+-=[]{}|;:,.<>?/~`';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle URL strings', () async {
        const plaintext = 'https://example.com:8080/path?query=value&other=123#fragment';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle email-like strings', () async {
        const plaintext = 'user+tag@example.co.uk';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });

      test('should handle markdown-like strings', () async {
        const plaintext = '# Heading\n\n**Bold** and *italic*\n\n- List item\n- Another item\n\n```code block```';
        final key = await cryptoService.generateKey();

        final encryptResult = await cryptoService.encryptString(
          plaintext: plaintext,
          keyBytes: key,
        );

        expect(encryptResult.isOk, true);

        final decryptResult = await cryptoService.decryptString(
          cipherAll: encryptResult.value,
          keyBytes: key,
        );

        expect(decryptResult.isOk, true);
        expect(decryptResult.value, plaintext);
      });
    });

    // **Feature: encrypted-notebook-app, Property 11: 加密不变性**
    // **Validates: Requirements 4.1**
    // Property: For any plaintext and key, encrypting the same plaintext multiple
    // times should produce different ciphertexts (due to random nonces), but each
    // ciphertext should decrypt back to the original plaintext. This ensures
    // encryption is non-deterministic (secure) while decryption is consistent.
    group('Property 11: Encryption Invariance', () {
      test('encrypting same plaintext produces different ciphertexts', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext (0-500 characters)
          final plaintextLength = i % 501;
          final plaintext = _generateRandomString(plaintextLength);
          
          // Generate random 32-byte key
          final key = await cryptoService.generateKey();
          
          // Encrypt the same plaintext multiple times
          final encryptResult1 = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          final encryptResult2 = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          final encryptResult3 = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult1.isOk, true,
              reason: 'First encryption should succeed');
          expect(encryptResult2.isOk, true,
              reason: 'Second encryption should succeed');
          expect(encryptResult3.isOk, true,
              reason: 'Third encryption should succeed');
          
          final ciphertext1 = encryptResult1.value;
          final ciphertext2 = encryptResult2.value;
          final ciphertext3 = encryptResult3.value;
          
          // Ciphertexts should be different (non-deterministic encryption)
          expect(ciphertext1, isNot(equals(ciphertext2)),
              reason: 'Encrypting same plaintext should produce different ciphertexts (iteration $i)');
          expect(ciphertext2, isNot(equals(ciphertext3)),
              reason: 'Encrypting same plaintext should produce different ciphertexts (iteration $i)');
          expect(ciphertext1, isNot(equals(ciphertext3)),
              reason: 'Encrypting same plaintext should produce different ciphertexts (iteration $i)');
          
          // All ciphertexts should have correct format (nonce:cipher:mac)
          expect(ciphertext1.split(':').length, equals(3),
              reason: 'Ciphertext should have format nonce:cipher:mac');
          expect(ciphertext2.split(':').length, equals(3),
              reason: 'Ciphertext should have format nonce:cipher:mac');
          expect(ciphertext3.split(':').length, equals(3),
              reason: 'Ciphertext should have format nonce:cipher:mac');
          
          // Each ciphertext should decrypt back to the original plaintext
          final decryptResult1 = await cryptoService.decryptString(
            cipherAll: ciphertext1,
            keyBytes: key,
          );
          
          final decryptResult2 = await cryptoService.decryptString(
            cipherAll: ciphertext2,
            keyBytes: key,
          );
          
          final decryptResult3 = await cryptoService.decryptString(
            cipherAll: ciphertext3,
            keyBytes: key,
          );
          
          expect(decryptResult1.isOk, true,
              reason: 'First decryption should succeed');
          expect(decryptResult2.isOk, true,
              reason: 'Second decryption should succeed');
          expect(decryptResult3.isOk, true,
              reason: 'Third decryption should succeed');
          
          // All decryptions should return the original plaintext
          expect(decryptResult1.value, equals(plaintext),
              reason: 'First ciphertext should decrypt to original plaintext (iteration $i)');
          expect(decryptResult2.value, equals(plaintext),
              reason: 'Second ciphertext should decrypt to original plaintext (iteration $i)');
          expect(decryptResult3.value, equals(plaintext),
              reason: 'Third ciphertext should decrypt to original plaintext (iteration $i)');
        }
      });

      test('encryption produces unique nonces', () async {
        // Verify that each encryption uses a different nonce
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext
          final plaintext = _generateRandomString(50 + (i % 100));
          
          // Generate random key
          final key = await cryptoService.generateKey();
          
          // Collect nonces from multiple encryptions
          final nonces = <String>{};
          const numEncryptions = 10;
          
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption $j should succeed');
            
            // Extract nonce (first part of "nonce:cipher:mac")
            final parts = encryptResult.value.split(':');
            final nonce = parts[0];
            
            nonces.add(nonce);
          }
          
          // All nonces should be unique
          expect(nonces.length, equals(numEncryptions),
              reason: 'All $numEncryptions encryptions should produce unique nonces (iteration $i)');
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 12: Nonce 唯一性**
    // **Validates: Requirements 4.2**
    // Property: For any encryption operation, the system should generate a unique
    // 12-byte nonce. Across multiple encryption operations (even with the same
    // plaintext and key), all nonces should be unique to ensure security.
    group('Property 12: Nonce Uniqueness', () {
      test('all nonces are unique across multiple encryptions', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext (0-500 characters)
          final plaintextLength = i % 501;
          final plaintext = _generateRandomString(plaintextLength);
          
          // Generate random 32-byte key
          final key = await cryptoService.generateKey();
          
          // Collect nonces from many encryption operations
          final nonces = <String>{};
          const numEncryptions = 50;
          
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption $j should succeed (iteration $i)');
            
            // Extract nonce (first part of "nonce:cipher:mac")
            final parts = encryptResult.value.split(':');
            expect(parts.length, equals(3),
                reason: 'Ciphertext should have format nonce:cipher:mac');
            
            final nonceB64 = parts[0];
            
            // Verify nonce is valid base64
            final nonceBytes = base64.decode(nonceB64);
            
            // Verify nonce is 12 bytes (AES-GCM standard)
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce should be 12 bytes for AES-GCM (iteration $i, encryption $j)');
            
            // Add to set to check uniqueness
            nonces.add(nonceB64);
          }
          
          // All nonces should be unique
          expect(nonces.length, equals(numEncryptions),
              reason: 'All $numEncryptions encryptions should produce unique nonces (iteration $i)');
        }
      });

      test('nonces are unique across different plaintexts', () async {
        // Test that nonces are unique even when encrypting different plaintexts
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random key
          final key = await cryptoService.generateKey();
          
          // Collect nonces from encrypting different plaintexts
          final nonces = <String>{};
          const numEncryptions = 30;
          
          for (int j = 0; j < numEncryptions; j++) {
            // Generate different plaintext for each encryption
            final plaintext = _generateRandomString(10 + j);
            
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption should succeed');
            
            // Extract nonce
            final parts = encryptResult.value.split(':');
            final nonceB64 = parts[0];
            
            // Verify nonce length
            final nonceBytes = base64.decode(nonceB64);
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce should be 12 bytes');
            
            nonces.add(nonceB64);
          }
          
          // All nonces should be unique
          expect(nonces.length, equals(numEncryptions),
              reason: 'All nonces should be unique across different plaintexts (iteration $i)');
        }
      });

      test('nonces are unique across different keys', () async {
        // Test that nonces are unique even when using different keys
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Use same plaintext
          final plaintext = _generateRandomString(100);
          
          // Collect nonces from encrypting with different keys
          final nonces = <String>{};
          const numEncryptions = 30;
          
          for (int j = 0; j < numEncryptions; j++) {
            // Generate different key for each encryption
            final key = await cryptoService.generateKey();
            
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption should succeed');
            
            // Extract nonce
            final parts = encryptResult.value.split(':');
            final nonceB64 = parts[0];
            
            // Verify nonce length
            final nonceBytes = base64.decode(nonceB64);
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce should be 12 bytes');
            
            nonces.add(nonceB64);
          }
          
          // All nonces should be unique
          expect(nonces.length, equals(numEncryptions),
              reason: 'All nonces should be unique across different keys (iteration $i)');
        }
      });

      test('nonces are unique in high-volume scenario', () async {
        // Test nonce uniqueness with a large number of encryptions
        // This simulates encrypting multiple VaultItem fields
        const numTests = 10;
        
        for (int i = 0; i < numTests; i++) {
          final key = await cryptoService.generateKey();
          
          // Simulate encrypting many VaultItem fields
          // Each VaultItem has 5 fields (title, username, password, url, note)
          // Simulate 100 VaultItems = 500 encryptions
          final nonces = <String>{};
          const numVaultItems = 100;
          const fieldsPerItem = 5;
          const totalEncryptions = numVaultItems * fieldsPerItem;
          
          for (int j = 0; j < totalEncryptions; j++) {
            // Generate random field content
            final fieldContent = _generateRandomString(20 + (j % 50));
            
            final encryptResult = await cryptoService.encryptString(
              plaintext: fieldContent,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption $j should succeed');
            
            // Extract nonce
            final parts = encryptResult.value.split(':');
            final nonceB64 = parts[0];
            
            // Verify nonce length
            final nonceBytes = base64.decode(nonceB64);
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce should be 12 bytes');
            
            nonces.add(nonceB64);
          }
          
          // All nonces should be unique
          expect(nonces.length, equals(totalEncryptions),
              reason: 'All $totalEncryptions nonces should be unique in high-volume scenario (iteration $i)');
        }
      });

      test('nonces have sufficient entropy', () async {
        // Test that nonces are truly random and not predictable
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final key = await cryptoService.generateKey();
          final plaintext = _generateRandomString(100);
          
          // Collect nonces
          final nonces = <List<int>>[];
          const numEncryptions = 20;
          
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true);
            
            // Extract nonce bytes
            final parts = encryptResult.value.split(':');
            final nonceBytes = base64.decode(parts[0]);
            
            nonces.add(nonceBytes);
          }
          
          // Check that nonces are not sequential or predictable
          // Compare consecutive nonces - they should differ significantly
          for (int j = 0; j < nonces.length - 1; j++) {
            final nonce1 = nonces[j];
            final nonce2 = nonces[j + 1];
            
            // Count how many bytes differ
            int differentBytes = 0;
            for (int k = 0; k < 12; k++) {
              if (nonce1[k] != nonce2[k]) {
                differentBytes++;
              }
            }
            
            // At least some bytes should differ (not all the same)
            expect(differentBytes, greaterThan(0),
                reason: 'Consecutive nonces should differ (iteration $i, nonces $j and ${j + 1})');
            
            // Nonces should not be identical
            expect(nonce1, isNot(equals(nonce2)),
                reason: 'Consecutive nonces should not be identical');
          }
        }
      });

      test('nonces remain unique across service instances', () async {
        // Test that different CryptoService instances produce unique nonces
        const numTests = 30;
        
        for (int i = 0; i < numTests; i++) {
          final key = await cryptoService.generateKey();
          final plaintext = _generateRandomString(100);
          
          // Collect nonces from multiple service instances
          final nonces = <String>{};
          const numInstances = 5;
          const encryptionsPerInstance = 10;
          
          for (int j = 0; j < numInstances; j++) {
            // Create new service instance
            final service = CryptoService();
            
            for (int k = 0; k < encryptionsPerInstance; k++) {
              final encryptResult = await service.encryptString(
                plaintext: plaintext,
                keyBytes: key,
              );
              
              expect(encryptResult.isOk, true);
              
              // Extract nonce
              final parts = encryptResult.value.split(':');
              final nonceB64 = parts[0];
              
              nonces.add(nonceB64);
            }
          }
          
          // All nonces should be unique across all instances
          final totalEncryptions = numInstances * encryptionsPerInstance;
          expect(nonces.length, equals(totalEncryptions),
              reason: 'All nonces should be unique across service instances (iteration $i)');
        }
      });

      test('encryption invariance with various plaintext types', () async {
        // Test with different types of plaintext content
        final testCases = [
          '',                                    // Empty string
          'a',                                   // Single character
          'Hello, World!',                       // Simple ASCII
          '你好世界',                             // Unicode
          '🔐🔑🛡️',                              // Emojis
          'Line1\nLine2\nLine3',                // Newlines
          'Tab\tSeparated\tValues',             // Tabs
          '{"key": "value", "nested": {}}',     // JSON-like
          'a' * 1000,                           // Long repeated character
          _generateRandomString(5000),          // Very long string
        ];
        
        for (int i = 0; i < testCases.length; i++) {
          final plaintext = testCases[i];
          final key = await cryptoService.generateKey();
          
          // Encrypt multiple times
          final ciphertexts = <String>[];
          const numEncryptions = 5;
          
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption should succeed for test case $i, encryption $j');
            
            ciphertexts.add(encryptResult.value);
          }
          
          // All ciphertexts should be different
          for (int j = 0; j < numEncryptions; j++) {
            for (int k = j + 1; k < numEncryptions; k++) {
              expect(ciphertexts[j], isNot(equals(ciphertexts[k])),
                  reason: 'Ciphertexts $j and $k should be different for test case $i');
            }
          }
          
          // All ciphertexts should decrypt to original plaintext
          for (int j = 0; j < numEncryptions; j++) {
            final decryptResult = await cryptoService.decryptString(
              cipherAll: ciphertexts[j],
              keyBytes: key,
            );
            
            expect(decryptResult.isOk, true,
                reason: 'Decryption should succeed for test case $i, ciphertext $j');
            expect(decryptResult.value, equals(plaintext),
                reason: 'Decrypted value should match original for test case $i, ciphertext $j');
          }
        }
      });

      test('different keys produce different ciphertexts', () async {
        // Verify that encrypting with different keys produces different results
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext
          final plaintext = _generateRandomString(100 + (i % 200));
          
          // Generate two different keys
          final key1 = await cryptoService.generateKey();
          final key2 = await cryptoService.generateKey();
          
          // Encrypt with both keys
          final encryptResult1 = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key1,
          );
          
          final encryptResult2 = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key2,
          );
          
          expect(encryptResult1.isOk, true);
          expect(encryptResult2.isOk, true);
          
          final ciphertext1 = encryptResult1.value;
          final ciphertext2 = encryptResult2.value;
          
          // Ciphertexts should be different
          expect(ciphertext1, isNot(equals(ciphertext2)),
              reason: 'Different keys should produce different ciphertexts (iteration $i)');
          
          // Each should decrypt with its own key
          final decryptResult1 = await cryptoService.decryptString(
            cipherAll: ciphertext1,
            keyBytes: key1,
          );
          
          final decryptResult2 = await cryptoService.decryptString(
            cipherAll: ciphertext2,
            keyBytes: key2,
          );
          
          expect(decryptResult1.isOk, true);
          expect(decryptResult2.isOk, true);
          expect(decryptResult1.value, equals(plaintext));
          expect(decryptResult2.value, equals(plaintext));
          
          // Cross-decryption should fail
          final crossDecrypt1 = await cryptoService.decryptString(
            cipherAll: ciphertext1,
            keyBytes: key2,
          );
          
          final crossDecrypt2 = await cryptoService.decryptString(
            cipherAll: ciphertext2,
            keyBytes: key1,
          );
          
          expect(crossDecrypt1.isErr, true,
              reason: 'Decrypting with wrong key should fail');
          expect(crossDecrypt2.isErr, true,
              reason: 'Decrypting with wrong key should fail');
        }
      });

      test('encryption preserves plaintext length information', () async {
        // Verify that encryption doesn't lose information about plaintext
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext of varying lengths
          final plaintextLength = i % 1001;
          final plaintext = _generateRandomString(plaintextLength);
          
          final key = await cryptoService.generateKey();
          
          // Encrypt
          final encryptResult = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed for length $plaintextLength');
          
          // Decrypt
          final decryptResult = await cryptoService.decryptString(
            cipherAll: encryptResult.value,
            keyBytes: key,
          );
          
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed for length $plaintextLength');
          
          // Decrypted plaintext should have exact same length
          expect(decryptResult.value.length, equals(plaintext.length),
              reason: 'Decrypted plaintext should preserve original length (iteration $i)');
          
          // And exact same content
          expect(decryptResult.value, equals(plaintext),
              reason: 'Decrypted plaintext should match original (iteration $i)');
        }
      });
    });

    // **Feature: encrypted-notebook-app, Property 13: 密文格式正确性**
    // **Validates: Requirements 4.3**
    // Property: For any encryption operation, the resulting ciphertext should
    // be in the format "nonce:cipher:mac" where all three parts are valid
    // Base64 encoded strings, the nonce is exactly 12 bytes (AES-GCM standard),
    // and the format is consistent and parseable.
    group('Property 13: Ciphertext Format Correctness', () {
      test('all ciphertexts have correct format nonce:cipher:mac', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random plaintext (0-1000 characters)
          final plaintextLength = i % 1001;
          final plaintext = _generateRandomString(plaintextLength);
          
          // Generate random 32-byte key
          final key = await cryptoService.generateKey();
          
          // Encrypt
          final encryptResult = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed (iteration $i)');
          
          final ciphertext = encryptResult.value;
          
          // Verify format: should have exactly 3 parts separated by ':'
          final parts = ciphertext.split(':');
          expect(parts.length, equals(3),
              reason: 'Ciphertext should have format "nonce:cipher:mac" with exactly 3 parts (iteration $i)');
          
          // Verify each part is non-empty
          expect(parts[0].isNotEmpty, true,
              reason: 'Nonce part should not be empty (iteration $i)');
          expect(parts[1].isNotEmpty, true,
              reason: 'Cipher part should not be empty (iteration $i)');
          expect(parts[2].isNotEmpty, true,
              reason: 'MAC part should not be empty (iteration $i)');
          
          // Verify each part is valid Base64
          List<int> nonceBytes;
          List<int> cipherBytes;
          List<int> macBytes;
          
          try {
            nonceBytes = base64.decode(parts[0]);
          } catch (e) {
            fail('Nonce should be valid Base64 (iteration $i): $e');
          }
          
          try {
            cipherBytes = base64.decode(parts[1]);
          } catch (e) {
            fail('Cipher should be valid Base64 (iteration $i): $e');
          }
          
          try {
            macBytes = base64.decode(parts[2]);
          } catch (e) {
            fail('MAC should be valid Base64 (iteration $i): $e');
          }
          
          // Verify nonce is exactly 12 bytes (AES-GCM standard)
          expect(nonceBytes.length, equals(12),
              reason: 'Nonce should be exactly 12 bytes for AES-GCM (iteration $i)');
          
          // Verify MAC is 16 bytes (AES-GCM standard)
          expect(macBytes.length, equals(16),
              reason: 'MAC should be exactly 16 bytes for AES-GCM (iteration $i)');
          
          // Verify cipher length is reasonable (should match plaintext length for stream cipher)
          // For empty plaintext, cipher should be empty
          if (plaintextLength == 0) {
            expect(cipherBytes.length, equals(0),
                reason: 'Cipher should be empty for empty plaintext (iteration $i)');
          } else {
            expect(cipherBytes.length, greaterThan(0),
                reason: 'Cipher should not be empty for non-empty plaintext (iteration $i)');
          }
          
          // Verify the ciphertext can be successfully decrypted
          final decryptResult = await cryptoService.decryptString(
            cipherAll: ciphertext,
            keyBytes: key,
          );
          
          expect(decryptResult.isOk, true,
              reason: 'Well-formed ciphertext should be decryptable (iteration $i)');
          expect(decryptResult.value, equals(plaintext),
              reason: 'Decrypted value should match original plaintext (iteration $i)');
        }
      });

      test('ciphertext format is consistent across multiple encryptions', () async {
        // Verify that all encryptions produce the same format
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final plaintext = _generateRandomString(100 + (i % 200));
          final key = await cryptoService.generateKey();
          
          // Perform multiple encryptions
          const numEncryptions = 10;
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await cryptoService.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption $j should succeed (iteration $i)');
            
            final ciphertext = encryptResult.value;
            
            // Verify format
            final parts = ciphertext.split(':');
            expect(parts.length, equals(3),
                reason: 'All ciphertexts should have 3-part format (iteration $i, encryption $j)');
            
            // Verify all parts are valid Base64
            expect(() => base64.decode(parts[0]), returnsNormally,
                reason: 'Nonce should be valid Base64 (iteration $i, encryption $j)');
            expect(() => base64.decode(parts[1]), returnsNormally,
                reason: 'Cipher should be valid Base64 (iteration $i, encryption $j)');
            expect(() => base64.decode(parts[2]), returnsNormally,
                reason: 'MAC should be valid Base64 (iteration $i, encryption $j)');
            
            // Verify nonce length
            final nonceBytes = base64.decode(parts[0]);
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce should always be 12 bytes (iteration $i, encryption $j)');
            
            // Verify MAC length
            final macBytes = base64.decode(parts[2]);
            expect(macBytes.length, equals(16),
                reason: 'MAC should always be 16 bytes (iteration $i, encryption $j)');
          }
        }
      });

      test('ciphertext format handles edge cases correctly', () async {
        // Test format correctness with various edge cases
        final key = await cryptoService.generateKey();
        
        final testCases = [
          '',                                    // Empty string
          'a',                                   // Single character
          'Hello, World!',                       // Simple ASCII
          '你好世界',                             // Unicode
          '🔐🔑🛡️',                              // Emojis
          'Line1\nLine2\nLine3',                // Newlines
          'Tab\tSeparated\tValues',             // Tabs
          '{"key": "value"}',                   // JSON-like
          'a' * 1000,                           // Long repeated character
          _generateRandomString(5000),          // Very long string
          '\x00\x01\x02\x03',                   // Control characters
          'Special: ::: chars',                 // Contains colons
        ];
        
        for (int i = 0; i < testCases.length; i++) {
          final plaintext = testCases[i];
          
          final encryptResult = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed for test case $i');
          
          final ciphertext = encryptResult.value;
          
          // Verify format
          final parts = ciphertext.split(':');
          expect(parts.length, equals(3),
              reason: 'Ciphertext should have 3-part format for test case $i');
          
          // Verify all parts are valid Base64
          final nonceBytes = base64.decode(parts[0]);
          final cipherBytes = base64.decode(parts[1]);
          final macBytes = base64.decode(parts[2]);
          
          // Verify lengths
          expect(nonceBytes.length, equals(12),
              reason: 'Nonce should be 12 bytes for test case $i');
          expect(macBytes.length, equals(16),
              reason: 'MAC should be 16 bytes for test case $i');
          
          // Verify decryption works
          final decryptResult = await cryptoService.decryptString(
            cipherAll: ciphertext,
            keyBytes: key,
          );
          
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed for test case $i');
          expect(decryptResult.value, equals(plaintext),
              reason: 'Decrypted value should match original for test case $i');
        }
      });

      test('ciphertext format does not contain invalid characters', () async {
        // Verify that ciphertext only contains valid Base64 and colon characters
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          final plaintext = _generateRandomString(i % 500);
          final key = await cryptoService.generateKey();
          
          final encryptResult = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult.isOk, true);
          final ciphertext = encryptResult.value;
          
          // Valid Base64 characters: A-Z, a-z, 0-9, +, /, =
          // Plus colon for separator
          final validCharsRegex = RegExp(r'^[A-Za-z0-9+/=:]+$');
          
          expect(validCharsRegex.hasMatch(ciphertext), true,
              reason: 'Ciphertext should only contain valid Base64 and colon characters (iteration $i)');
          
          // Should have exactly 2 colons (separating 3 parts)
          final colonCount = ':'.allMatches(ciphertext).length;
          expect(colonCount, equals(2),
              reason: 'Ciphertext should have exactly 2 colons (iteration $i)');
        }
      });

      test('ciphertext format is stable across service instances', () async {
        // Verify that different CryptoService instances produce the same format
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final plaintext = _generateRandomString(100 + (i % 200));
          final key = await cryptoService.generateKey();
          
          // Create multiple service instances
          const numInstances = 5;
          for (int j = 0; j < numInstances; j++) {
            final service = CryptoService();
            
            final encryptResult = await service.encryptString(
              plaintext: plaintext,
              keyBytes: key,
            );
            
            expect(encryptResult.isOk, true,
                reason: 'Encryption should succeed for instance $j (iteration $i)');
            
            final ciphertext = encryptResult.value;
            
            // Verify format
            final parts = ciphertext.split(':');
            expect(parts.length, equals(3),
                reason: 'Format should be consistent across instances (iteration $i, instance $j)');
            
            // Verify component lengths
            final nonceBytes = base64.decode(parts[0]);
            final macBytes = base64.decode(parts[2]);
            
            expect(nonceBytes.length, equals(12),
                reason: 'Nonce length should be consistent (iteration $i, instance $j)');
            expect(macBytes.length, equals(16),
                reason: 'MAC length should be consistent (iteration $i, instance $j)');
          }
        }
      });

      test('malformed ciphertext formats are rejected', () async {
        // Verify that decryption properly rejects malformed formats
        final key = await cryptoService.generateKey();
        
        final malformedCases = [
          'onlyonepart',                        // No colons
          'two:parts',                          // Only one colon
          'four:parts:are:invalid',             // Too many colons
          ':empty:nonce',                       // Empty nonce
          'nonce::emptymac',                    // Empty cipher
          'nonce:cipher:',                      // Empty MAC
          '::',                                 // All empty
          'invalid base64!:cipher:mac',         // Invalid Base64 in nonce
          'nonce:invalid base64!:mac',          // Invalid Base64 in cipher
          'nonce:cipher:invalid base64!',       // Invalid Base64 in MAC
          '',                                   // Empty string
        ];
        
        for (int i = 0; i < malformedCases.length; i++) {
          final malformed = malformedCases[i];
          
          final decryptResult = await cryptoService.decryptString(
            cipherAll: malformed,
            keyBytes: key,
          );
          
          expect(decryptResult.isErr, true,
              reason: 'Malformed ciphertext should be rejected (case $i: "$malformed")');
        }
      });

      test('ciphertext format preserves all encryption information', () async {
        // Verify that the format contains all necessary information for decryption
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          final plaintext = _generateRandomString(i % 500);
          final key = await cryptoService.generateKey();
          
          // Encrypt
          final encryptResult = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBytes: key,
          );
          
          expect(encryptResult.isOk, true);
          final ciphertext = encryptResult.value;
          
          // Parse the format
          final parts = ciphertext.split(':');
          final nonceBytes = base64.decode(parts[0]);
          final cipherBytes = base64.decode(parts[1]);
          final macBytes = base64.decode(parts[2]);
          
          // Verify we have all components
          expect(nonceBytes.isNotEmpty, true,
              reason: 'Nonce should be present (iteration $i)');
          expect(macBytes.isNotEmpty, true,
              reason: 'MAC should be present (iteration $i)');
          
          // For non-empty plaintext, cipher should be non-empty
          if (plaintext.isNotEmpty) {
            expect(cipherBytes.isNotEmpty, true,
                reason: 'Cipher should be present for non-empty plaintext (iteration $i)');
          }
          
          // Verify decryption succeeds with all components
          final decryptResult = await cryptoService.decryptString(
            cipherAll: ciphertext,
            keyBytes: key,
          );
          
          expect(decryptResult.isOk, true,
              reason: 'Format should preserve all information needed for decryption (iteration $i)');
          expect(decryptResult.value, equals(plaintext),
              reason: 'Decryption should recover original plaintext (iteration $i)');
        }
      });
    });
  });
}

// Helper function to generate random string
String _generateRandomString(int length) {
  if (length == 0) return '';
  
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*() \n\t你好世界🔐';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
