import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_notebook/core/network/connectivity_service.dart';
import 'package:encrypted_notebook/data/sync/offline_sync_manager.dart';
import 'package:encrypted_notebook/data/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

/// Provider for Connectivity instance
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  final service = ConnectivityService(connectivity: connectivity);
  
  // Initialize on first access
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// Provider for current connectivity status (synchronous)
final isOnlineProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isConnected;
});

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final firebaseClient = ref.watch(firebaseClientProvider);
  final notesDao = ref.watch(notesDaoProvider);
  final vaultDao = ref.watch(vaultDaoProvider);
  
  return SyncService(
    firebaseClient: firebaseClient,
    notesDao: notesDao,
    vaultDao: vaultDao,
  );
});

/// Provider for OfflineSyncManager
final offlineSyncManagerProvider = Provider<OfflineSyncManager>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  final manager = OfflineSyncManager(
    syncService: syncService,
    connectivityService: connectivityService,
  );
  
  // Initialize on first access
  manager.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});
