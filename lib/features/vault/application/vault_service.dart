import 'package:uuid/uuid.dart';
import '../../../core/crypto/crypto_service.dart';
import '../../../core/utils/result.dart';
import '../../../data/local/db/vault_dao.dart';
import '../../../domain/entities/vault_item.dart';

/// Service for managing vault items (CRUD operations)
class VaultService {
  final VaultDao _vaultDao;
  final CryptoService _cryptoService;
  final List<int> _dataKey;

  VaultService({
    required VaultDao vaultDao,
    required CryptoService cryptoService,
    required List<int> dataKey,
  })  : _vaultDao = vaultDao,
        _cryptoService = cryptoService,
        _dataKey = dataKey;

  /// Create a new vault item
  Future<Result<String, String>> createVaultItem({
    required String title,
    String? username,
    String? password,
    String? url,
    String? note,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final now = DateTime.now();

      final vaultItem = VaultItem(
        uuid: uuid,
        title: title,
        username: username,
        password: password,
        url: url,
        note: note,
        updatedAt: now,
      );

      // Encrypt the vault item
      final encryptResult = await vaultItem.encrypt(_cryptoService, _dataKey);
      if (encryptResult.isErr) {
        return Err('Failed to encrypt vault item: ${encryptResult.error}');
      }

      final encrypted = encryptResult.value;

      // Save to database
      await _vaultDao.createVaultItem(
        uuid: encrypted.uuid,
        titleEnc: encrypted.titleEnc,
        usernameEnc: encrypted.usernameEnc,
        passwordEnc: encrypted.passwordEnc,
        urlEnc: encrypted.urlEnc,
        noteEnc: encrypted.noteEnc,
      );

      return Ok(uuid);
    } catch (e) {
      return Err('Failed to create vault item: $e');
    }
  }

  /// Update an existing vault item
  Future<Result<void, String>> updateVaultItem({
    required String uuid,
    required String title,
    String? username,
    String? password,
    String? url,
    String? note,
  }) async {
    try {
      final now = DateTime.now();

      final vaultItem = VaultItem(
        uuid: uuid,
        title: title,
        username: username,
        password: password,
        url: url,
        note: note,
        updatedAt: now,
      );

      // Encrypt the vault item
      final encryptResult = await vaultItem.encrypt(_cryptoService, _dataKey);
      if (encryptResult.isErr) {
        return Err('Failed to encrypt vault item: ${encryptResult.error}');
      }

      final encrypted = encryptResult.value;

      // Update in database
      await _vaultDao.updateVaultItem(
        uuid,
        titleEnc: encrypted.titleEnc,
        usernameEnc: encrypted.usernameEnc,
        passwordEnc: encrypted.passwordEnc,
        urlEnc: encrypted.urlEnc,
        noteEnc: encrypted.noteEnc,
      );

      return const Ok(null);
    } catch (e) {
      return Err('Failed to update vault item: $e');
    }
  }

  /// Delete a vault item (soft delete)
  Future<Result<void, String>> deleteVaultItem(String uuid) async {
    try {
      await _vaultDao.softDelete(uuid);
      return const Ok(null);
    } catch (e) {
      return Err('Failed to delete vault item: $e');
    }
  }

  /// Get a vault item by UUID (decrypted)
  Future<Result<VaultItem, String>> getVaultItem(String uuid) async {
    try {
      final encrypted = await _vaultDao.findByUuid(uuid);
      if (encrypted == null) {
        return const Err('Vault item not found');
      }

      // Decrypt the vault item
      final decryptResult = await encrypted.decrypt(_cryptoService, _dataKey);
      if (decryptResult.isErr) {
        return Err('Failed to decrypt vault item: ${decryptResult.error}');
      }

      return Ok(decryptResult.value);
    } catch (e) {
      return Err('Failed to get vault item: $e');
    }
  }

  /// Get all vault items (decrypted)
  Future<Result<List<VaultItem>, String>> getAllVaultItems() async {
    try {
      final encryptedItems = await _vaultDao.getAllVaultItems();
      final decryptedItems = <VaultItem>[];

      for (final encrypted in encryptedItems) {
        final decryptResult = await encrypted.decrypt(_cryptoService, _dataKey);
        if (decryptResult.isOk) {
          decryptedItems.add(decryptResult.value);
        }
        // Skip items that fail to decrypt
      }

      return Ok(decryptedItems);
    } catch (e) {
      return Err('Failed to get vault items: $e');
    }
  }

  /// Search vault items by title
  Future<Result<List<VaultItem>, String>> searchVaultItems(
    String keyword,
  ) async {
    try {
      final allItemsResult = await getAllVaultItems();
      if (allItemsResult.isErr) {
        return Err(allItemsResult.error);
      }

      final allItems = allItemsResult.value;
      final filtered = allItems
          .where((item) =>
              item.title.toLowerCase().contains(keyword.toLowerCase()))
          .toList();

      return Ok(filtered);
    } catch (e) {
      return Err('Failed to search vault items: $e');
    }
  }
}
