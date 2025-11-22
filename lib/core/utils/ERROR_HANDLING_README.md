# Error Handling and Logging System

This document describes the error handling and logging infrastructure implemented for the Encrypted Notebook app.

## Overview

The error handling system provides:
- **Global error catching** for uncaught exceptions
- **Firebase Crashlytics integration** for production error tracking
- **Data sanitization** to prevent logging sensitive information
- **User-friendly error messages** for all common error types
- **Structured logging** with different severity levels

## Components

### 1. Logger (`logger.dart`)

Enhanced logger with automatic data sanitization and Crashlytics integration.

**Features:**
- Sanitizes passwords, keys, tokens, and PII from log messages
- Integrates with Firebase Crashlytics for production error tracking
- Supports multiple log levels: debug, info, warning, error, fatal
- Only logs to console in debug mode

**Usage:**
```dart
const _logger = Logger('MyComponent');

_logger.debug('Debug message');
_logger.info('Info message');
_logger.warning('Warning message', error);
_logger.error('Error occurred', error, stackTrace);
_logger.fatal('Fatal error', error, stackTrace);
```

**Sanitization:**
The logger automatically redacts:
- Passwords and master passwords
- Encryption keys (dataKey, passwordKey, wrappedDataKey)
- Authentication tokens
- Base64-encoded data (potential encrypted content)
- Email addresses (PII)

### 2. ErrorHandler (`error_handler.dart`)

Converts exceptions to user-friendly Chinese messages.

**Supported Error Types:**
- Firebase Authentication errors
- Firestore errors
- Firebase Storage errors
- Network errors
- Timeout errors
- Encryption/decryption errors
- Database errors
- File system errors

**Usage:**
```dart
try {
  // Some operation
} catch (error, stackTrace) {
  final message = ErrorHandler.getUserFriendlyMessage(error, stackTrace);
  print(message); // "网络连接失败，请检查您的网络设置"
}

// Or show directly in a snackbar
ErrorHandler.showErrorSnackBar(context, error, stackTrace);
```

### 3. ErrorBoundary (`error_boundary.dart`)

Widget that catches and displays errors gracefully.

**Usage:**
```dart
// Wrap any widget
ErrorBoundary(
  errorTitle: '加载失败',
  errorMessage: '无法加载数据',
  onRetry: () {
    // Retry logic
  },
  child: MyWidget(),
)

// Or use the extension
MyWidget().withErrorBoundary(
  errorTitle: '加载失败',
  onRetry: () { /* retry */ },
)
```

### 4. ErrorDialog (`error_dialog.dart`)

Utility for showing error dialogs and snackbars.

**Usage:**
```dart
// Show error dialog
await ErrorDialog.show(context, error, stackTrace: stackTrace);

// Show error snackbar
ErrorDialog.showError(context, error);

// Show success message
ErrorDialog.showSuccess(context, '保存成功');

// Show warning
ErrorDialog.showWarning(context, '网络连接不稳定');

// Show info
ErrorDialog.showInfo(context, '正在同步数据');

// Show confirmation dialog
final confirmed = await ErrorDialog.showConfirmation(
  context,
  title: '删除确认',
  message: '确定要删除这条笔记吗？',
  isDangerous: true,
);

// Show loading dialog
ErrorDialog.showLoading(context, message: '正在保存...');
// ... do work ...
ErrorDialog.hideLoading(context);
```

### 5. Result Type Extensions (`result.dart`)

Enhanced Result type with error handling utilities.

**Usage:**
```dart
// Get value or throw
final value = result.getOrThrow();

// Get value or default
final value = result.getOrDefault(defaultValue);

// Get value or compute from error
final value = result.getOrElse((error) => computeDefault(error));

// Unwrap Future<Result>
final value = await futureResult.unwrap();

// Catch errors in Future<Result>
final result = await futureResult.catchError((error) => MyError(error));
```

## Global Error Handling

The app sets up global error handlers in `main.dart`:

1. **Flutter Framework Errors**: Caught by `FlutterError.onError`
2. **Async Errors**: Caught by `PlatformDispatcher.instance.onError`
3. **Zone Errors**: Caught by `runZonedGuarded`

All uncaught errors are:
- Logged with sanitization
- Reported to Firebase Crashlytics
- Displayed to users with friendly messages (in production)

## Best Practices

### 1. Always Use Try-Catch for User Operations

```dart
Future<void> saveNote() async {
  try {
    await notesRepository.save(note);
    ErrorDialog.showSuccess(context, '保存成功');
  } catch (error, stackTrace) {
    _logger.error('Failed to save note', error, stackTrace);
    ErrorDialog.showError(context, error);
  }
}
```

### 2. Use Result Type for Domain Logic

```dart
Future<Result<Note, Exception>> loadNote(String id) async {
  try {
    final note = await repository.getNote(id);
    return Ok(note);
  } catch (error) {
    _logger.error('Failed to load note', error);
    return Err(Exception('Failed to load note'));
  }
}
```

### 3. Wrap Critical UI Components

```dart
@override
Widget build(BuildContext context) {
  return ErrorBoundary(
    onRetry: _loadData,
    child: _buildContent(),
  );
}
```

### 4. Never Log Sensitive Data

```dart
// ❌ BAD - logs password
_logger.debug('User password: $password');

// ✅ GOOD - sanitized automatically
_logger.debug('User authenticated successfully');

// ❌ BAD - logs encryption key
_logger.debug('DataKey: ${base64.encode(dataKey)}');

// ✅ GOOD - no sensitive data
_logger.debug('DataKey loaded successfully');
```

### 5. Provide Context in Error Messages

```dart
// ❌ BAD - no context
_logger.error('Failed', error);

// ✅ GOOD - clear context
_logger.error('Failed to sync note ${note.uuid}', error, stackTrace);
```

## Testing Error Handling

### Test Error Sanitization

```dart
test('Logger sanitizes passwords', () {
  final logger = Logger('Test');
  // Verify that password patterns are redacted
});
```

### Test User-Friendly Messages

```dart
test('ErrorHandler converts FirebaseAuthException', () {
  final error = FirebaseAuthException(code: 'user-not-found');
  final message = ErrorHandler.getUserFriendlyMessage(error);
  expect(message, contains('用户不存在'));
});
```

### Test Error Boundary

```dart
testWidgets('ErrorBoundary shows error UI', (tester) async {
  await tester.pumpWidget(
    ErrorBoundary(
      child: ThrowingWidget(),
    ),
  );
  
  expect(find.text('出错了'), findsOneWidget);
});
```

## Crashlytics Dashboard

View production errors at:
https://console.firebase.google.com/project/YOUR_PROJECT/crashlytics

**Key Metrics:**
- Crash-free users percentage
- Most common errors
- Error trends over time
- Affected devices and OS versions

## Requirements Validation

This implementation satisfies **Requirement 10.5**:

✅ **Global error handling**: All uncaught exceptions are caught and logged
✅ **Firebase Crashlytics integration**: Configured and reporting errors
✅ **Log sanitization**: Passwords, keys, and user content are redacted
✅ **User-friendly messages**: All error types have Chinese translations
✅ **Error display**: Multiple ways to show errors (dialogs, snackbars, boundaries)

## Future Enhancements

- [ ] Add error analytics and reporting dashboard
- [ ] Implement retry strategies with exponential backoff
- [ ] Add offline error queue for sync when network returns
- [ ] Implement error categorization and prioritization
- [ ] Add user feedback mechanism for errors
