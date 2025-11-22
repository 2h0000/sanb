# Error Handling Flow Diagram

## Global Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Start                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Initialize Firebase & Crashlytics               │
│  • Firebase.initializeApp()                                  │
│  • Configure Crashlytics                                     │
│  • Set up global error handlers                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Global Error Handlers                       │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  FlutterError.onError                          │         │
│  │  • Catches Flutter framework errors            │         │
│  │  • Logs to Crashlytics                         │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  PlatformDispatcher.instance.onError           │         │
│  │  • Catches uncaught async errors               │         │
│  │  • Logs to Crashlytics                         │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  runZonedGuarded                               │         │
│  │  • Catches zone errors                         │         │
│  │  • Logs to Crashlytics                         │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                      ┌───────────────┐
                      │  Run App      │
                      └───────────────┘
```

## Service Layer Error Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Service Method Call                       │
│  Example: notesService.createNote(title, content)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Try-Catch Block                           │
│  try {                                                       │
│    _logger.info('Creating note');                           │
│    final result = await _dao.createNote(...);               │
│    _logger.info('Note created successfully');               │
│    return Ok(result);                                       │
│  } catch (error, stackTrace) {                              │
│    _logger.error('Failed to create note', error, stack);    │
│    return Err(Exception('Failed to create note'));          │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Return Result  │
                    │  Ok or Err      │
                    └─────────────────┘
```

## UI Layer Error Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Action (e.g., Save)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Show Loading Dialog                         │
│  ErrorDialog.showLoading(context, '正在保存...');            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Call Service Method                         │
│  final result = await service.saveNote(note);               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Hide Loading Dialog                         │
│  ErrorDialog.hideLoading(context);                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Check Result   │
                    └─────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
        ┌──────────────┐          ┌──────────────┐
        │   Success    │          │    Error     │
        └──────────────┘          └──────────────┘
                │                           │
                ▼                           ▼
┌───────────────────────────┐  ┌───────────────────────────┐
│  Show Success Message     │  │  Convert to User-Friendly │
│  ErrorDialog.showSuccess  │  │  ErrorHandler.getMessage  │
│  Navigate back            │  │  Show Error Dialog/Snack  │
└───────────────────────────┘  └───────────────────────────┘
```

## Logger Sanitization Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Log Message                               │
│  _logger.error('Failed to unlock vault with password: xyz') │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Sanitization Process                        │
│                                                              │
│  Check for sensitive patterns:                              │
│  • password, masterPassword, pwd                            │
│  • key, dataKey, passwordKey, wrappedDataKey                │
│  • token, auth                                              │
│  • Base64 strings (>40 chars)                               │
│  • Email addresses                                          │
│                                                              │
│  Replace matches with [REDACTED]                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Sanitized Message                           │
│  'Failed to unlock vault with [REDACTED]: [REDACTED]'       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Log to Console │
                    │  (Debug only)   │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Log to         │
                    │  Crashlytics    │
                    │  (Production)   │
                    └─────────────────┘
```

## Error Boundary Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Widget Tree                               │
│                                                              │
│  ErrorBoundary(                                              │
│    errorTitle: '加载失败',                                   │
│    onRetry: () => reload(),                                 │
│    child: ComplexWidget(),                                  │
│  )                                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Render Child   │
                    └─────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
        ┌──────────────┐          ┌──────────────┐
        │   Success    │          │    Error     │
        │  Show Child  │          │   Thrown     │
        └──────────────┘          └──────────────┘
                                          │
                                          ▼
                              ┌─────────────────────┐
                              │  Catch Error        │
                              │  Log to Logger      │
                              │  Set Error State    │
                              └─────────────────────┘
                                          │
                                          ▼
                              ┌─────────────────────┐
                              │  Show Error Screen  │
                              │  • Error Icon       │
                              │  • Error Title      │
                              │  • Error Message    │
                              │  • Retry Button     │
                              └─────────────────────┘
```

## Error Message Conversion Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Exception Thrown                          │
│  FirebaseAuthException(code: 'user-not-found')              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              ErrorHandler.getUserFriendlyMessage             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Check Exception Type                        │
│                                                              │
│  Is FirebaseAuthException?     ──────────────┐              │
│  Is FirebaseException?         ──────────────┤              │
│  Is FirebaseStorageException?  ──────────────┤              │
│  Contains 'SocketException'?   ──────────────┤              │
│  Contains 'TimeoutException'?  ──────────────┤              │
│  Contains 'decrypt'?           ──────────────┤              │
│  Contains 'SqliteException'?   ──────────────┤              │
│  Contains 'FileSystemException'? ────────────┤              │
│  Unknown error                 ──────────────┘              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Map to User-Friendly Message                │
│                                                              │
│  'user-not-found' → '用户不存在，请检查邮箱地址'              │
│  'wrong-password' → '密码错误，请重试'                       │
│  'permission-denied' → '权限不足，无法访问该资源'            │
│  'SocketException' → '网络连接失败，请检查您的网络设置'      │
│  'decrypt' → '解密失败，请检查您的主密码是否正确'            │
│  Unknown → '操作失败，请稍后重试'                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Return Chinese Message                      │
│  '用户不存在，请检查邮箱地址'                                │
└─────────────────────────────────────────────────────────────┘
```

## Complete Error Handling Stack

```
┌─────────────────────────────────────────────────────────────┐
│                        User Action                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (Widget)                       │
│  • ErrorBoundary wraps critical components                  │
│  • ErrorDialog shows user-friendly messages                 │
│  • Handles Result types from services                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer (Service)                │
│  • Returns Result<T, Exception>                             │
│  • Logs errors with Logger                                  │
│  • Catches and wraps exceptions                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer (DAO/Repository)               │
│  • Performs database/network operations                     │
│  • Throws exceptions on failure                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Error Occurs                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Logger (Sanitization)                     │
│  • Sanitizes sensitive data                                 │
│  • Logs to console (debug)                                  │
│  • Logs to Crashlytics (production)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ErrorHandler (Conversion)                 │
│  • Converts exception to user-friendly message              │
│  • Returns Chinese message                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Display to User                           │
│  • Error dialog                                             │
│  • Error snackbar                                           │
│  • Error screen (via ErrorBoundary)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Crashlytics                      │
│  • Stores error report                                      │
│  • Tracks error trends                                      │
│  • Provides analytics                                       │
└─────────────────────────────────────────────────────────────┘
```

## Key Principles

1. **Catch Early**: Catch errors as close to the source as possible
2. **Log Everything**: Log all errors with context (sanitized)
3. **Convert for Users**: Convert technical errors to user-friendly messages
4. **Report to Crashlytics**: Send all errors to Crashlytics for tracking
5. **Sanitize Always**: Never log sensitive data (passwords, keys, content)
6. **Provide Context**: Include relevant information in error messages
7. **Allow Retry**: Provide retry mechanisms where appropriate
8. **Fail Gracefully**: Show friendly error screens instead of crashes
