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
    (title: 'Workflows',   icon: Icons.account_tree_outlined, route: WorkflowsPage.new),
    (title: 'Executions',  icon: Icons.bolt_outlined,         route: ExecutionsPage.new),
    (title: 'Data Tables', icon: Icons.table_chart_outlined,  route: DataTablesPage.new),
    (title: 'Credentials', icon: Icons.key_outlined,          route: CredentialsPage.new),
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _items[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => item.route()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(item.icon, size: 24),
                    const SizedBox(width: 16),
                    Text(item.title, style: theme.textTheme.h4),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 18),
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
