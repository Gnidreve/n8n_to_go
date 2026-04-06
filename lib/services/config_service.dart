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
    _baseUrl = _baseUrlFromStorage ? storedBase : dotenv.env['BASE_URL'];
    _apiKey = _apiKeyFromStorage ? storedKey : dotenv.env['API_KEY'];
  }

  /// Normalized base URL for API calls
  String get baseUrl => (_baseUrl ?? '').replaceAll(RegExp(r'/$'), '');
  String get apiKey => _apiKey ?? '';

  bool get isConfigured =>
      (_baseUrl?.isNotEmpty == true) && (_apiKey?.isNotEmpty == true);

  // Settings UI helpers
  bool get hasEnvBaseUrl => dotenv.env['BASE_URL']?.isNotEmpty == true;
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
}
