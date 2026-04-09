import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';
import '../../widgets/credential_schema_form.dart';

class CredentialCreatePage extends StatefulWidget {
  const CredentialCreatePage({
    super.key,
    required this.credentialType,
    required this.initialSchema,
  });

  final String credentialType;
  final Map<String, dynamic> initialSchema;

  @override
  State<CredentialCreatePage> createState() => _CredentialCreatePageState();
}

class _CredentialCreatePageState extends State<CredentialCreatePage> {
  final _name = TextEditingController();
  final _schemaFormKey = GlobalKey<CredentialSchemaFormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showErrorToast(context, 'Name is required');
      return;
    }
    final formState = _schemaFormKey.currentState;
    if (formState == null || formState.isLoading) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'type': widget.credentialType,
        'isResolvable': false,
        'data': formState.getData(),
      };
      await credentials.post(body);
      if (!mounted) return;
      showSuccessToast(context, 'Credential created');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorToast(context, 'Error', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Credential'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Field(
              label: 'Name',
              child: ShadInput(
                controller: _name,
                placeholder: const Text('z.B. My Github Account'),
              ),
            ),
            const SizedBox(height: 24),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 24),
            const Text('Credential data', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CredentialSchemaForm(
              key: _schemaFormKey,
              credentialType: widget.credentialType,
              initialSchema: widget.initialSchema,
            ),
          ],
        ),
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
