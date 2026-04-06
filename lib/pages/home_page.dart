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
    (title: 'Workflows',   icon: LucideIcons.workflow, route: WorkflowsPage.new),
    (title: 'Executions',  icon: LucideIcons.bolt,     route: ExecutionsPage.new),
    (title: 'Data Tables', icon: LucideIcons.table,    route: DataTablesPage.new),
    (title: 'Credentials', icon: LucideIcons.keyRound, route: CredentialsPage.new),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 1,
        separatorBuilder: (_, _) => const SizedBox.shrink(),
        itemBuilder: (context, _) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _items[i].route()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Icon(_items[i].icon, size: 24),
                        const SizedBox(width: 16),
                        Text(_items[i].title, style: theme.textTheme.h4),
                        const Spacer(),
                        const Icon(LucideIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                ),
                if (i < _items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
