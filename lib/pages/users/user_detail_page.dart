import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../api/api.dart';
import '../../utils/app_toast.dart';

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
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _firstName = TextEditingController(
      text: widget.initialUser['firstName'] as String? ?? '',
    );
    _lastName = TextEditingController(
      text: widget.initialUser['lastName'] as String? ?? '',
    );
    _email = TextEditingController(
      text: widget.initialUser['email'] as String? ?? '',
    );
    _fetch();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final user = await users.get(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _firstName.text = user['firstName'] as String? ?? '';
        _lastName.text = user['lastName'] as String? ?? '';
        _email.text = user['email'] as String? ?? '';
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await users.patch(widget.userId, {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
      });
      if (!mounted) return;
      setState(() => _saving = false);
      showSuccessToast(context, 'User saved');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorToast(context, 'Error', description: e.toString());
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
      showSuccessToast(context, 'User deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showErrorToast(context, 'Error', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Edit User'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
            onPressed: _loading || _saving ? null : _save,
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
                      _Field(
                        label: 'First name',
                        child: ShadInput(
                          controller: _firstName,
                          placeholder: const Text('First name'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Last name',
                        child: ShadInput(
                          controller: _lastName,
                          placeholder: const Text('Last name'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Email',
                        child: ShadInput(
                          controller: _email,
                          placeholder: const Text('Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Role',
                        child: ShadInput(
                          initialValue: _user['role'] as String? ?? '—',
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ShadButton.destructive(
                        width: double.infinity,
                        onPressed: _deleting ? null : _delete,
                        child: _deleting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Delete user'),
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
