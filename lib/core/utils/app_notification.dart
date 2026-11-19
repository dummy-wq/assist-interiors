import 'package:flutter/material.dart';

/// Centralized utility for instant, non-queuing user feedback and notifications.
/// Always clears any previous or queued SnackBars so only the latest change is shown.
class AppNotification {
  AppNotification._();

  static const Duration defaultCooldown = Duration.zero;

  @visibleForTesting
  static void resetCooldown() {
    // Retained as a no-op for test setup compatibility.
  }

  /// Shows a floating SnackBar after clearing any active or queued SnackBars,
  /// guaranteeing only the most recent status update appears on screen.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    Duration cooldown = defaultCooldown,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    messenger.clearSnackBars();
    return messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }
}
