import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logger.dart';

/// Global error handler for converting exceptions to user-friendly messages
class ErrorHandler {
  static const _logger = Logger('ErrorHandler');
  
  /// Convert an exception to a user-friendly error message
  static String getUserFriendlyMessage(Object error, [StackTrace? stackTrace]) {
    _logger.error('Handling error', error, stackTrace);
    
    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }
    
    // Firestore errors
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }
    
    // Storage errors
    if (error is FirebaseStorageException) {
      return _handleStorageError(error);
    }
    
    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return '网络连接失败，请检查您的网络设置';
    }
    
    // Timeout errors
    if (error.toString().contains('TimeoutException')) {
      return '操作超时，请稍后重试';
    }
    
    // Encryption/Decryption errors
    if (error.toString().contains('SecretBox') ||
        error.toString().contains('decrypt') ||
        error.toString().contains('cipher')) {
      return '解密失败，请检查您的主密码是否正确';
    }
    
    // Database errors
    if (error.toString().contains('SqliteException') ||
        error.toString().contains('DatabaseException')) {
      return '数据库操作失败，请稍后重试';
    }
    
    // File system errors
    if (error.toString().contains('FileSystemException') ||
        error.toString().contains('PathNotFoundException')) {
      return '文件操作失败，请检查存储权限';
    }
    
    // Generic error
    return '操作失败，请稍后重试';
  }
  
  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return '用户不存在，请检查邮箱地址';
      case 'wrong-password':
        return '密码错误，请重试';
      case 'invalid-email':
        return '邮箱格式不正确';
      case 'user-disabled':
        return '该账户已被禁用';
      case 'email-already-in-use':
        return '该邮箱已被注册';
      case 'weak-password':
        return '密码强度不足，请使用更强的密码';
      case 'operation-not-allowed':
        return '该操作未被允许';
      case 'invalid-credential':
        return '凭证无效，请重新登录';
      case 'network-request-failed':
        return '网络请求失败，请检查网络连接';
      case 'too-many-requests':
        return '请求过于频繁，请稍后重试';
      case 'requires-recent-login':
        return '该操作需要重新登录';
      default:
        return '认证失败：${error.message ?? "未知错误"}';
    }
  }
  
  static String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return '权限不足，无法访问该资源';
      case 'unavailable':
        return '服务暂时不可用，请稍后重试';
      case 'not-found':
        return '请求的资源不存在';
      case 'already-exists':
        return '资源已存在';
      case 'resource-exhausted':
        return '资源配额已用尽';
      case 'failed-precondition':
        return '操作条件不满足';
      case 'aborted':
        return '操作被中止';
      case 'out-of-range':
        return '操作超出有效范围';
      case 'unimplemented':
        return '该功能尚未实现';
      case 'internal':
        return '服务器内部错误';
      case 'data-loss':
        return '数据丢失或损坏';
      case 'unauthenticated':
        return '未认证，请先登录';
      case 'deadline-exceeded':
        return '操作超时';
      default:
        return '操作失败：${error.message ?? "未知错误"}';
    }
  }
  
  static String _handleStorageError(FirebaseStorageException error) {
    switch (error.code) {
      case 'object-not-found':
        return '文件不存在';
      case 'bucket-not-found':
        return '存储桶不存在';
      case 'project-not-found':
        return '项目不存在';
      case 'quota-exceeded':
        return '存储配额已用尽';
      case 'unauthenticated':
        return '未认证，请先登录';
      case 'unauthorized':
        return '权限不足';
      case 'retry-limit-exceeded':
        return '重试次数过多，请稍后重试';
      case 'invalid-checksum':
        return '文件校验失败';
      case 'canceled':
        return '操作已取消';
      case 'invalid-event-name':
        return '无效的事件名称';
      case 'invalid-url':
        return '无效的URL';
      case 'invalid-argument':
        return '无效的参数';
      case 'no-default-bucket':
        return '未配置默认存储桶';
      case 'cannot-slice-blob':
        return '文件处理失败';
      case 'server-file-wrong-size':
        return '文件大小不匹配';
      default:
        return '存储操作失败：${error.message ?? "未知错误"}';
    }
  }
  
  /// Show a user-friendly error message in a snackbar
  static void showErrorSnackBar(
    dynamic context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final message = getUserFriendlyMessage(error, stackTrace);
    
    // Check if context has ScaffoldMessenger
    try {
      final scaffoldMessenger = context is BuildContext 
          ? ScaffoldMessenger.of(context)
          : null;
      
      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _logger.warning('Failed to show snackbar', e);
    }
  }
}
