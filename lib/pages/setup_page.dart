import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../api/api.dart';
import '../services/config_service.dart';
import 'home_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _baseUrl = TextEditingController();
  final _port = TextEditingController();
  final _apiKey = TextEditingController();
  final _loginBaseUrl = TextEditingController();
  final _loginPort = TextEditingController(text: '5678');
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _saving = false;
  bool _apiKeyObscured = true;
  bool _loginPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    final splitBaseUrl = _splitBaseUrl(ConfigService.instance.displayBaseUrl);
    _baseUrl.text = splitBaseUrl.url;
    _port.text = splitBaseUrl.port;
    _loginBaseUrl.text = splitBaseUrl.url;
    _loginPort.text = splitBaseUrl.port.isEmpty ? '5678' : splitBaseUrl.port;
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _port.dispose();
    _apiKey.dispose();
    _loginBaseUrl.dispose();
    _loginPort.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final normalizedBaseUrl = _buildBaseUrl(_baseUrl.text, _port.text);
    final apiKey = _apiKey.text.trim();

    if (normalizedBaseUrl.isEmpty || apiKey.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Please fill in both fields'),
        ),
      );
      return;
    }

    final baseUrlError = _validateBaseUrl(normalizedBaseUrl);
    if (baseUrlError != null) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Invalid base URL'),
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
    try {
      final statusCode = await audit.post(
        baseUrl: normalizedBaseUrl,
        apiKey: apiKey,
      );

      if (!mounted) return;

      if (statusCode < 200 || statusCode >= 300) {
        setState(() => _saving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Connection failed'),
            description: Text(_auditErrorMessage(statusCode)),
          ),
        );
        return;
      }

      await ConfigService.instance.save(
        baseUrl: normalizedBaseUrl,
        apiKey: apiKey,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Connection failed'),
          description: Text(
            'Could not validate your n8n instance. Check the URL, API key, and network connection.',
          ),
        ),
      );
    }
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

  String _auditErrorMessage(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'The server rejected the API key.';
    }
    if (statusCode == 404) {
      return 'The n8n API endpoint could not be found.';
    }
    if (statusCode >= 500) {
      return 'The n8n server returned an internal error.';
    }
    return 'The n8n server did not confirm the connection.';
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
                  ShadTabs<String>(
                    value: 'api-key',
                    tabBarConstraints: const BoxConstraints(maxWidth: 400),
                    contentConstraints: const BoxConstraints(maxWidth: 400),
                    tabs: [
                      ShadTab(
                        value: 'login',
                        content: ShadCard(
                          title: const Text('Login'),
                          description: const Text(
                            'Direct login is in preparation and will be added in a separate flow.',
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              _Field(
                                label: 'URL',
                                child: ShadInput(
                                  controller: _loginBaseUrl,
                                  placeholder: const Text(
                                    'https://your-n8n-instance.com',
                                  ),
                                  leading: const Icon(LucideIcons.globe),
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: 'Port',
                                child: ShadInput(
                                  controller: _loginPort,
                                  placeholder: const Text('5678'),
                                  leading: const Icon(LucideIcons.network),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: 'Email',
                                child: ShadInput(
                                  controller: _loginEmail,
                                  placeholder: const Text('you@example.com'),
                                  leading: const Icon(LucideIcons.mail),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: 'Password',
                                child: ShadInput(
                                  controller: _loginPassword,
                                  placeholder: const Text('Your password'),
                                  obscureText: _loginPasswordObscured,
                                  leading: const Icon(LucideIcons.lock),
                                  trailing: _VisibilityToggle(
                                    obscured: _loginPasswordObscured,
                                    onPressed: () {
                                      setState(() {
                                        _loginPasswordObscured =
                                            !_loginPasswordObscured;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              const ShadButton(
                                width: double.infinity,
                                enabled: false,
                                child: Text('Continue with login'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                      ShadTab(
                        value: 'api-key',
                        content: ShadCard(
                          title: const Text('API Key'),
                          description: const Text(
                            'Connect with your base URL and n8n API key.',
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              _Field(
                                label: 'URL',
                                child: ShadInput(
                                  controller: _baseUrl,
                                  placeholder: const Text(
                                    'https://your-n8n-instance.com',
                                  ),
                                  leading: const Icon(LucideIcons.globe),
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: 'Port',
                                child: ShadInput(
                                  controller: _port,
                                  placeholder: const Text('5678'),
                                  leading: const Icon(LucideIcons.network),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: 'API Key',
                                child: ShadInput(
                                  controller: _apiKey,
                                  placeholder: const Text('Your n8n API key'),
                                  obscureText: _apiKeyObscured,
                                  leading: const Icon(LucideIcons.lock),
                                  trailing: _VisibilityToggle(
                                    obscured: _apiKeyObscured,
                                    onPressed: () {
                                      setState(() {
                                        _apiKeyObscured = !_apiKeyObscured;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ShadButton(
                                width: double.infinity,
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Connect'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('API Key'),
                      ),
                    ],
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

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.obscured,
    required this.onPressed,
  });

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        maxWidth: 28,
        maxHeight: 28,
        child: ShadIconButton(
          iconSize: 20,
          padding: const EdgeInsets.all(2),
          icon: Icon(obscured ? LucideIcons.eyeOff : LucideIcons.eye),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
