import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/error_view.dart';
import 'data_table_create_page.dart';
import 'data_table_detail_page.dart';
class DataTablesPage extends StatefulWidget {
  const DataTablesPage({super.key});

  @override
  State<DataTablesPage> createState() => _DataTablesPageState();
}

class _DataTablesPageState extends State<DataTablesPage> {
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
      final name = (Map<String, dynamic>.from(rawItem as Map)['name'] as String? ?? '').toLowerCase();
      return name.contains(_search);
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await dataTables.getAll();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = _extractTables(res);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e; });
    }
  }

  List<Map<String, dynamic>> _extractTables(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }
    if (response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (response.containsKey('id') || response.containsKey('name')) {
      return [response];
    }
    return const [];
  }

  int _columnCount(Map<String, dynamic> item) {
    final explicitCount = item['columnCount'] ?? item['columnsCount'];
    if (explicitCount is num) return explicitCount.toInt();
    final columns = item['columns'];
    if (columns is List) return columns.length;
    return 0;
  }

  int _rowCount(Map<String, dynamic> item) {
    final explicitCount = item['rowCount'] ?? item['rowsCount'];
    if (explicitCount is num) return explicitCount.toInt();
    final rows = item['rows'] ?? item['data'] ?? item['items'];
    if (rows is List) return rows.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Data Tables'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              final reload = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const DataTableCreatePage(),
                ),
              );
              if (reload == true) {
                await _fetch();
              }
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
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return ShadInput(
                        controller: _searchController,
                        placeholder: const Text('Search data tables'),
                        leading: const Icon(LucideIcons.search),
                      );
                    }
                    if (_filteredItems.isEmpty) return const Text('No data tables');
                    final item = Map<String, dynamic>.from(_filteredItems[i - 1] as Map);
                    final name = item['name'] as String? ?? 'Data Table';
                    final rowCount = _rowCount(item);
                    final columnCount = _columnCount(item);

                    return InkWell(
                      borderRadius: ShadTheme.of(context).radius,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DataTableDetailPage(
                            tableId: '${item['id'] ?? ''}',
                            initialTable: item,
                          ),
                        ),
                      ),
                      child: ShadCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.table,
                              size: 18,
                              color: ShadTheme.of(context).colorScheme.mutedForeground,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${rowCount > 0 ? rowCount : '—'} rows | $columnCount columns',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ShadTheme.of(context)
                                          .colorScheme
                                          .mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
