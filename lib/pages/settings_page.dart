import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import '../services/preferences_service.dart';
import '../services/push_notifications_service.dart';
import '../utils/app_dialog.dart';
import '../utils/app_toast.dart';
import 'setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsBusy = false;
  bool _notifications = false;
  String? _notificationToken;

  @override
  void initState() {
    super.initState();
    _notifications = PreferencesService.instance.pushNotificationsEnabled;
    _notificationToken = PreferencesService.instance.pushNotificationToken;
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    setState(() => _notificationsBusy = true);

    try {
      if (enabled) {
        final result = await PushNotificationsService.instance
            .enableNotifications();
        if (!mounted) return;

        setState(() {
          _notifications = result.enabled;
          _notificationToken = result.token;
        });

        if (result.enabled) {
          AppToast.success(context, 'Push notifications enabled');
        } else {
          AppToast.error(
            context,
            result.message ?? 'Push notifications unavailable',
            title: result.message != null
                ? 'Push notifications unavailable'
                : null,
          );
        }
      } else {
        await PushNotificationsService.instance.disableNotifications();
        if (!mounted) return;

        setState(() {
          _notifications = false;
          _notificationToken = null;
        });
        AppToast.info(context, 'Push notifications disabled');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notifications = PreferencesService.instance.pushNotificationsEnabled;
        _notificationToken = PreferencesService.instance.pushNotificationToken;
      });
      AppToast.error(
        context,
        error.toString(),
        title: 'Push notifications failed',
      );
    } finally {
      if (mounted) {
        setState(() => _notificationsBusy = false);
      }
    }
  }

  Future<void> _copyNotificationToken() async {
    final token = _notificationToken;
    if (token == null || token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    AppToast.info(context, 'Device token copied');
  }

  @override
  Widget build(BuildContext context) {
    final pushService = PushNotificationsService.instance;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.logOut), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ThemeSection(),
            const SizedBox(height: 24),
            _NotificationsSection(
              notifications: _notifications,
              notificationsBusy: _notificationsBusy,
              notificationToken: _notificationToken,
              pushService: pushService,
              onToggle: _setNotificationsEnabled,
              onCopyToken: _copyNotificationToken,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context, constraints) => ShadDialog.alert(
        constraints: constraints,
        title: const Text('Log out?'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'This will clear your saved URL, port, and API key from the app.',
          ),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Log out'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ConfigService.instance.clear();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SetupPage()),
      (_) => false,
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsField(
      label: 'Theme',
      child: SizedBox(
        width: double.infinity,
        child: ShadSelect<ThemeMode>(
          minWidth: 280,
          initialValue: PreferencesService.instance.themeMode,
          onChanged: (mode) {
            if (mode != null) {
              PreferencesService.instance.setThemeMode(mode);
            }
          },
          options: const [
            ShadOption(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(LucideIcons.laptopMinimal, size: 16),
                  SizedBox(width: 8),
                  Text('System'),
                ],
              ),
            ),
            ShadOption(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(LucideIcons.sun, size: 16),
                  SizedBox(width: 8),
                  Text('Light'),
                ],
              ),
            ),
            ShadOption(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(LucideIcons.moon, size: 16),
                  SizedBox(width: 8),
                  Text('Dark'),
                ],
              ),
            ),
          ],
          selectedOptionBuilder: (context, value) => Row(
            children: [
              Icon(switch (value) {
                ThemeMode.light => LucideIcons.sun,
                ThemeMode.dark => LucideIcons.moon,
                ThemeMode.system => LucideIcons.laptopMinimal,
              }, size: 16),
              const SizedBox(width: 8),
              Text(switch (value) {
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
                ThemeMode.system => 'System',
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({
    required this.notifications,
    required this.notificationsBusy,
    required this.notificationToken,
    required this.pushService,
    required this.onToggle,
    required this.onCopyToken,
  });

  final bool notifications;
  final bool notificationsBusy;
  final String? notificationToken;
  final PushNotificationsService pushService;
  final ValueChanged<bool> onToggle;
  final VoidCallback onCopyToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SettingsField(
                label: 'Notifications',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enable Firebase Cloud Messaging for this device.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            notificationsBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch.adaptive(value: notifications, onChanged: onToggle),
          ],
        ),
        if (!pushService.isAvailable) ...[
          const SizedBox(height: 12),
          Text(
            pushService.initializationError ??
                'Firebase is not configured yet. Add google-services.json to finish push setup.',
            style: TextStyle(
              fontSize: 13,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
            ),
          ),
        ],
        if (notificationToken != null && notificationToken!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SettingsField(
            label: 'Device Token',
            child: ShadCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    notificationToken!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ShadButton.outline(
                      onPressed: onCopyToken,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.copy, size: 14),
                          SizedBox(width: 8),
                          Text('Copy token'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shared field layout ───────────────────────────────────────────────────────

class _SettingsField extends StatelessWidget {
  const _SettingsField({required this.label, required this.child});

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
