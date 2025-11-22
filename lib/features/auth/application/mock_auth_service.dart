import 'dart:async';
import '../../../core/utils/result.dart';

/// Mock user for local testing
class MockUser {
  final String uid;
  final String email;

  MockUser({required this.uid, required this.email});
}

/// Mock authentication service for local testing without Firebase
class MockAuthService {
  MockUser? _currentUser;
  final _authStateController = StreamController<MockUser?>.broadcast();
  
  // Simulated user database
  final Map<String, String> _users = {};

  MockUser? get currentUser => _currentUser;

  Stream<MockUser?> get authStateChanges {
    // Emit current user immediately when stream is listened to
    return Stream.value(_currentUser).asyncExpand((user) async* {
      yield user;
      yield* _authStateController.stream;
    });
  }

  /// Sign in with email and password
  Future<Result<MockUser, String>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_users.containsKey(email)) {
      return Result.error('No user found with this email address');
    }

    if (_users[email] != password) {
      return Result.error('Incorrect password');
    }

    _currentUser = MockUser(
      uid: email.hashCode.toString(),
      email: email,
    );
    _authStateController.add(_currentUser);

    return Result.ok(_currentUser!);
  }

  /// Register a new user with email and password
  Future<Result<MockUser, String>> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_users.containsKey(email)) {
      return Result.error('An account already exists with this email');
    }

    if (!email.contains('@')) {
      return Result.error('Invalid email address');
    }

    if (password.length < 6) {
      return Result.error('Password is too weak. Please use a stronger password');
    }

    // Store user
    _users[email] = password;

    _currentUser = MockUser(
      uid: email.hashCode.toString(),
      email: email,
    );
    _authStateController.add(_currentUser);

    return Result.ok(_currentUser!);
  }

  /// Sign out the current user
  Future<Result<void, String>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _currentUser = null;
    _authStateController.add(null);
    
    return Result.ok(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
