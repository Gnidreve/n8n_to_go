import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static final PreferencesService instance = PreferencesService._();
  PreferencesService._();

  static const _keyThemeMode = 'theme_mode';
  static const _keyPushNotificationsEnabled = 'push_notifications_enabled';
  static const _keyPushNotificationToken = 'push_notification_token';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool _pushNotificationsEnabled = false;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  String? _pushNotificationToken;
  String? get pushNotificationToken => _pushNotificationToken;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyThemeMode);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _pushNotificationsEnabled =
        prefs.getBool(_keyPushNotificationsEnabled) ?? false;
    _pushNotificationToken = prefs.getString(_keyPushNotificationToken);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotificationsEnabled, enabled);
  }

  Future<void> setPushNotificationToken(String? token) async {
    _pushNotificationToken = token;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_keyPushNotificationToken);
      return;
    }
    await prefs.setString(_keyPushNotificationToken, token);
  }
}
