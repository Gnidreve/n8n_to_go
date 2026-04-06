import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfigService {
  static final ConfigService instance = ConfigService._();
  ConfigService._();

  static const _keyBaseUrl = 'base_url';
  static const _keyApiKey = 'api_key';

  final _storage = const FlutterSecureStorage();

  String? _baseUrl;
  String? _apiKey;
  bool _baseUrlFromStorage = false;
  bool _apiKeyFromStorage = false;

  Future<void> load() async {
    final storedBase = await _storage.read(key: _keyBaseUrl);
    final storedKey = await _storage.read(key: _keyApiKey);

    _baseUrlFromStorage = storedBase != null && storedBase.isNotEmpty;
    _apiKeyFromStorage = storedKey != null && storedKey.isNotEmpty;

    // Secure storage takes priority over .env
    _baseUrl = _baseUrlFromStorage
        ? storedBase
        : _composeBaseUrl(
            dotenv.env['BASE_URL'],
            dotenv.env['BASE_PORT'],
          );
    _apiKey = _apiKeyFromStorage ? storedKey : dotenv.env['API_KEY'];
  }

  /// Normalized base URL for API calls
  String get baseUrl => (_baseUrl ?? '').replaceAll(RegExp(r'/$'), '');
  String get apiKey => _apiKey ?? '';

  bool get isConfigured =>
      (_baseUrl?.isNotEmpty == true) && (_apiKey?.isNotEmpty == true);

  // Settings UI helpers
  bool get hasEnvBaseUrl =>
      _composeBaseUrl(
        dotenv.env['BASE_URL'],
        dotenv.env['BASE_PORT'],
      ).isNotEmpty;
  bool get hasEnvApiKey => dotenv.env['API_KEY']?.isNotEmpty == true;

  /// Field is editable when value is from storage (user can override)
  /// or when no value exists at all. Only disabled when exclusively from .env.
  bool get baseUrlEditable => _baseUrlFromStorage || !hasEnvBaseUrl;
  bool get apiKeyEditable => _apiKeyFromStorage || !hasEnvApiKey;

  String get displayBaseUrl => _baseUrl ?? '';
  String get displayApiKey => _apiKey ?? '';

  Future<void> save({required String baseUrl, required String apiKey}) async {
    await Future.wait([
      _storage.write(key: _keyBaseUrl, value: baseUrl),
      _storage.write(key: _keyApiKey, value: apiKey),
    ]);
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _baseUrlFromStorage = true;
    _apiKeyFromStorage = true;
  }

  String _composeBaseUrl(String? rawBaseUrl, String? rawPort) {
    final baseUrl = (rawBaseUrl ?? '').trim().replaceAll(RegExp(r'/$'), '');
    if (baseUrl.isEmpty) return '';

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return baseUrl;

    final port = (rawPort ?? '').trim();
    if (port.isEmpty) return baseUrl;

    final parsedPort = int.tryParse(port);
    if (parsedPort == null) return baseUrl;

    return uri.replace(port: parsedPort).toString().replaceAll(RegExp(r'/$'), '');
  }
}
