import '../../../core/crypto/key_manager.dart';
import '../../../core/utils/result.dart';

/// Development version of VaultUnlockService without Firebase dependency
class VaultUnlockServiceDev {
  final KeyManager _keyManager;

  VaultUnlockServiceDev({
    required KeyManager keyManager,
  }) : _keyManager = keyManager;

  /// Check if vault needs initial setup
  Future<bool> needsSetup() async {
    return !(await _keyManager.isInitialized());
  }

  /// Set up vault with a new master password
  Future<Result<List<int>, String>> setupVault({
    required String uid,
    required String masterPassword,
  }) async {
    try {
      // Initialize key manager with master password
      final initResult = await _keyManager.initializeWithMasterPassword(masterPassword);
      
      if (initResult.isErr) {
        return Result.error(initResult.error);
      }
      
      // Now unlock to get the data key
      final unlockResult = await _keyManager.unlockDataKey(masterPassword);
      
      return unlockResult.when(
        ok: (dataKey) {
          // In dev mode, we don't backup to cloud
          return Result.ok(dataKey);
        },
        error: (error) => Result.error(error),
      );
    } catch (e) {
      return Result.error('Failed to setup vault: $e');
    }
  }

  /// Unlock vault with master password
  Future<Result<List<int>, String>> unlockVault({
    required String uid,
    required String masterPassword,
  }) async {
    try {
      // Unlock with master password
      final result = await _keyManager.unlockDataKey(masterPassword);
      
      return result.when(
        ok: (dataKey) => Result.ok(dataKey),
        error: (error) => Result.error(error),
      );
    } catch (e) {
      return Result.error('Failed to unlock vault: $e');
    }
  }
}
