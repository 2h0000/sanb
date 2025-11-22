import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../application/vault_providers.dart';

/// Screen displaying the list of vault items
class VaultListScreen extends ConsumerStatefulWidget {
  const VaultListScreen({super.key});

  @override
  ConsumerState<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends ConsumerState<VaultListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _lockVault() {
    // Clear the data key to lock the vault
    ref.read(dataKeyProvider.notifier).state = null;
    // Router will redirect to unlock screen
  }

  @override
  Widget build(BuildContext context) {
    final vaultItemsAsync = ref.watch(vaultItemsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock Vault',
            onPressed: _lockVault,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vault items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Vault items list
          Expanded(
            child: vaultItemsAsync.when(
              data: (items) {
                // Filter items based on search query
                final filteredItems = _searchQuery.isEmpty
                    ? items
                    : items
                        .where((item) => item.title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.lock_open : Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No vault items yet'
                              : 'No items found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tap + to add your first item'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _VaultItemTile(
                      title: item.title,
                      username: item.username,
                      url: item.url,
                      onTap: () => context.push('/vault/${item.uuid}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading vault items'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vault/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VaultItemTile extends StatelessWidget {
  final String title;
  final String? username;
  final String? url;
  final VoidCallback onTap;

  const _VaultItemTile({
    required this.title,
    this.username,
    this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            _getIconForUrl(url),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: username != null
            ? Text(username!)
            : (url != null ? Text(url!, maxLines: 1, overflow: TextOverflow.ellipsis) : null),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _getIconForUrl(String? url) {
    if (url == null || url.isEmpty) {
      return Icons.key;
    }
    
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('github')) return Icons.code;
    if (lowerUrl.contains('google')) return Icons.g_mobiledata;
    if (lowerUrl.contains('facebook')) return Icons.facebook;
    if (lowerUrl.contains('twitter') || lowerUrl.contains('x.com')) return Icons.tag;
    if (lowerUrl.contains('linkedin')) return Icons.work;
    if (lowerUrl.contains('amazon')) return Icons.shopping_cart;
    if (lowerUrl.contains('netflix')) return Icons.movie;
    if (lowerUrl.contains('spotify')) return Icons.music_note;
    
    return Icons.language;
  }
}
