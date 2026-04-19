import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../widgets/app_toast_host.dart';

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
    final host = AppToastHost.maybeOf(context);
    if (host != null) {
      host.show(
        AppToastPayload(
          variant: switch (type) {
            _AppToastType.info => AppToastVariant.info,
            _AppToastType.success => AppToastVariant.success,
            _AppToastType.error => AppToastVariant.error,
          },
          message: message,
          title: title,
        ),
      );
      return;
    }

    final sonner = ShadSonner.maybeOf(context);
    if (sonner == null) {
      debugPrint('AppToastHost and ShadSonner are both unavailable.');
      return;
    }

    sonner.show(
      ShadToast(
        title: Text(title ?? message),
        description: title == null ? null : Text(message),
      ),
      append: false,
    );
  }
}
