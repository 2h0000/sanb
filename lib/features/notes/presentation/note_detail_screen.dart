import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/note.dart';
import '../application/notes_providers.dart';

/// Note detail screen displaying a single note's content
class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Note Not Found'),
            ),
            body: const Center(
              child: Text('This note does not exist or has been deleted.'),
            ),
          );
        }

        return _NoteDetailView(note: note);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading note: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDetailView extends ConsumerWidget {
  final Note note;

  const _NoteDetailView({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/notes/${note.uuid}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Metadata
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_formatDate(note.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.create, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(note.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tags
            if (note.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 16),
            // Content (Markdown)
            Text(
              note.contentMd.isEmpty ? 'No content' : note.contentMd,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Delete the note
              final result = await ref.read(notesServiceProvider).deleteNote(note.uuid);
              
              result.when(
                ok: (_) {
                  if (context.mounted) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note deleted')),
                    );
                    // Navigate back to notes list
                    context.go('/notes');
                  }
                },
                error: (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting note: $error')),
                    );
                  }
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
