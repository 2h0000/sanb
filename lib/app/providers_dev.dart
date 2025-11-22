import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/crypto/crypto_service.dart';
import '../core/crypto/key_manager.dart';
import '../data/local/db/app_database.dart';
import '../data/local/db/notes_dao.dart';
import '../data/local/db/vault_dao.dart';
import '../domain/entities/note.dart' as entity;
import '../features/auth/application/mock_auth_service.dart';

// ============================================================================
// Core Providers - Database, DAOs, and Crypto Services (Dev Mode)
// ============================================================================

/// Provider for the AppDatabase instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

/// Provider for NotesDao
final notesDaoProvider = Provider<NotesDao>((ref) {
  final database = ref.watch(databaseProvider);
  return NotesDao(database);
});

/// Provider for VaultDao
final vaultDaoProvider = Provider<VaultDao>((ref) {
  final database = ref.watch(databaseProvider);
  return VaultDao(database);
});

/// Provider for CryptoService
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

/// Provider for KeyManager
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});

// ============================================================================
// Mock Authentication Providers (Dev Mode)
// ============================================================================

/// Provider for mock auth service (singleton)
final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  final service = MockAuthService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for the current authentication state (mock)
final authStateProvider = StreamProvider<MockUser?>((ref) {
  final authService = ref.watch(mockAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the current user (mock)
final currentUserProvider = Provider<MockUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ============================================================================
// Vault Unlock State Providers (Dev Mode - No Cloud Backup)
// ============================================================================

/// State provider for the unlocked data key
final dataKeyProvider = StateProvider<List<int>?>((ref) => null);

/// Provider to check if vault is unlocked
final isVaultUnlockedProvider = Provider<bool>((ref) {
  final dataKey = ref.watch(dataKeyProvider);
  return dataKey != null;
});

/// Provider to check if vault is initialized locally
final isVaultInitializedProvider = FutureProvider<bool>((ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return await keyManager.isInitialized();
});

// ============================================================================
// Notes List Provider
// ============================================================================

/// Provider for the notes list stream
final notesListProvider = StreamProvider<List<entity.Note>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchAllNotes();
});

/// Provider for the count of non-deleted notes
final notesCountProvider = StreamProvider<int>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchNotesCount();
});
