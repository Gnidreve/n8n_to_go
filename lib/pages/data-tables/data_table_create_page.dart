import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';

class DataTableCreatePage extends StatefulWidget {
  const DataTableCreatePage({super.key});

  @override
  State<DataTableCreatePage> createState() => _DataTableCreatePageState();
}

class _DataTableCreatePageState extends State<DataTableCreatePage> {
  final _nameController = TextEditingController();
  final List<_ColumnDraft> _columns = [
    _ColumnDraft(),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final column in _columns) {
      column.dispose();
    }
    super.dispose();
  }

  void _addColumn() {
    setState(() {
      _columns.add(_ColumnDraft());
    });
  }

  void _removeColumn(int index) {
    if (_columns.length == 1) return;
    setState(() {
      final column = _columns.removeAt(index);
      column.dispose();
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Table name is required'),
        ),
      );
      return;
    }

    final preparedColumns = <Map<String, dynamic>>[];
    for (var i = 0; i < _columns.length; i++) {
      final columnName = _columns[i].nameController.text.trim();
      if (columnName.isEmpty) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Column name is required'),
            description: Text('Column ${i + 1} is missing a name.'),
          ),
        );
        return;
      }

      preparedColumns.add({
        'name': columnName,
        'type': _columns[i].type,
        'index': i,
      });
    }

    setState(() => _saving = true);
    try {
      await dataTables.post(
        name: name,
        columns: preparedColumns,
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(title: Text('Data table created')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create table'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('Table'),
            const SizedBox(height: 8),
            ShadCard(
              child: Column(
                children: [
                  _Field(
                    label: 'Name',
                    child: ShadInput(
                      controller: _nameController,
                      placeholder: const Text('My data table'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: _SectionLabel('Columns'),
                ),
                ShadButton.outline(
                  leading: const Icon(LucideIcons.plus, size: 14),
                  onPressed: _saving ? null : _addColumn,
                  child: const Text('Add column'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _columns.length; i++) ...[
              ShadCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Column ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          onPressed: _saving || _columns.length == 1
                              ? null
                              : () => _removeColumn(i),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      label: 'Name',
                      child: ShadInput(
                        controller: _columns[i].nameController,
                        placeholder: const Text('Column name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Type',
                      child: ShadSelect<String>(
                        initialValue: _columns[i].type,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _columns[i].type = value;
                          });
                        },
                        options: const [
                          ShadOption(value: 'string', child: Text('String')),
                          ShadOption(value: 'number', child: Text('Number')),
                          ShadOption(value: 'boolean', child: Text('Boolean')),
                        ],
                        selectedOptionBuilder: (context, value) => Text(
                          switch (value) {
                            'number' => 'Number',
                            'boolean' => 'Boolean',
                            _ => 'String',
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != _columns.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnDraft {
  _ColumnDraft()
      : nameController = TextEditingController(),
        type = 'string';

  final TextEditingController nameController;
  String type;

  void dispose() {
    nameController.dispose();
  }
}

class _Field extends StatelessWidget {
  const _Field({
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
