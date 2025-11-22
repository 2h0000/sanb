import 'package:drift/drift.dart';
import 'package:encrypted_notebook/data/local/db/app_database.dart';
import 'package:encrypted_notebook/domain/entities/vault_item.dart' as entity;

part 'vault_dao.g.dart';

@DriftAccessor(tables: [VaultItems])
class VaultDao extends DatabaseAccessor<AppDatabase> with _$VaultDaoMixin {
  VaultDao(AppDatabase db) : super(db);

  /// Create a new vault item (with encrypted fields)
  Future<int> createVaultItem({
    required String uuid,
    required String titleEnc,
    String? usernameEnc,
    String? passwordEnc,
    String? urlEnc,
    String? noteEnc,
  }) async {
    final companion = VaultItemsCompanion.insert(
      uuid: uuid,
      titleEnc: titleEnc,
      usernameEnc: Value(usernameEnc),
      passwordEnc: Value(passwordEnc),
      urlEnc: Value(urlEnc),
      noteEnc: Value(noteEnc),
    );
    return await into(vaultItems).insert(companion);
  }

  /// Update an existing vault item
  Future<int> updateVaultItem(
    String uuid, {
    String? titleEnc,
    String? usernameEnc,
    String? passwordEnc,
    String? urlEnc,
    String? noteEnc,
  }) async {
    final query = update(vaultItems)..where((t) => t.uuid.equals(uuid));
    
    return await query.write(
      VaultItemsCompanion(
        titleEnc: titleEnc != null ? Value(titleEnc) : const Value.absent(),
        usernameEnc: usernameEnc != null ? Value(usernameEnc) : const Value.absent(),
        passwordEnc: passwordEnc != null ? Value(passwordEnc) : const Value.absent(),
        urlEnc: urlEnc != null ? Value(urlEnc) : const Value.absent(),
        noteEnc: noteEnc != null ? Value(noteEnc) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft delete a vault item
  Future<int> softDelete(String uuid) async {
    final query = update(vaultItems)..where((t) => t.uuid.equals(uuid));
    
    return await query.write(
      VaultItemsCompanion(
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all non-deleted vault items
  Future<List<entity.VaultItemEncrypted>> getAllVaultItems() async {
    final query = select(vaultItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final results = await query.get();
    return results.map((item) => _toEncryptedEntity(item)).toList();
  }

  /// Find vault item by UUID
  Future<entity.VaultItemEncrypted?> findByUuid(String uuid) async {
    final query = select(vaultItems)..where((t) => t.uuid.equals(uuid));
    final result = await query.getSingleOrNull();
    return result != null ? _toEncryptedEntity(result) : null;
  }

  /// Get vault items that need syncing (updated after lastSyncTime)
  Future<List<entity.VaultItemEncrypted>> getVaultItemsForSync(DateTime lastSyncTime) async {
    final query = select(vaultItems)
      ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncTime));

    final results = await query.get();
    return results.map((item) => _toEncryptedEntity(item)).toList();
  }

  /// Watch all non-deleted vault items (for StreamProvider)
  Stream<List<entity.VaultItemEncrypted>> watchAllVaultItems() {
    final query = select(vaultItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    return query.watch().map((rows) => rows.map((item) => _toEncryptedEntity(item)).toList());
  }

  /// Insert or update a vault item with specific timestamps (for import)
  /// This preserves the original updatedAt timestamp
  Future<int> upsertVaultItemWithTimestamps({
    required String uuid,
    required String titleEnc,
    String? usernameEnc,
    String? passwordEnc,
    String? urlEnc,
    String? noteEnc,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) async {
    final companion = VaultItemsCompanion.insert(
      uuid: uuid,
      titleEnc: titleEnc,
      usernameEnc: Value(usernameEnc),
      passwordEnc: Value(passwordEnc),
      urlEnc: Value(urlEnc),
      noteEnc: Value(noteEnc),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
    );
    
    return await into(vaultItems).insertOnConflictUpdate(companion);
  }

  /// Convert Drift VaultItem to encrypted domain entity
  entity.VaultItemEncrypted _toEncryptedEntity(VaultItem item) {
    return entity.VaultItemEncrypted(
      uuid: item.uuid,
      titleEnc: item.titleEnc,
      usernameEnc: item.usernameEnc,
      passwordEnc: item.passwordEnc,
      urlEnc: item.urlEnc,
      noteEnc: item.noteEnc,
      updatedAt: item.updatedAt,
      deletedAt: item.deletedAt,
    );
  }
}
