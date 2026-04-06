import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/config_service.dart';
import 'home_page.dart';
import 'setup_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progress = _controller.drive(Tween(begin: 0.0, end: 1.0));
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      ConfigService.instance.load(),
      _controller.forward(),
    ]);
    if (!mounted) return;
    final next = ConfigService.instance.isConfigured
        ? const HomePage()
        : const SetupPage();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('lib/assets/splash-screem.svg', width: 160),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.6,
              ),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => ShadProgress(value: _progress.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
