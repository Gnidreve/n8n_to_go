import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'pages/splash_page.dart';
import 'services/preferences_service.dart';
import 'styles.dart';

// ── Entry ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await PreferencesService.instance.load();
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
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: PreferencesService.instance.themeMode,
      home: const SplashPage(),
    );
  }
}
