import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/dead_filter_select.dart';
import 'workflow_detail_page.dart';

class WorkflowsPage extends StatefulWidget {
  const WorkflowsPage({super.key});

  @override
  State<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
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
      final res = await workflows.getAll();
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Workflows'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $_error',
                    style: TextStyle(
                      color: ShadTheme.of(context).colorScheme.destructive,
                    ),
                  ),
                  )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length + 1,
                  separatorBuilder: (_, index) =>
                      index == 0 ? const SizedBox(height: 16) : const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return const DeadFilterSelect();
                    }
                    final item = _items[i - 1] as Map<String, dynamic>;
                    final name = item['name'] as String? ?? 'Workflow';
                    final description = item['description'] as String?;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkflowDetailPage(
                              id: item['id'] as String,
                              name: name,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              if (description != null && description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(description, style: const TextStyle(fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
