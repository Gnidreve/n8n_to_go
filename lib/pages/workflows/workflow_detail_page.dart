import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';
import '../../utils/execution_formatters.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../executions/execution_detail_page.dart';

class WorkflowDetailPage extends StatefulWidget {
  const WorkflowDetailPage({super.key, required this.id, required this.name});

  final String id;
  final String name;

  @override
  State<WorkflowDetailPage> createState() => _WorkflowDetailPageState();
}

class _ExecutionRow {
  const _ExecutionRow({
    required this.executionId,
    required this.item,
    required this.startedAtFormatted,
    required this.isError,
    required this.statusLabel,
    required this.durationLabel,
  });

  final String executionId;
  final Map<String, dynamic> item;
  final String startedAtFormatted;
  final bool isError;
  final String statusLabel;
  final String durationLabel;
}

class _WorkflowDetailPageState extends State<WorkflowDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _workflow;
  List<_ExecutionRow> _executions = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        workflows.get(widget.id),
        executions.getAllByWorkflowId(widget.id),
      ]);

      if (!mounted) return;
      final workflow = results[0];
      final executionsResponse = results[1];

      final rawExecutions = executionsResponse['data'] as List<dynamic>? ?? [];
      final executionRows = rawExecutions.map((e) {
        final item = Map<String, dynamic>.from(e as Map);
        final startedAt = parseExecutionDate(
          item['startedAt'] ?? item['createdAt'],
        );
        return _ExecutionRow(
          executionId: '${item['id'] ?? ''}',
          item: item,
          startedAtFormatted: formatExecutionDateTime(startedAt),
          isError: isExecutionError(item),
          statusLabel: executionStatusLabel(item),
          durationLabel: executionDurationLabel(item),
        );
      }).toList();

      setState(() {
        _loading = false;
        _workflow = workflow;
        _executions = executionRows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = _workflow;
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.name),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $_error'),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ShadTabs<String>(
                value: 'details',
                tabs: [
                  ShadTab(
                    value: 'details',
                    content: ShadCard(
                      title: const Text('Details'),
                      description: const Text(
                        'Workflow metadata and publication state.',
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _CopyRow('Workflow ID', w!['id'] as String? ?? '—'),
                          _StatusRow(active: w['active'] == true),
                          _Row(
                            'Archived',
                            w['isArchived'] == true ? 'Yes' : 'No',
                          ),
                          _Row('Trigger count', '${w['triggerCount'] ?? 0}'),
                          _Row(
                            'Execution order',
                            w['settings']?['executionOrder'] ?? '—',
                          ),
                          _Row('Created', w['createdAt'] ?? '—'),
                          _Row('Updated', w['updatedAt'] ?? '—'),
                          if ((w['tags'] as List?)?.isNotEmpty == true)
                            _Row(
                              'Tags',
                              (w['tags'] as List)
                                  .map((t) => t['name'])
                                  .join(', '),
                            ),
                        ],
                      ),
                    ),
                    child: const Text('Details'),
                  ),
                  ShadTab(
                    value: 'executions',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_executions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('No executions'),
                            ),
                          )
                        else
                          ..._executions.map((row) {
                            final accent = row.isError
                                ? const Color(0xFFF87171)
                                : const Color(0xFF86EFAC);

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ShadCard(
                                padding: EdgeInsets.zero,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: row.executionId.isEmpty
                                      ? null
                                      : () async {
                                          final reload =
                                              await Navigator.of(
                                                context,
                                              ).push<bool>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ExecutionDetailPage(
                                                        executionId:
                                                            row.executionId,
                                                        initialExecution:
                                                            row.item,
                                                      ),
                                                ),
                                              );
                                          if (reload == true) {
                                            await _fetch();
                                          }
                                        },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            bottomLeft: Radius.circular(6),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                row.startedAtFormatted,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: row.statusLabel,
                                                      style: TextStyle(
                                                        color: row.isError
                                                            ? const Color(
                                                                0xFFF87171,
                                                              )
                                                            : const Color(
                                                                0xFF86EFAC,
                                                              ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          ' in ${row.durationLabel}',
                                                      style: TextStyle(
                                                        color: theme
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
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(right: 20),
                                        child: Icon(
                                          LucideIcons.chevronRight,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                    child: const Text('Executions'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ShadButton.outline(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                showInfoToast(context, 'Copied to clipboard');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
                  const Icon(LucideIcons.copy, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF22c55e) : const Color(0xFF71717a),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(active ? 'Published' : 'Inactive'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
