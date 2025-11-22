import '../../../core/crypto/key_manager.dart';
import '../../../core/utils/result.dart';

/// Service for handling vault unlock operations (local only, no cloud backup)
class VaultUnlockService {
  final KeyManager _keyManager;

  VaultUnlockService({
    required KeyManager keyManager,
    Object? keyBackupService, // Ignored in local mode
  })  : _keyManager = keyManager;

  /// Checks if the vault needs to be set up (first time use)
  Future<bool> needsSetup() async {
    return !(await _keyManager.isInitialized());
  }

  /// Sets up the vault with a new master password
  Future<Result<List<int>, String>> setupVault({
    required String uid,
    required String masterPassword,
  }) async {
    // Initialize vault locally
    final initResult = await _keyManager.initializeWithMasterPassword(masterPassword);
    
    if (initResult.isErr) {
      return Result.error(initResult.error);
    }

    // Unlock to get the data key
    return await _keyManager.unlockDataKey(masterPassword);
  }

  /// Unlocks the vault with master password
  Future<Result<List<int>, String>> unlockVault({
    required String uid,
    required String masterPassword,
  }) async {
    // Just unlock locally
    return await _keyManager.unlockDataKey(masterPassword);
  }

  /// Changes the master password
  Future<Result<void, String>> changeMasterPassword({
    required String uid,
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _keyManager.changeMasterPassword(
      oldPassword,
      newPassword,
    );
  }

  /// Checks if key parameters exist in the cloud (always false in local mode)
  Future<Result<bool, String>> hasCloudBackup(String uid) async {
    return Result.ok(false);
  }
}
