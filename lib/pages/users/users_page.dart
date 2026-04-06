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
                      final item = Map<String, dynamic>.from(_items[index] as Map);
                      final email = item['email'] as String? ?? 'User';
                      final fullName = [
                        item['firstName'],
                        item['lastName'],
                      ]
                          .whereType<String>()
                          .where((part) => part.trim().isNotEmpty)
                          .join(' ');
                      final subtitle = fullName.isEmpty
                          ? (item['role'] as String? ?? '—')
                          : '$fullName | ${item['role'] ?? '—'}';

                      return ShadCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(LucideIcons.userRound),
                          title: Text(email),
                          subtitle: Text(subtitle),
                          trailing: const Icon(LucideIcons.chevronRight, size: 18),
                          onTap: () async {
                            final reload = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => UserDetailPage(
                                  userId: '${item['id'] ?? ''}',
                                  initialUser: item,
                                ),
                              ),
                            );
                            if (reload == true) {
                              await _fetch();
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
