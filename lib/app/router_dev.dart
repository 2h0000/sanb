import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen_dev.dart';
import '../features/settings/presentation/settings_screen_dev.dart';
import '../features/notes/presentation/notes_list_screen.dart';
import '../features/notes/presentation/note_detail_screen.dart';
import '../features/notes/presentation/note_edit_screen.dart';
import '../features/vault/presentation/vault_unlock_screen_dev.dart';
import '../features/vault/presentation/vault_list_screen.dart';
import '../features/vault/presentation/vault_detail_screen.dart';
import '../features/vault/presentation/vault_edit_screen.dart';

/// Development router without Firebase authentication
GoRouter createDevRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      // Authentication routes (using mock auth)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreenDev(),
      ),
      
      // Notes routes
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
      GoRoute(
        path: '/notes/new',
        builder: (context, state) => const NoteEditScreen(),
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return NoteDetailScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: '/notes/:id/edit',
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return NoteEditScreen(noteId: noteId);
        },
      ),
      
      // Vault routes
      GoRoute(
        path: '/vault/unlock',
        builder: (context, state) => const VaultUnlockScreenDev(),
      ),
      GoRoute(
        path: '/vault',
        builder: (context, state) => const VaultListScreen(),
      ),
      GoRoute(
        path: '/vault/new',
        builder: (context, state) => const VaultEditScreen(),
      ),
      GoRoute(
        path: '/vault/:id',
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return VaultDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/vault/:id/edit',
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return VaultEditScreen(itemId: itemId);
        },
      ),
      
      // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreenDev(),
      ),
    ],
  );
}
