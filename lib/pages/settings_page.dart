import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import '../services/preferences_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  bool _saving = false;
  bool _notifications = false;
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    final cfg = ConfigService.instance;
    _baseUrl = TextEditingController(text: cfg.displayBaseUrl);
    _apiKey = TextEditingController(text: cfg.displayApiKey);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ConfigService.instance.save(
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ShadToaster.of(context).show(
      const ShadToast(title: Text('Settings saved')),
    );
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
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsField(
            label: 'Base URL',
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
            child: ShadSelect<ThemeMode>(
              initialValue: PreferencesService.instance.themeMode,
              onChanged: (mode) {
                if (mode != null) PreferencesService.instance.setThemeMode(mode);
              },
              options: const [
                ShadOption(value: ThemeMode.system, child: Text('System')),
                ShadOption(value: ThemeMode.light,  child: Text('Light')),
                ShadOption(value: ThemeMode.dark,   child: Text('Dark')),
              ],
              selectedOptionBuilder: (context, value) => Text(switch (value) {
                ThemeMode.light  => 'Light',
                ThemeMode.dark   => 'Dark',
                ThemeMode.system => 'System',
              }),
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
