import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';

class DataTableCreatePage extends StatefulWidget {
  const DataTableCreatePage({super.key});

  @override
  State<DataTableCreatePage> createState() => _DataTableCreatePageState();
}

class _DataTableCreatePageState extends State<DataTableCreatePage> {
  final _nameController = TextEditingController();
  final List<_ColumnDraft> _columns = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final column in _columns) {
      column.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Table name is required');
      return;
    }
    if (_columns.isEmpty) {
      AppToast.error(context, 'At least one column is required');
      return;
    }

    final preparedColumns = <Map<String, dynamic>>[];
    for (var i = 0; i < _columns.length; i++) {
      final columnName = _columns[i].nameController.text.trim();
      if (columnName.isEmpty) {
        AppToast.error(context, 'Column ${i + 1} is missing a name.', title: 'Column name is required');
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
      AppToast.success(context, 'Data table created');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  Future<void> _openColumnDialog({int? index}) async {
    final draft = index == null ? _ColumnDraft() : _columns[index];
    final saved = await showShadDialog<bool>(
      context: context,
      builder: (context) => _ColumnDialog(
        draft: draft,
        isEditing: index != null,
      ),
    );

    if (saved != true) {
      if (index == null) {
        draft.dispose();
      }
      return;
    }

    setState(() {
      if (index == null) {
        _columns.add(draft);
      }
    });
  }

  void _removeColumn(int index) {
    setState(() {
      final column = _columns.removeAt(index);
      column.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create Data-Table'),
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
                  onPressed: _saving ? null : () => _openColumnDialog(),
                  child: const Text('Add column'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_columns.isEmpty)
              const ShadCard(
                child: Text('No columns added yet'),
              ),
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
                        ShadButton.outline(
                          leading: const Icon(LucideIcons.pencil, size: 14),
                          onPressed: _saving ? null : () => _openColumnDialog(index: i),
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          onPressed: _saving
                              ? null
                              : () => _removeColumn(i),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_columns[i].nameController.text.trim()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Type',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        _ColumnTypeIcon(type: _columns[i].type),
                        const SizedBox(width: 8),
                        Text(
                          switch (_columns[i].type) {
                            'number' => 'Number',
                            'boolean' => 'Boolean',
                            _ => 'String',
                          },
                        ),
                      ],
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

class _ColumnDialog extends StatefulWidget {
  const _ColumnDialog({
    required this.draft,
    required this.isEditing,
  });

  final _ColumnDraft draft;
  final bool isEditing;

  @override
  State<_ColumnDialog> createState() => _ColumnDialogState();
}

class _ColumnDialogState extends State<_ColumnDialog> {
  late final TextEditingController _nameController;
  late String _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.draft.nameController.text,
    );
    _type = widget.draft.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Column name is required');
      return;
    }

    widget.draft.nameController.text = name;
    widget.draft.type = _type;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(widget.isEditing ? 'Edit column' : 'Add column'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _Field(
            label: 'Name',
            child: ShadInput(
              controller: _nameController,
              placeholder: const Text('Column name'),
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Type',
            child: ShadSelect<String>(
              initialValue: _type,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                });
              },
              options: const [
                ShadOption(
                  value: 'string',
                  child: Row(
                    children: [
                      Icon(LucideIcons.type, size: 16),
                      SizedBox(width: 8),
                      Text('String'),
                    ],
                  ),
                ),
                ShadOption(
                  value: 'number',
                  child: Row(
                    children: [
                      Icon(LucideIcons.hash, size: 16),
                      SizedBox(width: 8),
                      Text('Number'),
                    ],
                  ),
                ),
                ShadOption(
                  value: 'boolean',
                  child: Row(
                    children: [
                      Icon(LucideIcons.binary, size: 16),
                      SizedBox(width: 8),
                      Text('Boolean'),
                    ],
                  ),
                ),
              ],
              selectedOptionBuilder: (context, value) => Row(
                children: [
                  _ColumnTypeIcon(type: value),
                  const SizedBox(width: 8),
                  Text(
                    switch (value) {
                      'number' => 'Number',
                      'boolean' => 'Boolean',
                      _ => 'String',
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                onPressed: _save,
                child: Text(widget.isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColumnTypeIcon extends StatelessWidget {
  const _ColumnTypeIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Icon(
      switch (type) {
        'number' => LucideIcons.hash,
        'boolean' => LucideIcons.binary,
        _ => LucideIcons.type,
      },
      size: 16,
    );
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
