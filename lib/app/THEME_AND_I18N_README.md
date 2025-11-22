# Theme and Internationalization Implementation

## Overview

This document describes the theme and internationalization (i18n) implementation for the Encrypted Notebook app.

## Theme System

### Features

- **Material Design 3**: Full support for Material Design 3 with dynamic color schemes
- **Light and Dark Themes**: Comprehensive light and dark theme implementations
- **Theme Persistence**: User's theme preference is saved and restored across app sessions
- **System Theme Support**: Automatically follows system theme when set to "System" mode

### Implementation

#### Theme Configuration (`lib/app/theme.dart`)

The `AppTheme` class provides two static methods:
- `lightTheme`: Returns a fully configured light theme
- `darkTheme`: Returns a fully configured dark theme

Both themes include:
- Color schemes generated from a seed color (Indigo)
- Consistent styling for all Material components:
  - AppBar with elevation and scrolling behavior
  - Cards with rounded corners
  - Input fields with filled style
  - Floating action buttons
  - List tiles
  - Dialogs and bottom sheets
  - Chips and dividers

#### Theme State Management (`lib/app/theme_providers.dart`)

The theme system uses Riverpod for state management:

```dart
// Provider for accessing current theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(_themeStorageProvider);
  return ThemeModeNotifier(storage);
});
```

**ThemeModeNotifier** handles:
- Loading saved theme preference from secure storage
- Persisting theme changes
- Providing current theme mode to the app

#### Theme Switcher UI

The settings screen includes a theme selector that allows users to choose between:
- **Light**: Always use light theme
- **Dark**: Always use dark theme
- **System**: Follow system theme preference

The theme switcher is implemented as a dialog with radio buttons for easy selection.

### Usage

To change the theme programmatically:

```dart
// Get the theme mode notifier
final themeNotifier = ref.read(themeModeProvider.notifier);

// Set theme mode
await themeNotifier.setThemeMode(ThemeMode.dark);
```

To access current theme mode:

```dart
final currentTheme = ref.watch(themeModeProvider);
```

## Internationalization (i18n)

### Features

- **Multi-language Support**: Basic structure for English and Chinese
- **Extensible**: Easy to add more languages
- **Type-safe**: Compile-time checked string keys
- **Fallback**: Defaults to English if translation is missing

### Implementation

#### Localization Class (`lib/app/l10n/app_localizations.dart`)

The `AppLocalizations` class provides:
- Static delegate for Flutter's localization system
- Supported locales list
- Getter methods for localized strings
- Language-specific string maps

**Supported Languages:**
- English (en)
- Chinese (zh)

**Available Strings:**
- Common: app_name, cancel, save, delete, edit, search, settings
- Notes: notes, new_note, note_title, note_content
- Vault: vault, unlock_vault, master_password
- Auth: sign_in, sign_out, email, password

### Usage

To use localized strings in your widgets:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  
  return Text(l10n.appName); // Returns "Encrypted Notebook" or "加密笔记本"
}
```

### Adding New Languages

1. Add the locale to `supportedLocales`:
```dart
static const List<Locale> supportedLocales = [
  Locale('en', ''),
  Locale('zh', ''),
  Locale('es', ''), // Spanish
];
```

2. Add the language code to `isSupported`:
```dart
@override
bool isSupported(Locale locale) {
  return ['en', 'zh', 'es'].contains(locale.languageCode);
}
```

3. Create a new string map:
```dart
static const Map<String, String> _esStrings = {
  'app_name': 'Cuaderno Encriptado',
  'cancel': 'Cancelar',
  // ... more strings
};
```

4. Add the case to `_localizedStrings`:
```dart
Map<String, String> get _localizedStrings {
  switch (locale.languageCode) {
    case 'zh':
      return _zhStrings;
    case 'es':
      return _esStrings;
    case 'en':
    default:
      return _enStrings;
  }
}
```

### Adding New Strings

1. Add a getter method:
```dart
String get myNewString => _localizedStrings['my_new_string'] ?? 'Default Value';
```

2. Add the key-value pair to all language maps:
```dart
static const Map<String, String> _enStrings = {
  // ... existing strings
  'my_new_string': 'My New String',
};

static const Map<String, String> _zhStrings = {
  // ... existing strings
  'my_new_string': '我的新字符串',
};
```

## Future Enhancements

### Theme System
- [ ] Custom color scheme picker
- [ ] Per-feature theme customization
- [ ] Theme preview before applying
- [ ] Import/export theme configurations

### Internationalization
- [ ] Integration with `flutter_localizations` for full i18n
- [ ] ARB file support for professional translation workflows
- [ ] Right-to-left (RTL) language support
- [ ] Date and number formatting per locale
- [ ] Pluralization support
- [ ] Language switcher in settings
- [ ] More languages (Spanish, French, German, Japanese, etc.)

## Testing

To test themes:
1. Open the app
2. Navigate to Settings
3. Tap on "Theme"
4. Select different theme modes and verify the UI updates correctly
5. Restart the app and verify the theme preference is persisted

To test localization:
1. Change your device language to Chinese
2. Restart the app
3. Verify that supported strings are displayed in Chinese
4. Change back to English and verify strings are in English

## Notes

- Theme preference is stored in Flutter Secure Storage for consistency with other app data
- The localization system is basic and can be enhanced with the `intl` package for more advanced features
- All UI components automatically adapt to the selected theme
- The app follows Material Design 3 guidelines for consistent user experience
