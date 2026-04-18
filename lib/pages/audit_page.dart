import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../api/api.dart';
import '../utils/app_toast.dart';
import '../widgets/error_view.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  bool _loading = true;
  Object? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await audit.report(
        body: {
          'additionalOptions': {
            'daysAbandonedWorkflow': 1,
            'categories': [
              'credentials',
              'database',
              'filesystem',
              'nodes',
              'instance',
            ],
          },
        },
      );

      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prettyJson = _report == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(_report);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Audit'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share),
            onPressed: _report == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: prettyJson));
                    AppToast.info(context, 'Copied to clipboard');
                  },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorView(error: _error!)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ShadCard(
                        child: SelectableText(
                          prettyJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
