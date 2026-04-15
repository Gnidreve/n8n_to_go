import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';
import '../../utils/execution_formatters.dart';

class ExecutionDetailPage extends StatefulWidget {
  const ExecutionDetailPage({
    super.key,
    required this.executionId,
    required this.initialExecution,
  });

  final String executionId;
  final Map<String, dynamic> initialExecution;

  @override
  State<ExecutionDetailPage> createState() => _ExecutionDetailPageState();
}

class _ExecutionDetailPageState extends State<ExecutionDetailPage> {
  late Map<String, dynamic> _execution;
  bool _loading = true;
  bool _retrying = false;
  bool _deleting = false;
  bool _didChange = false;
  String? _loadWarning;

  @override
  void initState() {
    super.initState();
    _execution = widget.initialExecution;
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final execution = await executions.get(
        widget.executionId,
        includeData: false,
      );
      if (!mounted) return;
      setState(() {
        _execution = execution;
        _loading = false;
        _loadWarning = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadWarning = e.toString();
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete execution?'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('This will permanently delete the execution.'),
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
      await executions.delete(widget.executionId);
      if (!mounted) return;
      AppToast.success(context, 'Execution deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  Future<void> _retryExecution() async {
    setState(() => _retrying = true);
    try {
      final retriedExecution = await executions.retry(widget.executionId);
      if (!mounted) return;
      setState(() {
        _execution = retriedExecution;
        _retrying = false;
        _didChange = true;
      });
      AppToast.success(context, 'Execution retried');
    } catch (e) {
      if (!mounted) return;
      setState(() => _retrying = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  String get _title => 'Execution ${_execution['id'] ?? widget.executionId}';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isError = isExecutionError(_execution);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_execution);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(_didChange),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loadWarning != null) ...[
                    ShadCard(
                      child: Text(
                        'Live execution fetch failed: $_loadWarning\n'
                        'Showing notification data fallback.',
                        style: TextStyle(color: theme.colorScheme.destructive),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ShadCard(
                    title: const Text('Overview'),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _DetailRow(
                          'Workflow name',
                          _stringValue(_execution['workflowName']),
                        ),
                        _DetailRow(
                          'Workflow ID',
                          _stringValue(_execution['workflowId']),
                        ),
                        _DetailRow('ID', _stringValue(_execution['id'])),
                        _DetailRow('Status', executionStatusLabel(_execution)),
                        _DetailRow(
                          'Finished',
                          _boolLabel(_execution['finished']),
                        ),
                        _DetailRow('Mode', _stringValue(_execution['mode'])),
                        _DetailRow(
                          'Retry of',
                          _stringValue(_execution['retryOf']),
                        ),
                        _DetailRow(
                          'Retry success ID',
                          _stringValue(_execution['retrySuccessId']),
                        ),
                        _DetailRow(
                          'Last node',
                          _stringValue(_execution['lastNodeExecuted']),
                        ),
                        _DetailRow('URL', _stringValue(_execution['url'])),
                        _DetailRow(
                          'Started at',
                          _dateTimeLabel(_execution['startedAt']),
                        ),
                        _DetailRow(
                          'Stopped at',
                          _dateTimeLabel(_execution['stoppedAt']),
                        ),
                        _DetailRow(
                          'Wait till',
                          _dateTimeLabel(_execution['waitTill']),
                        ),
                        _DetailRow(
                          'Duration',
                          executionDurationLabel(_execution),
                        ),
                        _DetailRow(
                          'Error message',
                          _stringValue(_execution['error']?['message']),
                        ),
                      ],
                    ),
                  ),
                  if (isError) ...[
                    const SizedBox(height: 16),
                    ShadButton(
                      onPressed: _retrying ? null : _retryExecution,
                      child: _retrying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retry execution'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ShadCard(
                    title: const Text('Data'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _JsonBlock(value: _execution['data']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadCard(
                    title: const Text('Custom data'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _JsonBlock(value: _execution['customData']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadCard(
                    title: const Text('Raw execution JSON'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        SelectableText(
                          prettyJson,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final pretty = const JsonEncoder.withIndent('  ').convert(value);

    return SelectableText(
      pretty,
      style: TextStyle(
        fontFamily: 'monospace',
        color: theme.colorScheme.foreground,
      ),
    );
  }
}

String _stringValue(dynamic value) {
  if (value == null) return '—';
  final text = value.toString();
  return text.isEmpty ? '—' : text;
}

String _boolLabel(dynamic value) {
  if (value is bool) return value ? 'Yes' : 'No';
  return _stringValue(value);
}

String _dateTimeLabel(dynamic value) {
  final parsed = parseExecutionDate(value);
  if (parsed == null) return _stringValue(value);
  return formatExecutionDateTime(parsed);
}
