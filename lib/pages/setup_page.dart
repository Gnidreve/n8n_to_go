import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import 'home_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_baseUrl.text.trim().isEmpty || _apiKey.text.trim().isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Please fill in both fields'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await ConfigService.instance.save(
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('lib/assets/splash-screem.svg', height: 48),
                  const SizedBox(height: 24),
                  Text('n8n for mobile', style: theme.textTheme.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Connect your n8n instance',
                    style: theme.textTheme.muted,
                  ),
                  const SizedBox(height: 40),
                  _Field(
                    label: 'Base URL',
                    child: ShadInput(
                      controller: _baseUrl,
                      placeholder: const Text('https://your-n8n-instance.com'),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label: 'API Key',
                    child: ShadInput(
                      controller: _apiKey,
                      placeholder: const Text('Your n8n API key'),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShadButton(
                    width: double.infinity,
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
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
