import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/crypto/crypto_service.dart';
import '../core/crypto/key_manager.dart';
import '../data/local/db/app_database.dart';
import '../data/local/db/notes_dao.dart';
import '../data/local/db/vault_dao.dart';
import '../domain/entities/note.dart' as entity;
import '../features/auth/application/local_auth_service.dart';

// ============================================================================
// Core Providers - Database, DAOs, and Crypto Services
// ============================================================================

/// Provider for the AppDatabase instance
/// This is a singleton that manages the SQLite database connection
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  // Ensure database is properly closed when provider is disposed
  ref.onDispose(() {
    database.close();
  });
  
  return database;
});

/// Provider for NotesDao
/// Provides access to notes table operations
final notesDaoProvider = Provider<NotesDao>((ref) {
  final database = ref.watch(databaseProvider);
  return NotesDao(database);
});

/// Provider for VaultDao
/// Provides access to vault items table operations
final vaultDaoProvider = Provider<VaultDao>((ref) {
  final database = ref.watch(databaseProvider);
  return VaultDao(database);
});

/// Provider for CryptoService
/// Handles AES-GCM encryption and decryption operations
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

/// Provider for KeyManager
/// Manages master password, key derivation, and key wrapping
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});

/// Provider for LocalAuthService
/// Handles local authentication (no Firebase)
final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final service = LocalAuthService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// ============================================================================
// Authentication Providers
// ============================================================================

/// Provider for the current authentication state
/// Returns a stream of LocalUser? that updates when auth state changes
final authStateProvider = StreamProvider<LocalUser?>((ref) {
  final authService = ref.watch(localAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the current user (synchronous access)
/// In local mode, always returns a user
final currentUserProvider = Provider<LocalUser?>((ref) {
  final authService = ref.watch(localAuthServiceProvider);
  return authService.currentUser;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ============================================================================
// Vault Unlock State Providers
// ============================================================================

/// State provider for the unlocked data key
/// This holds the decrypted 32-byte data key in memory after successful vault unlock
/// The data key is used to encrypt/decrypt vault items
final dataKeyProvider = StateProvider<List<int>?>((ref) => null);

/// Provider to check if vault is unlocked
/// Returns true if dataKey is available in memory
final isVaultUnlockedProvider = Provider<bool>((ref) {
  final dataKey = ref.watch(dataKeyProvider);
  return dataKey != null;
});

/// Provider to check if vault is initialized locally
/// Returns true if key parameters exist in secure storage
final isVaultInitializedProvider = FutureProvider<bool>((ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  return await keyManager.isInitialized();
});

// ============================================================================
// Notes List Provider (StreamProvider)
// ============================================================================

/// Provider for the notes list stream
/// Returns a stream of all non-deleted notes, sorted by updatedAt descending
/// This automatically updates the UI when notes change in the database
final notesListProvider = StreamProvider<List<entity.Note>>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchAllNotes();
});

/// Provider for the count of non-deleted notes
final notesCountProvider = StreamProvider<int>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return notesDao.watchNotesCount();
});
