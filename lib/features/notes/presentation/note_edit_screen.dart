import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/note.dart';
import '../application/notes_providers.dart';

/// Note edit screen for creating and editing notes
class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<String> _tags = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  Note? _originalNote;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null && widget.noteId != 'new') {
      final noteAsync = ref.read(noteByIdProvider(widget.noteId!));
      await noteAsync.when(
        data: (note) async {
          if (note != null) {
            setState(() {
              _originalNote = note;
              _titleController.text = note.title;
              _contentController.text = note.contentMd;
              _tags = List.from(note.tags);
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        },
        loading: () async {},
        error: (error, stack) async {
          setState(() {
            _isLoading = false;
          });
        },
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    // Track changes
    _titleController.addListener(_markAsChanged);
    _contentController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.noteId == null || widget.noteId == 'new';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!isNew && _originalNote == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Note Not Found'),
        ),
        body: const Center(
          child: Text('This note does not exist or has been deleted.'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'New Note' : 'Edit Note'),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveNote,
                tooltip: 'Save',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              // Content field (Markdown)
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content (Markdown)',
                  hintText: 'Enter note content...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 10,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              // Tags section
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Tag input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tags display
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final isNew = widget.noteId == null || widget.noteId == 'new';

    try {
      final result = isNew
          ? await ref.read(notesServiceProvider).createNote(
                title: title,
                contentMd: content,
                tags: _tags,
              )
          : await ref.read(notesServiceProvider).updateNote(
                uuid: widget.noteId!,
                title: title,
                contentMd: content,
                tags: _tags,
              );

      result.when(
        ok: (note) {
          if (mounted) {
            setState(() {
              _hasChanges = false;
              _isSaving = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isNew ? 'Note created' : 'Note saved')),
            );
            
            // Navigate back to notes list
            context.go('/notes');
          }
        },
        error: (error) {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving note: $error')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
