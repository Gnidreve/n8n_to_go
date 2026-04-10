import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../CREDENTIAL_TYPES.dart';
import '../../api/api.dart';
import '../../utils/app_toast.dart';
import '../../widgets/credential_icon.dart';
import 'credential_create_page.dart';

class CredentialTypeSelectPage extends StatefulWidget {
  const CredentialTypeSelectPage({super.key});

  @override
  State<CredentialTypeSelectPage> createState() => _CredentialTypeSelectPageState();
}

class _CredentialTypeSelectPageState extends State<CredentialTypeSelectPage> {
  String? _loadingType;
  String _search = '';

  Future<void> _openCreateForm(String credentialType) async {
    setState(() => _loadingType = credentialType);

    try {
      final decoded = await credentials.schema.get(credentialType);
      if (!mounted) return;

      final reload = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CredentialCreatePage(
            credentialType: credentialType,
            initialSchema: decoded,
          ),
        ),
      );

      if (!mounted) return;
      if (reload == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _loadingType = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingType = null);
      AppToast.error(context, e.toString(), title: 'Failed to load schema');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final sortedTypes = credentialTypes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final filtered = query.isEmpty
        ? sortedTypes
        : sortedTypes
            .where((e) => e.key.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Choose Credential'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length + 1,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox(height: 12) : const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ShadInput(
                placeholder: const Text('Search credentials'),
                leading: const Icon(LucideIcons.search, size: 16),
                onChanged: (value) => setState(() => _search = value),
              );
            }
            final entry = filtered[index - 1];
            final credentialLabel = entry.key;
            final credentialType = entry.value;
            final isLoading = _loadingType == credentialType;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: CredentialIcon(type: credentialType),
              title: Text(
                credentialLabel,
                textAlign: TextAlign.left,
              ),
              trailing: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.chevronRight, size: 20),
              onTap: _loadingType == null ? () => _openCreateForm(credentialType) : null,
            );
          },
        ),
      ),
    );
  }
}
