import 'package:uuid/uuid.dart';
import '../../../core/utils/result.dart';
import '../../../data/local/db/notes_dao.dart';
import '../../../domain/entities/note.dart';

/// Service for managing notes business logic
class NotesService {
  final NotesDao _notesDao;
  final _uuid = const Uuid();

  NotesService({required NotesDao notesDao}) : _notesDao = notesDao;

  /// Create a new note
  Future<Result<Note, String>> createNote({
    required String title,
    required String contentMd,
    List<String> tags = const [],
  }) async {
    try {
      final uuid = _uuid.v4();
      final now = DateTime.now();

      await _notesDao.createNote(
        uuid: uuid,
        title: title,
        contentMd: contentMd,
        tags: tags,
      );

      // Fetch the created note
      final note = await _notesDao.findByUuid(uuid);
      if (note == null) {
        return Result.error('Failed to create note');
      }

      return Result.ok(note);
    } catch (e) {
      return Result.error('Error creating note: $e');
    }
  }

  /// Update an existing note
  Future<Result<Note, String>> updateNote({
    required String uuid,
    required String title,
    required String contentMd,
    List<String> tags = const [],
  }) async {
    try {
      final rowsAffected = await _notesDao.updateNote(
        uuid,
        title: title,
        contentMd: contentMd,
        tags: tags,
      );

      if (rowsAffected == 0) {
        return Result.error('Note not found');
      }

      // Fetch the updated note
      final note = await _notesDao.findByUuid(uuid);
      if (note == null) {
        return Result.error('Failed to fetch updated note');
      }

      return Result.ok(note);
    } catch (e) {
      return Result.error('Error updating note: $e');
    }
  }

  /// Delete a note (soft delete)
  Future<Result<void, String>> deleteNote(String uuid) async {
    try {
      final rowsAffected = await _notesDao.softDelete(uuid);

      if (rowsAffected == 0) {
        return Result.error('Note not found');
      }

      return Result.ok(null);
    } catch (e) {
      return Result.error('Error deleting note: $e');
    }
  }

  /// Get a note by UUID
  Future<Result<Note?, String>> getNoteByUuid(String uuid) async {
    try {
      final note = await _notesDao.findByUuid(uuid);
      return Result.ok(note);
    } catch (e) {
      return Result.error('Error fetching note: $e');
    }
  }

  /// Get all notes
  Future<Result<List<Note>, String>> getAllNotes() async {
    try {
      final notes = await _notesDao.getAllNotes();
      return Result.ok(notes);
    } catch (e) {
      return Result.error('Error fetching notes: $e');
    }
  }

  /// Search notes by keyword
  Future<Result<List<Note>, String>> searchNotes(String keyword) async {
    try {
      final notes = await _notesDao.search(keyword);
      return Result.ok(notes);
    } catch (e) {
      return Result.error('Error searching notes: $e');
    }
  }
}
