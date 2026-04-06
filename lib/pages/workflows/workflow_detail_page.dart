import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class WorkflowDetailPage extends StatefulWidget {
  const WorkflowDetailPage({super.key, required this.id, required this.name});

  final String id;
  final String name;

  @override
  State<WorkflowDetailPage> createState() => _WorkflowDetailPageState();
}

class _WorkflowDetailPageState extends State<WorkflowDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _workflow;
  List<dynamic> _executions = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        workflows.get(widget.id),
        executions.getAllByWorkflowId(widget.id),
      ]);

      if (!mounted) return;
      final workflow = results[0];
      final executionsResponse = results[1];

      setState(() {
        _loading = false;
        _workflow = workflow;
        _executions = executionsResponse['data'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Unknown date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    final day = value.day;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute:$second';
  }

  bool _isError(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return raw.contains('error') || raw.contains('fail');
  }

  String _statusLabel(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString();
    if (raw.isEmpty) return 'Unknown';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _durationLabel(Map<String, dynamic> item) {
    final explicit = item['runTime'] ?? item['duration'] ?? item['executionTime'];
    if (explicit is num) {
      final seconds = explicit >= 1000 ? explicit / 1000 : explicit.toDouble();
      return _formatSeconds(seconds);
    }

    final startedAt = _parseDate(item['startedAt']);
    final stoppedAt = _parseDate(item['stoppedAt'] ?? item['finishedAt']);
    if (startedAt != null && stoppedAt != null) {
      final seconds = stoppedAt.difference(startedAt).inMilliseconds / 1000;
      return _formatSeconds(seconds);
    }

    return '—';
  }

  String _formatSeconds(double seconds) {
    if (seconds >= 10) return '${seconds.toStringAsFixed(2)}s';
    if (seconds >= 1) return '${seconds.toStringAsFixed(3)}s';
    return '${seconds.toStringAsFixed(0)}ms';
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
                              _Row('Archived', w['isArchived'] == true ? 'Yes' : 'No'),
                              _Row('Trigger count', '${w['triggerCount'] ?? 0}'),
                              _Row('Execution order', w['settings']?['executionOrder'] ?? '—'),
                              _Row('Created', w['createdAt'] ?? '—'),
                              _Row('Updated', w['updatedAt'] ?? '—'),
                              if ((w['tags'] as List?)?.isNotEmpty == true)
                                _Row(
                                  'Tags',
                                  (w['tags'] as List).map((t) => t['name']).join(', '),
                                ),
                            ],
                          ),
                        ),
                        child: const Text('Details'),
                      ),
                      ShadTab(
                        value: 'executions',
                        content: ShadCard(
                          title: const Text('Executions'),
                          description: const Text(
                            'Recent executions for this workflow.',
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              if (_executions.isEmpty)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('No executions'),
                                )
                              else
                                ..._executions.map(
                                  (e) {
                                    final item = Map<String, dynamic>.from(e as Map);
                                    final startedAt = _parseDate(
                                      item['startedAt'] ?? item['createdAt'],
                                    );
                                    final isError = _isError(item);
                                    final accent = isError
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF86EFAC);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: ShadCard(
                                        padding: EdgeInsets.zero,
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
                                                      _formatDateTime(startedAt),
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
                                                            text: _statusLabel(item),
                                                            style: TextStyle(
                                                              color: isError
                                                                  ? const Color(0xFFF87171)
                                                                  : const Color(0xFF86EFAC),
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' in ${_durationLabel(item)}',
                                                            style: TextStyle(
                                                              color: theme.colorScheme
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
                                              padding: EdgeInsets.only(right: 14),
                                              child: Icon(
                                                LucideIcons.refreshCw,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ShadButton.outline(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ShadToaster.of(context).show(
                  const ShadToast(title: Text('Copied to clipboard')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
            child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
