// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentMdMeta =
      const VerificationMeta('contentMd');
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
      'content_md', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        title,
        contentMd,
        tagsJson,
        isEncrypted,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content_md')) {
      context.handle(_contentMdMeta,
          contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta));
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      contentMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_md'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String uuid;
  final String title;
  final String contentMd;
  final String tagsJson;
  final bool isEncrypted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Note(
      {required this.id,
      required this.uuid,
      required this.title,
      required this.contentMd,
      required this.tagsJson,
      required this.isEncrypted,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    map['content_md'] = Variable<String>(contentMd);
    map['tags_json'] = Variable<String>(tagsJson);
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      contentMd: Value(contentMd),
      tagsJson: Value(tagsJson),
      isEncrypted: Value(isEncrypted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      contentMd: serializer.fromJson<String>(json['contentMd']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'contentMd': serializer.toJson<String>(contentMd),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Note copyWith(
          {int? id,
          String? uuid,
          String? title,
          String? contentMd,
          String? tagsJson,
          bool? isEncrypted,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Note(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        title: title ?? this.title,
        contentMd: contentMd ?? this.contentMd,
        tagsJson: tagsJson ?? this.tagsJson,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('contentMd: $contentMd, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, title, contentMd, tagsJson,
      isEncrypted, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.contentMd == this.contentMd &&
          other.tagsJson == this.tagsJson &&
          other.isEncrypted == this.isEncrypted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String> contentMd;
  final Value<String> tagsJson;
  final Value<bool> isEncrypted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.title = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? contentMd,
    Expression<String>? tagsJson,
    Expression<bool>? isEncrypted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (contentMd != null) 'content_md': contentMd,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? title,
      Value<String>? contentMd,
      Value<String>? tagsJson,
      Value<bool>? isEncrypted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return NotesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      contentMd: contentMd ?? this.contentMd,
      tagsJson: tagsJson ?? this.tagsJson,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('contentMd: $contentMd, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $VaultItemsTable extends VaultItems
    with TableInfo<$VaultItemsTable, VaultItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleEncMeta =
      const VerificationMeta('titleEnc');
  @override
  late final GeneratedColumn<String> titleEnc = GeneratedColumn<String>(
      'title_enc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameEncMeta =
      const VerificationMeta('usernameEnc');
  @override
  late final GeneratedColumn<String> usernameEnc = GeneratedColumn<String>(
      'username_enc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _passwordEncMeta =
      const VerificationMeta('passwordEnc');
  @override
  late final GeneratedColumn<String> passwordEnc = GeneratedColumn<String>(
      'password_enc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlEncMeta = const VerificationMeta('urlEnc');
  @override
  late final GeneratedColumn<String> urlEnc = GeneratedColumn<String>(
      'url_enc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteEncMeta =
      const VerificationMeta('noteEnc');
  @override
  late final GeneratedColumn<String> noteEnc = GeneratedColumn<String>(
      'note_enc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        titleEnc,
        usernameEnc,
        passwordEnc,
        urlEnc,
        noteEnc,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_items';
  @override
  VerificationContext validateIntegrity(Insertable<VaultItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title_enc')) {
      context.handle(_titleEncMeta,
          titleEnc.isAcceptableOrUnknown(data['title_enc']!, _titleEncMeta));
    } else if (isInserting) {
      context.missing(_titleEncMeta);
    }
    if (data.containsKey('username_enc')) {
      context.handle(
          _usernameEncMeta,
          usernameEnc.isAcceptableOrUnknown(
              data['username_enc']!, _usernameEncMeta));
    }
    if (data.containsKey('password_enc')) {
      context.handle(
          _passwordEncMeta,
          passwordEnc.isAcceptableOrUnknown(
              data['password_enc']!, _passwordEncMeta));
    }
    if (data.containsKey('url_enc')) {
      context.handle(_urlEncMeta,
          urlEnc.isAcceptableOrUnknown(data['url_enc']!, _urlEncMeta));
    }
    if (data.containsKey('note_enc')) {
      context.handle(_noteEncMeta,
          noteEnc.isAcceptableOrUnknown(data['note_enc']!, _noteEncMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      titleEnc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_enc'])!,
      usernameEnc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username_enc']),
      passwordEnc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_enc']),
      urlEnc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url_enc']),
      noteEnc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_enc']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $VaultItemsTable createAlias(String alias) {
    return $VaultItemsTable(attachedDatabase, alias);
  }
}

class VaultItem extends DataClass implements Insertable<VaultItem> {
  final int id;
  final String uuid;
  final String titleEnc;
  final String? usernameEnc;
  final String? passwordEnc;
  final String? urlEnc;
  final String? noteEnc;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const VaultItem(
      {required this.id,
      required this.uuid,
      required this.titleEnc,
      this.usernameEnc,
      this.passwordEnc,
      this.urlEnc,
      this.noteEnc,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title_enc'] = Variable<String>(titleEnc);
    if (!nullToAbsent || usernameEnc != null) {
      map['username_enc'] = Variable<String>(usernameEnc);
    }
    if (!nullToAbsent || passwordEnc != null) {
      map['password_enc'] = Variable<String>(passwordEnc);
    }
    if (!nullToAbsent || urlEnc != null) {
      map['url_enc'] = Variable<String>(urlEnc);
    }
    if (!nullToAbsent || noteEnc != null) {
      map['note_enc'] = Variable<String>(noteEnc);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  VaultItemsCompanion toCompanion(bool nullToAbsent) {
    return VaultItemsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      titleEnc: Value(titleEnc),
      usernameEnc: usernameEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(usernameEnc),
      passwordEnc: passwordEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordEnc),
      urlEnc:
          urlEnc == null && nullToAbsent ? const Value.absent() : Value(urlEnc),
      noteEnc: noteEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(noteEnc),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory VaultItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultItem(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      titleEnc: serializer.fromJson<String>(json['titleEnc']),
      usernameEnc: serializer.fromJson<String?>(json['usernameEnc']),
      passwordEnc: serializer.fromJson<String?>(json['passwordEnc']),
      urlEnc: serializer.fromJson<String?>(json['urlEnc']),
      noteEnc: serializer.fromJson<String?>(json['noteEnc']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'titleEnc': serializer.toJson<String>(titleEnc),
      'usernameEnc': serializer.toJson<String?>(usernameEnc),
      'passwordEnc': serializer.toJson<String?>(passwordEnc),
      'urlEnc': serializer.toJson<String?>(urlEnc),
      'noteEnc': serializer.toJson<String?>(noteEnc),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  VaultItem copyWith(
          {int? id,
          String? uuid,
          String? titleEnc,
          Value<String?> usernameEnc = const Value.absent(),
          Value<String?> passwordEnc = const Value.absent(),
          Value<String?> urlEnc = const Value.absent(),
          Value<String?> noteEnc = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      VaultItem(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        titleEnc: titleEnc ?? this.titleEnc,
        usernameEnc: usernameEnc.present ? usernameEnc.value : this.usernameEnc,
        passwordEnc: passwordEnc.present ? passwordEnc.value : this.passwordEnc,
        urlEnc: urlEnc.present ? urlEnc.value : this.urlEnc,
        noteEnc: noteEnc.present ? noteEnc.value : this.noteEnc,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  VaultItem copyWithCompanion(VaultItemsCompanion data) {
    return VaultItem(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      titleEnc: data.titleEnc.present ? data.titleEnc.value : this.titleEnc,
      usernameEnc:
          data.usernameEnc.present ? data.usernameEnc.value : this.usernameEnc,
      passwordEnc:
          data.passwordEnc.present ? data.passwordEnc.value : this.passwordEnc,
      urlEnc: data.urlEnc.present ? data.urlEnc.value : this.urlEnc,
      noteEnc: data.noteEnc.present ? data.noteEnc.value : this.noteEnc,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultItem(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('titleEnc: $titleEnc, ')
          ..write('usernameEnc: $usernameEnc, ')
          ..write('passwordEnc: $passwordEnc, ')
          ..write('urlEnc: $urlEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, titleEnc, usernameEnc, passwordEnc,
      urlEnc, noteEnc, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultItem &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.titleEnc == this.titleEnc &&
          other.usernameEnc == this.usernameEnc &&
          other.passwordEnc == this.passwordEnc &&
          other.urlEnc == this.urlEnc &&
          other.noteEnc == this.noteEnc &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class VaultItemsCompanion extends UpdateCompanion<VaultItem> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> titleEnc;
  final Value<String?> usernameEnc;
  final Value<String?> passwordEnc;
  final Value<String?> urlEnc;
  final Value<String?> noteEnc;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const VaultItemsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.titleEnc = const Value.absent(),
    this.usernameEnc = const Value.absent(),
    this.passwordEnc = const Value.absent(),
    this.urlEnc = const Value.absent(),
    this.noteEnc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  VaultItemsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String titleEnc,
    this.usernameEnc = const Value.absent(),
    this.passwordEnc = const Value.absent(),
    this.urlEnc = const Value.absent(),
    this.noteEnc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : uuid = Value(uuid),
        titleEnc = Value(titleEnc);
  static Insertable<VaultItem> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? titleEnc,
    Expression<String>? usernameEnc,
    Expression<String>? passwordEnc,
    Expression<String>? urlEnc,
    Expression<String>? noteEnc,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (titleEnc != null) 'title_enc': titleEnc,
      if (usernameEnc != null) 'username_enc': usernameEnc,
      if (passwordEnc != null) 'password_enc': passwordEnc,
      if (urlEnc != null) 'url_enc': urlEnc,
      if (noteEnc != null) 'note_enc': noteEnc,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  VaultItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? titleEnc,
      Value<String?>? usernameEnc,
      Value<String?>? passwordEnc,
      Value<String?>? urlEnc,
      Value<String?>? noteEnc,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt}) {
    return VaultItemsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      titleEnc: titleEnc ?? this.titleEnc,
      usernameEnc: usernameEnc ?? this.usernameEnc,
      passwordEnc: passwordEnc ?? this.passwordEnc,
      urlEnc: urlEnc ?? this.urlEnc,
      noteEnc: noteEnc ?? this.noteEnc,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (titleEnc.present) {
      map['title_enc'] = Variable<String>(titleEnc.value);
    }
    if (usernameEnc.present) {
      map['username_enc'] = Variable<String>(usernameEnc.value);
    }
    if (passwordEnc.present) {
      map['password_enc'] = Variable<String>(passwordEnc.value);
    }
    if (urlEnc.present) {
      map['url_enc'] = Variable<String>(urlEnc.value);
    }
    if (noteEnc.present) {
      map['note_enc'] = Variable<String>(noteEnc.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultItemsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('titleEnc: $titleEnc, ')
          ..write('usernameEnc: $usernameEnc, ')
          ..write('passwordEnc: $passwordEnc, ')
          ..write('urlEnc: $urlEnc, ')
          ..write('noteEnc: $noteEnc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  _$AppDatabase.connect(DatabaseConnection c) : super.connect(c);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $VaultItemsTable vaultItems = $VaultItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notes, vaultItems];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String uuid,
  Value<String> title,
  Value<String> contentMd,
  Value<String> tagsJson,
  Value<bool> isEncrypted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> title,
  Value<String> contentMd,
  Value<String> tagsJson,
  Value<bool> isEncrypted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> contentMd = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            uuid: uuid,
            title: title,
            contentMd: contentMd,
            tagsJson: tagsJson,
            isEncrypted: isEncrypted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            Value<String> title = const Value.absent(),
            Value<String> contentMd = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              NotesCompanion.insert(
            id: id,
            uuid: uuid,
            title: title,
            contentMd: contentMd,
            tagsJson: tagsJson,
            isEncrypted: isEncrypted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()>;
typedef $$VaultItemsTableCreateCompanionBuilder = VaultItemsCompanion Function({
  Value<int> id,
  required String uuid,
  required String titleEnc,
  Value<String?> usernameEnc,
  Value<String?> passwordEnc,
  Value<String?> urlEnc,
  Value<String?> noteEnc,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});
typedef $$VaultItemsTableUpdateCompanionBuilder = VaultItemsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> titleEnc,
  Value<String?> usernameEnc,
  Value<String?> passwordEnc,
  Value<String?> urlEnc,
  Value<String?> noteEnc,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
});

class $$VaultItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleEnc => $composableBuilder(
      column: $table.titleEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usernameEnc => $composableBuilder(
      column: $table.usernameEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordEnc => $composableBuilder(
      column: $table.passwordEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get urlEnc => $composableBuilder(
      column: $table.urlEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteEnc => $composableBuilder(
      column: $table.noteEnc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$VaultItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleEnc => $composableBuilder(
      column: $table.titleEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usernameEnc => $composableBuilder(
      column: $table.usernameEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordEnc => $composableBuilder(
      column: $table.passwordEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get urlEnc => $composableBuilder(
      column: $table.urlEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteEnc => $composableBuilder(
      column: $table.noteEnc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$VaultItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultItemsTable> {
  $$VaultItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get titleEnc =>
      $composableBuilder(column: $table.titleEnc, builder: (column) => column);

  GeneratedColumn<String> get usernameEnc => $composableBuilder(
      column: $table.usernameEnc, builder: (column) => column);

  GeneratedColumn<String> get passwordEnc => $composableBuilder(
      column: $table.passwordEnc, builder: (column) => column);

  GeneratedColumn<String> get urlEnc =>
      $composableBuilder(column: $table.urlEnc, builder: (column) => column);

  GeneratedColumn<String> get noteEnc =>
      $composableBuilder(column: $table.noteEnc, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$VaultItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VaultItemsTable,
    VaultItem,
    $$VaultItemsTableFilterComposer,
    $$VaultItemsTableOrderingComposer,
    $$VaultItemsTableAnnotationComposer,
    $$VaultItemsTableCreateCompanionBuilder,
    $$VaultItemsTableUpdateCompanionBuilder,
    (VaultItem, BaseReferences<_$AppDatabase, $VaultItemsTable, VaultItem>),
    VaultItem,
    PrefetchHooks Function()> {
  $$VaultItemsTableTableManager(_$AppDatabase db, $VaultItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> titleEnc = const Value.absent(),
            Value<String?> usernameEnc = const Value.absent(),
            Value<String?> passwordEnc = const Value.absent(),
            Value<String?> urlEnc = const Value.absent(),
            Value<String?> noteEnc = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              VaultItemsCompanion(
            id: id,
            uuid: uuid,
            titleEnc: titleEnc,
            usernameEnc: usernameEnc,
            passwordEnc: passwordEnc,
            urlEnc: urlEnc,
            noteEnc: noteEnc,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String titleEnc,
            Value<String?> usernameEnc = const Value.absent(),
            Value<String?> passwordEnc = const Value.absent(),
            Value<String?> urlEnc = const Value.absent(),
            Value<String?> noteEnc = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              VaultItemsCompanion.insert(
            id: id,
            uuid: uuid,
            titleEnc: titleEnc,
            usernameEnc: usernameEnc,
            passwordEnc: passwordEnc,
            urlEnc: urlEnc,
            noteEnc: noteEnc,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VaultItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VaultItemsTable,
    VaultItem,
    $$VaultItemsTableFilterComposer,
    $$VaultItemsTableOrderingComposer,
    $$VaultItemsTableAnnotationComposer,
    $$VaultItemsTableCreateCompanionBuilder,
    $$VaultItemsTableUpdateCompanionBuilder,
    (VaultItem, BaseReferences<_$AppDatabase, $VaultItemsTable, VaultItem>),
    VaultItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$VaultItemsTableTableManager get vaultItems =>
      $$VaultItemsTableTableManager(_db, _db.vaultItems);
}
