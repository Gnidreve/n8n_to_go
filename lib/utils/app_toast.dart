import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../styles.dart';

enum _AppToastType { info, success, error }

class AppToast {
  const AppToast._();

  static void info(BuildContext context, String message, {String? title}) {
    _show(context, type: _AppToastType.info, message: message, title: title);
  }

  static void success(BuildContext context, String message, {String? title}) {
    _show(context, type: _AppToastType.success, message: message, title: title);
  }

  static void error(BuildContext context, String message, {String? title}) {
    _show(context, type: _AppToastType.error, message: message, title: title);
  }

  static void _show(
    BuildContext context, {
    required _AppToastType type,
    required String message,
    String? title,
  }) {
    final theme = ShadTheme.of(context);
    final sonner = ShadSonner.of(context);
    final color = switch (type) {
      _AppToastType.info => theme.colorScheme.foreground,
      _AppToastType.success => kColorSuccess,
      _AppToastType.error => theme.colorScheme.destructive,
    };
    final icon = switch (type) {
      _AppToastType.info => LucideIcons.info,
      _AppToastType.success => LucideIcons.circleCheckBig,
      _AppToastType.error => LucideIcons.circleAlert,
    };

    sonner.show(
      ShadToast(
        title: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title ?? message,
                style: theme.textTheme.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        description: title == null
            ? null
            : Text(
                message,
                style: theme.textTheme.small.copyWith(color: color),
              ),
        backgroundColor: theme.colorScheme.card,
      ),
    );
  }
}
