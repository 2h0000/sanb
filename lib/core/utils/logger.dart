import 'package:flutter/foundation.dart';

/// Logger utility with data sanitization (no Firebase)
class Logger {
  final String tag;
  
  const Logger(this.tag);
  
  /// Sanitize sensitive data from messages
  /// Removes potential passwords, keys, tokens, and user content
  static String _sanitize(String message) {
    String sanitized = message;
    
    // Sanitize common sensitive patterns
    final patterns = [
      // Password-like patterns
      RegExp(r'password["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'masterPassword["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'pwd["\s:=]+[^\s,}\]]+', caseSensitive: false),
      
      // Key-like patterns
      RegExp(r'key["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'dataKey["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'passwordKey["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'wrappedDataKey["\s:=]+[^\s,}\]]+', caseSensitive: false),
      
      // Token-like patterns
      RegExp(r'token["\s:=]+[^\s,}\]]+', caseSensitive: false),
      RegExp(r'auth["\s:=]+[^\s,}\]]+', caseSensitive: false),
      
      // Email patterns (partial sanitization)
      RegExp(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
    ];
    
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    
    return sanitized;
  }
  
  /// Log debug message (only in debug mode)
  void debug(String message) {
    if (kDebugMode) {
      final sanitized = _sanitize(message);
      debugPrint('[$tag] DEBUG: $sanitized');
    }
  }
  
  /// Log info message
  void info(String message) {
    final sanitized = _sanitize(message);
    if (kDebugMode) {
      debugPrint('[$tag] INFO: $sanitized');
    }
  }
  
  /// Log warning message
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $sanitized');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
  
  /// Log error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    debugPrint('[$tag] ERROR: $sanitized');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Log fatal error (critical errors that should always be logged)
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    debugPrint('[$tag] FATAL: $sanitized');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
