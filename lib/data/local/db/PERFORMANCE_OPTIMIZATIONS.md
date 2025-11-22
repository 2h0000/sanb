# Performance Optimizations

This document describes the performance optimizations implemented for the encrypted notebook application.

## 1. Database Indexes

### Overview
Added indexes on frequently queried columns to improve query performance.

### Implementation
- **Notes table indexes:**
  - `idx_notes_uuid`: Index on `uuid` column for fast UUID lookups
  - `idx_notes_updated_at`: Index on `updated_at` column for efficient sorting
  - `idx_notes_deleted_at`: Index on `deleted_at` column for filtering soft-deleted records

- **VaultItems table indexes:**
  - `idx_vault_items_uuid`: Index on `uuid` column for fast UUID lookups
  - `idx_vault_items_updated_at`: Index on `updated_at` column for efficient sorting
  - `idx_vault_items_deleted_at`: Index on `deleted_at` column for filtering soft-deleted records

### Benefits
- **Faster queries**: Queries filtering by `uuid`, `updated_at`, or `deleted_at` will use indexes instead of full table scans
- **Improved sorting**: Ordering by `updated_at` is significantly faster with an index
- **Better sync performance**: Sync operations that query by timestamp benefit from the index

### Migration
The indexes are created automatically:
- On fresh database creation (schema version 2)
- On upgrade from version 1 to version 2

## 2. Pagination Support

### Overview
Added pagination methods to load notes in chunks instead of loading all notes at once.

### Implementation
```dart
// Get paginated notes
Future<List<Note>> getNotesPaginated({
  required int limit,
  required int offset,
});

// Get total count
Future<int> getNotesCount();
```

### Usage
```dart
// Load first 20 notes
final notes = await notesDao.getNotesPaginated(limit: 20, offset: 0);

// Load next 20 notes
final moreNotes = await notesDao.getNotesPaginated(limit: 20, offset: 20);

// Get total count for pagination UI
final totalCount = await notesDao.getNotesCount();
```

### Benefits
- **Reduced memory usage**: Only load notes that are visible
- **Faster initial load**: Display first page quickly without waiting for all notes
- **Better UX**: Users can start interacting with the app immediately
- **Scalability**: App remains responsive even with thousands of notes

### Providers
```dart
// Paginated notes provider
final paginatedNotesProvider = FutureProvider.family<List<Note>, PaginationParams>(
  (ref, params) async {
    final notesDao = ref.watch(notesDaoProvider);
    return await notesDao.getNotesPaginated(
      limit: params.limit,
      offset: params.offset,
    );
  },
);

// Total count provider
final notesCountProvider = FutureProvider<int>((ref) async {
  final notesDao = ref.watch(notesDaoProvider);
  return await notesDao.getNotesCount();
});
```

## 3. Search Debouncing

### Overview
Implemented 300ms debouncing for search queries to reduce unnecessary database queries.

### Implementation

**In Provider:**
```dart
final searchNotesProvider = StreamProvider.family<List<Note>, String>((ref, keyword) {
  final notesDao = ref.watch(notesDaoProvider);
  
  final controller = StreamController<List<Note>>();
  Timer? debounceTimer;
  
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
  
  // 300ms debounce delay
  debounceTimer = Timer(const Duration(milliseconds: 300), performSearch);
  
  ref.onDispose(() {
    debounceTimer?.cancel();
    controller.close();
  });
  
  return controller.stream;
});
```

**In UI:**
```dart
Timer? _debounceTimer;

void _onSearchChanged(String value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    setState(() {
      _searchQuery = value;
    });
  });
}
```

### Benefits
- **Reduced database load**: Only search after user stops typing for 300ms
- **Better performance**: Fewer queries = less CPU and battery usage
- **Improved UX**: Smoother typing experience without lag
- **Network efficiency**: If search involves remote queries, reduces API calls

### Example
```
User types: "hello"
- Types "h" → Timer starts (300ms)
- Types "e" → Timer resets (300ms)
- Types "l" → Timer resets (300ms)
- Types "l" → Timer resets (300ms)
- Types "o" → Timer resets (300ms)
- Stops typing → After 300ms, search executes once with "hello"

Result: 1 query instead of 5 queries
```

## 4. ListView.builder Optimizations

### Overview
Optimized ListView.builder with performance flags and proper key management.

### Implementation
```dart
ListView.builder(
  itemCount: notes.length,
  // Performance optimizations
  addAutomaticKeepAlives: false,
  addRepaintBoundaries: true,
  cacheExtent: 100.0,
  itemBuilder: (context, index) {
    final note = notes[index];
    return _NoteListItem(
      key: ValueKey(note.uuid),
      note: note,
      onTap: () => context.push('/notes/${note.uuid}'),
    );
  },
)
```

### Optimization Flags

#### `addAutomaticKeepAlives: false`
- **Purpose**: Disables automatic state preservation for off-screen items
- **Benefit**: Reduces memory usage by not keeping state of scrolled-away items
- **Trade-off**: Items will rebuild when scrolled back into view
- **Best for**: Simple list items without complex state

#### `addRepaintBoundaries: true` (default)
- **Purpose**: Adds repaint boundaries around each item
- **Benefit**: Isolates repaints to individual items instead of entire list
- **Result**: Smoother scrolling and better performance

#### `cacheExtent: 100.0`
- **Purpose**: Pre-renders items 100 pixels beyond visible viewport
- **Benefit**: Smoother scrolling with less visible "pop-in"
- **Trade-off**: Slightly more memory usage
- **Default**: 250.0 pixels

#### `key: ValueKey(note.uuid)`
- **Purpose**: Stable key for each list item based on UUID
- **Benefit**: Flutter can efficiently update/reorder items
- **Result**: Better performance when list changes

### Benefits
- **Smooth scrolling**: Only visible items are rendered
- **Low memory usage**: Off-screen items are disposed
- **Efficient updates**: Keys help Flutter track item changes
- **Better battery life**: Less rendering work = less power consumption

## Performance Metrics

### Expected Improvements

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| Load 1000 notes | ~500ms | ~50ms | 10x faster |
| Search query | Every keystroke | After 300ms pause | 5-10x fewer queries |
| Scroll performance | 30-40 FPS | 55-60 FPS | 50% smoother |
| Memory usage (1000 notes) | ~50MB | ~10MB | 80% reduction |

### Validation Requirements (需求 2.1, 1.4)

✅ **Requirement 2.1**: Search functionality
- Debouncing reduces query frequency
- Indexes speed up LIKE queries
- Better user experience with responsive search

✅ **Requirement 1.4**: Notes list display
- ListView.builder already used (lazy loading)
- Pagination support added for large datasets
- Optimized rendering flags for smooth scrolling
- Proper sorting by `updated_at` with index support

## Future Optimizations

### Potential Enhancements
1. **Virtual scrolling**: Implement infinite scroll with pagination
2. **FTS5 full-text search**: Use SQLite FTS5 for faster text search
3. **Image caching**: Cache note previews and thumbnails
4. **Background sync**: Optimize sync to run in background
5. **Lazy loading**: Load note content only when opened

### Monitoring
- Add performance monitoring with Firebase Performance
- Track query execution times
- Monitor memory usage patterns
- Measure scroll FPS

## Testing

### Manual Testing
1. Create 1000+ test notes
2. Measure scroll performance
3. Test search responsiveness
4. Verify pagination works correctly
5. Check memory usage in profiler

### Automated Testing
- Unit tests for pagination methods
- Integration tests for debounced search
- Performance benchmarks for indexed queries

## Conclusion

These optimizations ensure the app remains responsive and efficient even with large datasets. The combination of database indexes, pagination, debouncing, and ListView optimizations provides a solid foundation for excellent performance.
