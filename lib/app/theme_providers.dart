import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage key for theme mode preference
const _themeModeKey = 'theme_mode';

/// Provider for theme mode storage
final _themeStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for managing theme mode state
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(_themeStorageProvider);
  return ThemeModeNotifier(storage);
});

/// Notifier for managing theme mode state with persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load saved theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final savedMode = await _storage.read(key: _themeModeKey);
      if (savedMode != null) {
        state = _parseThemeMode(savedMode);
      }
    } catch (e) {
      // If loading fails, keep default (system)
      state = ThemeMode.system;
    }
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _themeModeKey, value: mode.name);
    } catch (e) {
      // Silently fail if storage write fails
    }
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
