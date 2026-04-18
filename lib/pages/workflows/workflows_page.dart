import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/error_view.dart';
import 'workflow_detail_page.dart';

class WorkflowsPage extends StatefulWidget {
  const WorkflowsPage({super.key});

  @override
  State<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
  bool _loading = true;
  Object? _error;
  List<dynamic> _items = [];
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await workflows.getAll();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = res['data'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e; });
    }
  }

  List<dynamic> get _filteredItems {
    return _items.where((rawItem) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      if (item['isArchived'] == true) return false;
      final name = (item['name'] as String? ?? '').toLowerCase();
      return _search.isEmpty || name.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Workflows'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error!)
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length + 1,
                  separatorBuilder: (_, index) =>
                      index == 0 ? const SizedBox(height: 16) : const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return ShadInput(
                        controller: _searchController,
                        placeholder: const Text('Workflows durchsuchen'),
                        leading: const Icon(LucideIcons.search),
                      );
                    }
                    final item = Map<String, dynamic>.from(filteredItems[i - 1] as Map);
                    final name = item['name'] as String? ?? 'Workflow';
                    final isActive = item['active'] == true;
                    final theme = ShadTheme.of(context);
                    return ShadCard(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: theme.radius,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkflowDetailPage(
                              id: item['id'] as String,
                              name: name,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.workflow,
                                size: 20,
                                color: theme.colorScheme.foreground,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isActive ? 'Published' : 'Unpublished',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: theme.colorScheme.foreground,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
