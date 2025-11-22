# Database Layer

This directory contains the Drift database implementation for the encrypted notebook app.

## Files

- `app_database.dart` - Main database definition with table schemas
- `app_database.g.dart` - Generated code from Drift (DO NOT EDIT MANUALLY)
- `notes_dao.dart` - Data Access Object for Notes operations
- `vault_dao.dart` - Data Access Object for VaultItems operations

## Database Schema

### Notes Table
- `id` - Auto-increment primary key
- `uuid` - Unique identifier (TEXT, UNIQUE)
- `title` - Note title (TEXT, default '')
- `content_md` - Markdown content (TEXT, default '')
- `tags_json` - JSON array of tags (TEXT, default '[]')
- `is_encrypted` - Encryption flag (BOOLEAN, default false)
- `created_at` - Creation timestamp (DATETIME, auto-set)
- `updated_at` - Last update timestamp (DATETIME, auto-set)
- `deleted_at` - Soft delete timestamp (DATETIME, nullable)

### VaultItems Table
- `id` - Auto-increment primary key
- `uuid` - Unique identifier (TEXT, UNIQUE)
- `title_enc` - Encrypted title (TEXT)
- `username_enc` - Encrypted username (TEXT, nullable)
- `password_enc` - Encrypted password (TEXT, nullable)
- `url_enc` - Encrypted URL (TEXT, nullable)
- `note_enc` - Encrypted note (TEXT, nullable)
- `updated_at` - Last update timestamp (DATETIME, auto-set)
- `deleted_at` - Soft delete timestamp (DATETIME, nullable)

## Code Generation

When you modify the table definitions in `app_database.dart`, you need to regenerate the code:

```bash
# Run build_runner to generate Drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Or use watch mode for continuous generation during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Testing

The database can be tested using in-memory SQLite databases:

```dart
final database = AppDatabase.forTesting(NativeDatabase.memory());
```

See `test/data/local/db/app_database_test.dart` for examples.

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 5.1**: Notes table with all specified fields
- **Requirement 5.2**: VaultItems table with encrypted fields
- **Requirement 5.3**: UUID unique constraint enforced
- **Requirement 5.4**: Automatic timestamp setting via defaults
- **Requirement 5.5**: Database file stored as `notebook.sqlite` in app documents directory
- **Requirement 10.3**: Database migration strategy configured
- **Requirement 10.4**: Tables and indexes created on first run
