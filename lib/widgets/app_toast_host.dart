import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../styles.dart';

enum AppToastVariant { info, success, error }

class AppToastPayload {
  const AppToastPayload({
    required this.variant,
    required this.message,
    this.title,
  });

  final AppToastVariant variant;
  final String message;
  final String? title;
}

class AppToastHostScope extends InheritedWidget {
  const AppToastHostScope({
    super.key,
    required this.state,
    required super.child,
  });

  final AppToastHostState state;

  @override
  bool updateShouldNotify(AppToastHostScope oldWidget) =>
      state != oldWidget.state;
}

class AppToastHost extends StatefulWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  static AppToastHostState of(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw FlutterError(
        'Could not find AppToastHost in the ancestor widget tree.',
      );
    }
    return state;
  }

  static AppToastHostState? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppToastHostScope>();
    return scope?.state;
  }

  @override
  State<AppToastHost> createState() => AppToastHostState();
}

class _ToastEntry {
  _ToastEntry({
    required this.id,
    required this.payload,
    required this.controller,
  });

  final Object id;
  final AppToastPayload payload;
  final AnimationController controller;
  Timer? timer;
}

class AppToastHostState extends State<AppToastHost>
    with TickerProviderStateMixin {
  static const _toastDuration = Duration(seconds: 5);
  static const _animationDuration = Duration(milliseconds: 220);

  final _entries = <_ToastEntry>[];

  Object show(AppToastPayload payload) {
    final entry = _ToastEntry(
      id: UniqueKey(),
      payload: payload,
      controller: AnimationController(
        vsync: this,
        duration: _animationDuration,
        reverseDuration: _animationDuration,
      ),
    );

    setState(() {
      _entries.insert(0, entry);
    });

    entry.controller.forward();
    entry.timer = Timer(_toastDuration, () => hide(entry.id));
    return entry.id;
  }

  Future<void> hide(Object id) async {
    final entry = _entries.cast<_ToastEntry?>().firstWhere(
      (candidate) => candidate?.id == id,
      orElse: () => null,
    );
    if (entry == null) return;

    entry.timer?.cancel();
    entry.timer = null;

    if (entry.controller.status != AnimationStatus.dismissed) {
      await entry.controller.reverse();
    }

    if (!mounted) {
      entry.controller.dispose();
      return;
    }

    setState(() {
      _entries.remove(entry);
    });
    entry.controller.dispose();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.timer?.cancel();
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 16;

    return AppToastHostScope(
      state: this,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _entries.length; i++) ...[
                            IgnorePointer(
                              ignoring: false,
                              child: _ToastEntryView(
                                entry: _entries[i],
                                onDismiss: () => hide(_entries[i].id),
                              ),
                            ),
                            if (i != _entries.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToastEntryView extends StatelessWidget {
  const _ToastEntryView({required this.entry, required this.onDismiss});

  final _ToastEntry entry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: entry.controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.12),
            end: Offset.zero,
          ).animate(animation),
          child: _ToastCard(payload: entry.payload, onDismiss: onDismiss),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.payload, required this.onDismiss});

  final AppToastPayload payload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = switch (payload.variant) {
      AppToastVariant.info => theme.colorScheme.foreground,
      AppToastVariant.success => kColorSuccess,
      AppToastVariant.error => theme.colorScheme.destructive,
    };
    final icon = switch (payload.variant) {
      AppToastVariant.info => LucideIcons.info,
      AppToastVariant.success => LucideIcons.circleCheckBig,
      AppToastVariant.error => LucideIcons.circleAlert,
    };

    return ShadToast.raw(
      variant: payload.variant == AppToastVariant.error
          ? ShadToastVariant.destructive
          : ShadToastVariant.primary,
      backgroundColor: theme.colorScheme.card,
      border: ShadBorder.all(color: theme.colorScheme.border, width: 1),
      radius: theme.radius,
      padding: const EdgeInsets.all(16),
      closeIcon: const SizedBox.shrink(),
      title: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              payload.title ?? payload.message,
              style: theme.textTheme.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      description: payload.title == null
          ? null
          : Text(
              payload.message,
              style: theme.textTheme.small.copyWith(color: color),
            ),
      actionPadding: const EdgeInsetsDirectional.only(start: 12),
      action: ShadIconButton.ghost(
        icon: Icon(LucideIcons.x, size: 14, color: color),
        width: 20,
        height: 20,
        padding: EdgeInsets.zero,
        hoverBackgroundColor: const Color(0x00000000),
        hoverForegroundColor: color,
        pressedForegroundColor: color,
        foregroundColor: color.withValues(alpha: .7),
        onPressed: onDismiss,
      ),
    );
  }
}
