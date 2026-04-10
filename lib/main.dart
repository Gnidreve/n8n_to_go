import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'pages/splash_page.dart';
import 'services/preferences_service.dart';
import 'services/push_notifications_service.dart';
import 'styles.dart';

// ── Entry ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await PreferencesService.instance.load();
  await PushNotificationsService.instance.initialize();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PreferencesService.instance.addListener(_onPrefsChanged);
    _applySystemUI();
    PushNotificationsService.instance.configureNotificationNavigation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PreferencesService.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  // Also react when the OS-level brightness changes (ThemeMode.system case).
  @override
  void didChangePlatformBrightness() => _applySystemUI();

  void _onPrefsChanged() {
    _applySystemUI();
    setState(() {});
  }

  void _applySystemUI() {
    final mode = PreferencesService.instance.themeMode;
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? const SystemUiOverlayStyle(
              systemNavigationBarColor: Color(0xFF171717),
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              systemNavigationBarColor: Color(0xFFfafafa),
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      navigatorKey: appNavigatorKey,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: PreferencesService.instance.themeMode,
      materialThemeBuilder: (context, theme) {
        final shadTheme = ShadTheme.of(context);
        return theme.copyWith(
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: shadTheme.colorScheme.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle:
                theme.appBarTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: shadTheme.colorScheme.foreground,
                ),
            shape: Border(
              bottom: BorderSide(color: shadTheme.colorScheme.border, width: 1),
            ),
          ),
        );
      },
      home: const SplashPage(),
    );
  }
}
