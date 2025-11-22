import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_notebook/core/utils/logger.dart';
import 'package:encrypted_notebook/data/local/db/notes_dao.dart';
import 'package:encrypted_notebook/data/local/db/vault_dao.dart';
import 'package:encrypted_notebook/data/remote/firebase_client.dart';
import 'package:encrypted_notebook/domain/entities/note.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart';

/// SyncService handles bidirectional synchronization between local database and Firestore
/// Implements:
/// - Uplink sync: Push local changes to Firestore
/// - Downlink sync: Listen to Firestore changes and update local database
/// - LWW (Last Write Wins) conflict resolution based on updatedAt timestamps
/// - Conflict copy creation when timestamps are equal but content differs
class SyncService {
  final FirebaseClient _firebaseClient;
  final NotesDao _notesDao;
  final VaultDao _vaultDao;
  final Logger _logger = const Logger('SyncService');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _vaultSubscription;

  bool _isRunning = false;

  SyncService({
    required FirebaseClient firebaseClient,
    required NotesDao notesDao,
    required VaultDao vaultDao,
  })  : _firebaseClient = firebaseClient,
        _notesDao = notesDao,
        _vaultDao = vaultDao;

  /// Check if sync is currently running
  bool get isRunning => _isRunning;

  /// Start synchronization for the given user
  /// Subscribes to Firestore collections and begins listening for changes
  Future<void> startSync(String uid) async {
    if (_isRunning) {
      _logger.warning('Sync already running for user $uid');
      return;
    }

    _logger.info('Starting sync for user $uid');
    _isRunning = true;

    try {
      // Push any pending local changes first
      await pushLocalChanges(uid);

      // Subscribe to notes collection
      _notesSubscription = _firebaseClient.watchNotes(uid).listen(
        (snapshot) => _handleNotesSnapshot(snapshot),
        onError: (error) {
          _logger.error('Error watching notes', error);
        },
      );

      // Subscribe to vault collection
      _vaultSubscription = _firebaseClient.watchVault(uid).listen(
        (snapshot) => _handleVaultSnapshot(snapshot),
        onError: (error) {
          _logger.error('Error watching vault', error);
        },
      );

      _logger.info('Sync started successfully for user $uid');
    } catch (e, stackTrace) {
      _logger.error('Failed to start sync', e, stackTrace);
      _isRunning = false;
      rethrow;
    }
  }

  /// Stop synchronization
  /// Cancels all active subscriptions
  Future<void> stopSync() async {
    _logger.info('Stopping sync');
    
    await _notesSubscription?.cancel();
    await _vaultSubscription?.cancel();
    
    _notesSubscription = null;
    _vaultSubscription = null;
    _isRunning = false;
    
    _logger.info('Sync stopped');
  }

  /// Push local changes to Firestore
  /// Uploads all notes and vault items that have been modified
  /// Gracefully handles network errors - individual push failures don't stop the process
  Future<void> pushLocalChanges(String uid) async {
    _logger.info('Pushing local changes to Firestore');

    try {
      // Push all notes
      final notes = await _notesDao.getAllNotes();
      for (final note in notes) {
        await _pushNote(uid, note);
      }

      // Push all vault items
      final vaultItems = await _vaultDao.getAllVaultItems();
      for (final item in vaultItems) {
        await _pushVaultItem(uid, item);
      }

      _logger.info('Local changes pushed successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to push local changes', e, stackTrace);
      // Don't rethrow - allow operation to continue even if some pushes failed
    }
  }

  /// Push a single note to Firestore
  /// Gracefully handles network errors without throwing
  Future<void> _pushNote(String uid, Note note) async {
    try {
      final noteData = note.toJson();
      await _firebaseClient.pushNote(uid, noteData);
      _logger.debug('Pushed note ${note.uuid}');
    } catch (e) {
      _logger.error('Failed to push note ${note.uuid}', e);
      // Don't rethrow - allow offline operation to continue
    }
  }

  /// Push a single vault item to Firestore
  /// Gracefully handles network errors without throwing
  Future<void> _pushVaultItem(String uid, VaultItemEncrypted item) async {
    try {
      final itemData = item.toJson();
      await _firebaseClient.pushVaultItem(uid, itemData);
      _logger.debug('Pushed vault item ${item.uuid}');
    } catch (e) {
      _logger.error('Failed to push vault item ${item.uuid}', e);
      // Don't rethrow - allow offline operation to continue
    }
  }

  /// Handle notes collection snapshot from Firestore
  Future<void> _handleNotesSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    _logger.debug('Received notes snapshot with ${snapshot.docChanges.length} changes');

    for (final change in snapshot.docChanges) {
      try {
        await _handleRemoteNoteChange(change.doc);
      } catch (e, stackTrace) {
        _logger.error('Failed to handle note change for ${change.doc.id}', e, stackTrace);
      }
    }
  }

  /// Handle vault collection snapshot from Firestore
  Future<void> _handleVaultSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    _logger.debug('Received vault snapshot with ${snapshot.docChanges.length} changes');

    for (final change in snapshot.docChanges) {
      try {
        await _handleRemoteVaultChange(change.doc);
      } catch (e, stackTrace) {
        _logger.error('Failed to handle vault change for ${change.doc.id}', e, stackTrace);
      }
    }
  }

  /// Handle a remote note change from Firestore
  /// Implements LWW conflict resolution
  Future<void> _handleRemoteNoteChange(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!doc.exists) {
      _logger.debug('Note ${doc.id} does not exist, skipping');
      return;
    }

    final data = doc.data()!;
    final remoteNote = Note.fromJson(data);
    
    _logger.debug('Processing remote note ${remoteNote.uuid}');

    // Check if note exists locally
    final localNote = await _notesDao.findByUuid(remoteNote.uuid);

    if (localNote == null) {
      // Note doesn't exist locally, insert it
      _logger.debug('Note ${remoteNote.uuid} not found locally, inserting');
      await _notesDao.createNote(
        uuid: remoteNote.uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );
      return;
    }

    // Note exists locally, resolve conflict
    await _resolveNoteConflict(localNote, remoteNote);
  }

  /// Handle a remote vault item change from Firestore
  /// Implements LWW conflict resolution
  Future<void> _handleRemoteVaultChange(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!doc.exists) {
      _logger.debug('Vault item ${doc.id} does not exist, skipping');
      return;
    }

    final data = doc.data()!;
    final remoteItem = VaultItemEncrypted.fromJson(data);
    
    _logger.debug('Processing remote vault item ${remoteItem.uuid}');

    // Check if vault item exists locally
    final localItem = await _vaultDao.findByUuid(remoteItem.uuid);

    if (localItem == null) {
      // Item doesn't exist locally, insert it
      _logger.debug('Vault item ${remoteItem.uuid} not found locally, inserting');
      await _vaultDao.createVaultItem(
        uuid: remoteItem.uuid,
        titleEnc: remoteItem.titleEnc,
        usernameEnc: remoteItem.usernameEnc,
        passwordEnc: remoteItem.passwordEnc,
        urlEnc: remoteItem.urlEnc,
        noteEnc: remoteItem.noteEnc,
      );
      return;
    }

    // Item exists locally, resolve conflict
    await _resolveVaultConflict(localItem, remoteItem);
  }

  /// Resolve conflict between local and remote note using LWW strategy
  /// If timestamps are equal but content differs, create a conflict copy
  Future<void> _resolveNoteConflict(Note localNote, Note remoteNote) async {
    final localTime = localNote.updatedAt;
    final remoteTime = remoteNote.updatedAt;

    _logger.debug(
      'Resolving note conflict for ${localNote.uuid}: '
      'local=$localTime, remote=$remoteTime',
    );

    if (remoteTime.isAfter(localTime)) {
      // Remote is newer, update local with remote data
      _logger.debug('Remote note is newer, updating local');
      await _notesDao.updateNote(
        localNote.uuid,
        title: remoteNote.title,
        contentMd: remoteNote.contentMd,
        tags: remoteNote.tags,
      );
    } else if (localTime.isAfter(remoteTime)) {
      // Local is newer, push local to remote
      _logger.debug('Local note is newer, pushing to remote');
      final uid = _firebaseClient.currentUserId;
      if (uid != null) {
        await _pushNote(uid, localNote);
      }
    } else {
      // Timestamps are equal, check if content differs
      if (_noteContentDiffers(localNote, remoteNote)) {
        _logger.warning(
          'Note ${localNote.uuid} has same timestamp but different content, '
          'creating conflict copy',
        );
        await _createNoteConflictCopy(remoteNote);
      } else {
        _logger.debug('Note ${localNote.uuid} is identical, no action needed');
      }
    }
  }

  /// Resolve conflict between local and remote vault item using LWW strategy
  /// If timestamps are equal but content differs, create a conflict copy
  Future<void> _resolveVaultConflict(
    VaultItemEncrypted localItem,
    VaultItemEncrypted remoteItem,
  ) async {
    final localTime = localItem.updatedAt;
    final remoteTime = remoteItem.updatedAt;

    _logger.debug(
      'Resolving vault conflict for ${localItem.uuid}: '
      'local=$localTime, remote=$remoteTime',
    );

    if (remoteTime.isAfter(localTime)) {
      // Remote is newer, update local with remote data
      _logger.debug('Remote vault item is newer, updating local');
      await _vaultDao.updateVaultItem(
        localItem.uuid,
        titleEnc: remoteItem.titleEnc,
        usernameEnc: remoteItem.usernameEnc,
        passwordEnc: remoteItem.passwordEnc,
        urlEnc: remoteItem.urlEnc,
        noteEnc: remoteItem.noteEnc,
      );
    } else if (localTime.isAfter(remoteTime)) {
      // Local is newer, push local to remote
      _logger.debug('Local vault item is newer, pushing to remote');
      final uid = _firebaseClient.currentUserId;
      if (uid != null) {
        await _pushVaultItem(uid, localItem);
      }
    } else {
      // Timestamps are equal, check if content differs
      if (_vaultContentDiffers(localItem, remoteItem)) {
        _logger.warning(
          'Vault item ${localItem.uuid} has same timestamp but different content, '
          'creating conflict copy',
        );
        await _createVaultConflictCopy(remoteItem);
      } else {
        _logger.debug('Vault item ${localItem.uuid} is identical, no action needed');
      }
    }
  }

  /// Check if note content differs between local and remote
  bool _noteContentDiffers(Note local, Note remote) {
    return local.title != remote.title ||
        local.contentMd != remote.contentMd ||
        !_listEquals(local.tags, remote.tags);
  }

  /// Check if vault item content differs between local and remote
  bool _vaultContentDiffers(VaultItemEncrypted local, VaultItemEncrypted remote) {
    return local.titleEnc != remote.titleEnc ||
        local.usernameEnc != remote.usernameEnc ||
        local.passwordEnc != remote.passwordEnc ||
        local.urlEnc != remote.urlEnc ||
        local.noteEnc != remote.noteEnc;
  }

  /// Helper to compare two lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Create a conflict copy of a note with a modified UUID
  Future<void> _createNoteConflictCopy(Note remoteNote) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final conflictUuid = '${remoteNote.uuid}-conflict-$timestamp';
    
    _logger.info('Creating conflict copy with UUID: $conflictUuid');
    
    await _notesDao.createNote(
      uuid: conflictUuid,
      title: '${remoteNote.title} (Conflict)',
      contentMd: remoteNote.contentMd,
      tags: remoteNote.tags,
    );
  }

  /// Create a conflict copy of a vault item with a modified UUID
  Future<void> _createVaultConflictCopy(VaultItemEncrypted remoteItem) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final conflictUuid = '${remoteItem.uuid}-conflict-$timestamp';
    
    _logger.info('Creating conflict copy with UUID: $conflictUuid');
    
    await _vaultDao.createVaultItem(
      uuid: conflictUuid,
      titleEnc: remoteItem.titleEnc,
      usernameEnc: remoteItem.usernameEnc,
      passwordEnc: remoteItem.passwordEnc,
      urlEnc: remoteItem.urlEnc,
      noteEnc: remoteItem.noteEnc,
    );
  }
}
