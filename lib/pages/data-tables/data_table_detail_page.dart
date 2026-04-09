import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import 'data_table_row_form_page.dart';

class DataTableDetailPage extends StatefulWidget {
  const DataTableDetailPage({
    super.key,
    required this.tableId,
    required this.initialTable,
  });

  final String tableId;
  final Map<String, dynamic> initialTable;

  @override
  State<DataTableDetailPage> createState() => _DataTableDetailPageState();
}

class _DataTableDetailPageState extends State<DataTableDetailPage> {
  late Map<String, dynamic> _table;
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _table = widget.initialTable;
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.tableId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        dataTables.get(widget.tableId),
        dataTables.rows.getAll(
          widget.tableId,
          limit: 100,
        ),
      ]);
      if (!mounted) return;
      final table = _extractTable(results[0]);
      setState(() {
        _table = table;
        _rows = (results[1]['data'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _extractTable(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return response;
  }

  String get _name => _table['name'] as String? ?? 'Data Table';

  List<Map<String, dynamic>> get _columns {
    final rawColumns = _table['columns'];
    if (rawColumns is! List) return const [];
    return rawColumns
        .whereType<Map>()
        .map((column) => Map<String, dynamic>.from(column))
        .toList()
      ..sort((a, b) {
        final aIndex = a['index'] as num? ?? 0;
        final bIndex = b['index'] as num? ?? 0;
        return aIndex.compareTo(bIndex);
      });
  }

  int get _columnCount {
    final explicitCount = _table['columnCount'] ?? _table['columnsCount'];
    if (explicitCount is num) return explicitCount.toInt();
    return _columns.length;
  }

  int get _rowCount {
    final explicitCount = _table['rowCount'] ?? _table['rowsCount'];
    if (explicitCount is num) return explicitCount.toInt();
    return _rows.length;
  }

  List<String> get _columnLabels {
    if (_columns.isEmpty && _rows.isNotEmpty) {
      return _rows.first.keys
          .where((key) => key != 'id' && key != 'createdAt' && key != 'updatedAt')
          .toList();
    }

    return _columns.map((column) {
      return column['name'] as String? ??
          column['displayName'] as String? ??
          column['id'] as String? ??
          'Column';
    }).toList();
  }

  List<List<String>> get _tableRows {
    final labels = _columnLabels;
    return _rows.map((row) {
      return labels.map((label) {
        final direct = row[label];
        if (direct != null) return '$direct';

        final match = _columns.cast<Map<String, dynamic>?>().firstWhere(
              (column) =>
                  column?['name'] == label ||
                  column?['displayName'] == label ||
                  column?['id'] == label,
              orElse: () => null,
            );

        if (match != null) {
          final key = match['id'] ?? match['name'] ?? match['displayName'];
          final value = row[key];
          if (value != null) return '$value';
        }

        if (row.containsKey(label)) return '${row[label]}';
        return '—';
      }).toList();
    }).toList();
  }

  String _columnLabel(Map<String, dynamic> column) {
    return column['name'] as String? ??
        column['displayName'] as String? ??
        column['id'] as String? ??
        'Column';
  }

  String _columnKey(Map<String, dynamic> column) {
    return column['id'] as String? ??
        column['name'] as String? ??
        column['displayName'] as String? ??
        'column';
  }

  List<Map<String, dynamic>> get _resolvedColumns {
    if (_columns.isNotEmpty) return _columns;
    if (_rows.isEmpty) return const [];

    return _rows.first.keys
        .where((key) => key != 'id' && key != 'createdAt' && key != 'updatedAt')
        .map(
          (key) => <String, dynamic>{
            'id': key,
            'name': key,
          },
        )
        .toList();
  }

  Map<String, dynamic> _resolvedRow(Map<String, dynamic> row) {
    final result = <String, dynamic>{};
    for (final column in _resolvedColumns) {
      final label = _columnLabel(column);
      final key = _columnKey(column);
      result[key] = row[key] ?? row[label];
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(_name),
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error'),
        ),
      );
    }

    final labels = _columnLabels;
    final rows = _tableRows;
    final sourceRows = _rows;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_name),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _resolvedColumns.isEmpty
                ? null
                : () async {
                    final reload = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => DataTableRowFormPage(
                          title: 'Create row',
                          dataTableId: widget.tableId,
                          columns: _resolvedColumns,
                        ),
                      ),
                    );
                    if (reload == true) await _fetch();
                  },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$_rowCount rows | $_columnCount columns',
                style: TextStyle(
                  fontSize: 13,
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
              ),
            ),
            if (labels.isEmpty)
              const ShadCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No columns available'),
                  ),
                ),
              )
            else
              ShadCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.sizeOf(context).width - 64,
                    ),
                    child: _DataTable(
                      labels: labels,
                      rows: rows,
                      sourceRows: sourceRows,
                      resolvedColumns: _resolvedColumns,
                      tableId: widget.tableId,
                      resolveRow: _resolvedRow,
                      onReload: _fetch,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({
    required this.labels,
    required this.rows,
    required this.sourceRows,
    required this.resolvedColumns,
    required this.tableId,
    required this.resolveRow,
    required this.onReload,
  });

  final List<String> labels;
  final List<List<String>> rows;
  final List<Map<String, dynamic>> sourceRows;
  final List<Map<String, dynamic>> resolvedColumns;
  final String tableId;
  final Map<String, dynamic> Function(Map<String, dynamic>) resolveRow;
  final Future<void> Function() onReload;

  static const _cellPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final borderColor = theme.colorScheme.border;

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(color: borderColor, width: 0.5),
        bottom: BorderSide(color: borderColor, width: 0.5),
      ),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          children: labels
              .map(
                (label) => Padding(
                  padding: _cellPadding,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Empty state
        if (rows.isEmpty)
          TableRow(
            children: labels
                .map(
                  (_) => Padding(
                    padding: _cellPadding,
                    child: const Text('—', style: TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
          ),
        // Data rows
        ...rows.asMap().entries.map(
          (entry) => TableRow(
            children: entry.value
                .map(
                  (value) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final reload = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => DataTableRowFormPage(
                            title: 'Edit row',
                            dataTableId: tableId,
                            columns: resolvedColumns,
                            initialRow: resolveRow(sourceRows[entry.key]),
                          ),
                        ),
                      );
                      if (reload == true) await onReload();
                    },
                    child: Padding(
                      padding: _cellPadding,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
