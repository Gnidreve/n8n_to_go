import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// ── Toast helpers ─────────────────────────────────────────────────────────────
// Three states:
//   success → green title text
//   error   → red title text  (use ShadToast.destructive under the hood)
//   info    → default foreground text  (e.g. "Copied to clipboard")
//
// All three show a decorative copy icon on the left.

const _kSuccessColor = Color(0xFF86EFAC);
const _kErrorColor = Color(0xFFF87171);

Widget _toastTitle(String text, {Color? color}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(LucideIcons.copy, size: 13, color: color),
    const SizedBox(width: 6),
    Flexible(
      child: Text(text, style: color != null ? TextStyle(color: color) : null),
    ),
  ],
);

/// Shown after successful mutations (saved, deleted, created…).
void showSuccessToast(BuildContext context, String title) {
  ShadToaster.of(
    context,
  ).show(ShadToast(title: _toastTitle(title, color: _kSuccessColor)));
}

/// Shown when something goes wrong.
void showErrorToast(BuildContext context, String title, {String? description}) {
  ShadToaster.of(context).show(
    ShadToast.destructive(
      title: _toastTitle(title, color: _kErrorColor),
      description: description != null ? Text(description) : null,
    ),
  );
}

/// Shown for neutral info messages (e.g. "Copied to clipboard").
void showInfoToast(BuildContext context, String title, {String? description}) {
  ShadToaster.of(context).show(
    ShadToast(
      title: _toastTitle(title),
      description: description != null ? Text(description) : null,
    ),
  );
}
