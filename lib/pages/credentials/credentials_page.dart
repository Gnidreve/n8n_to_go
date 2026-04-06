import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/credential_icon.dart';
import '../../widgets/dead_filter_select.dart';
import 'credential_detail_page.dart';
import 'credential_type_select_page.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await credentials.getAll(limit: 100);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = res['data'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Credentials'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              final reload = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const CredentialTypeSelectPage()),
              );
              if (reload == true) _fetch();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $_error',
                    style: TextStyle(
                      color: ShadTheme.of(context).colorScheme.destructive,
                    ),
                  ),
                )
              : ListView.separated(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      itemCount: _items.isEmpty ? 2 : _items.length + 1,
                      separatorBuilder: (_, index) =>
                          index == 0 ? const SizedBox(height: 12) : const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: DeadFilterSelect(),
                          );
                        }
                        if (_items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No credentials'),
                          );
                        }
                        final item = _items[i - 1] as Map<String, dynamic>;
                        final name = item['name'] as String? ?? '—';
                        final type = item['type'] as String?;
                        return ListTile(
                          leading: CredentialIcon(type: type),
                          title: Text(name),
                          trailing: const Icon(LucideIcons.chevronRight, size: 20),
                          onTap: () async {
                            final reload = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => CredentialDetailPage(credential: item),
                              ),
                            );
                            if (reload == true) _fetch();
                          },
                        );
                      },
                    ),
    );
  }
}
