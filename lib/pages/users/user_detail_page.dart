import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({
    super.key,
    required this.userId,
    required this.initialUser,
    this.inviteAcceptUrl,
  });

  final String userId;
  final Map<String, dynamic> initialUser;

  /// When set, an alert dialog is shown on first render with this URL.
  final String? inviteAcceptUrl;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Map<String, dynamic> _user;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _fetch();
    if (widget.inviteAcceptUrl != null && widget.inviteAcceptUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showInviteDialog());
    }
  }

  Future<void> _fetch() async {
    try {
      final user = await users.get(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showInviteDialog() async {
    final url = widget.inviteAcceptUrl!;
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

  Future<void> _delete() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete user?'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('This will permanently delete the user.'),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await users.delete(widget.userId);
      if (!mounted) return;
      AppToast.success(context, 'User deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.error(context, e.toString(), title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user['firstName'] as String? ?? '';
    final lastName = _user['lastName'] as String? ?? '';
    final fullName = [firstName, lastName]
        .where((p) => p.trim().isNotEmpty)
        .join(' ');
    final email = _user['email'] as String? ?? '—';
    final role = _user['role'] as String? ?? '—';
    final id = '${_user['id'] ?? '—'}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('User'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash2),
            onPressed: _deleting ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(
                        color:
                            ShadTheme.of(context).colorScheme.destructive,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (fullName.isNotEmpty) _Row('Name', fullName),
                      _Row('Email', email),
                      _Row('Role', role),
                      _Row('ID', id),
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
