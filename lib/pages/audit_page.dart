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
            'categories': ['credentials', 'database', 'filesystem', 'nodes', 'instance'],
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

  List<Map<String, dynamic>> get _sections {
    final report = _report;
    if (report == null) return [];
    final result = <Map<String, dynamic>>[];
    for (final value in report.values) {
      final reportMap = Map<String, dynamic>.from(value as Map);
      final sections = reportMap['sections'] as List? ?? [];
      for (final s in sections) {
        result.add(Map<String, dynamic>.from(s as Map));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final theme = ShadTheme.of(context);

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
                    final json = const JsonEncoder.withIndent('  ').convert(_report);
                    Clipboard.setData(ClipboardData(text: json));
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
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sections.isEmpty ? 1 : sections.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (sections.isEmpty) {
                          return const Text('No audit findings.');
                        }
                        final section = sections[i];
                        final title = section['title'] as String? ?? '—';
                        final description = section['description'] as String? ?? '';
                        return ShadCard(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: theme.radius,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AuditSectionPage(section: section),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.mutedForeground,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
      ),
    );
  }
}

// ── Detail page ───────────────────────────────────────────────────────────────

class AuditSectionPage extends StatelessWidget {
  const AuditSectionPage({super.key, required this.section});

  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final title = section['title'] as String? ?? '—';
    final description = section['description'] as String? ?? '';
    final recommendation = section['recommendation'] as String?;
    final location = section['location'] as List?;
    final nextVersions = section['nextVersions'] as List?;
    final settings = section['settings'] as Map?;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(description, style: TextStyle(color: theme.colorScheme.mutedForeground)),
            if (recommendation != null) ...[
              const SizedBox(height: 16),
              const ShadSeparator.horizontal(),
              const SizedBox(height: 16),
              Text('Recommendation', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(recommendation),
            ],
            if (location != null && location.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Affected items', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...location.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                final kind = item['kind'] as String? ?? '';
                if (kind == 'credential') {
                  return _LocationCard(
                    primary: item['name'] as String? ?? '—',
                    secondary: 'Credential · ${item['id'] ?? ''}',
                  );
                }
                return _LocationCard(
                  primary: item['nodeName'] as String? ?? '—',
                  secondary: '${item['workflowName'] ?? ''} · ${item['nodeType'] ?? ''}',
                );
              }),
            ],
            if (nextVersions != null && nextVersions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Available updates', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...nextVersions.map((raw) {
                final v = Map<String, dynamic>.from(raw as Map);
                final desc = (v['description'] as String? ?? '')
                    .replaceAll(RegExp(r'<[^>]+>'), '');
                return _LocationCard(
                  primary: v['name'] as String? ?? '—',
                  secondary: desc,
                );
              }),
            ],
            if (settings != null) ...[
              const SizedBox(height: 20),
              Text('Settings', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._flattenSettings(settings).map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, dynamic>> _flattenSettings(Map settings, [String prefix = '']) {
    final result = <MapEntry<String, dynamic>>[];
    for (final entry in settings.entries) {
      final key = prefix.isEmpty ? '${entry.key}' : '$prefix.${entry.key}';
      if (entry.value is Map) {
        result.addAll(_flattenSettings(entry.value as Map, key));
      } else {
        result.add(MapEntry(key, entry.value));
      }
    }
    return result;
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.primary, required this.secondary});

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(primary, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              secondary,
              style: TextStyle(
                fontSize: 12,
                color: ShadTheme.of(context).colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
