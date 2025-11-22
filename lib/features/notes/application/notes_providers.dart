import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/note.dart';
import 'notes_service.dart';

/// Provider for NotesService
final notesServiceProvider = Provider<NotesService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  return NotesService(notesDao: notesDao);
});

/// Provider for a single note by UUID
final noteByIdProvider = FutureProvider.family<Note?, String>((ref, uuid) async {
  final notesDao = ref.watch(notesDaoProvider);
  return await notesDao.findByUuid(uuid);
});

/// Provider for searching notes with debouncing (300ms delay)
final searchNotesProvider = StreamProvider.family<List<Note>, String>((ref, keyword) {
  final notesDao = ref.watch(notesDaoProvider);
  
  // Create a stream controller for debounced search
  final controller = StreamController<List<Note>>();
  Timer? debounceTimer;
  
  // Perform the search after debounce delay
  void performSearch() async {
    try {
      final results = await notesDao.search(keyword);
      if (!controller.isClosed) {
        controller.add(results);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
  
  // Start debounce timer (300ms delay)
  debounceTimer = Timer(const Duration(milliseconds: 300), performSearch);
  
  // Cleanup on dispose
  ref.onDispose(() {
    debounceTimer?.cancel();
    controller.close();
  });
  
  return controller.stream;
});

/// Provider for paginated notes
/// Returns a list of notes with pagination support
final paginatedNotesProvider = FutureProvider.family<List<Note>, PaginationParams>(
  (ref, params) async {
    final notesDao = ref.watch(notesDaoProvider);
    return await notesDao.getNotesPaginated(
      limit: params.limit,
      offset: params.offset,
    );
  },
);

/// Provider for total notes count
final notesCountProvider = FutureProvider<int>((ref) async {
  final notesDao = ref.watch(notesDaoProvider);
  return await notesDao.getNotesCount();
});

/// Pagination parameters
class PaginationParams {
  final int limit;
  final int offset;

  const PaginationParams({
    required this.limit,
    required this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => limit.hashCode ^ offset.hashCode;
}
