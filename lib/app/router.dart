import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/notes/presentation/notes_list_screen.dart';
import '../features/notes/presentation/note_detail_screen.dart';
import '../features/notes/presentation/note_edit_screen.dart';
import '../features/vault/presentation/vault_unlock_screen.dart';
import '../features/vault/presentation/vault_list_screen.dart';
import '../features/vault/presentation/vault_detail_screen.dart';
import '../features/vault/presentation/vault_edit_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isVaultUnlocked = ref.watch(isVaultUnlockedProvider);
  
  return GoRouter(
    initialLocation: '/notes',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isVaultRoute = location.startsWith('/vault');
      final isVaultUnlockRoute = location == '/vault/unlock';
      
      // Vault unlock guard: If accessing vault routes (except unlock page) 
      // and vault is not unlocked, redirect to unlock page
      if (isVaultRoute && !isVaultUnlockRoute && !isVaultUnlocked) {
        return '/vault/unlock';
      }
      
      // If vault is unlocked and on unlock page, redirect to vault list
      if (isVaultUnlockRoute && isVaultUnlocked) {
        return '/vault';
      }
      
      // No redirect needed
      return null;
    },
    routes: [
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
        builder: (context, state) => const VaultUnlockScreen(),
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
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
