import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
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
        _error = e.toString();
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
            onPressed: null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: ShadTheme.of(context).colorScheme.destructive,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.isEmpty ? 1 : _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (_items.isEmpty) return const Text('No users');
                      final item = Map<String, dynamic>.from(
                        _items[index] as Map,
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
