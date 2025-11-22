import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/vault_providers.dart';

/// Screen for creating or editing a vault item
class VaultEditScreen extends ConsumerStatefulWidget {
  final String? itemId;

  const VaultEditScreen({super.key, this.itemId});

  @override
  ConsumerState<VaultEditScreen> createState() => _VaultEditScreenState();
}

class _VaultEditScreenState extends ConsumerState<VaultEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoadingItem = false;

  bool get _isNewItem => widget.itemId == null || widget.itemId == 'new';

  @override
  void initState() {
    super.initState();
    if (!_isNewItem) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoadingItem = true;
    });

    final vaultService = ref.read(vaultServiceProvider);
    if (vaultService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault is locked')),
        );
        context.go('/vault');
      }
      return;
    }

    final result = await vaultService.getVaultItem(widget.itemId!);

    if (!mounted) return;

    result.when(
      ok: (item) {
        _titleController.text = item.title;
        _usernameController.text = item.username ?? '';
        _passwordController.text = item.password ?? '';
        _urlController.text = item.url ?? '';
        _noteController.text = item.note ?? '';
        setState(() {
          _isLoadingItem = false;
        });
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item: $error')),
        );
        context.go('/vault');
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final vaultService = ref.read(vaultServiceProvider);
    if (vaultService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault is locked')),
        );
      }
      return;
    }

    final title = _titleController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final url = _urlController.text.trim();
    final note = _noteController.text.trim();

    final result = _isNewItem
        ? await vaultService.createVaultItem(
            title: title,
            username: username.isEmpty ? null : username,
            password: password.isEmpty ? null : password,
            url: url.isEmpty ? null : url,
            note: note.isEmpty ? null : note,
          )
        : await vaultService.updateVaultItem(
            uuid: widget.itemId!,
            title: title,
            username: username.isEmpty ? null : username,
            password: password.isEmpty ? null : password,
            url: url.isEmpty ? null : url,
            note: note.isEmpty ? null : note,
          );

    if (!mounted) return;

    result.when(
      ok: (uuid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNewItem ? 'Item created' : 'Item updated'),
          ),
        );
        context.go('/vault');
      },
      error: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $error')),
        );
      },
    );
  }

  void _showPasswordGenerator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PasswordGeneratorSheet(
        onPasswordGenerated: (password) {
          _passwordController.text = password;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingItem) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isNewItem ? 'New Vault Item' : 'Edit Vault Item'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewItem ? 'New Vault Item' : 'Edit Vault Item'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveItem,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.password),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: _showPasswordGenerator,
                      tooltip: 'Generate Password',
                    ),
                  ],
                ),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordGeneratorSheet extends StatefulWidget {
  final Function(String) onPasswordGenerated;

  const _PasswordGeneratorSheet({required this.onPasswordGenerated});

  @override
  State<_PasswordGeneratorSheet> createState() =>
      _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends State<_PasswordGeneratorSheet> {
  int _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (_includeUppercase) chars += uppercase;
    if (_includeLowercase) chars += lowercase;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = '';
      });
      return;
    }

    final random = Random.secure();
    final password = List.generate(
      _length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    setState(() {
      _generatedPassword = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Generator',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _generatedPassword.isEmpty
                        ? 'Select at least one option'
                        : _generatedPassword,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generatePassword,
                  tooltip: 'Regenerate',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Length: $_length'),
          Slider(
            value: _length.toDouble(),
            min: 8,
            max: 32,
            divisions: 24,
            label: _length.toString(),
            onChanged: (value) {
              setState(() {
                _length = value.toInt();
              });
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Uppercase (A-Z)'),
            value: _includeUppercase,
            onChanged: (value) {
              setState(() {
                _includeUppercase = value ?? true;
              });
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Lowercase (a-z)'),
            value: _includeLowercase,
            onChanged: (value) {
              setState(() {
                _includeLowercase = value ?? true;
              });
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Numbers (0-9)'),
            value: _includeNumbers,
            onChanged: (value) {
              setState(() {
                _includeNumbers = value ?? true;
              });
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Symbols (!@#\$...)'),
            value: _includeSymbols,
            onChanged: (value) {
              setState(() {
                _includeSymbols = value ?? true;
              });
              _generatePassword();
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _generatedPassword.isEmpty
                ? null
                : () {
                    widget.onPasswordGenerated(_generatedPassword);
                    Navigator.of(context).pop();
                  },
            child: const Text('Use This Password'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
