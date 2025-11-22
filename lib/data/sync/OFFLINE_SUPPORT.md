# Offline Support Implementation

## Overview

The offline support system ensures that the encrypted notebook app works seamlessly whether the user is online or offline. All operations are local-first, and synchronization happens automatically when network connectivity is available.

## Architecture

### Components

1. **ConnectivityService** (`lib/core/network/connectivity_service.dart`)
   - Monitors network connectivity status using `connectivity_plus` package
   - Provides real-time stream of connectivity changes
   - Detects when network becomes available or unavailable

2. **OfflineSyncManager** (`lib/data/sync/offline_sync_manager.dart`)
   - Coordinates between connectivity status and sync operations
   - Automatically resumes sync when network is restored
   - Queues sync operations when offline
   - Manages graceful degradation during network interruptions

3. **SyncService** (`lib/data/sync/sync_service.dart`)
   - Handles bidirectional synchronization with Firestore
   - Implements LWW (Last Write Wins) conflict resolution
   - Gracefully handles network errors without blocking local operations

## Key Features

### 1. Local-First Operations (Requirement 14.1, 14.2)

All CRUD operations work directly with the local SQLite database:
- Creating notes/vault items
- Updating content
- Deleting items (soft delete)
- Searching and querying

**No network dependency**: Users can perform all operations offline, and changes are persisted locally.

### 2. Network State Monitoring (Requirement 14.2)

The `ConnectivityService` continuously monitors network status:
```dart
final connectivityService = ref.watch(connectivityServiceProvider);
final isOnline = connectivityService.isConnected;
```

Connectivity changes are broadcast via a stream:
```dart
connectivityService.connectivityStream.listen((isConnected) {
  if (isConnected) {
    // Network restored
  } else {
    // Network lost
  }
});
```

### 3. Automatic Sync on Network Recovery (Requirement 14.3)

When network connectivity is restored:
1. `ConnectivityService` detects the change
2. `OfflineSyncManager` receives the notification
3. Pending sync operations are automatically executed
4. Local changes are pushed to Firestore
5. Remote changes are pulled and merged

```dart
// Automatic sync happens transparently
await offlineSyncManager.startSync(userId);
// If offline, sync is queued
// When online, sync starts immediately
```

### 4. Offline Conflict Resolution (Requirement 14.4)

The system uses **Last Write Wins (LWW)** strategy based on `updatedAt` timestamps:

- **Remote newer**: Local data is updated with remote version
- **Local newer**: Local data is pushed to remote
- **Same timestamp, different content**: Conflict copy is created with suffix `-conflict-{timestamp}`

This is implemented in `SyncService._resolveNoteConflict()` and `SyncService._resolveVaultConflict()`.

### 5. Local-First Queries (Requirement 14.5)

All queries read from the local database, never waiting for network:
```dart
// Always reads from local SQLite database
final notes = await notesDao.getAllNotes();
final searchResults = await notesDao.search(keyword);
```

The UI uses `StreamProvider` to watch local database changes:
```dart
final notesListProvider = StreamProvider<List<Note>>((ref) {
  final dao = ref.watch(notesDaoProvider);
  return dao.watchAllNotes(); // Watches local DB
});
```

## Usage

### Initialization

```dart
// Initialize offline sync manager
final offlineSyncManager = ref.read(offlineSyncManagerProvider);
await offlineSyncManager.initialize();

// Start sync for authenticated user
final userId = FirebaseAuth.instance.currentUser?.uid;
if (userId != null) {
  await offlineSyncManager.startSync(userId);
}
```

### Checking Connectivity Status

```dart
// Get current status
final isOnline = ref.read(isOnlineProvider);

// Watch for changes
ref.listen(connectivityStatusProvider, (previous, next) {
  next.when(
    data: (isConnected) {
      if (isConnected) {
        // Show "Online" indicator
      } else {
        // Show "Offline" indicator
      }
    },
    loading: () {},
    error: (error, stack) {},
  );
});
```

### Manual Sync Trigger

```dart
// Manually push local changes (only if online)
final offlineSyncManager = ref.read(offlineSyncManagerProvider);
await offlineSyncManager.pushLocalChanges(userId);
```

## Error Handling

### Network Errors

Network errors during sync operations are handled gracefully:
- Individual push failures don't stop the entire sync process
- Errors are logged but don't throw exceptions
- Failed operations are retried when network is restored

### Offline Operations

When offline:
- All local operations continue to work normally
- Sync operations are queued and marked as pending
- UI can show offline indicator but functionality remains available

## Testing Offline Scenarios

### Simulating Offline Mode

1. **Airplane Mode**: Enable airplane mode on device
2. **Network Disconnect**: Disconnect WiFi/mobile data
3. **Firestore Emulator**: Stop the emulator to simulate backend unavailability

### Test Cases

1. **Create offline, sync online**:
   - Go offline
   - Create notes/vault items
   - Go online
   - Verify items sync to Firestore

2. **Edit offline, conflict resolution**:
   - Edit same note on two devices while offline
   - Go online on both devices
   - Verify LWW resolution or conflict copy creation

3. **Delete offline, sync online**:
   - Go offline
   - Delete items (soft delete)
   - Go online
   - Verify deletedAt syncs to Firestore

4. **Network interruption during sync**:
   - Start sync operation
   - Disconnect network mid-sync
   - Verify graceful handling
   - Reconnect and verify resume

## Providers

### Available Providers

```dart
// Connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>

// Connectivity status stream
final connectivityStatusProvider = StreamProvider<bool>

// Current online status (synchronous)
final isOnlineProvider = Provider<bool>

// Sync service
final syncServiceProvider = Provider<SyncService>

// Offline sync manager
final offlineSyncManagerProvider = Provider<OfflineSyncManager>
```

## Dependencies

- `connectivity_plus: ^5.0.2` - Network connectivity monitoring
- `drift` - Local SQLite database
- `cloud_firestore` - Cloud synchronization
- `riverpod` - State management

## Future Enhancements

1. **Retry Logic**: Exponential backoff for failed sync operations
2. **Sync Queue**: Persistent queue for offline operations
3. **Partial Sync**: Only sync changed items instead of all items
4. **Bandwidth Optimization**: Compress data before syncing
5. **Conflict UI**: User interface for manually resolving conflicts
6. **Sync Status**: Detailed sync progress indicators
