import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security_providers.dart';

/// Observer that monitors app lifecycle and triggers security actions
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  
  AppLifecycleObserver(this.ref);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityService = ref.read(securityServiceProvider);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background, start auto-lock timer
        securityService.startAutoLockTimer();
        break;
      case AppLifecycleState.resumed:
        // App came to foreground, cancel auto-lock timer
        securityService.cancelAutoLockTimer();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated or hidden
        break;
    }
  }
}
