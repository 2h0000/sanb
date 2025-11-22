import 'package:flutter/material.dart';
import 'error_handler.dart';

/// Utility class for showing error dialogs and messages
class ErrorDialog {
  /// Show an error dialog with a user-friendly message
  static Future<void> show(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? title,
    VoidCallback? onRetry,
  }) async {
    final message = ErrorHandler.getUserFriendlyMessage(error, stackTrace);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '错误'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('重试'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Show an info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF9800),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Show an error snackbar
  static void showError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
  }) {
    final message = ErrorHandler.getUserFriendlyMessage(error, stackTrace);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Show a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Show a loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(message ?? '加载中...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Hide the loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
