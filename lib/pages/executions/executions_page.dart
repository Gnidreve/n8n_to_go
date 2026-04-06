import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/execution_formatters.dart';
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
                      final startedAt = parseExecutionDate(
                        item['startedAt'] ?? item['createdAt'],
                      );
                      final isError = isExecutionError(item);
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
                                      formatExecutionDateTime(startedAt),
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
                                            text: executionStatusLabel(item),
                                            style: TextStyle(
                                              color: isError
                                                  ? const Color(0xFFF87171)
                                                  : const Color(0xFF86EFAC),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' in ${executionDurationLabel(item)}',
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
