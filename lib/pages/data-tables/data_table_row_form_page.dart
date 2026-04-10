import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';

class DataTableRowFormPage extends StatefulWidget {
  const DataTableRowFormPage({
    super.key,
    required this.title,
    required this.dataTableId,
    required this.columns,
    this.initialRow,
  });

  final String title;
  final String dataTableId;
  final List<Map<String, dynamic>> columns;
  final Map<String, dynamic>? initialRow;

  @override
  State<DataTableRowFormPage> createState() => _DataTableRowFormPageState();
}

class _DataTableRowFormPageState extends State<DataTableRowFormPage> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _boolValues;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{};
    _boolValues = <String, bool>{};

    for (final column in widget.columns) {
      final key = _columnKey(column);
      final value = _valueForColumn(column);
      if (_isBooleanColumn(column, value)) {
        _boolValues[key] = value == true;
      } else {
        _controllers[key] = TextEditingController(
          text: value == null || value == '—' ? '' : '$value',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  dynamic _valueForColumn(Map<String, dynamic> column) {
    final row = widget.initialRow;
    if (row == null) return null;

    final key = _columnKey(column);
    final label = _columnLabel(column);
    return row[key] ?? row[label];
  }

  bool _isBooleanColumn(Map<String, dynamic> column, dynamic value) {
    final rawType = (column['type'] ??
            column['dataType'] ??
            column['columnType'] ??
            '')
        .toString()
        .toLowerCase();
    return value is bool || rawType.contains('bool');
  }

  bool _isNumericColumn(Map<String, dynamic> column, dynamic value) {
    final rawType = (column['type'] ??
            column['dataType'] ??
            column['columnType'] ??
            '')
        .toString()
        .toLowerCase();
    return value is num ||
        rawType.contains('int') ||
        rawType.contains('number') ||
        rawType.contains('float') ||
        rawType.contains('double') ||
        rawType.contains('decimal');
  }

  dynamic _typedValueForColumn(Map<String, dynamic> column) {
    final key = _columnKey(column);
    final rawType = (column['type'] ??
            column['dataType'] ??
            column['columnType'] ??
            '')
        .toString()
        .toLowerCase();

    if (_boolValues.containsKey(key)) {
      return _boolValues[key] ?? false;
    }

    final text = _controllers[key]?.text.trim() ?? '';
    if (text.isEmpty) return '';

    if (rawType.contains('int')) {
      return int.tryParse(text) ?? text;
    }
    if (rawType.contains('number') ||
        rawType.contains('float') ||
        rawType.contains('double') ||
        rawType.contains('decimal')) {
      return num.tryParse(text) ?? text;
    }

    return text;
  }

  Map<String, dynamic> _payloadData() {
    return {
      for (final column in widget.columns)
        _columnLabel(column): _typedValueForColumn(column),
    };
  }

  Map<String, dynamic>? _buildUpdateFilter() {
    final initialRow = widget.initialRow;
    if (initialRow == null) return null;
    final rowId = initialRow['id'];
    if (rowId == null) return null;
    return {
      'type': 'and',
      'filters': [
        {
          'columnName': 'id',
          'condition': 'eq',
          'value': rowId,
        },
      ],
    };
  }

  Future<void> _delete() async {
    final filter = _buildUpdateFilter();
    if (widget.initialRow == null || filter == null) return;

    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete row?'),
        description: const Text('This row will be permanently deleted.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await dataTables.rows.delete(
        widget.dataTableId,
        filter: jsonEncode(filter),
      );
      if (!mounted) return;
      AppToast.success(context, 'Row deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  Future<void> _save() async {
    if (widget.dataTableId.isEmpty) {
      AppToast.error(context, 'Missing data table ID');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = _payloadData();
      if (widget.initialRow == null) {
        await dataTables.rows.insert(
          widget.dataTableId,
          data: [payload],
        );
      } else {
        final filter = _buildUpdateFilter();
        if (filter == null) {
          throw Exception('Missing original row values for update filter');
        }

        await dataTables.rows.update(
          widget.dataTableId,
          filter: filter,
          data: payload,
        );
      }

      if (!mounted) return;
      AppToast.success(context, widget.initialRow == null ? 'Row created' : 'Row updated');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.initialRow != null)
            IconButton(
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.trash2),
              onPressed: _saving || _deleting ? null : _delete,
            ),
          IconButton(
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
            onPressed: _saving || _deleting ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final column in widget.columns) ...[
              _RowField(
                label: _columnLabel(column),
                child: Builder(
                  builder: (context) {
                    final key = _columnKey(column);
                    final value = _valueForColumn(column);

                    if (_isBooleanColumn(column, value)) {
                      return ShadCheckbox(
                        value: _boolValues[key] ?? false,
                        onChanged: (next) =>
                            setState(() => _boolValues[key] = next),
                      );
                    }

                    return ShadInput(
                      controller: _controllers[key],
                      keyboardType: _isNumericColumn(column, value)
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _RowField extends StatelessWidget {
  const _RowField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        child,
      ],
    );
  }
}
