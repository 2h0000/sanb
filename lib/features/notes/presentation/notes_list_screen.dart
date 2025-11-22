import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/note.dart';
import '../application/notes_providers.dart';

/// Notes list screen displaying all user notes with search functionality
class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Debounced search handler (300ms delay)
  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = _searchQuery.isEmpty
        ? ref.watch(notesListProvider)
        : ref.watch(searchNotesProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => context.push('/vault/unlock'),
            tooltip: 'Vault',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.note_add : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No notes found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first note',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Individual note list item widget
class _NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Extract preview text from markdown content (first 100 chars)
    final preview = note.contentMd.isEmpty
        ? 'No content'
        : note.contentMd.length > 100
            ? '${note.contentMd.substring(0, 100)}...'
            : note.contentMd;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Content preview
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Tags and timestamp
              Row(
                children: [
                  // Tags
                  if (note.tags.isNotEmpty) ...[
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: note.tags.take(3).map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  // Updated timestamp
                  Text(
                    _formatTimestamp(note.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
