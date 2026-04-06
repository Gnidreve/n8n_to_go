import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import '../services/preferences_service.dart';
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
  bool _notifications = false;
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    final cfg = ConfigService.instance;
    final splitBaseUrl = _splitBaseUrl(cfg.displayBaseUrl);
    _baseUrl = TextEditingController(text: splitBaseUrl.url);
    _port = TextEditingController(text: splitBaseUrl.port);
    _apiKey = TextEditingController(text: cfg.displayApiKey);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _port.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final baseUrl = _buildBaseUrl(_baseUrl.text, _port.text);
    final baseUrlError = _validateBaseUrl(baseUrl);
    if (baseUrlError != null) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Invalid URL'),
          description: Text(baseUrlError),
        ),
      );
      return;
    }

    final portError = _validatePort(_port.text);
    if (portError != null) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Invalid port'),
          description: Text(portError),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await ConfigService.instance.save(
      baseUrl: baseUrl,
      apiKey: _apiKey.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ShadToaster.of(context).show(
      const ShadToast(title: Text('Settings saved')),
    );
  }

  ({String url, String port}) _splitBaseUrl(String rawValue) {
    final normalizedValue = rawValue.trim();
    final uri = Uri.tryParse(normalizedValue);
    if (uri == null || uri.host.isEmpty) {
      return (url: normalizedValue, port: '');
    }

    final hasExplicitPort = normalizedValue.contains(':${uri.port}');
    return (
      url: uri.replace(port: null).toString().replaceAll(RegExp(r'/$'), ''),
      port: hasExplicitPort ? '${uri.port}' : '',
    );
  }

  String _buildBaseUrl(String rawUrl, String rawPort) {
    final normalizedUrl = rawUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || uri.host.isEmpty) return normalizedUrl;

    final port = rawPort.trim();
    if (port.isEmpty) {
      return uri.replace(port: null).toString().replaceAll(RegExp(r'/$'), '');
    }

    final parsedPort = int.tryParse(port);
    if (parsedPort == null) return normalizedUrl;
    return uri.replace(port: parsedPort).toString().replaceAll(RegExp(r'/$'), '');
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

  @override
  Widget build(BuildContext context) {
    final cfg = ConfigService.instance;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
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
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SettingsField(
                  label: 'URL',
                  child: ShadInput(
                    controller: _baseUrl,
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
                    controller: _port,
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
                    controller: _apiKey,
                    placeholder: const Text('Your n8n API key'),
                    leading: const Icon(LucideIcons.lock),
                    enabled: cfg.apiKeyEditable,
                    obscureText: _apiKeyObscured,
                    trailing: SizedBox.square(
                      dimension: 24,
                      child: OverflowBox(
                        maxWidth: 28,
                        maxHeight: 28,
                        child: ShadIconButton(
                          iconSize: 20,
                          padding: const EdgeInsets.all(2),
                          icon: Icon(
                            _apiKeyObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                          ),
                          onPressed: () {
                            setState(() {
                              _apiKeyObscured = !_apiKeyObscured;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ShadSeparator.horizontal(
                  thickness: 4,
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  radius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 24),
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
                          Text(
                            switch (value) {
                              ThemeMode.light => 'Light',
                              ThemeMode.dark => 'Dark',
                              ThemeMode.system => 'System',
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ShadSeparator.horizontal(
                  thickness: 4,
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  radius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 24),
                ShadCheckbox(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  label: const Text('Enable notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ShadButton.destructive(
              width: double.infinity,
              onPressed: () async {
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
              },
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}

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
