import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'workflows/workflows_page.dart';
import 'executions/executions_page.dart';
import 'data-tables/data_tables_page.dart';
import 'credentials/credentials_page.dart';
import 'settings_page.dart';

Widget n8nAppBarTitle() => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SvgPicture.asset('lib/assets/appbar-logo.svg', height: 22),
    const SizedBox(width: 10),
    const Text('n8n for mobile'),
  ],
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final _items = [
    (title: 'Audit', icon: LucideIcons.shieldCheck, route: null),
    (title: 'Workflows', icon: LucideIcons.workflow, route: WorkflowsPage.new),
    (title: 'Executions', icon: LucideIcons.bolt, route: ExecutionsPage.new),
    (title: 'Data Tables', icon: LucideIcons.table, route: DataTablesPage.new),
    (title: 'Credentials', icon: LucideIcons.keyRound, route: CredentialsPage.new),
    (title: 'Users', icon: LucideIcons.users, route: null),
    (title: 'Settings', icon: LucideIcons.settings, route: SettingsPage.new),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: n8nAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final item in _items) ...[
                _HomeMenuCard(
                  title: item.title,
                  icon: item.icon,
                  onTap: item.route == null
                      ? null
                      : () {
                          final route = item.route!;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => route()),
                          );
                        },
                ),
                if (item != _items.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: theme.radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: onTap == null
                    ? theme.colorScheme.mutedForeground
                    : theme.colorScheme.foreground,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onTap == null
                        ? theme.colorScheme.mutedForeground
                        : theme.colorScheme.foreground,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: onTap == null
                    ? theme.colorScheme.mutedForeground
                    : theme.colorScheme.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
