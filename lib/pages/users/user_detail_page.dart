import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({
    super.key,
    required this.userId,
    required this.initialUser,
  });

  final String userId;
  final Map<String, dynamic> initialUser;

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
      ShadToaster.of(context).show(
        const ShadToast(title: Text('User deleted')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user['email'] as String? ?? 'User';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(email),
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
            onPressed: _loading || _deleting ? null : _delete,
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
                    child: Text('Error: $_error'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ShadCard(
                        title: const Text('User'),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _DetailRow('Email', _user['email']?.toString() ?? '—'),
                            _DetailRow('First name', _user['firstName']?.toString() ?? '—'),
                            _DetailRow('Last name', _user['lastName']?.toString() ?? '—'),
                            _DetailRow(
                              'Pending',
                              _user['isPending'] == true ? 'Yes' : 'No',
                            ),
                            _DetailRow('Role', _user['role']?.toString() ?? '—'),
                            _DetailRow('Created', _user['createdAt']?.toString() ?? '—'),
                            _DetailRow('Updated', _user['updatedAt']?.toString() ?? '—'),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

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
            width: 110,
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
