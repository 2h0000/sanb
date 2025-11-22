import '../entities/note.dart';

/// Repository interface for notes operations
abstract class NotesRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteByUuid(String uuid);
  Future<void> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String uuid);
  Future<List<Note>> searchNotes(String keyword);
}
