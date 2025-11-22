import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/vault_item.dart';
import 'vault_unlock_service.dart';
import 'vault_service.dart';

/// Provider for VaultUnlockService
final vaultUnlockServiceProvider = Provider<VaultUnlockService>((ref) {
  final keyManager = ref.watch(keyManagerProvider);

  return VaultUnlockService(
    keyManager: keyManager,
    keyBackupService: null, // No cloud backup in local mode
  );
});

/// Provider to check if vault needs setup
final vaultNeedsSetupProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(vaultUnlockServiceProvider);
  return await service.needsSetup();
});

/// Provider for VaultService (only available when vault is unlocked)
final vaultServiceProvider = Provider<VaultService?>((ref) {
  final dataKey = ref.watch(dataKeyProvider);
  if (dataKey == null) {
    return null;
  }

  final vaultDao = ref.watch(vaultDaoProvider);
  final cryptoService = ref.watch(cryptoServiceProvider);

  return VaultService(
    vaultDao: vaultDao,
    cryptoService: cryptoService,
    dataKey: dataKey,
  );
});

/// Provider for vault items list stream (decrypted)
final vaultItemsListProvider = StreamProvider<List<VaultItem>>((ref) async* {
  final vaultService = ref.watch(vaultServiceProvider);
  
  if (vaultService == null) {
    yield [];
    return;
  }

  final vaultDao = ref.watch(vaultDaoProvider);
  
  // Watch encrypted items from database
  await for (final encryptedItems in vaultDao.watchAllVaultItems()) {
    final decryptedItems = <VaultItem>[];
    
    // Decrypt each item
    for (final encrypted in encryptedItems) {
      final dataKey = ref.read(dataKeyProvider);
      if (dataKey == null) break;
      
      final cryptoService = ref.read(cryptoServiceProvider);
      final decryptResult = await encrypted.decrypt(cryptoService, dataKey);
      
      if (decryptResult.isOk) {
        decryptedItems.add(decryptResult.value);
      }
    }
    
    yield decryptedItems;
  }
});

/// Provider for a single vault item by UUID
final vaultItemProvider = FutureProvider.family<VaultItem?, String>((ref, uuid) async {
  final vaultService = ref.watch(vaultServiceProvider);
  if (vaultService == null) {
    return null;
  }

  final result = await vaultService.getVaultItem(uuid);
  return result.when(
    ok: (item) => item,
    error: (_) => null,
  );
});
