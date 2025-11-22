# Error Handling Quick Reference

## Quick Start

### 1. Import Required Files

```dart
import 'package:encrypted_notebook/core/utils/logger.dart';
import 'package:encrypted_notebook/core/utils/error_handler.dart';
import 'package:encrypted_notebook/core/utils/error_dialog.dart';
import 'package:encrypted_notebook/core/utils/error_boundary.dart';
import 'package:encrypted_notebook/core/utils/result.dart';
```

### 2. Create Logger

```dart
class MyService {
  static const _logger = Logger('MyService');
  
  // Use logger throughout the class
}
```

### 3. Service Method Pattern

```dart
Future<Result<T, Exception>> myMethod() async {
  try {
    _logger.info('Starting operation');
    final result = await _doWork();
    _logger.info('Operation completed');
    return Ok(result);
  } catch (error, stackTrace) {
    _logger.error('Operation failed', error, stackTrace);
    return Err(Exception('Operation failed'));
  }
}
```

### 4. UI Error Handling Pattern

```dart
Future<void> _handleAction(BuildContext context) async {
  try {
    ErrorDialog.showLoading(context, message: '处理中...');
    final result = await service.doSomething();
    ErrorDialog.hideLoading(context);
    
    result.when(
      ok: (value) {
        ErrorDialog.showSuccess(context, '操作成功');
        // Handle success
      },
      error: (error) {
        ErrorDialog.showError(context, error);
      },
    );
  } catch (error, stackTrace) {
    ErrorDialog.hideLoading(context);
    ErrorDialog.showError(context, error, stackTrace: stackTrace);
  }
}
```

## Common Patterns

### Pattern 1: Simple Service Method

```dart
Future<Result<Note, Exception>> getNote(String id) async {
  try {
    _logger.info('Fetching note: $id');
    final note = await _dao.getNote(id);
    return Ok(note);
  } catch (error, stackTrace) {
    _logger.error('Failed to fetch note', error, stackTrace);
    return Err(Exception('Failed to fetch note'));
  }
}
```

### Pattern 2: Service Method with Validation

```dart
Future<Result<void, Exception>> saveNote(Note note) async {
  try {
    // Validate
    if (note.title.isEmpty) {
      return Err(Exception('Title cannot be empty'));
    }
    
    _logger.info('Saving note: ${note.uuid}');
    await _dao.saveNote(note);
    _logger.info('Note saved successfully');
    return const Ok(null);
  } catch (error, stackTrace) {
    _logger.error('Failed to save note', error, stackTrace);
    return Err(Exception('Failed to save note'));
  }
}
```

### Pattern 3: UI with Loading State

```dart
Future<void> _saveNote(BuildContext context) async {
  ErrorDialog.showLoading(context, message: '保存中...');
  
  try {
    final result = await notesService.saveNote(_note);
    ErrorDialog.hideLoading(context);
    
    result.when(
      ok: (_) {
        ErrorDialog.showSuccess(context, '保存成功');
        Navigator.pop(context);
      },
      error: (error) {
        ErrorDialog.showError(context, error);
      },
    );
  } catch (error, stackTrace) {
    ErrorDialog.hideLoading(context);
    ErrorDialog.showError(context, error, stackTrace: stackTrace);
  }
}
```

### Pattern 4: UI with Error Boundary

```dart
@override
Widget build(BuildContext context) {
  return ErrorBoundary(
    errorTitle: '加载失败',
    onRetry: _loadData,
    child: _buildContent(),
  );
}
```

### Pattern 5: Provider with Error Handling

```dart
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final service = ref.watch(notesServiceProvider);
  final result = await service.getAllNotes();
  
  return result.when(
    ok: (notes) => notes,
    error: (error) => throw error,
  );
});
```

### Pattern 6: AsyncValue Error Handling

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final notesAsync = ref.watch(notesProvider);
  
  return notesAsync.when(
    data: (notes) => _buildList(notes),
    loading: () => const CircularProgressIndicator(),
    error: (error, stack) {
      _logger.error('Failed to load notes', error, stack);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(ErrorHandler.getUserFriendlyMessage(error, stack)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(notesProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    },
  );
}
```

## Logger Usage

### Log Levels

```dart
// Debug - Development only
_logger.debug('Debug information');

// Info - General information
_logger.info('User logged in');

// Warning - Potential issues
_logger.warning('Network unstable', error);

// Error - Recoverable errors
_logger.error('Failed to sync', error, stackTrace);

// Fatal - Critical errors
_logger.fatal('Database corrupted', error, stackTrace);
```

### What to Log

✅ **DO Log:**
- Operation start/completion
- Important state changes
- Error conditions
- Performance metrics (without sensitive data)

❌ **DON'T Log:**
- Passwords or master passwords
- Encryption keys
- User content (notes, vault items)
- Email addresses (PII)
- Authentication tokens

### Automatic Sanitization

The logger automatically sanitizes:
```dart
_logger.debug('password: secret123');
// Logs: "[REDACTED]: [REDACTED]"

_logger.debug('dataKey: abc123def456');
// Logs: "[REDACTED]: [REDACTED]"

_logger.debug('user@example.com logged in');
// Logs: "[REDACTED] logged in"
```

## Error Dialog Usage

### Show Error

```dart
// From exception
ErrorDialog.showError(context, error);

// With stack trace
ErrorDialog.showError(context, error, stackTrace: stackTrace);
```

### Show Success

```dart
ErrorDialog.showSuccess(context, '保存成功');
```

### Show Warning

```dart
ErrorDialog.showWarning(context, '网络连接不稳定');
```

### Show Info

```dart
ErrorDialog.showInfo(context, '正在同步数据');
```

### Show Confirmation

```dart
final confirmed = await ErrorDialog.showConfirmation(
  context,
  title: '删除确认',
  message: '确定要删除这条笔记吗？',
  confirmText: '删除',
  cancelText: '取消',
  isDangerous: true,
);

if (confirmed) {
  // Delete the note
}
```

### Show Loading

```dart
ErrorDialog.showLoading(context, message: '加载中...');
// ... do work ...
ErrorDialog.hideLoading(context);
```

### Show Error Dialog

```dart
await ErrorDialog.show(
  context,
  error,
  title: '操作失败',
  onRetry: () => _retryOperation(),
);
```

## Result Type Usage

### Create Results

```dart
// Success
return Ok(value);
return Result.ok(value);

// Error
return Err(error);
return Result.error(error);
```

### Handle Results

```dart
// Pattern matching
result.when(
  ok: (value) => print('Success: $value'),
  error: (error) => print('Error: $error'),
);

// Get value or throw
final value = result.getOrThrow();

// Get value or default
final value = result.getOrDefault(defaultValue);

// Get value or compute
final value = result.getOrElse((error) => computeDefault(error));
```

### Transform Results

```dart
// Map success value
final mapped = result.map((value) => value * 2);

// Map error value
final mapped = result.mapErr((error) => 'Error: $error');
```

### Future Results

```dart
// Unwrap Future<Result>
final value = await futureResult.unwrap();

// Catch errors
final result = await futureResult.catchError(
  (error) => Exception('Caught: $error'),
);
```

## Error Boundary Usage

### Basic Usage

```dart
ErrorBoundary(
  child: MyWidget(),
)
```

### With Custom Messages

```dart
ErrorBoundary(
  errorTitle: '加载失败',
  errorMessage: '无法加载数据，请稍后重试',
  child: MyWidget(),
)
```

### With Retry

```dart
ErrorBoundary(
  errorTitle: '加载失败',
  onRetry: () {
    // Retry logic
    setState(() {
      _loadData();
    });
  },
  child: MyWidget(),
)
```

### Using Extension

```dart
MyWidget().withErrorBoundary(
  errorTitle: '加载失败',
  onRetry: _loadData,
)
```

## Error Handler Usage

### Convert Exception to Message

```dart
try {
  // Some operation
} catch (error, stackTrace) {
  final message = ErrorHandler.getUserFriendlyMessage(error, stackTrace);
  print(message); // User-friendly Chinese message
}
```

### Show Error Snackbar

```dart
try {
  // Some operation
} catch (error, stackTrace) {
  ErrorHandler.showErrorSnackBar(context, error, stackTrace);
}
```

## Common Error Types

### Firebase Auth Errors

```dart
FirebaseAuthException(code: 'user-not-found')
// → "用户不存在，请检查邮箱地址"

FirebaseAuthException(code: 'wrong-password')
// → "密码错误，请重试"

FirebaseAuthException(code: 'email-already-in-use')
// → "该邮箱已被注册"
```

### Firestore Errors

```dart
FirebaseException(code: 'permission-denied')
// → "权限不足，无法访问该资源"

FirebaseException(code: 'unavailable')
// → "服务暂时不可用，请稍后重试"
```

### Network Errors

```dart
Exception('SocketException: ...')
// → "网络连接失败，请检查您的网络设置"

Exception('TimeoutException: ...')
// → "操作超时，请稍后重试"
```

### Encryption Errors

```dart
Exception('SecretBox decryption failed')
// → "解密失败，请检查您的主密码是否正确"
```

### Database Errors

```dart
Exception('SqliteException: ...')
// → "数据库操作失败，请稍后重试"
```

## Testing

### Test Error Handling

```dart
test('service returns error on failure', () async {
  final mockDao = MockDao();
  when(mockDao.getData()).thenThrow(Exception('DB error'));
  
  final service = MyService(dao: mockDao);
  final result = await service.getData();
  
  expect(result.isErr, true);
});
```

### Test Error Messages

```dart
test('converts auth error to Chinese', () {
  final error = FirebaseAuthException(code: 'user-not-found');
  final message = ErrorHandler.getUserFriendlyMessage(error);
  
  expect(message, '用户不存在，请检查邮箱地址');
});
```

### Test Logger Sanitization

```dart
test('logger sanitizes passwords', () {
  // Test that sensitive data is redacted
});
```

## Checklist

### For Services

- [ ] Create logger instance
- [ ] Return Result types
- [ ] Log operation start/completion
- [ ] Log errors with context
- [ ] Catch and wrap exceptions
- [ ] Don't log sensitive data

### For UI

- [ ] Use ErrorBoundary for critical components
- [ ] Use ErrorDialog for user feedback
- [ ] Show loading states
- [ ] Handle Result types properly
- [ ] Provide retry mechanisms
- [ ] Convert errors to user-friendly messages

### For Providers

- [ ] Handle errors properly
- [ ] Log errors
- [ ] Propagate errors correctly
- [ ] Use Result types where appropriate

## Tips

1. **Always use the Logger** - It sanitizes automatically
2. **Always convert errors** - Use ErrorHandler for user messages
3. **Always provide context** - Include relevant IDs in logs
4. **Never log sensitive data** - Passwords, keys, content
5. **Use Result types** - For domain logic
6. **Use ErrorBoundary** - For critical UI components
7. **Provide retry options** - When operations can be retried
8. **Test error handling** - Write tests for error scenarios

## Resources

- `ERROR_HANDLING_README.md` - Comprehensive guide
- `ERROR_HANDLING_INTEGRATION.md` - Integration examples
- `ERROR_FLOW_DIAGRAM.md` - Visual flow diagrams
- `IMPLEMENTATION_SUMMARY.md` - Implementation details
