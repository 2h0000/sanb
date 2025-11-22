import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/app_lifecycle_observer.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_providers.dart';

class EncryptedNotebookApp extends ConsumerStatefulWidget {
  const EncryptedNotebookApp({super.key});

  @override
  ConsumerState<EncryptedNotebookApp> createState() => _EncryptedNotebookAppState();
}

class _EncryptedNotebookAppState extends ConsumerState<EncryptedNotebookApp> {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Secure Advanced Notebook',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
