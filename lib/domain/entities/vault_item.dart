import '../../../core/crypto/crypto_service.dart';
import '../../../core/utils/result.dart';

/// VaultItem entity representing a password vault entry (decrypted)
class VaultItem {
  final String uuid;
  final String title;
  final String? username;
  final String? password;
  final String? url;
  final String? note;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const VaultItem({
    required this.uuid,
    required this.title,
    this.username,
    this.password,
    this.url,
    this.note,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Encrypt all fields using the provided crypto service and data key
  Future<Result<VaultItemEncrypted, String>> encrypt(
    CryptoService crypto,
    List<int> dataKey,
  ) async {
    // Encrypt title (required field)
    final titleResult = await crypto.encryptString(
      plaintext: title,
      keyBytes: dataKey,
    );
    if (titleResult.isErr) {
      return Err('Failed to encrypt title: ${titleResult.error}');
    }

    // Encrypt optional fields
    String? usernameEnc;
    if (username != null) {
      final result = await crypto.encryptString(
        plaintext: username!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to encrypt username: ${result.error}');
      }
      usernameEnc = result.value;
    }

    String? passwordEnc;
    if (password != null) {
      final result = await crypto.encryptString(
        plaintext: password!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to encrypt password: ${result.error}');
      }
      passwordEnc = result.value;
    }

    String? urlEnc;
    if (url != null) {
      final result = await crypto.encryptString(
        plaintext: url!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to encrypt url: ${result.error}');
      }
      urlEnc = result.value;
    }

    String? noteEnc;
    if (note != null) {
      final result = await crypto.encryptString(
        plaintext: note!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to encrypt note: ${result.error}');
      }
      noteEnc = result.value;
    }

    return Ok(VaultItemEncrypted(
      uuid: uuid,
      titleEnc: titleResult.value,
      usernameEnc: usernameEnc,
      passwordEnc: passwordEnc,
      urlEnc: urlEnc,
      noteEnc: noteEnc,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    ));
  }

  /// Copy with modifications
  VaultItem copyWith({
    String? uuid,
    String? title,
    String? username,
    String? password,
    String? url,
    String? note,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return VaultItem(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultItem &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;
}

/// VaultItemEncrypted entity representing encrypted vault data
class VaultItemEncrypted {
  final String uuid;
  final String titleEnc;
  final String? usernameEnc;
  final String? passwordEnc;
  final String? urlEnc;
  final String? noteEnc;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const VaultItemEncrypted({
    required this.uuid,
    required this.titleEnc,
    this.usernameEnc,
    this.passwordEnc,
    this.urlEnc,
    this.noteEnc,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Decrypt all fields using the provided crypto service and data key
  Future<Result<VaultItem, String>> decrypt(
    CryptoService crypto,
    List<int> dataKey,
  ) async {
    // Decrypt title (required field)
    final titleResult = await crypto.decryptString(
      cipherAll: titleEnc,
      keyBytes: dataKey,
    );
    if (titleResult.isErr) {
      return Err('Failed to decrypt title: ${titleResult.error}');
    }

    // Decrypt optional fields
    String? username;
    if (usernameEnc != null) {
      final result = await crypto.decryptString(
        cipherAll: usernameEnc!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to decrypt username: ${result.error}');
      }
      username = result.value;
    }

    String? password;
    if (passwordEnc != null) {
      final result = await crypto.decryptString(
        cipherAll: passwordEnc!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to decrypt password: ${result.error}');
      }
      password = result.value;
    }

    String? url;
    if (urlEnc != null) {
      final result = await crypto.decryptString(
        cipherAll: urlEnc!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to decrypt url: ${result.error}');
      }
      url = result.value;
    }

    String? note;
    if (noteEnc != null) {
      final result = await crypto.decryptString(
        cipherAll: noteEnc!,
        keyBytes: dataKey,
      );
      if (result.isErr) {
        return Err('Failed to decrypt note: ${result.error}');
      }
      note = result.value;
    }

    return Ok(VaultItem(
      uuid: uuid,
      title: titleResult.value,
      username: username,
      password: password,
      url: url,
      note: note,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    ));
  }

  /// Convert to JSON for storage and synchronization
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'titleEnc': titleEnc,
      'usernameEnc': usernameEnc,
      'passwordEnc': passwordEnc,
      'urlEnc': urlEnc,
      'noteEnc': noteEnc,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory VaultItemEncrypted.fromJson(Map<String, dynamic> json) {
    return VaultItemEncrypted(
      uuid: json['uuid'] as String,
      titleEnc: json['titleEnc'] as String,
      usernameEnc: json['usernameEnc'] as String?,
      passwordEnc: json['passwordEnc'] as String?,
      urlEnc: json['urlEnc'] as String?,
      noteEnc: json['noteEnc'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}
