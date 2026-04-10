import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'audit_page.dart';
import 'workflows/workflows_page.dart';
import 'executions/executions_page.dart';
import 'data-tables/data_tables_page.dart';
import 'credentials/credentials_page.dart';
import 'settings_page.dart';
import 'users/users_page.dart';

Widget n8nAppBarTitle() => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SvgPicture.asset('lib/assets/appbar-logo.svg', height: 22),
    const SizedBox(width: 10),
    const Text('n8n to go'),
  ],
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final _items = [
    (
      title: 'Audit',
      subtitle: 'Check access and health',
      icon: LucideIcons.shieldCheck,
      route: AuditPage.new,
    ),
    (
      title: 'Workflows',
      subtitle: 'Browse your workflows',
      icon: LucideIcons.workflow,
      route: WorkflowsPage.new,
    ),
    (
      title: 'Executions',
      subtitle: 'Inspect recent executions',
      icon: LucideIcons.bolt,
      route: ExecutionsPage.new,
    ),
    (
      title: 'Data Tables',
      subtitle: 'View tables, rows, and fields',
      icon: LucideIcons.table,
      route: DataTablesPage.new,
    ),
    (
      title: 'Credentials',
      subtitle: 'Manage your secret keys',
      icon: LucideIcons.keyRound,
      route: CredentialsPage.new,
    ),
    (
      title: 'Users',
      subtitle: 'See user details',
      icon: LucideIcons.users,
      route: UsersPage.new,
    ),
    (
      title: 'Settings',
      subtitle: 'Manage your app settings',
      icon: LucideIcons.settings,
      route: SettingsPage.new,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: n8nAppBarTitle(),
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
                  subtitle: item.subtitle,
                  icon: item.icon,
                  onTap: () {
                    final route = item.route;
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => route()));
                  },
                ),
                if (item != _items.last) const SizedBox(height: 8),
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
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onTap == null
                            ? theme.colorScheme.mutedForeground
                            : theme.colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
