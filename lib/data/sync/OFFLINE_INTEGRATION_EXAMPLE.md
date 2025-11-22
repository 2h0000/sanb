# Offline Support Integration Example

## Complete Integration Guide

This guide shows how to integrate offline support into your Flutter app.

## Step 1: Update Main App Initialization

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:encrypted_notebook/data/sync/offline_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize offline sync manager on app start
    ref.read(offlineSyncManagerProvider);
    
    return MaterialApp(
      title: 'Encrypted Notebook',
      home: const HomeScreen(),
    );
  }
}
```

## Step 2: Start Sync on User Login

```dart
// lib/features/auth/application/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/sync/offline_providers.dart';

class AuthService {
  final Ref _ref;
  final FirebaseAuth _auth;
  
  AuthService(this._ref, this._auth);
  
  Future<void> signIn(String email, String password) async {
    // Sign in with Firebase
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Start offline-aware sync
    final userId = credential.user?.uid;
    if (userId != null) {
      final offlineSyncManager = _ref.read(offlineSyncManagerProvider);
      await offlineSyncManager.startSync(userId);
    }
  }
  
  Future<void> signOut() async {
    // Stop sync before signing out
    final offlineSyncManager = _ref.read(offlineSyncManagerProvider);
    await offlineSyncManager.stopSync();
    
    // Sign out from Firebase
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref, FirebaseAuth.instance);
});
```

## Step 3: Display Connectivity Status in UI

```dart
// lib/features/common/widgets/connectivity_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/sync/offline_providers.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    
    return connectivityStatus.when(
      data: (isConnected) {
        if (!isConnected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange,
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Offline - Changes will sync when online',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

## Step 4: Use in Main Screen

```dart
// lib/features/notes/presentation/notes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/features/common/widgets/connectivity_indicator.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Column(
        children: [
          // Show connectivity status
          const ConnectivityIndicator(),
          
          // Notes list
          Expanded(
            child: NotesListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create note - works offline!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Step 5: Handle Offline Operations in Notes

```dart
// lib/features/notes/application/notes_service.dart
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/sync/offline_providers.dart';
import 'package:encrypted_notebook/domain/entities/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NotesService {
  final NotesDao _notesDao;
  final Ref _ref;
  
  NotesService(this._notesDao, this._ref);
  
  /// Create a new note
  /// Works offline - will sync when online
  Future<void> createNote({
    required String title,
    required String contentMd,
    List<String> tags = const [],
  }) async {
    // Create note locally (always works)
    final uuid = const Uuid().v4();
    await _notesDao.createNote(
      uuid: uuid,
      title: title,
      contentMd: contentMd,
      tags: tags,
    );
    
    // Try to sync if online
    final offlineSyncManager = _ref.read(offlineSyncManagerProvider);
    if (offlineSyncManager.isOnline) {
      final userId = /* get current user id */;
      if (userId != null) {
        await offlineSyncManager.pushLocalChanges(userId);
      }
    }
    // If offline, changes will sync automatically when network returns
  }
  
  /// Update a note
  /// Works offline - will sync when online
  Future<void> updateNote({
    required String uuid,
    String? title,
    String? contentMd,
    List<String>? tags,
  }) async {
    // Update locally (always works)
    await _notesDao.updateNote(
      uuid,
      title: title,
      contentMd: contentMd,
      tags: tags,
    );
    
    // Try to sync if online
    final offlineSyncManager = _ref.read(offlineSyncManagerProvider);
    if (offlineSyncManager.isOnline) {
      final userId = /* get current user id */;
      if (userId != null) {
        await offlineSyncManager.pushLocalChanges(userId);
      }
    }
  }
  
  /// Delete a note (soft delete)
  /// Works offline - will sync when online
  Future<void> deleteNote(String uuid) async {
    // Delete locally (always works)
    await _notesDao.softDelete(uuid);
    
    // Try to sync if online
    final offlineSyncManager = _ref.read(offlineSyncManagerProvider);
    if (offlineSyncManager.isOnline) {
      final userId = /* get current user id */;
      if (userId != null) {
        await offlineSyncManager.pushLocalChanges(userId);
      }
    }
  }
  
  /// Search notes
  /// Always reads from local database (works offline)
  Future<List<Note>> searchNotes(String keyword) async {
    return await _notesDao.search(keyword);
  }
  
  /// Get all notes
  /// Always reads from local database (works offline)
  Future<List<Note>> getAllNotes() async {
    return await _notesDao.getAllNotes();
  }
}

final notesServiceProvider = Provider<NotesService>((ref) {
  final database = ref.watch(databaseProvider);
  return NotesService(database.notesDao, ref);
});
```

## Step 6: Show Sync Status (Optional)

```dart
// lib/features/common/widgets/sync_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/sync/offline_providers.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final offlineSyncManager = ref.watch(offlineSyncManagerProvider);
    final isSyncing = offlineSyncManager.isSyncRunning;
    
    if (!isOnline) {
      return const Chip(
        avatar: Icon(Icons.cloud_off, size: 16),
        label: Text('Offline'),
        backgroundColor: Colors.orange,
      );
    }
    
    if (isSyncing) {
      return const Chip(
        avatar: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('Syncing...'),
        backgroundColor: Colors.blue,
      );
    }
    
    return const Chip(
      avatar: Icon(Icons.cloud_done, size: 16),
      label: Text('Synced'),
      backgroundColor: Colors.green,
    );
  }
}
```

## Step 7: Testing Offline Functionality

```dart
// test/integration/offline_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypted_notebook/data/sync/offline_sync_manager.dart';
import 'package:encrypted_notebook/core/network/connectivity_service.dart';

void main() {
  group('Offline Support Integration Tests', () {
    test('Create note offline, sync when online', () async {
      // TODO: Implement integration test
      // 1. Simulate offline mode
      // 2. Create a note
      // 3. Verify note is in local database
      // 4. Simulate online mode
      // 5. Wait for sync
      // 6. Verify note is in Firestore
    });
    
    test('Edit note offline, resolve conflict online', () async {
      // TODO: Implement integration test
      // 1. Create note while online
      // 2. Go offline
      // 3. Edit note on device A
      // 4. Edit same note on device B (simulate)
      // 5. Go online
      // 6. Verify LWW resolution or conflict copy
    });
  });
}
```

## Key Points

1. **All operations work offline**: Create, read, update, delete operations always work with local database
2. **Automatic sync**: When network is restored, changes sync automatically
3. **No code changes needed**: Existing CRUD operations continue to work
4. **Graceful degradation**: Network errors don't break the app
5. **User feedback**: Show connectivity status to inform users
6. **Conflict resolution**: LWW strategy handles conflicts automatically

## Troubleshooting

### Sync not starting after network restoration

Check that:
1. `OfflineSyncManager` is initialized in main app
2. `startSync()` was called with valid user ID
3. Firebase is properly configured
4. User is authenticated

### Local changes not syncing

Check that:
1. Network connectivity is actually available
2. Firestore security rules allow write access
3. No errors in logs (check `Logger` output)
4. User is still authenticated

### Conflict copies being created unnecessarily

This happens when:
1. System clocks are not synchronized between devices
2. Timestamps are being modified incorrectly
3. Consider using server timestamps in Firestore
