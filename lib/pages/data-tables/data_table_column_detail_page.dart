import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../utils/app_toast.dart';

class DataTableColumnDetailPage extends StatefulWidget {
  const DataTableColumnDetailPage({
    super.key,
    required this.column,
    required this.tableId,
    required this.allColumns,
  });

  final Map<String, dynamic> column;
  final String tableId;
  final List<Map<String, dynamic>> allColumns;

  @override
  State<DataTableColumnDetailPage> createState() =>
      _DataTableColumnDetailPageState();
}

class _DataTableColumnDetailPageState
    extends State<DataTableColumnDetailPage> {
  late final TextEditingController _nameController;
  late String _type;

  @override
  void initState() {
    super.initState();
    final col = widget.column;
    _nameController = TextEditingController(
      text: col['name'] as String? ??
          col['displayName'] as String? ??
          col['id'] as String? ??
          '',
    );
    _type = (col['type'] as String? ?? 'string').toLowerCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onDelete() {
    AppToast.info(context, 'Column delete not yet implemented');
  }

  void _onSave() {
    AppToast.info(context, 'Column save not yet implemented');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Column'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _onDelete,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  if (value != null) setState(() => _type = value);
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
                        Icon(LucideIcons.squareCheck, size: 16),
                        SizedBox(width: 8),
                        Text('Boolean'),
                      ],
                    ),
                  ),
                ],
                selectedOptionBuilder: (context, value) => Row(
                  children: [
                    Icon(
                      switch (value) {
                        'number' => LucideIcons.hash,
                        'boolean' => LucideIcons.squareCheck,
                        _ => LucideIcons.type,
                      },
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(switch (value) {
                      'number' => 'Number',
                      'boolean' => 'Boolean',
                      _ => 'String',
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ShadButton(
              width: double.infinity,
              onPressed: _onSave,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

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
