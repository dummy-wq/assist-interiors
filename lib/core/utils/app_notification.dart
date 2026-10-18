import 'package:flutter/material.dart';

/// Centralized utility for throttled, rate-limited user feedback and notifications.
/// Prevents notification queue buildup when users rapidly spam interactive buttons.
class AppNotification {
  AppNotification._();

  static DateTime? _lastNotificationTime;
  static const Duration defaultCooldown = Duration(milliseconds: 1200);

  @visibleForTesting
  static void resetCooldown() {
    _lastNotificationTime = null;
  }

  /// Shows a floating SnackBar with built-in rate-limiting and queue clearing.
  /// If called again before [cooldown] has elapsed, subsequent triggers are ignored.
  /// If a snackbar is already active when a valid new one arrives, it replaces it instantly.
  static void show(
    BuildContext context, {
    required String message,
    Duration cooldown = defaultCooldown,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final now = DateTime.now();
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < cooldown) {
      // Ignored: Rate-limit window active, preventing spam queue buildup
      return;
    }
    _lastNotificationTime = now;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }
}
