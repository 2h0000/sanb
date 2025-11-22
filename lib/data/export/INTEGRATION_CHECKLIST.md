# Export Service Integration Checklist

## ✅ Implementation Complete

Task 10 (数据导出功能实现) has been successfully implemented. Use this checklist to integrate the export functionality into your app.

## Files Created

- ✅ `lib/data/export/export_service.dart` - Core export service
- ✅ `lib/data/export/export_providers.dart` - Riverpod providers
- ✅ `test/data/export/export_service_test.dart` - Unit tests
- ✅ `lib/data/export/README.md` - Documentation
- ✅ `lib/data/export/USAGE_EXAMPLE.md` - Usage examples
- ✅ `lib/data/export/IMPLEMENTATION_SUMMARY.md` - Implementation details

## Integration Steps

### 1. Verify Dependencies (Already in pubspec.yaml)
```yaml
dependencies:
  file_picker: ^6.1.1
  share_plus: ^7.2.1
  path_provider: ^2.1.1
```

### 2. Import Providers in Your App
Add to your main provider setup or settings screen:

```dart
import 'package:encrypted_notebook/data/export/export_providers.dart';
```

### 3. Add Export Buttons to Settings Screen

Location: `lib/features/settings/presentation/settings_screen.dart`

```dart
// Add these buttons to your settings screen
ListTile(
  leading: Icon(Icons.note),
  title: Text('Export Notes'),
  onTap: () async {
    final exportService = ref.read(exportServiceProvider);
    final dataKey = ref.read(dataKeyProvider);
    
    if (dataKey == null) {
      // Show error: vault not unlocked
      return;
    }
    
    final result = await exportService.exportNotes(
      dataKey: dataKey,
      shareFile: true,
    );
    
    // Handle result
  },
),
```

### 4. Ensure DataKey Provider Exists

The export service requires access to the DataKey. Make sure you have:

```dart
final dataKeyProvider = StateProvider<List<int>?>((ref) => null);
```

This should be set when the user unlocks the vault.

### 5. Add Error Handling

Use the examples in `USAGE_EXAMPLE.md` for proper error handling:
- Check if vault is unlocked
- Show loading indicators
- Display success/error messages
- Handle user cancellation

### 6. Test the Integration

#### Manual Testing Steps:
1. ✅ Launch the app
2. ✅ Unlock the vault (to get DataKey)
3. ✅ Navigate to settings
4. ✅ Tap "Export Notes"
5. ✅ Verify share sheet appears (or file picker)
6. ✅ Save the file
7. ✅ Verify file is encrypted (can't read as plain text)
8. ✅ Repeat for "Export Vault" and "Export All"

#### Unit Testing:
```bash
flutter test test/data/export/export_service_test.dart
```

### 7. Platform-Specific Considerations

#### Android
- ✅ File picker works out of the box
- ✅ Share sheet works out of the box
- ✅ No additional permissions needed for temporary files

#### iOS
- ✅ File picker works out of the box
- ✅ Share sheet works out of the box
- ✅ Files saved to app's document directory

### 8. UI/UX Recommendations

#### Loading States
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Center(
    child: CircularProgressIndicator(),
  ),
);
```

#### Success Feedback
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Export successful!'),
    backgroundColor: Colors.green,
  ),
);
```

#### Error Feedback
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Export failed: ${result.error}'),
    backgroundColor: Colors.red,
  ),
);
```

### 9. Security Reminders

- ✅ Export files are encrypted with DataKey
- ✅ Vault items have double encryption (DB + export)
- ✅ DataKey never leaves device unencrypted
- ✅ Users should keep export files secure
- ✅ Export requires vault to be unlocked

### 10. Documentation for Users

Add help text in your UI:

```dart
InfoDialog(
  title: 'About Exports',
  content: 
    'Export files are encrypted with your master password. '
    'Keep them secure and remember your password to import them later. '
    'You can use exports to backup your data or transfer to another device.',
);
```

## Quick Start Example

Minimal integration in settings screen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypted_notebook/data/export/export_providers.dart';

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('Export All Data'),
            subtitle: Text('Backup notes and vault'),
            onTap: () => _exportAll(context, ref),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    final exportService = ref.read(exportServiceProvider);
    final dataKey = ref.read(dataKeyProvider);
    
    if (dataKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please unlock vault first')),
      );
      return;
    }
    
    final result = await exportService.exportAll(
      dataKey: dataKey,
      shareFile: true,
    );
    
    if (result.isOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## Troubleshooting

### Issue: "Please unlock vault first"
**Solution**: User needs to unlock vault before exporting. The DataKey is required for encryption.

### Issue: "User cancelled operation"
**Solution**: This is normal - user cancelled the file picker or share dialog. No action needed.

### Issue: "Encryption failed"
**Solution**: Check that DataKey is valid (32 bytes). Verify vault unlock was successful.

### Issue: File picker not showing
**Solution**: 
- Check that `file_picker` dependency is installed
- Run `flutter pub get`
- Verify platform-specific setup (usually automatic)

### Issue: Share sheet not showing
**Solution**:
- Check that `share_plus` dependency is installed
- Run `flutter pub get`
- Test on physical device (may not work in simulator)

## Next Task

After integrating export functionality, proceed to:
- **Task 11**: Data Import Functionality (导入功能实现)

This will allow users to restore exported data.

## Support

For detailed usage examples, see:
- `USAGE_EXAMPLE.md` - 5 complete UI examples
- `README.md` - Technical documentation
- `IMPLEMENTATION_SUMMARY.md` - Implementation details

## Completion Checklist

Before marking integration complete:

- [ ] Export buttons added to settings screen
- [ ] DataKey provider is accessible
- [ ] Error handling implemented
- [ ] Loading indicators added
- [ ] Success/error messages shown
- [ ] Tested on Android (if applicable)
- [ ] Tested on iOS (if applicable)
- [ ] User documentation added
- [ ] Security warnings displayed

---

**Status**: Ready for integration ✅
**Next Step**: Add export UI to settings screen
