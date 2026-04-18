import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import '../services/push_notifications_service.dart';
import 'home_page.dart';
import 'setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ConfigService.instance.load();
    if (!mounted) return;
    final next = ConfigService.instance.isConfigured
        ? const HomePage()
        : const SetupPage();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationsService.instance.consumePendingNotificationNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset('lib/assets/splash-screem.svg', width: 160),
      ),
    );
  }
}
