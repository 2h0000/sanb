import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_notebook/core/utils/logger.dart';

/// Service for monitoring network connectivity status
/// Provides real-time updates on network availability
class ConnectivityService {
  final Connectivity _connectivity;
  final Logger _logger = const Logger('ConnectivityService');
  
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();
  
  /// Get current connectivity status
  bool get isConnected => _isConnected;
  
  /// Stream of connectivity status changes
  /// Emits true when connected, false when disconnected
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    _logger.info('Initializing connectivity service');
    
    // Check initial connectivity status
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        _logger.error('Error in connectivity stream', error);
      },
    );
    
    _logger.info('Connectivity service initialized, connected: $_isConnected');
  }
  
  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      _logger.error('Failed to check connectivity', e);
      _updateConnectivityStatus([ConnectivityResult.none]);
    }
  }
  
  /// Handle connectivity change events
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _logger.debug('Connectivity changed: $results');
    _updateConnectivityStatus(results);
  }
  
  /// Update connectivity status based on results
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    
    // Consider connected if any result is not 'none'
    _isConnected = results.any((result) => result != ConnectivityResult.none);
    
    if (wasConnected != _isConnected) {
      _logger.info('Connectivity status changed: $_isConnected');
      _connectivityController.add(_isConnected);
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('Disposing connectivity service');
    await _subscription?.cancel();
    await _connectivityController.close();
  }
}
