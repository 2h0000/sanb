import 'dart:async';
import 'package:flutter/services.dart';

/// Service that handles security features like auto-lock and clipboard clearing
class SecurityService {
  Timer? _autoLockTimer;
  Timer? _clipboardClearTimer;
  
  /// Duration after which vault auto-locks when app is in background
  static const Duration autoLockDuration = Duration(minutes: 5);
  
  /// Duration after which clipboard is cleared after copying password
  static const Duration clipboardClearDuration = Duration(seconds: 30);
  
  /// Callback to be called when auto-lock timer expires
  final VoidCallback? onAutoLock;
  
  SecurityService({this.onAutoLock});
  
  /// Start the auto-lock timer
  /// This should be called when the app goes to background
  void startAutoLockTimer() {
    cancelAutoLockTimer();
    
    _autoLockTimer = Timer(autoLockDuration, () {
      onAutoLock?.call();
    });
  }
  
  /// Cancel the auto-lock timer
  /// This should be called when the app comes to foreground
  void cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }
  
  /// Copy text to clipboard and schedule automatic clearing
  Future<void> copyToClipboardWithAutoClear(String text) async {
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));
    
    // Cancel any existing clipboard clear timer
    _clipboardClearTimer?.cancel();
    
    // Schedule clipboard clearing
    _clipboardClearTimer = Timer(clipboardClearDuration, () {
      _clearClipboard();
    });
  }
  
  /// Clear the clipboard
  Future<void> _clearClipboard() async {
    await Clipboard.setData(const ClipboardData(text: ''));
  }
  
  /// Dispose and cleanup timers
  void dispose() {
    _autoLockTimer?.cancel();
    _clipboardClearTimer?.cancel();
  }
}
