import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../CREDENTIAL_TYPES.dart';
import '../../widgets/credential_icon.dart';
import '../../widgets/filter_select.dart';
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
  Set<String> _selectedTypes = <String>{};

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

  List<FilterSelectOption> get _filterOptions {
    final seen = <String>{};
    final options = <FilterSelectOption>[];
    for (final rawItem in _items) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final type = item['type'] as String?;
      if (type == null || type.isEmpty || !seen.add(type)) continue;
      final label = credentialTypes.entries
          .where((entry) => entry.value == type)
          .map((entry) => entry.key)
          .firstOrNull;
      options.add(
        FilterSelectOption(
          value: type,
          label: label ?? type,
          leading: SizedBox.square(
            dimension: 18,
            child: CredentialIcon(type: type),
          ),
        ),
      );
    }
    return options;
  }

  List<dynamic> get _filteredItems {
    if (_selectedTypes.isEmpty) return _items;
    return _items.where((rawItem) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final type = item['type'] as String?;
      return type != null && _selectedTypes.contains(type);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

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
                      itemCount: filteredItems.isEmpty ? 2 : filteredItems.length + 1,
                      separatorBuilder: (_, index) =>
                          index == 0 ? const SizedBox(height: 12) : const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: FilterSelect(
                              options: _filterOptions,
                              selectedValues: _selectedTypes,
                              onChanged: (values) {
                                setState(() {
                                  _selectedTypes = values;
                                });
                              },
                              searchPlaceholder: 'Search credential types',
                              emptyLabel: 'No credential types found',
                            ),
                          );
                        }
                        if (filteredItems.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No credentials'),
                          );
                        }
                        final item = filteredItems[i - 1] as Map<String, dynamic>;
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
