# Theme Visual Guide

## Theme Switcher Location

The theme switcher is located in the Settings screen:

```
Settings Screen
├── Account Section (if logged in)
│   └── User email and UID
├── Appearance Section ⭐ NEW
│   └── Theme Selector
│       ├── Icon (changes based on current theme)
│       ├── Title: "Theme"
│       ├── Subtitle: Current theme mode
│       └── Tap to open theme selection dialog
├── Data Management Section
│   ├── Export Data
│   └── Import Data
├── Security Section
│   └── Change Master Password
├── About Section
│   └── About
└── Sign Out Button
```

## Theme Selection Dialog

When you tap on the Theme selector, a dialog appears with three options:

```
┌─────────────────────────────────┐
│      Choose Theme               │
├─────────────────────────────────┤
│                                 │
│  ○ Light                        │
│    Always use light theme       │
│                                 │
│  ○ Dark                         │
│    Always use dark theme        │
│                                 │
│  ● System                       │
│    Follow system theme          │
│                                 │
├─────────────────────────────────┤
│              [Cancel]           │
└─────────────────────────────────┘
```

## Theme Icons

The theme selector shows different icons based on the current mode:

- **Light Mode**: 🌞 `Icons.light_mode`
- **Dark Mode**: 🌙 `Icons.dark_mode`
- **System Mode**: 🔆 `Icons.brightness_auto`

## Material Design 3 Components Styled

All components have been styled with Material Design 3 principles:

### Cards
```
┌─────────────────────────────────┐
│  Card with 16px rounded corners │
│  Elevation: 1                   │
│  Clip behavior: antiAlias       │
└─────────────────────────────────┘
```

### Input Fields
```
┌─────────────────────────────────┐
│  Filled input with 12px radius  │
│  Padding: 16px horizontal       │
│  Background: surfaceVariant     │
└─────────────────────────────────┘
```

### Dialogs
```
┌─────────────────────────────────┐
│  Dialog with 20px rounded       │
│  corners and elevation 3        │
│                                 │
│  Content here...                │
│                                 │
│         [Cancel]  [OK]          │
└─────────────────────────────────┘
```

### List Tiles
```
┌─────────────────────────────────┐
│  🔧  List Item Title            │
│      Subtitle text              │
│                              >  │
└─────────────────────────────────┘
12px rounded corners, proper padding
```

### Floating Action Buttons
```
    ┌─────────┐
    │    +    │  16px rounded corners
    └─────────┘  Elevation: 2
```

## Color Scheme

Both themes use **Indigo** as the seed color, which generates:

### Light Theme
- Primary: Indigo-based
- Surface: Light background
- On-surface: Dark text
- Surface variant: Subtle backgrounds
- Outline: Borders and dividers

### Dark Theme
- Primary: Indigo-based (lighter shade)
- Surface: Dark background
- On-surface: Light text
- Surface variant: Subtle backgrounds
- Outline: Borders and dividers

## Theme Persistence

The theme preference is automatically saved when changed:

```
User selects theme
       ↓
ThemeModeNotifier.setThemeMode()
       ↓
Save to Flutter Secure Storage
       ↓
Update app theme immediately
       ↓
On next app launch
       ↓
Load saved preference
       ↓
Apply saved theme
```

## Localization Support

The app supports multiple languages:

### English (en)
```
App Name: "Encrypted Notebook"
Settings: "Settings"
Theme: "Theme"
```

### Chinese (zh)
```
App Name: "加密笔记本"
Settings: "设置"
Theme: "主题"
```

### Adding More Languages

To add a new language (e.g., Spanish):

1. Add to supported locales:
```dart
Locale('es', ''), // Spanish
```

2. Create string map:
```dart
static const Map<String, String> _esStrings = {
  'app_name': 'Cuaderno Encriptado',
  'settings': 'Configuración',
  // ... more strings
};
```

3. Add to switch statement:
```dart
case 'es':
  return _esStrings;
```

## Usage in Code

### Accessing Theme
```dart
// Get current theme mode
final themeMode = ref.watch(themeModeProvider);

// Change theme
await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
```

### Accessing Localized Strings
```dart
// In a widget
final l10n = AppLocalizations.of(context);
Text(l10n.appName); // "Encrypted Notebook" or "加密笔记本"
```

### Using Theme Colors
```dart
// Access theme colors
final colorScheme = Theme.of(context).colorScheme;
Container(
  color: colorScheme.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: colorScheme.onPrimary),
  ),
);
```

## Testing Checklist

- [ ] Open Settings
- [ ] Tap on Theme selector
- [ ] Select Light theme → Verify UI changes
- [ ] Select Dark theme → Verify UI changes
- [ ] Select System theme → Verify follows device
- [ ] Close and reopen app → Verify theme persists
- [ ] Navigate to different screens → Verify consistent styling
- [ ] Change device language to Chinese → Verify strings change
- [ ] Change back to English → Verify strings change back

## Accessibility

Both themes are designed with accessibility in mind:

- **Contrast**: Sufficient contrast ratios for text readability
- **Touch Targets**: Minimum 48x48 dp for interactive elements
- **Visual Feedback**: Clear hover and pressed states
- **Semantic Colors**: Proper use of error, warning, and success colors
- **Focus Indicators**: Visible focus states for keyboard navigation

## Performance

- **Instant Updates**: Theme changes apply immediately without rebuild delays
- **Efficient Storage**: Theme preference stored locally for fast loading
- **No Network Calls**: All theme data is local
- **Minimal Memory**: Lightweight theme configuration

## Conclusion

The theme system provides:
✅ Beautiful, modern Material Design 3 UI
✅ User choice and personalization
✅ Consistent styling across all screens
✅ Smooth transitions between themes
✅ Persistent user preferences
✅ International language support
✅ Accessibility compliance
✅ Excellent performance
