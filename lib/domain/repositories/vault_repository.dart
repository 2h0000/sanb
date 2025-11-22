import '../entities/vault_item.dart';

/// Repository interface for vault operations
abstract class VaultRepository {
  Future<List<VaultItem>> getAllVaultItems();
  Future<VaultItem?> getVaultItemByUuid(String uuid);
  Future<void> createVaultItem(VaultItem item);
  Future<void> updateVaultItem(VaultItem item);
  Future<void> deleteVaultItem(String uuid);
}
