import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import 'data_table_detail_page.dart';
class DataTablesPage extends StatefulWidget {
  const DataTablesPage({super.key});

  @override
  State<DataTablesPage> createState() => _DataTablesPageState();
}

class _DataTablesPageState extends State<DataTablesPage> {
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
      final res = await dataTables.getAll();
      final data = res['data'];
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = data is List<dynamic>
            ? data
            : res.isNotEmpty
                ? [res]
                : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.isEmpty ? 1 : _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (_items.isEmpty) return const Text('No data tables');
                    final item = Map<String, dynamic>.from(_items[i] as Map);
                    final name = item['name'] as String? ?? 'Data Table';
                    final rowCount = _rowCount(item);
                    final columnCount = _columnCount(item);

                    return InkWell(
                      borderRadius: ShadTheme.of(context).radius,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DataTableDetailPage(
                            tableId: item['id'] as String? ?? '',
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
                                    '$rowCount rows | $columnCount columns',
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
    );
  }
}
