import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/date_time_formatter.dart';
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
      final name =
          (Map<String, dynamic>.from(rawItem as Map)['name'] as String? ?? '')
              .toLowerCase();
      return name.contains(_search);
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await dataTables.getAll();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = _extractTables(res);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
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

  String _formatTimeAgo(dynamic value) {
    final date = parseDateTime(value);
    if (date == null) return '—';

    final difference = DateTime.now().difference(date);
    if (difference.isNegative) return 'just now';

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }

    final weeks = (difference.inDays / 7).floor();
    if (difference.inDays < 30) {
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    final months = (difference.inDays / 30).floor();
    if (difference.inDays < 365) {
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    final years = (difference.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  String _metaTextFor(Map<String, dynamic> item) {
    final columnCount = _columnCount(item);
    final updatedAt = _formatTimeAgo(item['updatedAt']);

    return ['$columnCount columns', 'Last updated $updatedAt'].join(' | ');
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
                MaterialPageRoute(builder: (_) => const DataTableCreatePage()),
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
                  itemCount: _filteredItems.isEmpty
                      ? 2
                      : _filteredItems.length + 1,
                  separatorBuilder: (_, index) => index == 0
                      ? const SizedBox(height: 16)
                      : const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return ShadInput(
                        controller: _searchController,
                        placeholder: const Text('Search data tables'),
                        leading: const Icon(LucideIcons.search),
                      );
                    }
                    if (_filteredItems.isEmpty) {
                      return const Text('No data tables');
                    }
                    final item = Map<String, dynamic>.from(
                      _filteredItems[i - 1] as Map,
                    );
                    final name = item['name'] as String? ?? 'Data Table';
                    final theme = ShadTheme.of(context);

                    return ShadCard(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: theme.radius,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DataTableDetailPage(
                              tableId: '${item['id'] ?? ''}',
                              initialTable: item,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.database,
                                size: 20,
                                color: theme.colorScheme.foreground,
                              ),
                              const SizedBox(width: 14),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      _metaTextFor(item),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            theme.colorScheme.mutedForeground,
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
                  },
                ),
              ),
      ),
    );
  }
}
