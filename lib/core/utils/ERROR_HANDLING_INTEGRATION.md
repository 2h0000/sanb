# Error Handling Integration Guide

This guide shows how to integrate the error handling system into existing features.

## Integration Checklist

- [x] Global error handlers configured in `main.dart`
- [x] Logger with sanitization implemented
- [x] ErrorHandler for user-friendly messages
- [x] ErrorBoundary widget for UI error catching
- [x] ErrorDialog utilities for showing errors
- [ ] Update existing services to use new error handling
- [ ] Update existing UI to show user-friendly errors
- [ ] Add error boundaries to critical screens

## Service Layer Integration

### Example: NotesService

**Before:**
```dart
class NotesService {
  Future<void> createNote(String title, String content) async {
    try {
      final note = Note(...);
      await _dao.createNote(note);
    } catch (e) {
      print('Error: $e'); // ❌ Not user-friendly
      rethrow;
    }
  }
}
```

**After:**
```dart
class NotesService {
  static const _logger = Logger('NotesService');
  
  Future<Result<void, Exception>> createNote(String title, String content) async {
    try {
      _logger.info('Creating note with title: $title');
      final note = Note(...);
      await _dao.createNote(note);
      _logger.info('Note created successfully');
      return const Ok(null);
    } catch (error, stackTrace) {
      _logger.error('Failed to create note', error, stackTrace);
      return Err(Exception('Failed to create note'));
    }
  }
}
```

### Example: SyncService

**Before:**
```dart
class SyncService {
  Future<void> syncNotes() async {
    final notes = await _dao.getAllNotes();
    for (final note in notes) {
      await _firebaseClient.pushNote(note); // ❌ No error handling
    }
  }
}
```

**After:**
```dart
class SyncService {
  static const _logger = Logger('SyncService');
  
  Future<Result<int, Exception>> syncNotes() async {
    try {
      _logger.info('Starting notes sync');
      final notes = await _dao.getAllNotes();
      int synced = 0;
      
      for (final note in notes) {
        try {
          await _firebaseClient.pushNote(note);
          synced++;
        } catch (error, stackTrace) {
          _logger.warning('Failed to sync note ${note.uuid}', error);
          // Continue with other notes
        }
      }
      
      _logger.info('Synced $synced notes');
      return Ok(synced);
    } catch (error, stackTrace) {
      _logger.error('Sync failed', error, stackTrace);
      return Err(Exception('Sync failed'));
    }
  }
}
```

### Example: CryptoService

**Before:**
```dart
class CryptoService {
  Future<String> encryptString(String plaintext, List<int> key) async {
    final secretBox = await _algo.encrypt(...);
    return base64.encode(...);
  }
}
```

**After:**
```dart
class CryptoService {
  static const _logger = Logger('CryptoService');
  
  Future<Result<String, Exception>> encryptString(
    String plaintext,
    List<int> key,
  ) async {
    try {
      // Note: Logger will sanitize the key automatically
      _logger.debug('Encrypting string');
      final secretBox = await _algo.encrypt(...);
      final result = base64.encode(...);
      _logger.debug('Encryption successful');
      return Ok(result);
    } catch (error, stackTrace) {
      _logger.error('Encryption failed', error, stackTrace);
      return Err(Exception('Encryption failed'));
    }
  }
}
```

## UI Layer Integration

### Example: NotesListScreen

**Before:**
```dart
class NotesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    
    return notesAsync.when(
      data: (notes) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'), // ❌ Not user-friendly
    );
  }
}
```

**After:**
```dart
class NotesListScreen extends ConsumerWidget {
  static const _logger = Logger('NotesListScreen');
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    
    return ErrorBoundary(
      errorTitle: '加载笔记失败',
      onRetry: () => ref.refresh(notesListProvider),
      child: notesAsync.when(
        data: (notes) => _buildNotesList(notes),
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  onPressed: () => ref.refresh(notesListProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### Example: NoteEditScreen

**Before:**
```dart
class NoteEditScreen extends ConsumerWidget {
  Future<void> _saveNote() async {
    try {
      await notesService.saveNote(note);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')), // ❌ Not user-friendly
      );
    }
  }
}
```

**After:**
```dart
class NoteEditScreen extends ConsumerWidget {
  static const _logger = Logger('NoteEditScreen');
  
  Future<void> _saveNote(BuildContext context) async {
    try {
      ErrorDialog.showLoading(context, message: '正在保存...');
      
      final result = await notesService.saveNote(note);
      
      ErrorDialog.hideLoading(context);
      
      result.when(
        ok: (_) {
          ErrorDialog.showSuccess(context, '保存成功');
          Navigator.pop(context);
        },
        error: (error) {
          _logger.error('Failed to save note', error);
          ErrorDialog.showError(context, error);
        },
      );
    } catch (error, stackTrace) {
      ErrorDialog.hideLoading(context);
      _logger.error('Unexpected error saving note', error, stackTrace);
      ErrorDialog.showError(context, error, stackTrace: stackTrace);
    }
  }
}
```

### Example: VaultUnlockScreen

**Before:**
```dart
class VaultUnlockScreen extends ConsumerWidget {
  Future<void> _unlock(String password) async {
    try {
      final dataKey = await keyManager.unlockDataKey(password);
      ref.read(dataKeyProvider.notifier).state = dataKey;
      Navigator.pushReplacement(context, ...);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('$e'), // ❌ Not user-friendly
        ),
      );
    }
  }
}
```

**After:**
```dart
class VaultUnlockScreen extends ConsumerWidget {
  static const _logger = Logger('VaultUnlockScreen');
  
  Future<void> _unlock(BuildContext context, String password) async {
    try {
      ErrorDialog.showLoading(context, message: '正在解锁...');
      
      final result = await keyManager.unlockDataKey(password);
      
      ErrorDialog.hideLoading(context);
      
      result.when(
        ok: (dataKey) {
          ref.read(dataKeyProvider.notifier).state = dataKey;
          ref.read(vaultUnlockedProvider.notifier).state = true;
          ErrorDialog.showSuccess(context, '解锁成功');
          Navigator.pushReplacement(context, ...);
        },
        error: (error) {
          _logger.warning('Failed to unlock vault', error);
          ErrorDialog.show(
            context,
            error,
            title: '解锁失败',
            onRetry: () => _unlock(context, password),
          );
        },
      );
    } catch (error, stackTrace) {
      ErrorDialog.hideLoading(context);
      _logger.error('Unexpected error unlocking vault', error, stackTrace);
      ErrorDialog.showError(context, error, stackTrace: stackTrace);
    }
  }
}
```

## Provider Integration

### Example: Error-Aware Provider

```dart
final notesServiceProvider = Provider<NotesService>((ref) {
  return NotesService(
    dao: ref.watch(notesDaoProvider),
    logger: const Logger('NotesService'),
  );
});

final createNoteProvider = FutureProvider.family<void, CreateNoteParams>(
  (ref, params) async {
    final service = ref.watch(notesServiceProvider);
    final result = await service.createNote(params.title, params.content);
    
    return result.when(
      ok: (_) => null,
      error: (error) => throw error,
    );
  },
);
```

## Testing Integration

### Example: Test Error Handling

```dart
group('NotesService Error Handling', () {
  test('createNote returns error on database failure', () async {
    final mockDao = MockNotesDao();
    when(mockDao.createNote(any)).thenThrow(Exception('DB error'));
    
    final service = NotesService(dao: mockDao);
    final result = await service.createNote('Title', 'Content');
    
    expect(result.isErr, true);
    expect(result.error.toString(), contains('Failed to create note'));
  });
  
  test('createNote logs error on failure', () async {
    // Verify logger is called with error
  });
});

group('ErrorHandler', () {
  test('converts FirebaseAuthException to Chinese', () {
    final error = FirebaseAuthException(code: 'user-not-found');
    final message = ErrorHandler.getUserFriendlyMessage(error);
    
    expect(message, '用户不存在，请检查邮箱地址');
  });
  
  test('converts network errors to Chinese', () {
    final error = Exception('SocketException: Network unreachable');
    final message = ErrorHandler.getUserFriendlyMessage(error);
    
    expect(message, '网络连接失败，请检查您的网络设置');
  });
});
```

## Migration Checklist

### Phase 1: Core Services (Priority: High)
- [ ] Update `CryptoService` to return `Result` types
- [ ] Update `KeyManager` to return `Result` types
- [ ] Update `NotesDao` error handling
- [ ] Update `VaultDao` error handling
- [ ] Update `SyncService` error handling

### Phase 2: Application Services (Priority: High)
- [ ] Update `NotesService` to use new error handling
- [ ] Update `VaultService` to use new error handling
- [ ] Update `AuthService` to use new error handling
- [ ] Update `ExportService` to use new error handling
- [ ] Update `ImportService` to use new error handling

### Phase 3: UI Screens (Priority: Medium)
- [ ] Add ErrorBoundary to `NotesListScreen`
- [ ] Add ErrorBoundary to `NoteEditScreen`
- [ ] Add ErrorBoundary to `VaultListScreen`
- [ ] Add ErrorBoundary to `VaultUnlockScreen`
- [ ] Update all screens to use `ErrorDialog` utilities

### Phase 4: Providers (Priority: Medium)
- [ ] Update all providers to handle errors properly
- [ ] Add error logging to all providers
- [ ] Test error propagation through provider chain

### Phase 5: Testing (Priority: Low)
- [ ] Add unit tests for error handling
- [ ] Add widget tests for error UI
- [ ] Add integration tests for error flows
- [ ] Test Crashlytics integration

## Common Patterns

### Pattern 1: Service Method with Result

```dart
Future<Result<T, Exception>> methodName() async {
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

### Pattern 2: UI with Error Handling

```dart
Future<void> _handleAction(BuildContext context) async {
  try {
    ErrorDialog.showLoading(context);
    final result = await service.doSomething();
    ErrorDialog.hideLoading(context);
    
    result.when(
      ok: (value) => ErrorDialog.showSuccess(context, '成功'),
      error: (error) => ErrorDialog.showError(context, error),
    );
  } catch (error, stackTrace) {
    ErrorDialog.hideLoading(context);
    ErrorDialog.showError(context, error, stackTrace: stackTrace);
  }
}
```

### Pattern 3: Provider with Error Handling

```dart
final myProvider = FutureProvider<T>((ref) async {
  final service = ref.watch(serviceProvider);
  final result = await service.getData();
  
  return result.when(
    ok: (data) => data,
    error: (error) => throw error,
  );
});
```

## Notes

- Always use the Logger for any logging (it sanitizes automatically)
- Always convert exceptions to user-friendly messages before showing to users
- Always log errors with context (what operation failed, relevant IDs)
- Never log passwords, keys, or user content directly
- Use ErrorBoundary for critical UI components
- Use Result types for domain logic
- Use ErrorDialog utilities for consistent UI
