import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx, BoxConstraints constraints) builder,
}) {
  final width = MediaQuery.sizeOf(context).width * 0.85;
  final constraints = BoxConstraints(maxWidth: width);
  return showShadDialog<T>(
    context: context,
    builder: (ctx) => builder(ctx, constraints),
  );
}
