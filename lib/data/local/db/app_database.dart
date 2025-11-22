import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Notes table definition
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get contentMd => text().withDefault(const Constant(''))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// VaultItems table definition
class VaultItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get titleEnc => text()();
  TextColumn get usernameEnc => text().nullable()();
  TextColumn get passwordEnc => text().nullable()();
  TextColumn get urlEnc => text().nullable()();
  TextColumn get noteEnc => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Notes, VaultItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Constructor for testing with custom executor
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Create indexes for performance optimization
          await _createIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add indexes in version 2
            await _createIndexes();
          }
        },
      );

  /// Create performance indexes for frequently queried columns
  Future<void> _createIndexes() async {
    // Notes table indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notes_uuid ON notes(uuid);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON notes(deleted_at);',
    );
    
    // VaultItems table indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vault_items_uuid ON vault_items(uuid);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vault_items_updated_at ON vault_items(updated_at);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vault_items_deleted_at ON vault_items(deleted_at);',
    );
  }
}

// Database connection logic
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notebook.sqlite'));
    return NativeDatabase(file);
  });
}
