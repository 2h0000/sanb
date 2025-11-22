import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_notebook/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('getUserFriendlyMessage', () {
      test('converts FirebaseAuthException user-not-found', () {
        final error = FirebaseAuthException(code: 'user-not-found');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '用户不存在，请检查邮箱地址');
      });
      
      test('converts FirebaseAuthException wrong-password', () {
        final error = FirebaseAuthException(code: 'wrong-password');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '密码错误，请重试');
      });
      
      test('converts FirebaseAuthException invalid-email', () {
        final error = FirebaseAuthException(code: 'invalid-email');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '邮箱格式不正确');
      });
      
      test('converts FirebaseAuthException email-already-in-use', () {
        final error = FirebaseAuthException(code: 'email-already-in-use');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '该邮箱已被注册');
      });
      
      test('converts FirebaseException permission-denied', () {
        final error = FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
        );
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '权限不足，无法访问该资源');
      });
      
      test('converts network errors', () {
        final error = Exception('SocketException: Network unreachable');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '网络连接失败，请检查您的网络设置');
      });
      
      test('converts timeout errors', () {
        final error = Exception('TimeoutException: Operation timed out');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '操作超时，请稍后重试');
      });
      
      test('converts decryption errors', () {
        final error = Exception('SecretBox decryption failed');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '解密失败，请检查您的主密码是否正确');
      });
      
      test('converts database errors', () {
        final error = Exception('SqliteException: database is locked');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '数据库操作失败，请稍后重试');
      });
      
      test('converts file system errors', () {
        final error = Exception('FileSystemException: Permission denied');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '文件操作失败，请检查存储权限');
      });
      
      test('returns generic message for unknown errors', () {
        final error = Exception('Some unknown error');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        expect(message, '操作失败，请稍后重试');
      });
    });
  });
}
