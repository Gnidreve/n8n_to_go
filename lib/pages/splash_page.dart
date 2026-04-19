import 'dart:async';

import 'package:flutter/material.dart';

import '../services/config_service.dart';
import '../services/push_notifications_service.dart';
import '../widgets/themed_svg_asset.dart';
import 'home_page.dart';
import 'setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _configLoadTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    Widget nextPage = const SetupPage();
    String? startupErrorMessage;

    try {
      await ConfigService.instance.load().timeout(_configLoadTimeout);
      if (ConfigService.instance.isConfigured) {
        nextPage = const HomePage();
      }
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Splash init timed out: $error');
      debugPrintStack(stackTrace: stackTrace);
      startupErrorMessage =
          'Saved app configuration could not be loaded in time. Please reconnect your n8n instance.';
    } catch (error, stackTrace) {
      debugPrint('Splash init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      startupErrorMessage =
          'Saved app configuration could not be loaded. Please reconnect your n8n instance.';
    }

    if (!mounted) return;

    final next = startupErrorMessage == null
        ? nextPage
        : SetupPage(startupErrorMessage: startupErrorMessage);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => next));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationsService.instance.consumePendingNotificationNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const ThemedSvgAsset(
          lightAsset: 'lib/assets/splash-screem.svg',
          darkAsset: 'lib/assets/splash-screen.dark.svg',
          width: 160,
        ),
      ),
    );
  }
}
