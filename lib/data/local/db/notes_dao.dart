import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/domain/entities/note.dart' as entity;

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(AppDatabase db) : super(db);

  /// Create a new note
  Future<int> createNote({
    required String uuid,
    required String title,
    required String contentMd,
    List<String> tags = const [],
  }) async {
    final companion = NotesCompanion.insert(
      uuid: uuid,
      title: Value(title),
      contentMd: Value(contentMd),
      tagsJson: Value(jsonEncode(tags)),
    );
    return await into(notes).insert(companion);
  }

  /// Update an existing note
  Future<int> updateNote(
    String uuid, {
    String? title,
    String? contentMd,
    List<String>? tags,
  }) async {
    final query = update(notes)..where((t) => t.uuid.equals(uuid));
    
    return await query.write(
      NotesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        contentMd: contentMd != null ? Value(contentMd) : const Value.absent(),
        tagsJson: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete a note
  Future<int> softDelete(String uuid) async {
    final query = update(notes)..where((t) => t.uuid.equals(uuid));
    
    return await query.write(
      NotesCompanion(
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Search notes by keyword (LIKE query)
  Future<List<entity.Note>> search(String keyword) async {
    final query = select(notes)
      ..where((t) =>
          t.deletedAt.isNull() &
          (t.title.like('%$keyword%') | t.contentMd.like('%$keyword%')))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final results = await query.get();
    return results.map(_toEntity).toList();
  }

  /// Get all non-deleted notes
  Future<List<entity.Note>> getAllNotes() async {
    final query = select(notes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final results = await query.get();
    return results.map(_toEntity).toList();
  }

  /// Get paginated non-deleted notes
  /// [limit] - number of notes to fetch
  /// [offset] - number of notes to skip
  Future<List<entity.Note>> getNotesPaginated({
    required int limit,
    required int offset,
  }) async {
    final query = select(notes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_toEntity).toList();
  }

  /// Get total count of non-deleted notes
  Future<int> getNotesCount() async {
    final query = selectOnly(notes)
      ..addColumns([notes.id.count()])
      ..where(notes.deletedAt.isNull());

    final result = await query.getSingle();
    return result.read(notes.id.count()) ?? 0;
  }

  /// Find note by UUID
  Future<entity.Note?> findByUuid(String uuid) async {
    final query = select(notes)..where((t) => t.uuid.equals(uuid));
    final result = await query.getSingleOrNull();
    return result != null ? _toEntity(result) : null;
  }

  /// Get notes that need syncing (updated after lastSyncTime)
  Future<List<entity.Note>> getNotesForSync(DateTime lastSyncTime) async {
    final query = select(notes)
      ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncTime));

    final results = await query.get();
    return results.map(_toEntity).toList();
  }

  /// Watch all non-deleted notes (for StreamProvider)
  Stream<List<entity.Note>> watchAllNotes() {
    final query = select(notes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  /// Watch count of non-deleted notes
  Stream<int> watchNotesCount() {
    final query = selectOnly(notes)
      ..addColumns([notes.id.count()])
      ..where(notes.deletedAt.isNull());

    return query.map((row) => row.read(notes.id.count()) ?? 0).watchSingle();
  }

  /// Insert or update a note with specific timestamps (for import)
  /// This preserves the original createdAt and updatedAt timestamps
  Future<int> upsertNoteWithTimestamps({
    required String uuid,
    required String title,
    required String contentMd,
    List<String> tags = const [],
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) async {
    final companion = NotesCompanion.insert(
      uuid: uuid,
      title: Value(title),
      contentMd: Value(contentMd),
      tagsJson: Value(jsonEncode(tags)),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
    );
    
    return await into(notes).insertOnConflictUpdate(companion);
  }

  /// Convert Drift Note to domain entity
  entity.Note _toEntity(Note note) {
    return entity.Note(
      uuid: note.uuid,
      title: note.title,
      contentMd: note.contentMd,
      tags: (jsonDecode(note.tagsJson) as List<dynamic>).cast<String>(),
      isEncrypted: note.isEncrypted,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      deletedAt: note.deletedAt,
    );
  }
}
