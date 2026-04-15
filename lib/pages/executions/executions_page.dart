import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../styles.dart';
import '../../utils/execution_formatters.dart';
import 'execution_detail_page.dart';

class ExecutionsPage extends StatefulWidget {
  const ExecutionsPage({super.key});

  @override
  State<ExecutionsPage> createState() => _ExecutionsPageState();
}

class _ExecutionsPageState extends State<ExecutionsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(
      () => setState(() => _search = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredItems {
    if (_search.isEmpty) return _items;
    return _items.where((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final workflowName =
          (item['workflowName'] as String? ?? '').toLowerCase();
      final id = '${item['id'] ?? ''}'.toLowerCase();
      final status = (item['status'] as String? ?? '').toLowerCase();
      return workflowName.contains(_search) ||
          id.contains(_search) ||
          status.contains(_search);
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await executions.getAll();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = res['data'] as List<dynamic>? ?? [];
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
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Executions'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loading ? null : _fetch,
          ),
        ],
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
                  style: TextStyle(color: theme.colorScheme.destructive),
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.isEmpty
                      ? 2
                      : _filteredItems.length + 1,
                  separatorBuilder: (_, index) => index == 0
                      ? const SizedBox(height: 16)
                      : const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ShadInput(
                        controller: _searchController,
                        placeholder: const Text('Search executions'),
                        leading: const Icon(LucideIcons.search),
                      );
                    }
                    if (_filteredItems.isEmpty) {
                      return Text(
                        'No executions',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      );
                    }
                    final item = Map<String, dynamic>.from(
                      _filteredItems[index - 1] as Map,
                    );
                    return _ExecutionCard(item: item, onReload: _fetch);
                  },
                ),
              ),
      ),
    );
  }
}

class _ExecutionCard extends StatelessWidget {
  const _ExecutionCard({required this.item, required this.onReload});

  final Map<String, dynamic> item;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final startedAt = parseExecutionDate(item['startedAt'] ?? item['createdAt']);
    final isError = isExecutionError(item);
    final accent = isError ? kColorError : kColorSuccessSubtle;
    final executionId = '${item['id'] ?? ''}';

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: executionId.isEmpty
            ? null
            : () async {
                final reload = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ExecutionDetailPage(
                      executionId: executionId,
                      initialExecution: item,
                    ),
                  ),
                );
                if (reload == true) await onReload();
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
                                  ? kColorError
                                  : kColorSuccessSubtle,
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
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(LucideIcons.chevronRight, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
