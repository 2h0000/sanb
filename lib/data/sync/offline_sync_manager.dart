import 'dart:async';
import 'package:encrypted_notebook/core/network/connectivity_service.dart';
import 'package:encrypted_notebook/core/utils/logger.dart';
import 'package:encrypted_notebook/data/sync/sync_service.dart';

/// Manages offline-aware synchronization
/// Coordinates between connectivity status and sync operations
/// Implements:
/// - Automatic sync when network becomes available
/// - Queue management for offline operations
/// - Graceful handling of network interruptions
class OfflineSyncManager {
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  final Logger _logger = const Logger('OfflineSyncManager');
  
  StreamSubscription<bool>? _connectivitySubscription;
  String? _currentUserId;
  bool _syncPending = false;
  
  OfflineSyncManager({
    required SyncService syncService,
    required ConnectivityService connectivityService,
  })  : _syncService = syncService,
        _connectivityService = connectivityService;
  
  /// Check if currently online
  bool get isOnline => _connectivityService.isConnected;
  
  /// Check if sync is running
  bool get isSyncRunning => _syncService.isRunning;
  
  /// Initialize offline sync manager
  Future<void> initialize() async {
    _logger.info('Initializing offline sync manager');
    
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _handleConnectivityChange,
      onError: (error) {
        _logger.error('Error in connectivity subscription', error);
      },
    );
    
    _logger.info('Offline sync manager initialized');
  }
  
  /// Start sync for a user
  /// If online, starts sync immediately
  /// If offline, marks sync as pending for when network returns
  Future<void> startSync(String uid) async {
    _logger.info('Starting sync for user $uid (online: $isOnline)');
    _currentUserId = uid;
    
    if (isOnline) {
      try {
        await _syncService.startSync(uid);
        _syncPending = false;
      } catch (e, stackTrace) {
        _logger.error('Failed to start sync', e, stackTrace);
        _syncPending = true;
        // Don't rethrow - we'll retry when network returns
      }
    } else {
      _logger.info('Offline - sync will start when network is available');
      _syncPending = true;
    }
  }
  
  /// Stop sync
  Future<void> stopSync() async {
    _logger.info('Stopping sync');
    _currentUserId = null;
    _syncPending = false;
    
    if (_syncService.isRunning) {
      await _syncService.stopSync();
    }
  }
  
  /// Push local changes to cloud
  /// Only attempts if online, otherwise queues for later
  Future<void> pushLocalChanges(String uid) async {
    if (!isOnline) {
      _logger.info('Offline - local changes will be pushed when network is available');
      _syncPending = true;
      return;
    }
    
    try {
      await _syncService.pushLocalChanges(uid);
    } catch (e, stackTrace) {
      _logger.error('Failed to push local changes', e, stackTrace);
      _syncPending = true;
      rethrow;
    }
  }
  
  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(bool isConnected) async {
    _logger.info('Connectivity changed: $isConnected');
    
    if (isConnected) {
      await _handleNetworkRestored();
    } else {
      await _handleNetworkLost();
    }
  }
  
  /// Handle network restoration
  Future<void> _handleNetworkRestored() async {
    _logger.info('Network restored');
    
    // If we have a pending sync and a user ID, start sync
    if (_syncPending && _currentUserId != null) {
      _logger.info('Resuming sync for user $_currentUserId');
      
      try {
        // If sync is not running, start it
        if (!_syncService.isRunning) {
          await _syncService.startSync(_currentUserId!);
        } else {
          // If sync is already running, just push local changes
          await _syncService.pushLocalChanges(_currentUserId!);
        }
        
        _syncPending = false;
        _logger.info('Sync resumed successfully');
      } catch (e, stackTrace) {
        _logger.error('Failed to resume sync', e, stackTrace);
        // Keep sync pending for next retry
      }
    }
  }
  
  /// Handle network loss
  Future<void> _handleNetworkLost() async {
    _logger.info('Network lost - sync will continue with local operations only');
    
    // Don't stop sync service - it will handle network errors gracefully
    // Just mark that we need to sync when network returns
    if (_currentUserId != null) {
      _syncPending = true;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('Disposing offline sync manager');
    
    await _connectivitySubscription?.cancel();
    await _connectivityService.dispose();
    
    if (_syncService.isRunning) {
      await _syncService.stopSync();
    }
  }
}
