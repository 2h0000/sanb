import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import 'security_service.dart';

/// Provider for SecurityService
/// This service handles auto-lock and clipboard clearing
final securityServiceProvider = Provider<SecurityService>((ref) {
  final service = SecurityService(
    onAutoLock: () {
      // Lock the vault by clearing the data key
      ref.read(dataKeyProvider.notifier).state = null;
    },
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
