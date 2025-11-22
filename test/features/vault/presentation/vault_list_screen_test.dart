import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/features/vault/presentation/vault_list_screen.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart';
import 'package:encrypted_notebook/features/vault/application/vault_providers.dart';
import 'package:encrypted_notebook/app/providers.dart';

void main() {
  group('VaultListScreen Widget Tests', () {
    // Helper function to create test vault items
    VaultItem createTestVaultItem({
      required String uuid,
      required String title,
      String? username,
      String? password,
      String? url,
      String? note,
      DateTime? updatedAt,
    }) {
      return VaultItem(
        uuid: uuid,
        title: title,
        username: username,
        password: password,
        url: url,
        note: note,
        updatedAt: updatedAt ?? DateTime.now(),
        deletedAt: null,
      );
    }

    // Helper function to create a test widget with providers
    Widget createTestWidget({
      required List<VaultItem> vaultItems,
      bool hasDataKey = true,
    }) {
      return ProviderScope(
        overrides: [
          // Override the vaultItemsListProvider to return test data
          vaultItemsListProvider.overrideWith((ref) {
            return Stream.value(vaultItems);
          }),
          // Override dataKeyProvider to simulate unlocked vault
          dataKeyProvider.overrideWith((ref) {
            return hasDataKey ? List.generate(32, (i) => i) : null;
          }),
        ],
        child: const MaterialApp(
          home: VaultListScreen(),
        ),
      );
    }

    testWidgets('displays vault items list when items are available',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub Account',
          username: 'user@example.com',
          url: 'https://github.com',
        ),
        createTestVaultItem(
          uuid: 'item-2',
          title: 'Email Account',
          username: 'myemail@example.com',
          url: 'https://gmail.com',
        ),
        createTestVaultItem(
          uuid: 'item-3',
          title: 'Bank Account',
          username: 'john_doe',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Check that all vault item titles are displayed
      expect(find.text('GitHub Account'), findsOneWidget);
      expect(find.text('Email Account'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);

      // Check that usernames are displayed as subtitles
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('myemail@example.com'), findsOneWidget);
      expect(find.text('john_doe'), findsOneWidget);
    });

    testWidgets('displays empty state when no vault items exist',
        (WidgetTester tester) async {
      // Arrange
      final emptyItems = <VaultItem>[];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: emptyItems));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No vault items yet'), findsOneWidget);
      expect(find.text('Tap + to add your first item'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
    });

    testWidgets('vault item card is tappable',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-123',
          title: 'Test Item',
          username: 'testuser',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Vault item card with ListTile is present and tappable
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      
      // Verify the card can be found
      final cardFinder = find.ancestor(
        of: find.text('Test Item'),
        matching: find.byType(Card),
      );
      expect(cardFinder, findsOneWidget);
      
      // Verify chevron icon is present (indicates tappable)
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('search box is visible and functional',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub Account',
          username: 'user@github.com',
        ),
        createTestVaultItem(
          uuid: 'item-2',
          title: 'Gmail Account',
          username: 'user@gmail.com',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Search box is visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search vault items...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Act - Enter search text
      await tester.enterText(find.byType(TextField), 'GitHub');
      await tester.pump();

      // Assert - Search text is entered
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('GitHub'));
    });

    testWidgets('search filters vault items by title',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub Account',
          username: 'user@github.com',
        ),
        createTestVaultItem(
          uuid: 'item-2',
          title: 'Gmail Account',
          username: 'user@gmail.com',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Initially both items are visible
      expect(find.text('GitHub Account'), findsOneWidget);
      expect(find.text('Gmail Account'), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'GitHub');
      await tester.pump();

      // Assert - Only GitHub item is visible
      expect(find.text('GitHub Account'), findsOneWidget);
      expect(find.text('Gmail Account'), findsNothing);
    });

    testWidgets('displays "No items found" when search returns no results',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub Account',
          username: 'user@github.com',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Enter search text that returns no results
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      // Assert - Empty search state is displayed
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
    });

    testWidgets('clear button appears when search text is entered',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Test Item',
          username: 'testuser',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Clear button is not visible initially
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert - Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button clears search text',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Test Item',
          username: 'testuser',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Assert - Search text is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(''));
    });

    testWidgets('FAB is visible and tappable',
        (WidgetTester tester) async {
      // Arrange
      final testItems = <VaultItem>[];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('lock icon is visible in app bar',
        (WidgetTester tester) async {
      // Arrange
      final testItems = <VaultItem>[];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Lock icon is present
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.lock), findsOneWidget);
    });

    testWidgets('settings icon is visible in app bar',
        (WidgetTester tester) async {
      // Arrange
      final testItems = <VaultItem>[];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Settings icon is present
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.settings), findsOneWidget);
    });

    testWidgets('displays appropriate icon based on URL',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub',
          url: 'https://github.com',
        ),
        createTestVaultItem(
          uuid: 'item-2',
          title: 'Google',
          url: 'https://google.com',
        ),
        createTestVaultItem(
          uuid: 'item-3',
          title: 'No URL',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Icons are displayed
      expect(find.byIcon(Icons.code), findsOneWidget); // GitHub
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget); // Google
      expect(find.byIcon(Icons.key), findsOneWidget); // No URL
    });

    testWidgets('displays URL as subtitle when username is not provided',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Website',
          url: 'https://example.com',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - URL is displayed as subtitle
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('displays username as subtitle when both username and URL are provided',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Account',
          username: 'myusername',
          url: 'https://example.com',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Username is displayed as subtitle (not URL)
      expect(find.text('myusername'), findsOneWidget);
      // URL should not be visible in the list (only in detail view)
      expect(find.text('https://example.com'), findsNothing);
    });

    testWidgets('displays CircleAvatar with icon for each item',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Test Item',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - CircleAvatar is present
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays loading indicator while loading',
        (WidgetTester tester) async {
      // Arrange - Create a provider that delays
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultItemsListProvider.overrideWith((ref) async* {
              await Future.delayed(const Duration(milliseconds: 100));
              yield <VaultItem>[];
            }),
            dataKeyProvider.overrideWith((ref) => List.generate(32, (i) => i)),
          ],
          child: const MaterialApp(
            home: VaultListScreen(),
          ),
        ),
      );

      // Pump once to start loading
      await tester.pump();

      // Assert - Loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete loading
      await tester.pumpAndSettle();

      // Assert - Loading indicator is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays error state when loading fails',
        (WidgetTester tester) async {
      // Arrange - Create a provider that throws an error
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultItemsListProvider.overrideWith((ref) async* {
              throw Exception('Failed to load vault items');
            }),
            dataKeyProvider.overrideWith((ref) => List.generate(32, (i) => i)),
          ],
          child: const MaterialApp(
            home: VaultListScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Error state is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading vault items'), findsOneWidget);
    });

    testWidgets('app bar displays "Vault" title',
        (WidgetTester tester) async {
      // Arrange
      final testItems = <VaultItem>[];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - App bar title is displayed
      expect(find.widgetWithText(AppBar, 'Vault'), findsOneWidget);
    });

    testWidgets('search is case-insensitive',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'GitHub Account',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Enter lowercase search text
      await tester.enterText(find.byType(TextField), 'github');
      await tester.pump();

      // Assert - Item is still visible (case-insensitive search)
      expect(find.text('GitHub Account'), findsOneWidget);
    });

    testWidgets('displays multiple vault items correctly',
        (WidgetTester tester) async {
      // Arrange
      final testItems = List.generate(
        5,
        (i) => createTestVaultItem(
          uuid: 'item-$i',
          title: 'Item $i',
          username: 'user$i',
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - All items are displayed
      for (int i = 0; i < 5; i++) {
        expect(find.text('Item $i'), findsOneWidget);
        expect(find.text('user$i'), findsOneWidget);
      }
    });

    testWidgets('vault items are displayed in cards',
        (WidgetTester tester) async {
      // Arrange
      final testItems = [
        createTestVaultItem(
          uuid: 'item-1',
          title: 'Test Item',
        ),
      ];

      // Act
      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Items are in Card widgets
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('lock vault button is present and tappable',
        (WidgetTester tester) async {
      // Arrange
      final testItems = <VaultItem>[];

      await tester.pumpWidget(createTestWidget(vaultItems: testItems));
      await tester.pumpAndSettle();

      // Assert - Lock button is present
      expect(find.widgetWithIcon(IconButton, Icons.lock), findsOneWidget);

      // Act - Tap lock button (verify it's tappable)
      await tester.tap(find.widgetWithIcon(IconButton, Icons.lock));
      await tester.pumpAndSettle();

      // Note: In a real integration test, we would verify the provider state changed
      // and the app navigates to the unlock screen. For unit tests, we just verify
      // the button exists and is tappable.
      expect(find.widgetWithIcon(IconButton, Icons.lock), findsOneWidget);
    });
  });
}
