/// Note entity representing a user's note
class Note {
  final String uuid;
  final String title;
  final String contentMd;
  final List<String> tags;
  final bool isEncrypted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Note({
    required this.uuid,
    required this.title,
    required this.contentMd,
    this.tags = const [],
    this.isEncrypted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Convert to JSON for synchronization
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'contentMd': contentMd,
      'tags': tags,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      contentMd: json['contentMd'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  /// Copy with modifications
  Note copyWith({
    String? uuid,
    String? title,
    String? contentMd,
    List<String>? tags,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Note(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      contentMd: contentMd ?? this.contentMd,
      tags: tags ?? this.tags,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          title == other.title &&
          contentMd == other.contentMd &&
          tags.length == other.tags.length &&
          isEncrypted == other.isEncrypted;

  @override
  int get hashCode => uuid.hashCode;
}
