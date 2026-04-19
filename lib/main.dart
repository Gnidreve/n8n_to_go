import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';

import 'pages/splash_page.dart';
import 'services/preferences_service.dart';
import 'services/push_notifications_service.dart';
import 'styles.dart';
import 'widgets/app_toast_host.dart';

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
  static const _themeTransitionDuration = Duration(milliseconds: 200);
  static const _themeTransitionCurve = Curves.easeInOutCubic;
  static const _sonnerHorizontalPadding = 16.0;
  static const _sonnerBottomPadding = 16.0;
  static const _sonnerTopSpacing = 16.0;

  Timer? _systemUiSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PreferencesService.instance.addListener(_onPrefsChanged);
    _scheduleSystemUIUpdate(immediate: true);
    PushNotificationsService.instance.configureNotificationNavigation();
  }

  @override
  void dispose() {
    _systemUiSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    PreferencesService.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  // Also react when the OS-level brightness changes (ThemeMode.system case).
  @override
  void didChangePlatformBrightness() {
    if (PreferencesService.instance.themeMode == ThemeMode.system) {
      _scheduleSystemUIUpdate();
    }
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  void _onPrefsChanged() {
    setState(() {});
    _scheduleSystemUIUpdate();
  }

  void _scheduleSystemUIUpdate({bool immediate = false}) {
    _systemUiSyncTimer?.cancel();
    if (immediate) {
      _applySystemUI();
      return;
    }

    _systemUiSyncTimer = Timer(_themeTransitionDuration ~/ 2, () {
      if (mounted) _applySystemUI();
    });
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

  EdgeInsets _resolveSonnerPadding() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return const EdgeInsets.fromLTRB(
        _sonnerHorizontalPadding,
        _sonnerTopSpacing,
        _sonnerHorizontalPadding,
        _sonnerBottomPadding,
      );
    }

    final view = views.first;
    final topInset = view.padding.top / view.devicePixelRatio;
    return EdgeInsets.fromLTRB(
      _sonnerHorizontalPadding,
      topInset + _sonnerTopSpacing,
      _sonnerHorizontalPadding,
      _sonnerBottomPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sonnerPadding = _resolveSonnerPadding();

    return ShadApp(
      navigatorKey: appNavigatorKey,
      theme: appTheme.copyWith(
        sonnerTheme: appTheme.sonnerTheme.copyWith(padding: sonnerPadding),
      ),
      darkTheme: appDarkTheme.copyWith(
        sonnerTheme: appDarkTheme.sonnerTheme.copyWith(padding: sonnerPadding),
      ),
      builder: (context, child) =>
          AppToastHost(child: child ?? const SizedBox.shrink()),
      themeMode: PreferencesService.instance.themeMode,
      themeCurve: _themeTransitionCurve,
      materialThemeBuilder: (context, theme) {
        final shadTheme = ShadTheme.of(context);
        return theme.copyWith(
          appBarTheme: theme.appBarTheme.copyWith(
            // Temporary: slightly increase the global app bar height for review.
            toolbarHeight: 62,
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
