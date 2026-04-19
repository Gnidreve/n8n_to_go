import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_toast.dart';
import 'data_table_column_detail_page.dart';
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
  bool _deleting = false;
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
        dataTables.rows.getAll(widget.tableId, limit: 100),
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
          .where(
            (key) => key != 'id' && key != 'createdAt' && key != 'updatedAt',
          )
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
        if (direct != null) return _displayCellValue(direct);

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
          if (value != null) return _displayCellValue(value);
        }

        if (row.containsKey(label)) return _displayCellValue(row[label]);
        return '—';
      }).toList();
    }).toList();
  }

  String _displayCellValue(dynamic value) {
    return '$value'
        .replaceAll('\r\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\t', ' ');
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
        .map((key) => <String, dynamic>{'id': key, 'name': key})
        .toList();
  }

  Future<void> _delete() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context, constraints) => ShadDialog.alert(
        constraints: constraints,
        title: const Text('Delete table?'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'This will permanently delete the table and all its data.',
          ),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await dataTables.delete(widget.tableId);
      if (!mounted) return;
      AppToast.success(context, 'Table deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  Future<void> _showColumnDialog(Map<String, dynamic> column) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DataTableColumnDetailPage(
          column: column,
          tableId: widget.tableId,
          allColumns: _resolvedColumns,
        ),
      ),
    );
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash2),
            onPressed: _deleting ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: labels.isEmpty
                    ? const ShadCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No columns available'),
                          ),
                        ),
                      )
                    : ShadCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _DataTable(
                                    labels: labels,
                                    rows: rows,
                                    sourceRows: sourceRows,
                                    resolvedColumns: _resolvedColumns,
                                    tableId: widget.tableId,
                                    viewportWidth:
                                        MediaQuery.sizeOf(context).width - 32,
                                    resolveRow: _resolvedRow,
                                    onReload: _fetch,
                                    onColumnTap: (column) =>
                                        _showColumnDialog(column),
                                  );
                                },
                              ),
                            ),
                            _AddRowButton(
                              enabled: _resolvedColumns.isNotEmpty,
                              onTap: _resolvedColumns.isEmpty
                                  ? null
                                  : () async {
                                      final reload = await Navigator.of(context)
                                          .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DataTableRowFormPage(
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
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _TableSummary(
                rowCount: _rowCount,
                columnCount: _columnCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Icon(
          LucideIcons.plus,
          size: 16,
          color: enabled
              ? theme.colorScheme.mutedForeground
              : theme.colorScheme.border,
        ),
      ),
    );
  }
}

class _ColumnTypeIcon extends StatelessWidget {
  const _ColumnTypeIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'number' => LucideIcons.hash,
      'boolean' => LucideIcons.squareCheck,
      _ => LucideIcons.type,
    };
    return Icon(
      icon,
      size: 13,
      color: ShadTheme.of(context).colorScheme.mutedForeground,
    );
  }
}

class _TableSummary extends StatelessWidget {
  const _TableSummary({required this.rowCount, required this.columnCount});

  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      color: ShadTheme.of(context).colorScheme.mutedForeground,
    );

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('$rowCount rows', style: style),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: style),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('$columnCount columns', style: style),
          ),
        ),
      ],
    );
  }
}

class _DataTable extends StatefulWidget {
  const _DataTable({
    required this.labels,
    required this.rows,
    required this.sourceRows,
    required this.resolvedColumns,
    required this.tableId,
    required this.viewportWidth,
    required this.resolveRow,
    required this.onReload,
    required this.onColumnTap,
  });

  final List<String> labels;
  final List<List<String>> rows;
  final List<Map<String, dynamic>> sourceRows;
  final List<Map<String, dynamic>> resolvedColumns;
  final String tableId;
  final double viewportWidth;
  final Map<String, dynamic> Function(Map<String, dynamic>) resolveRow;
  final Future<void> Function() onReload;
  final void Function(Map<String, dynamic>) onColumnTap;

  @override
  State<_DataTable> createState() => _DataTableState();
}

class _DataTableState extends State<_DataTable> {
  static const _cellPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const _headerIconSize = 13.0;
  static const _headerIconGap = 5.0;

  final ScrollController _headerHorizontalScrollController = ScrollController();
  final ScrollController _bodyHorizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyHorizontalScrollController.addListener(_syncHeaderScroll);
  }

  @override
  void dispose() {
    _bodyHorizontalScrollController.removeListener(_syncHeaderScroll);
    _headerHorizontalScrollController.dispose();
    _bodyHorizontalScrollController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (!_headerHorizontalScrollController.hasClients ||
        !_bodyHorizontalScrollController.hasClients) {
      return;
    }

    final offset = _bodyHorizontalScrollController.offset.clamp(
      0.0,
      _headerHorizontalScrollController.position.maxScrollExtent,
    );

    if (_headerHorizontalScrollController.offset == offset) {
      return;
    }

    _headerHorizontalScrollController.jumpTo(offset);
  }

  double _measureText(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  List<double> _columnWidths(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bodyStyle = const TextStyle(fontSize: 13);
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: theme.colorScheme.mutedForeground,
    );

    return widget.resolvedColumns.asMap().entries.map((entry) {
      final columnIndex = entry.key;
      final label = widget.labels.length > columnIndex
          ? widget.labels[columnIndex]
          : '';
      final values = widget.rows.isEmpty
          ? const ['—']
          : widget.rows.map(
              (row) => row.length > columnIndex ? row[columnIndex] : '—',
            );

      final widestValue = values.fold<double>(
        0,
        (currentMax, value) =>
            math.max(currentMax, _measureText(context, value, bodyStyle)),
      );

      final headerWidth =
          _headerIconSize +
          _headerIconGap +
          _measureText(context, label, headerStyle);

      return math.max(headerWidth, widestValue) + _cellPadding.horizontal;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final borderColor = theme.colorScheme.border;
    final columnWidths = _columnWidths(context);
    final totalTableWidth = columnWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    final effectiveWidth = math.max(widget.viewportWidth, totalTableWidth);
    final tableColumnWidths = <int, TableColumnWidth>{
      for (final entry in columnWidths.asMap().entries)
        entry.key: FixedColumnWidth(entry.value),
    };

    return Column(
      children: [
        SingleChildScrollView(
          controller: _headerHorizontalScrollController,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: effectiveWidth,
            child: Table(
              columnWidths: tableColumnWidths,
              border: TableBorder(bottom: BorderSide(color: borderColor)),
              children: [
                TableRow(
                  children: widget.resolvedColumns.asMap().entries.map((entry) {
                    final col = entry.value;
                    final label = widget.labels.length > entry.key
                        ? widget.labels[entry.key]
                        : '';
                    final type = (col['type'] as String? ?? 'string')
                        .toLowerCase();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onColumnTap(col),
                      child: Padding(
                        padding: _cellPadding,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ColumnTypeIcon(type: type),
                            const SizedBox(width: _headerIconGap),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _bodyHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Table(
                    columnWidths: tableColumnWidths,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: borderColor,
                        width: 0.5,
                      ),
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                    children: [
                      if (widget.rows.isEmpty)
                        TableRow(
                          children: widget.labels
                              .map(
                                (_) => Padding(
                                  padding: _cellPadding,
                                  child: const Text(
                                    '—',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ...widget.rows.asMap().entries.map(
                        (entry) => TableRow(
                          children: entry.value
                              .map(
                                (value) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final reload = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DataTableRowFormPage(
                                                  title: 'Edit row',
                                                  dataTableId: widget.tableId,
                                                  columns:
                                                      widget.resolvedColumns,
                                                  initialRow: widget.resolveRow(
                                                    widget.sourceRows[entry
                                                        .key],
                                                  ),
                                                ),
                                          ),
                                        );
                                    if (reload == true) {
                                      await widget.onReload();
                                    }
                                  },
                                  child: Padding(
                                    padding: _cellPadding,
                                    child: Text(
                                      value,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
