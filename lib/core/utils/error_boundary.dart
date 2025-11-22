import 'package:flutter/material.dart';
import 'error_handler.dart';
import 'logger.dart';

/// Error boundary widget that catches and displays errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorTitle,
    this.errorMessage,
    this.onRetry,
  });
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  static const _logger = Logger('ErrorBoundary');
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    // Reset error state when widget is created
    _error = null;
    _stackTrace = null;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context);
    }
    
    return widget.child;
  }
  
  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    final userMessage = widget.errorMessage ?? 
        ErrorHandler.getUserFriendlyMessage(_error!, _stackTrace);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorTitle ?? '出错了',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                userMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                    widget.onRetry?.call();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Manually set an error to display
  void setError(Object error, [StackTrace? stackTrace]) {
    _logger.error('Error boundary caught error', error, stackTrace);
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }
  
  /// Clear the current error
  void clearError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }
}

/// Extension to easily show error boundaries
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    String? errorTitle,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return ErrorBoundary(
      errorTitle: errorTitle,
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: this,
    );
  }
}
