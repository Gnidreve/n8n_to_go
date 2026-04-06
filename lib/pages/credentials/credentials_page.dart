import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/credential_icon.dart';
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
              : _items.isEmpty
                  ? const Center(child: Text('No credentials'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = _items[i] as Map<String, dynamic>;
                        final name = item['name'] as String? ?? '—';
                        final type = item['type'] as String?;
                        return ListTile(
                          leading: CredentialIcon(type: type),
                          title: Text(name),
                          subtitle: type != null ? Text(type) : null,
                          trailing: const Icon(Icons.chevron_right, size: 20),
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
