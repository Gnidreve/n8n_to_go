import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import '../services/preferences_service.dart';
import '../services/push_notifications_service.dart';
import '../utils/app_toast.dart';
import '../utils/url_utils.dart';
import 'setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _port;
  late final TextEditingController _apiKey;
  bool _saving = false;
  bool _notificationsBusy = false;
  bool _notifications = false;
  bool _apiKeyObscured = true;
  String? _notificationToken;
  String _activeTab = 'general';

  @override
  void initState() {
    super.initState();
    final cfg = ConfigService.instance;
    final split = splitBaseUrl(cfg.displayBaseUrl);
    _baseUrl = TextEditingController(text: split.url);
    _port = TextEditingController(text: split.port);
    _apiKey = TextEditingController(text: cfg.displayApiKey);
    _notifications = PreferencesService.instance.pushNotificationsEnabled;
    _notificationToken = PreferencesService.instance.pushNotificationToken;
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _port.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final baseUrl = buildBaseUrl(_baseUrl.text, _port.text);
    final baseUrlError = _validateBaseUrl(baseUrl);
    if (baseUrlError != null) {
      AppToast.error(context, baseUrlError, title: 'Invalid URL');
      return;
    }

    final portError = _validatePort(_port.text);
    if (portError != null) {
      AppToast.error(context, portError, title: 'Invalid port');
      return;
    }

    setState(() => _saving = true);
    await ConfigService.instance.save(
      baseUrl: baseUrl,
      apiKey: _apiKey.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.success(context, 'Settings saved');
  }

  String? _validateBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid URL.';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://.';
    }
    return null;
  }

  String? _validatePort(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsedPort = int.tryParse(trimmed);
    if (parsedPort == null) {
      return 'Port must be a number.';
    }
    if (parsedPort < 1 || parsedPort > 65535) {
      return 'Port must be between 1 and 65535.';
    }
    return null;
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
            title: result.message != null ? 'Push notifications unavailable' : null,
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
    final cfg = ConfigService.instance;
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
          if (_activeTab == 'general')
            IconButton(
              icon: const Icon(LucideIcons.logOut),
              onPressed: _logout,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ShadTabs<String>(
                value: _activeTab,
                onChanged: (v) => setState(() => _activeTab = v),
                tabs: [
                  const ShadTab(
                    value: 'general',
                    content: SizedBox.shrink(),
                    child: Text('General'),
                  ),
                  const ShadTab(
                    value: 'appearance',
                    content: SizedBox.shrink(),
                    child: Text('Appearance'),
                  ),
                  if (cfg.notificationsEnabled)
                    const ShadTab(
                      value: 'notifications',
                      content: SizedBox.shrink(),
                      child: Text('Notifications'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (_activeTab) {
                'appearance' => _AppearanceTab(),
                'notifications' => _NotificationsTab(
                    notifications: _notifications,
                    notificationsBusy: _notificationsBusy,
                    notificationToken: _notificationToken,
                    pushService: pushService,
                    onToggle: _setNotificationsEnabled,
                    onCopyToken: _copyNotificationToken,
                  ),
                _ => _GeneralTab(
                    baseUrl: _baseUrl,
                    port: _port,
                    apiKey: _apiKey,
                    cfg: cfg,
                    apiKeyObscured: _apiKeyObscured,
                    onToggleObscure: () =>
                        setState(() => _apiKeyObscured = !_apiKeyObscured),
                    saving: _saving,
                    onSave: _save,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
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

// ── General tab ───────────────────────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({
    required this.baseUrl,
    required this.port,
    required this.apiKey,
    required this.cfg,
    required this.apiKeyObscured,
    required this.onToggleObscure,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController baseUrl;
  final TextEditingController port;
  final TextEditingController apiKey;
  final ConfigService cfg;
  final bool apiKeyObscured;
  final VoidCallback onToggleObscure;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsField(
          label: 'URL',
          child: ShadInput(
            controller: baseUrl,
            placeholder: const Text('https://your-n8n-instance.com'),
            leading: const Icon(LucideIcons.globe),
            enabled: cfg.baseUrlEditable,
            keyboardType: TextInputType.url,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsField(
          label: 'Port',
          child: ShadInput(
            controller: port,
            placeholder: const Text('5678'),
            leading: const Icon(LucideIcons.network),
            enabled: cfg.baseUrlEditable,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsField(
          label: 'API Key',
          child: ShadInput(
            controller: apiKey,
            placeholder: const Text('Your n8n API key'),
            leading: const Icon(LucideIcons.lock),
            enabled: cfg.apiKeyEditable,
            obscureText: apiKeyObscured,
            trailing: SizedBox.square(
              dimension: 24,
              child: OverflowBox(
                maxWidth: 28,
                maxHeight: 28,
                child: ShadIconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(2),
                  icon: Icon(
                    apiKeyObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ShadButton(
          width: double.infinity,
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Appearance tab ────────────────────────────────────────────────────────────

class _AppearanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsField(
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
                  Icon(
                    switch (value) {
                      ThemeMode.light => LucideIcons.sun,
                      ThemeMode.dark => LucideIcons.moon,
                      ThemeMode.system => LucideIcons.laptopMinimal,
                    },
                    size: 16,
                  ),
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
        ),
      ],
    );
  }
}

// ── Notifications tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enable Firebase Cloud Messaging for this device.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ShadTheme.of(context).colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            notificationsBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch.adaptive(
                    value: notifications,
                    onChanged: onToggle,
                  ),
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
