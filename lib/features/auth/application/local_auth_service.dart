import 'dart:async';
import '../../../core/utils/result.dart';

/// Simple local user model
class LocalUser {
  final String id;
  final String email;
  
  LocalUser({required this.id, required this.email});
  
  // Alias for compatibility
  String get uid => id;
}

/// Local authentication service (no Firebase)
/// This is a simple implementation that auto-logs in the user
class LocalAuthService {
  final _authStateController = StreamController<LocalUser?>.broadcast();
  LocalUser? _currentUser;

  LocalAuthService() {
    // Auto-login with a default local user
    _currentUser = LocalUser(
      id: 'local-user',
      email: 'local@device.com',
    );
    // Add initial value to stream
    Future.microtask(() => _authStateController.add(_currentUser));
  }

  /// Get the current user (always returns a user in local mode)
  LocalUser? get currentUser => _currentUser;

  /// Stream of authentication state changes
  Stream<LocalUser?> get authStateChanges => _authStateController.stream;

  /// Sign in (always succeeds for local mode)
  Future<Result<LocalUser, String>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = LocalUser(
      id: 'local-user',
      email: email,
    );
    _authStateController.add(_currentUser);
    return Result.ok(_currentUser!);
  }

  /// Register (always succeeds for local mode)
  Future<Result<LocalUser, String>> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = LocalUser(
      id: 'local-user',
      email: email,
    );
    _authStateController.add(_currentUser);
    return Result.ok(_currentUser!);
  }

  /// Sign out
  Future<Result<void, String>> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    return Result.ok(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
