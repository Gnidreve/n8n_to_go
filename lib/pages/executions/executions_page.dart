import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/dead_filter_select.dart';
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Executions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                  itemCount: _items.isEmpty ? 2 : _items.length + 1,
                  separatorBuilder: (_, index) => index == 0
                      ? const SizedBox(height: 16)
                      : const ShadSeparator.horizontal(
                    thickness: 4,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    radius: BorderRadius.all(Radius.circular(4)),
                  ),
                  itemBuilder: (context, i) {
                    if (i == 0) return const DeadFilterSelect();
                    if (_items.isEmpty) return const Text('No executions');
                    return Text(
                      const JsonEncoder.withIndent('  ').convert(_items[i - 1]),
                    );
                  },
                ),
    );
  }
}
