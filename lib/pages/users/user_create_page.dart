import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final _email = TextEditingController();
  String _role = 'global:member';
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _showInviteDialog(String url) async {
    await showShadDialog<void>(
      context: context,
      builder: (ctx) => ShadDialog.alert(
        title: const Text('User invited'),
        description: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this invite URL with the new user:'),
              const SizedBox(height: 8),
              SelectableText(url, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
          ShadButton.outline(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              AppToast.info(context, 'Invite URL copied');
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.copy, size: 14),
                SizedBox(width: 8),
                Text('Copy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      AppToast.error(context, 'Email is required');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await users.post({'email': email, 'role': _role});
      if (!mounted) return;
      if (result.isEmpty) {
        setState(() => _saving = false);
        AppToast.error(context, 'Unexpected empty response');
        return;
      }
      final first = Map<String, dynamic>.from(result.first as Map);
      final error = first['error'] as String?;
      if (error != null && error.isNotEmpty) {
        setState(() => _saving = false);
        AppToast.error(context, error, title: 'Error');
        return;
      }
      final user = Map<String, dynamic>.from(first['user'] as Map);
      final inviteAcceptUrl = user['inviteAcceptUrl'] as String?;
      if (!mounted) return;
      if (inviteAcceptUrl != null && inviteAcceptUrl.isNotEmpty) {
        await _showInviteDialog(inviteAcceptUrl);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add User'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
              label: 'Email',
              child: ShadInput(
                controller: _email,
                placeholder: const Text('user@example.com'),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Role',
              child: SizedBox(
                width: double.infinity,
                child: ShadSelect<String>(
                  minWidth: 280,
                  initialValue: _role,
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                  options: const [
                    ShadOption(
                      value: 'global:member',
                      child: Text('Member'),
                    ),
                    ShadOption(
                      value: 'global:admin',
                      child: Text('Admin'),
                    ),
                  ],
                  selectedOptionBuilder: (context, value) => Text(
                    value == 'global:admin' ? 'Admin' : 'Member',
                  ),
                ),
              ),
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
