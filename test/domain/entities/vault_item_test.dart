import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart';
import 'package:encrypted_notebook/core/crypto/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('VaultItem', () {
    // **Feature: encrypted-notebook-app, Property 14: VaultItem 加密往返一致性**
    // **Validates: Requirements 4.4**
    // Property: For any VaultItem, encrypting it with a dataKey and then
    // decrypting it with the same dataKey should return a VaultItem with
    // identical field values. This ensures that the encryption/decryption
    // process preserves all data without loss or corruption.
    group('Property 14: VaultItem Encryption Round-Trip Consistency', () {
      test('encrypting then decrypting VaultItem returns original values', () async {
        // Run the property test with multiple random inputs
        const numTests = 100;
        
        for (int i = 0; i < numTests; i++) {
          // Generate random dataKey (32 bytes)
          final dataKey = await cryptoService.generateKey();
          
          // Generate random VaultItem with all fields populated
          final originalItem = _generateRandomVaultItem(i);
          
          // Encrypt the VaultItem
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed (iteration $i)');
          
          final encryptedItem = encryptResult.value;
          
          // Verify encrypted item has the same uuid and timestamps
          expect(encryptedItem.uuid, equals(originalItem.uuid),
              reason: 'UUID should be preserved (iteration $i)');
          expect(encryptedItem.updatedAt, equals(originalItem.updatedAt),
              reason: 'updatedAt should be preserved (iteration $i)');
          expect(encryptedItem.deletedAt, equals(originalItem.deletedAt),
              reason: 'deletedAt should be preserved (iteration $i)');
          
          // Verify all fields are encrypted (not equal to original)
          expect(encryptedItem.titleEnc, isNot(equals(originalItem.title)),
              reason: 'Title should be encrypted (iteration $i)');
          
          if (originalItem.username != null) {
            expect(encryptedItem.usernameEnc, isNot(equals(originalItem.username)),
                reason: 'Username should be encrypted (iteration $i)');
          }
          
          if (originalItem.password != null) {
            expect(encryptedItem.passwordEnc, isNot(equals(originalItem.password)),
                reason: 'Password should be encrypted (iteration $i)');
          }
          
          if (originalItem.url != null) {
            expect(encryptedItem.urlEnc, isNot(equals(originalItem.url)),
                reason: 'URL should be encrypted (iteration $i)');
          }
          
          if (originalItem.note != null) {
            expect(encryptedItem.noteEnc, isNot(equals(originalItem.note)),
                reason: 'Note should be encrypted (iteration $i)');
          }
          
          // Decrypt the VaultItem
          final decryptResult = await encryptedItem.decrypt(cryptoService, dataKey);
          
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify all fields match the original
          expect(decryptedItem.uuid, equals(originalItem.uuid),
              reason: 'UUID should match after round-trip (iteration $i)');
          expect(decryptedItem.title, equals(originalItem.title),
              reason: 'Title should match after round-trip (iteration $i)');
          expect(decryptedItem.username, equals(originalItem.username),
              reason: 'Username should match after round-trip (iteration $i)');
          expect(decryptedItem.password, equals(originalItem.password),
              reason: 'Password should match after round-trip (iteration $i)');
          expect(decryptedItem.url, equals(originalItem.url),
              reason: 'URL should match after round-trip (iteration $i)');
          expect(decryptedItem.note, equals(originalItem.note),
              reason: 'Note should match after round-trip (iteration $i)');
          expect(decryptedItem.updatedAt, equals(originalItem.updatedAt),
              reason: 'updatedAt should match after round-trip (iteration $i)');
          expect(decryptedItem.deletedAt, equals(originalItem.deletedAt),
              reason: 'deletedAt should match after round-trip (iteration $i)');
        }
      });

      test('round-trip works with only required fields', () async {
        // Test with VaultItems that have only the required title field
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Create VaultItem with only required fields
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: _generateRandomString(10 + (i % 50)),
            username: null,
            password: null,
            url: null,
            note: null,
            updatedAt: DateTime.now(),
            deletedAt: null,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed with only required fields (iteration $i)');
          
          final encryptedItem = encryptResult.value;
          
          // Verify optional fields remain null
          expect(encryptedItem.usernameEnc, isNull,
              reason: 'Null username should remain null after encryption (iteration $i)');
          expect(encryptedItem.passwordEnc, isNull,
              reason: 'Null password should remain null after encryption (iteration $i)');
          expect(encryptedItem.urlEnc, isNull,
              reason: 'Null url should remain null after encryption (iteration $i)');
          expect(encryptedItem.noteEnc, isNull,
              reason: 'Null note should remain null after encryption (iteration $i)');
          
          // Decrypt
          final decryptResult = await encryptedItem.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed with only required fields (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify all fields match
          expect(decryptedItem.uuid, equals(originalItem.uuid));
          expect(decryptedItem.title, equals(originalItem.title));
          expect(decryptedItem.username, isNull);
          expect(decryptedItem.password, isNull);
          expect(decryptedItem.url, isNull);
          expect(decryptedItem.note, isNull);
        }
      });

      test('round-trip works with various field combinations', () async {
        // Test with different combinations of populated fields
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Create VaultItem with random field combinations
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: _generateRandomString(10 + (i % 20)),
            username: (i % 2 == 0) ? _generateRandomString(8 + (i % 15)) : null,
            password: (i % 3 == 0) ? _generateRandomString(12 + (i % 20)) : null,
            url: (i % 4 == 0) ? _generateRandomUrl() : null,
            note: (i % 5 == 0) ? _generateRandomString(20 + (i % 100)) : null,
            updatedAt: DateTime.now().subtract(Duration(days: i % 365)),
            deletedAt: (i % 10 == 0) ? DateTime.now().subtract(Duration(days: i % 30)) : null,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed with field combination (iteration $i)');
          
          // Decrypt
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed with field combination (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify all fields match
          expect(decryptedItem.uuid, equals(originalItem.uuid),
              reason: 'UUID should match (iteration $i)');
          expect(decryptedItem.title, equals(originalItem.title),
              reason: 'Title should match (iteration $i)');
          expect(decryptedItem.username, equals(originalItem.username),
              reason: 'Username should match (iteration $i)');
          expect(decryptedItem.password, equals(originalItem.password),
              reason: 'Password should match (iteration $i)');
          expect(decryptedItem.url, equals(originalItem.url),
              reason: 'URL should match (iteration $i)');
          expect(decryptedItem.note, equals(originalItem.note),
              reason: 'Note should match (iteration $i)');
        }
      });

      test('round-trip preserves special characters in all fields', () async {
        // Test with special characters, Unicode, emojis, etc.
        const numTests = 50;
        
        final specialStrings = [
          'Simple text',
          'With spaces and punctuation!',
          'Email: user@example.com',
          'URL: https://example.com:8080/path?query=value',
          'Password: P@ssw0rd!#\$%^&*()',
          '中文字符',
          '日本語',
          '한국어',
          'Emoji: 🔐🔑🛡️',
          'Newlines:\nLine 1\nLine 2',
          'Tabs:\tColumn 1\tColumn 2',
          'JSON: {"key": "value"}',
          'XML: <tag>content</tag>',
          'Quotes: "double" and \'single\'',
          'Backslash: C:\\path\\to\\file',
          'Special: @#\$%^&*()_+-=[]{}|;:,.<>?/~`',
        ];
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Pick random special strings for each field
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: specialStrings[i % specialStrings.length],
            username: specialStrings[(i + 1) % specialStrings.length],
            password: specialStrings[(i + 2) % specialStrings.length],
            url: specialStrings[(i + 3) % specialStrings.length],
            note: specialStrings[(i + 4) % specialStrings.length],
            updatedAt: DateTime.now(),
            deletedAt: null,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed with special characters (iteration $i)');
          
          // Decrypt
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed with special characters (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify all fields match exactly
          expect(decryptedItem.title, equals(originalItem.title),
              reason: 'Title with special characters should match (iteration $i)');
          expect(decryptedItem.username, equals(originalItem.username),
              reason: 'Username with special characters should match (iteration $i)');
          expect(decryptedItem.password, equals(originalItem.password),
              reason: 'Password with special characters should match (iteration $i)');
          expect(decryptedItem.url, equals(originalItem.url),
              reason: 'URL with special characters should match (iteration $i)');
          expect(decryptedItem.note, equals(originalItem.note),
              reason: 'Note with special characters should match (iteration $i)');
        }
      });

      test('round-trip works with empty strings', () async {
        // Test with empty strings (different from null)
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Create VaultItem with empty strings
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: (i % 2 == 0) ? '' : _generateRandomString(10),
            username: (i % 3 == 0) ? '' : _generateRandomString(8),
            password: (i % 4 == 0) ? '' : _generateRandomString(12),
            url: (i % 5 == 0) ? '' : _generateRandomUrl(),
            note: (i % 6 == 0) ? '' : _generateRandomString(20),
            updatedAt: DateTime.now(),
            deletedAt: null,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed with empty strings (iteration $i)');
          
          // Decrypt
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed with empty strings (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify empty strings are preserved
          expect(decryptedItem.title, equals(originalItem.title),
              reason: 'Empty title should be preserved (iteration $i)');
          expect(decryptedItem.username, equals(originalItem.username),
              reason: 'Empty username should be preserved (iteration $i)');
          expect(decryptedItem.password, equals(originalItem.password),
              reason: 'Empty password should be preserved (iteration $i)');
          expect(decryptedItem.url, equals(originalItem.url),
              reason: 'Empty url should be preserved (iteration $i)');
          expect(decryptedItem.note, equals(originalItem.note),
              reason: 'Empty note should be preserved (iteration $i)');
        }
      });

      test('round-trip works with very long field values', () async {
        // Test with very long strings in fields
        const numTests = 30;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Create VaultItem with very long fields
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: _generateRandomString(100 + (i * 50)),
            username: _generateRandomString(200 + (i * 100)),
            password: _generateRandomString(150 + (i * 75)),
            url: _generateRandomString(300 + (i * 150)),
            note: _generateRandomString(1000 + (i * 500)),
            updatedAt: DateTime.now(),
            deletedAt: null,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed with long fields (iteration $i)');
          
          // Decrypt
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true,
              reason: 'Decryption should succeed with long fields (iteration $i)');
          
          final decryptedItem = decryptResult.value;
          
          // Verify all fields match
          expect(decryptedItem.title, equals(originalItem.title),
              reason: 'Long title should match (iteration $i)');
          expect(decryptedItem.username, equals(originalItem.username),
              reason: 'Long username should match (iteration $i)');
          expect(decryptedItem.password, equals(originalItem.password),
              reason: 'Long password should match (iteration $i)');
          expect(decryptedItem.url, equals(originalItem.url),
              reason: 'Long url should match (iteration $i)');
          expect(decryptedItem.note, equals(originalItem.note),
              reason: 'Long note should match (iteration $i)');
        }
      });

      test('decryption fails with wrong dataKey', () async {
        // Verify that using a different dataKey fails to decrypt
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          // Generate two different dataKeys
          final dataKey1 = await cryptoService.generateKey();
          final dataKey2 = await cryptoService.generateKey();
          
          final originalItem = _generateRandomVaultItem(i);
          
          // Encrypt with first key
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey1);
          expect(encryptResult.isOk, true,
              reason: 'Encryption should succeed (iteration $i)');
          
          // Try to decrypt with second key (should fail)
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey2);
          
          expect(decryptResult.isErr, true,
              reason: 'Decryption with wrong key should fail (iteration $i)');
        }
      });

      test('multiple round-trips preserve data', () async {
        // Test that encrypting and decrypting multiple times preserves data
        const numTests = 30;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          final originalItem = _generateRandomVaultItem(i);
          
          var currentItem = originalItem;
          
          // Perform multiple round-trips
          const numRoundTrips = 5;
          for (int j = 0; j < numRoundTrips; j++) {
            // Encrypt
            final encryptResult = await currentItem.encrypt(cryptoService, dataKey);
            expect(encryptResult.isOk, true,
                reason: 'Encryption should succeed (iteration $i, round-trip $j)');
            
            // Decrypt
            final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
            expect(decryptResult.isOk, true,
                reason: 'Decryption should succeed (iteration $i, round-trip $j)');
            
            currentItem = decryptResult.value;
          }
          
          // After multiple round-trips, data should still match original
          expect(currentItem.uuid, equals(originalItem.uuid),
              reason: 'UUID should match after multiple round-trips (iteration $i)');
          expect(currentItem.title, equals(originalItem.title),
              reason: 'Title should match after multiple round-trips (iteration $i)');
          expect(currentItem.username, equals(originalItem.username),
              reason: 'Username should match after multiple round-trips (iteration $i)');
          expect(currentItem.password, equals(originalItem.password),
              reason: 'Password should match after multiple round-trips (iteration $i)');
          expect(currentItem.url, equals(originalItem.url),
              reason: 'URL should match after multiple round-trips (iteration $i)');
          expect(currentItem.note, equals(originalItem.note),
              reason: 'Note should match after multiple round-trips (iteration $i)');
        }
      });

      test('round-trip preserves timestamp precision', () async {
        // Test that DateTime values are preserved with precision
        const numTests = 50;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          
          // Create timestamps with various precisions
          final updatedAt = DateTime.now().subtract(Duration(
            days: i % 365,
            hours: i % 24,
            minutes: i % 60,
            seconds: i % 60,
            milliseconds: i % 1000,
          ));
          
          final deletedAt = (i % 2 == 0) 
              ? DateTime.now().subtract(Duration(
                  days: i % 100,
                  hours: i % 12,
                  minutes: i % 30,
                ))
              : null;
          
          final originalItem = VaultItem(
            uuid: _generateUuid(),
            title: _generateRandomString(20),
            username: _generateRandomString(15),
            password: _generateRandomString(20),
            url: _generateRandomUrl(),
            note: _generateRandomString(50),
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          );
          
          // Encrypt
          final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
          expect(encryptResult.isOk, true);
          
          // Decrypt
          final decryptResult = await encryptResult.value.decrypt(cryptoService, dataKey);
          expect(decryptResult.isOk, true);
          
          final decryptedItem = decryptResult.value;
          
          // Verify timestamps match exactly
          expect(decryptedItem.updatedAt, equals(originalItem.updatedAt),
              reason: 'updatedAt timestamp should be preserved exactly (iteration $i)');
          expect(decryptedItem.deletedAt, equals(originalItem.deletedAt),
              reason: 'deletedAt timestamp should be preserved exactly (iteration $i)');
        }
      });

      test('encrypted fields are different each time', () async {
        // Verify that encrypting the same VaultItem multiple times produces
        // different ciphertexts (due to random nonces)
        const numTests = 30;
        
        for (int i = 0; i < numTests; i++) {
          final dataKey = await cryptoService.generateKey();
          final originalItem = _generateRandomVaultItem(i);
          
          // Encrypt the same item multiple times
          final encryptedItems = <VaultItemEncrypted>[];
          const numEncryptions = 5;
          
          for (int j = 0; j < numEncryptions; j++) {
            final encryptResult = await originalItem.encrypt(cryptoService, dataKey);
            expect(encryptResult.isOk, true);
            encryptedItems.add(encryptResult.value);
          }
          
          // All encrypted versions should have different ciphertexts
          for (int j = 0; j < numEncryptions; j++) {
            for (int k = j + 1; k < numEncryptions; k++) {
              expect(encryptedItems[j].titleEnc, isNot(equals(encryptedItems[k].titleEnc)),
                  reason: 'Title ciphertexts should differ (iteration $i, encryptions $j and $k)');
              
              if (originalItem.username != null) {
                expect(encryptedItems[j].usernameEnc, isNot(equals(encryptedItems[k].usernameEnc)),
                    reason: 'Username ciphertexts should differ (iteration $i, encryptions $j and $k)');
              }
              
              if (originalItem.password != null) {
                expect(encryptedItems[j].passwordEnc, isNot(equals(encryptedItems[k].passwordEnc)),
                    reason: 'Password ciphertexts should differ (iteration $i, encryptions $j and $k)');
              }
            }
          }
          
          // But all should decrypt to the same original values
          for (int j = 0; j < numEncryptions; j++) {
            final decryptResult = await encryptedItems[j].decrypt(cryptoService, dataKey);
            expect(decryptResult.isOk, true);
            
            final decryptedItem = decryptResult.value;
            expect(decryptedItem.title, equals(originalItem.title));
            expect(decryptedItem.username, equals(originalItem.username));
            expect(decryptedItem.password, equals(originalItem.password));
          }
        }
      });
    });
  });
}

// Helper function to generate a random VaultItem with all fields populated
VaultItem _generateRandomVaultItem(int seed) {
  final random = Random(seed);
  
  return VaultItem(
    uuid: _generateUuid(),
    title: _generateRandomString(10 + random.nextInt(40)),
    username: _generateRandomString(8 + random.nextInt(20)),
    password: _generateRandomString(12 + random.nextInt(30)),
    url: _generateRandomUrl(),
    note: _generateRandomString(20 + random.nextInt(200)),
    updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    deletedAt: (random.nextInt(10) == 0) 
        ? DateTime.now().subtract(Duration(days: random.nextInt(30)))
        : null,
  );
}

// Helper function to generate a UUID
String _generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  
  // Set version (4) and variant bits
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

// Helper function to generate a random string
String _generateRandomString(int length) {
  if (length == 0) return '';
  
  // Use only ASCII printable characters and common Unicode characters that are safe
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?/~ ';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

// Helper function to generate a random URL
String _generateRandomUrl() {
  final random = Random.secure();
  final protocols = ['http', 'https', 'ftp'];
  final domains = ['example.com', 'test.org', 'demo.net', 'sample.io'];
  final paths = ['', '/path', '/path/to/resource', '/api/v1/endpoint'];
  
  final protocol = protocols[random.nextInt(protocols.length)];
  final domain = domains[random.nextInt(domains.length)];
  final path = paths[random.nextInt(paths.length)];
  final port = random.nextInt(10) == 0 ? ':${8000 + random.nextInt(2000)}' : '';
  
  return '$protocol://$domain$port$path';
}
