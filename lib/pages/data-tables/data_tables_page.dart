import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/config_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DataTablesPage extends StatefulWidget {
  const DataTablesPage({super.key});

  @override
  State<DataTablesPage> createState() => _DataTablesPageState();
}

class _DataTablesPageState extends State<DataTablesPage> {
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
      final cfg = ConfigService.instance;
      final res = await http.get(
        Uri.parse('${cfg.baseUrl}/api/v1/data-tables'),
        headers: {'X-N8N-API-KEY': cfg.apiKey},
      );
      if (!mounted) return;
      final decoded = await compute(jsonDecode, res.body) as Map<String, dynamic>;
      setState(() {
        _loading = false;
        _items = decoded['data'] as List<dynamic>? ?? [];
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
        title: const Text('Data Tables'),
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
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const ShadSeparator.horizontal(
                    thickness: 4,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    radius: BorderRadius.all(Radius.circular(4)),
                  ),
                  itemBuilder: (context, i) => Text(
                    const JsonEncoder.withIndent('  ').convert(_items[i]),
                  ),
                ),
    );
  }
}
