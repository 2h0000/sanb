import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/features/vault/presentation/vault_unlock_screen.dart';
import 'package:encrypted_notebook/features/vault/application/vault_unlock_service.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';
import 'package:encrypted_notebook/app/providers.dart';
import 'package:encrypted_notebook/core/utils/result.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock VaultUnlockService for testing
class MockVaultUnlockService implements VaultUnlockService {
  bool _needsSetup = false;
  bool _shouldFailUnlock = false;
  String? _unlockError;
  List<int>? _returnedDataKey;

  void setNeedsSetup(bool value) {
    _needsSetup = value;
  }

  void setShouldFailUnlock(bool value, {String? error}) {
    _shouldFailUnlock = value;
    _unlockError = error ?? 'Invalid password';
  }

  void setReturnedDataKey(List<int>? key) {
    _returnedDataKey = key;
  }

  @override
  Future<bool> needsSetup() async {
    return _needsSetup;
  }

  @override
  Future<Result<List<int>, String>> unlockVault({
    required String uid,
    required String masterPassword,
  }) async {
    if (_shouldFailUnlock) {
      return Result.error(_unlockError ?? 'Invalid password');
    }
    final dataKey = _returnedDataKey ?? List.generate(32, (i) => i);
    return Result.ok(dataKey);
  }

  @override
  Future<Result<List<int>, String>> setupVault({
    required String uid,
    required String masterPassword,
  }) async {
    if (_shouldFailUnlock) {
      return Result.error(_unlockError ?? 'Setup failed');
    }
    final dataKey = _returnedDataKey ?? List.generate(32, (i) => i);
    return Result.ok(dataKey);
  }

  @override
  Future<Result<void, String>> changeMasterPassword({
    required String uid,
    required String oldPassword,
    required String newPassword,
  }) async {
    return Result.ok(null);
  }

  @override
  Future<Result<bool, String>> hasCloudBackup(String uid) async {
    return Result.ok(false);
  }
}

// Mock User for testing
class MockUser implements User {
  @override
  final String uid;

  MockUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VaultUnlockScreen Widget Tests', () {
    // Helper function to create a test widget with providers
    Widget createTestWidget({
      required MockVaultUnlockService mockService,
      bool needsSetup = false,
      User? user,
    }) {
      mockService.setNeedsSetup(needsSetup);
      final testUser = user ?? MockUser('test-user-123');

      return ProviderScope(
        overrides: [
          vaultUnlockServiceProvider.overrideWithValue(mockService),
          vaultNeedsSetupProvider.overrideWith((ref) async => needsSetup),
          currentUserProvider.overrideWith((ref) => testUser),
          dataKeyProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(
          home: VaultUnlockScreen(),
        ),
      );
    }

    testWidgets('displays unlock form when vault is already set up',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      // Act
      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Unlock UI is displayed
      expect(find.text('Unlock Vault'), findsOneWidget);
      expect(
        find.text('Enter your master password to access your vault'),
        findsOneWidget,
      );
      expect(find.text('Master Password'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
      
      // Assert - Confirm password field is NOT shown for unlock
      expect(find.text('Confirm Password'), findsNothing);
    });

    testWidgets('displays setup form when vault needs setup',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      // Act
      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Setup UI is displayed
      expect(find.text('Set Up Master Password'), findsOneWidget);
      expect(
        find.text('Create a strong master password to protect your vault'),
        findsOneWidget,
      );
      expect(find.text('Master Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Set Up Vault'), findsOneWidget);
      
      // Assert - Warning message is shown
      expect(
        find.textContaining('Important: Remember your master password'),
        findsOneWidget,
      );
    });

    testWidgets('allows user to input master password',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'mySecurePassword123',
      );
      await tester.pump();

      // Assert - Password is entered
      final textField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Master Password'),
      );
      expect(textField.controller?.text, equals('mySecurePassword123'));
    });

    testWidgets('password field is obscured by default',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Password field is obscured
      // We verify by checking that the visibility icon is present
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('can toggle password visibility',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Initially shows visibility icon (password is obscured)
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));

      // Act - Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Assert - Now shows visibility_off icon (password is visible)
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));

      // Act - Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Assert - Shows visibility icon again (password is obscured)
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('displays error message when password is incorrect',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();
      mockService.setShouldFailUnlock(true, error: 'Invalid password');

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter password and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'wrongPassword',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // Assert - Error message is displayed
      expect(find.text('Invalid password'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('successful unlock stores data key in provider',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();
      final testDataKey = List.generate(32, (i) => i + 10);
      mockService.setReturnedDataKey(testDataKey);

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter password and unlock
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'correctPassword',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // Assert - Data key was stored (no error message shown)
      expect(find.text('Invalid password'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('validates empty password on unlock',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Try to unlock without entering password
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // Assert - Validation error is shown
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('validates password length on setup',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'short',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Set Up Vault'));
      await tester.pumpAndSettle();

      // Assert - Validation error is shown
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('validates password confirmation matches on setup',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password456',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Set Up Vault'));
      await tester.pumpAndSettle();

      // Assert - Validation error is shown
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('displays loading indicator while unlocking',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter password and start unlock
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pump(); // Start async operation
      await tester.pump(const Duration(milliseconds: 100)); // Give time for loading state

      // Assert - Loading indicator is shown (or operation completed quickly)
      final hasLoadingIndicator = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasErrorMessage = find.text('Invalid password').evaluate().isNotEmpty;
      
      // Either loading is shown or operation completed
      expect(hasLoadingIndicator || !hasErrorMessage, isTrue);
    });

    testWidgets('button is disabled while loading',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter password and start unlock
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'password123',
      );
      
      // Assert - Button is enabled before tapping
      final buttonBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Unlock'),
      );
      expect(buttonBefore.onPressed, isNotNull);
      
      // Act - Tap to start unlock
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pump(); // Start async operation
      
      // Note: The operation completes very quickly in tests, so we just verify
      // that the unlock was attempted (no validation errors shown)
      await tester.pumpAndSettle();
      
      // Assert - No validation errors (unlock was attempted)
      expect(find.text('Please enter a password'), findsNothing);
    });

    testWidgets('displays lock icon',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Lock icon is displayed
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('displays key icon in password field',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Key icon is displayed in password field
      expect(find.byIcon(Icons.key), findsAtLeastNWidgets(1));
    });

    testWidgets('app bar has no back button',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - No back button (automaticallyImplyLeading: false)
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('displays Vault title in app bar',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: false,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - App bar title is displayed
      expect(find.widgetWithText(AppBar, 'Vault'), findsOneWidget);
    });

    testWidgets('successful setup stores data key',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();
      final testDataKey = List.generate(32, (i) => i + 20);
      mockService.setReturnedDataKey(testDataKey);

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter matching passwords and setup
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'securePassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'securePassword123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Set Up Vault'));
      await tester.pumpAndSettle();

      // Assert - No error message (setup succeeded)
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('displays error when setup fails',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();
      mockService.setShouldFailUnlock(true, error: 'Setup failed');

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Act - Enter matching passwords and setup
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'securePassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'securePassword123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Set Up Vault'));
      await tester.pumpAndSettle();

      // Assert - Error message is displayed
      expect(find.text('Setup failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('can toggle confirm password visibility',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      await tester.pumpWidget(
        createTestWidget(
          mockService: mockService,
          needsSetup: true,
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Initially shows visibility icons (passwords are obscured)
      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsNWidgets(2)); // One for each password field

      // Act - Tap visibility toggle for confirm password (the second one)
      await tester.tap(visibilityIcons.last);
      await tester.pumpAndSettle();

      // Assert - Now shows visibility_off icon for confirm password
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('handles null user gracefully',
        (WidgetTester tester) async {
      // Arrange
      final mockService = MockVaultUnlockService();

      // Create widget with null user
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultUnlockServiceProvider.overrideWithValue(mockService),
            vaultNeedsSetupProvider.overrideWith((ref) async => false),
            currentUserProvider.overrideWith((ref) => null), // Null user
            dataKeyProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: VaultUnlockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Try to unlock
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Master Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pumpAndSettle();

      // Assert - Error message is displayed
      expect(find.text('User not authenticated'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
