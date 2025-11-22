import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers_dev.dart';
import '../application/vault_providers_dev.dart';
import '../../auth/application/mock_auth_service.dart';

/// Development version of vault unlock screen without Firebase
class VaultUnlockScreenDev extends ConsumerStatefulWidget {
  const VaultUnlockScreenDev({super.key});

  @override
  ConsumerState<VaultUnlockScreenDev> createState() => _VaultUnlockScreenDevState();
}

class _VaultUnlockScreenDevState extends ConsumerState<VaultUnlockScreenDev> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    final vaultUnlockService = ref.read(vaultUnlockServiceProvider);
    final masterPassword = _passwordController.text;

    final result = await vaultUnlockService.unlockVault(
      uid: user.uid,
      masterPassword: masterPassword,
    );

    if (!mounted) return;

    result.when(
      ok: (dataKey) {
        // Store data key in provider
        ref.read(dataKeyProvider.notifier).state = dataKey;
        
        setState(() {
          _isLoading = false;
        });
        
        // Show success message and navigate to vault list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vault unlocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to vault list (use push to keep back button)
        context.push('/vault');
      },
      error: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    final vaultUnlockService = ref.read(vaultUnlockServiceProvider);
    final masterPassword = _passwordController.text;

    final result = await vaultUnlockService.setupVault(
      uid: user.uid,
      masterPassword: masterPassword,
    );

    if (!mounted) return;

    result.when(
      ok: (dataKey) {
        // Store data key in provider
        ref.read(dataKeyProvider.notifier).state = dataKey;
        
        setState(() {
          _isLoading = false;
        });
        
        // Show success message and navigate to vault list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vault setup successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to vault list (use push to keep back button)
        context.push('/vault');
      },
      error: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsSetupAsync = ref.watch(vaultNeedsSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
      ),
      body: needsSetupAsync.when(
        data: (needsSetup) => _buildForm(context, needsSetup),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool needsSetup) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dev Mode Banner
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.developer_mode, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dev Mode - Local Storage Only',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                needsSetup ? 'Set Up Master Password' : 'Unlock Vault',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                needsSetup
                    ? 'Create a strong master password to protect your vault'
                    : 'Enter your master password to access your vault',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (needsSetup && value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              if (needsSetup) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : (needsSetup ? _handleSetup : _handleUnlock),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(needsSetup ? 'Set Up Vault' : 'Unlock'),
              ),
              if (needsSetup) ...[
                const SizedBox(height: 16),
                Text(
                  '⚠️ Important: Remember your master password. It cannot be recovered if lost.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
