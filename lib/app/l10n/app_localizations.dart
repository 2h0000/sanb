import 'package:flutter/material.dart';

/// App localizations for internationalization support
/// 
/// This is a basic implementation that can be extended with more languages
/// and integrated with the intl package for full i18n support.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('zh', ''), // Chinese
  ];

  // Common strings
  String get appName => _localizedStrings['app_name'] ?? 'Encrypted Notebook';
  String get cancel => _localizedStrings['cancel'] ?? 'Cancel';
  String get save => _localizedStrings['save'] ?? 'Save';
  String get delete => _localizedStrings['delete'] ?? 'Delete';
  String get edit => _localizedStrings['edit'] ?? 'Edit';
  String get search => _localizedStrings['search'] ?? 'Search';
  String get settings => _localizedStrings['settings'] ?? 'Settings';
  
  // Notes
  String get notes => _localizedStrings['notes'] ?? 'Notes';
  String get newNote => _localizedStrings['new_note'] ?? 'New Note';
  String get noteTitle => _localizedStrings['note_title'] ?? 'Title';
  String get noteContent => _localizedStrings['note_content'] ?? 'Content';
  
  // Vault
  String get vault => _localizedStrings['vault'] ?? 'Vault';
  String get unlockVault => _localizedStrings['unlock_vault'] ?? 'Unlock Vault';
  String get masterPassword => _localizedStrings['master_password'] ?? 'Master Password';
  
  // Auth
  String get signIn => _localizedStrings['sign_in'] ?? 'Sign In';
  String get signOut => _localizedStrings['sign_out'] ?? 'Sign Out';
  String get email => _localizedStrings['email'] ?? 'Email';
  String get password => _localizedStrings['password'] ?? 'Password';

  Map<String, String> get _localizedStrings {
    switch (locale.languageCode) {
      case 'zh':
        return _zhStrings;
      case 'en':
      default:
        return _enStrings;
    }
  }

  static const Map<String, String> _enStrings = {
    'app_name': 'Encrypted Notebook',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'settings': 'Settings',
    'notes': 'Notes',
    'new_note': 'New Note',
    'note_title': 'Title',
    'note_content': 'Content',
    'vault': 'Vault',
    'unlock_vault': 'Unlock Vault',
    'master_password': 'Master Password',
    'sign_in': 'Sign In',
    'sign_out': 'Sign Out',
    'email': 'Email',
    'password': 'Password',
  };

  static const Map<String, String> _zhStrings = {
    'app_name': '加密笔记本',
    'cancel': '取消',
    'save': '保存',
    'delete': '删除',
    'edit': '编辑',
    'search': '搜索',
    'settings': '设置',
    'notes': '笔记',
    'new_note': '新建笔记',
    'note_title': '标题',
    'note_content': '内容',
    'vault': '密码库',
    'unlock_vault': '解锁密码库',
    'master_password': '主密码',
    'sign_in': '登录',
    'sign_out': '退出',
    'email': '邮箱',
    'password': '密码',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
