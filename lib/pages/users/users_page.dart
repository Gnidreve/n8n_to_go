import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/error_view.dart';
import 'user_create_page.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = true;
  Object? _error;
  List<dynamic> _items = [];
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(
      () => setState(() => _search = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredItems {
    if (_search.isEmpty) return _items;
    return _items.where((rawItem) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final firstName = (item['firstName'] as String? ?? '').toLowerCase();
      final lastName = (item['lastName'] as String? ?? '').toLowerCase();
      final email = (item['email'] as String? ?? '').toLowerCase();
      return firstName.contains(_search) ||
          lastName.contains(_search) ||
          email.contains(_search);
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await users.getAll(limit: 100);
      if (!mounted) return;
      setState(() {
        _items = response['data'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Users'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              final reload = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const UserCreatePage()),
              );
              if (reload == true) await _fetch();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorView(error: _error!)
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.isEmpty ? 2 : _filteredItems.length + 1,
                    separatorBuilder: (_, index) =>
                        index == 0 ? const SizedBox(height: 16) : const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ShadInput(
                          controller: _searchController,
                          placeholder: const Text('Search users'),
                          leading: const Icon(LucideIcons.search),
                        );
                      }
                      if (_filteredItems.isEmpty) return const Text('No users');
                      final item = Map<String, dynamic>.from(
                        _filteredItems[index - 1] as Map,
                      );
                      final firstName = item['firstName'] as String? ?? '';
                      final lastName = item['lastName'] as String? ?? '';
                      final fullName = [firstName, lastName]
                          .where((p) => p.trim().isNotEmpty)
                          .join(' ');
                      final email = item['email'] as String? ?? '—';
                      final role = item['role'] as String? ?? '';
                      final displayName =
                          fullName.isNotEmpty ? fullName : email;

                      return _UserCard(
                        displayName: displayName,
                        email: email,
                        role: role,
                        onTap: () async {
                          final reload =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => UserDetailPage(
                                userId: '${item['id'] ?? ''}',
                                initialUser: item,
                              ),
                            ),
                          );
                          if (reload == true) await _fetch();
                        },
                      );
                    },
                  ),
                ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.displayName,
    required this.email,
    required this.role,
    required this.onTap,
  });

  final String displayName;
  final String email;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: theme.radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              _UserRoleIcon(role: role),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRoleIcon extends StatelessWidget {
  const _UserRoleIcon({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    if (role.isNotEmpty) {
      final assetPath = 'lib/assets/users/$role.svg';
      return SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          ShadTheme.of(context).colorScheme.foreground,
          BlendMode.srcIn,
        ),
        placeholderBuilder: (_) => const _FallbackIcon(),
      );
    }
    return const _FallbackIcon();
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.userRound,
      size: 20,
      color: ShadTheme.of(context).colorScheme.foreground,
    );
  }
}
