import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/router_dev.dart';
import 'app/theme.dart';
import 'app/theme_providers.dart';
import 'app/providers.dart' as prod;
import 'app/providers_dev.dart' as dev;
import 'features/vault/application/vault_providers.dart' as prod_vault;
import 'features/vault/application/vault_providers_dev.dart' as dev_vault;
import 'core/utils/logger.dart';

const _logger = Logger('Main');

/// Development entry point without Firebase
/// Use this for local testing without Firebase configuration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  _logger.info('Starting app in development mode (Firebase disabled)');
  
  runApp(
    ProviderScope(
      overrides: [
        // Override production providers with dev versions
        prod.currentUserProvider.overrideWith((ref) {
          final authState = ref.watch(dev.authStateProvider);
          return authState.maybeWhen(
            data: (user) => user,
            orElse: () => null,
          );
        }),
        prod.authStateProvider.overrideWith((ref) {
          final authService = ref.watch(dev.mockAuthServiceProvider);
          return authService.authStateChanges;
        }),
        prod.dataKeyProvider.overrideWith((ref) => ref.watch(dev.dataKeyProvider.notifier).state),
        prod.isVaultUnlockedProvider.overrideWith((ref) {
          final dataKey = ref.watch(dev.dataKeyProvider);
          return dataKey != null;
        }),
        prod.databaseProvider.overrideWith((ref) => ref.watch(dev.databaseProvider)),
        prod.notesDaoProvider.overrideWith((ref) => ref.watch(dev.notesDaoProvider)),
        prod.vaultDaoProvider.overrideWith((ref) => ref.watch(dev.vaultDaoProvider)),
        prod.cryptoServiceProvider.overrideWith((ref) => ref.watch(dev.cryptoServiceProvider)),
        prod.keyManagerProvider.overrideWith((ref) => ref.watch(dev.keyManagerProvider)),
        
        // Override vault providers
        prod_vault.vaultUnlockServiceProvider.overrideWith((ref) => ref.watch(dev_vault.vaultUnlockServiceProvider)),
        prod_vault.vaultNeedsSetupProvider.overrideWith((ref) async {
          final service = ref.watch(dev_vault.vaultUnlockServiceProvider);
          return await service.needsSetup();
        }),
        prod_vault.vaultServiceProvider.overrideWith((ref) => ref.watch(dev_vault.vaultServiceProvider)),
        prod_vault.vaultItemsListProvider.overrideWith((ref) => ref.watch(dev_vault.vaultItemsListProvider)),
      ],
      child: DevApp(),
    ),
  );
}

class DevApp extends ConsumerWidget {
  DevApp({super.key});

  final _router = createDevRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Secure Advanced Notebook (Dev)',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
    );
  }
}
