import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
class ExecutionsPage extends StatefulWidget {
  const ExecutionsPage({super.key});

  @override
  State<ExecutionsPage> createState() => _ExecutionsPageState();
}

class _ExecutionsPageState extends State<ExecutionsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await executions.getAll();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = res['data'] as List<dynamic>? ?? [];
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
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Executions'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.isEmpty ? 1 : _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (_items.isEmpty) return const Text('No executions');
                      final item = Map<String, dynamic>.from(_items[i] as Map);
                      final startedAt = _parseDate(
                        item['startedAt'] ?? item['createdAt'],
                      );
                      final isError = _isError(item);
                      final accent = isError
                          ? const Color(0xFFF87171)
                          : const Color(0xFF86EFAC);

                      return ShadCard(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' in ${_durationLabel(item)}',
                                            style: TextStyle(
                                              color: theme.colorScheme.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isError)
                              const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(
                                  LucideIcons.refreshCw,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
