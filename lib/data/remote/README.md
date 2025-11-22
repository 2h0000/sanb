# Firebase Remote Data Layer

This directory contains the Firebase client implementation for cloud synchronization.

## FirebaseClient

The `FirebaseClient` class encapsulates all Firebase operations including:

- **Firestore Operations**: CRUD operations for notes and vault items
- **Storage Operations**: File upload/download for attachments
- **Key Management**: Upload/download encryption key parameters

### Collection Structure

```
users/
  {uid}/
    notes/
      {noteId}/
        - uuid: string
        - title: string
        - contentMd: string
        - tagsJson: string
        - isEncrypted: boolean
        - createdAt: timestamp
        - updatedAt: timestamp
        - deletedAt: timestamp | null
    
    vault/
      {itemId}/
        - uuid: string
        - titleEnc: string (encrypted)
        - usernameEnc: string (encrypted)
        - passwordEnc: string (encrypted)
        - urlEnc: string (encrypted)
        - noteEnc: string (encrypted)
        - updatedAt: timestamp
        - deletedAt: timestamp | null
    
    keys/
      master/
        - kdfSalt: string (base64)
        - kdfIterations: number
        - wrappedDataKey: string (base64)
        - wrapNonce: string (base64)
```

### Storage Structure

```
users/
  {uid}/
    files/
      {filename}
```

## Security Rules

### Firestore Security Rules

The Firestore security rules (`firestore.rules`) ensure that:

1. **Authentication Required**: All operations require authentication
2. **User Isolation**: Users can only access their own data (uid-based access control)
3. **Collection-Level Security**: Each subcollection (notes, vault, keys) has explicit rules
4. **Key Protection**: Key parameters cannot be deleted (only created/updated)

**Requirements Validated**: 8.1, 8.2, 8.3, 8.5

### Storage Security Rules

The Storage security rules (`storage.rules`) ensure that:

1. **Authentication Required**: All operations require authentication
2. **User Isolation**: Users can only access files in their own directory
3. **File Size Limits**: Maximum 10MB per file
4. **Path-Based Access Control**: uid in path must match authenticated user's uid

**Requirements Validated**: 8.4, 8.5

## Deployment

### Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Deploy Storage Rules

```bash
firebase deploy --only storage:rules
```

### Deploy Both

```bash
firebase deploy --only firestore:rules,storage:rules
```

## Usage Example

```dart
// Initialize Firebase client
final firebaseClient = FirebaseClient();

// Check authentication
if (firebaseClient.isAuthenticated) {
  final uid = firebaseClient.currentUserId!;
  
  // Push a note
  await firebaseClient.pushNote(uid, {
    'uuid': 'note-123',
    'title': 'My Note',
    'contentMd': '# Hello World',
    'tagsJson': '["tag1", "tag2"]',
    'isEncrypted': false,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
    'deletedAt': null,
  });
  
  // Watch notes for real-time updates
  firebaseClient.watchNotes(uid).listen((snapshot) {
    for (var change in snapshot.docChanges) {
      print('Note changed: ${change.doc.id}');
    }
  });
  
  // Upload key parameters
  await firebaseClient.uploadKeyParams(uid, {
    'kdfSalt': 'base64-encoded-salt',
    'kdfIterations': 210000,
    'wrappedDataKey': 'base64-encoded-wrapped-key',
    'wrapNonce': 'base64-encoded-nonce',
  });
  
  // Download key parameters
  final keyParams = await firebaseClient.downloadKeyParams(uid);
  if (keyParams != null) {
    print('Key parameters retrieved');
  }
}
```

## Requirements Coverage

This implementation satisfies the following requirements:

- **6.1**: Subscribe to Firestore collections for notes and vault
- **8.1**: Verify request.auth.uid equals document owner uid for reads
- **8.2**: Verify request.auth.uid equals document owner uid for writes
- **8.3**: Reject all operations for unauthenticated users
- **8.4**: Verify Storage path uid matches request.auth.uid
- **8.5**: Return permission denied error when validation fails
- **9.1**: Upload key parameters to Firestore
- **9.2**: Download key parameters from Firestore

## Testing

Unit tests for FirebaseClient should mock Firebase services to test:

- Collection reference generation
- Data serialization/deserialization
- Error handling
- Authentication state checks

Integration tests should verify:

- Real-time sync functionality
- Security rules enforcement
- Conflict resolution
