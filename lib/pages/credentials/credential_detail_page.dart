import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../widgets/credential_schema_form.dart';

class CredentialDetailPage extends StatefulWidget {
  const CredentialDetailPage({super.key, required this.credential});

  final Map<String, dynamic> credential;

  @override
  State<CredentialDetailPage> createState() => _CredentialDetailPageState();
}

class _CredentialDetailPageState extends State<CredentialDetailPage> {
  late final TextEditingController _name;
  final _schemaFormKey = GlobalKey<CredentialSchemaFormState>();
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.credential['name'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _id => widget.credential['id'] as String;
  String get _type => widget.credential['type'] as String? ?? '—';

  Future<void> _save() async {
    final formState = _schemaFormKey.currentState;
    if (formState == null || formState.isLoading) return;
    setState(() => _saving = true);
    try {
      final data = formState.getData();
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'type': _type,
        'isGlobal': false,
        'isResolvable': false,
        'isPartialData': data.isEmpty,
        if (data.isNotEmpty) 'data': data,
      };
      await credentials.patch(_id, body);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(title: Text('Credential saved')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(title: const Text('Error'), description: Text(e.toString())),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete credential?'),
        description: Text('"${_name.text}" will be permanently deleted.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await credentials.delete(_id);
      if (!mounted) return;
      ShadToaster.of(context).show(const ShadToast(title: Text('Credential deleted')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(title: const Text('Error'), description: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.credential;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_name.text.isNotEmpty ? _name.text : 'Credential'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: _deleting
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline),
            onPressed: _deleting ? null : _delete,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Row('ID', c['id'] as String? ?? '—'),
            _Row('Type', _type),
            _Row('Created', c['createdAt'] as String? ?? '—'),
            _Row('Updated', c['updatedAt'] as String? ?? '—'),
            const SizedBox(height: 24),
            _Field(
              label: 'Name',
              child: ShadInput(controller: _name),
            ),
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 24),
            const Text('Credential data', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CredentialSchemaForm(key: _schemaFormKey, credentialType: _type),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        child,
      ],
    );
  }
}
