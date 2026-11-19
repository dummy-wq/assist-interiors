import 'package:flutter/material.dart';

/// Displays a calm, subtly animated dialog (160ms fade + gentle 0.96 -> 1.0 scale)
/// used consistently across viewers, confirmation popups, and forms.
Future<T?> showStudioDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Dismiss dialog',
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.54),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogCtx, _, _) => builder(dialogCtx),
    transitionBuilder: (dialogCtx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
