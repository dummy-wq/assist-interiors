import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Centralized utility for instant, non-queuing user feedback and notifications.
/// Always clears any previous or queued SnackBars so only the latest change is shown.
class AppNotification {
  AppNotification._();

  static const Duration defaultCooldown = Duration.zero;
  static const Duration defaultDuration = Duration(milliseconds: 2500);

  @visibleForTesting
  static void resetCooldown() {
    // Retained as a no-op for test setup compatibility.
  }

  /// Shows a floating SnackBar after clearing any active or queued SnackBars,
  /// guaranteeing only the most recent status update appears on screen.
  /// Displays for 2.5 seconds by default with a tiny bottom progress bar
  /// that reduces from right to left.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    Widget? content,
    Duration cooldown = defaultCooldown,
    Duration duration = defaultDuration,
    Color? backgroundColor,
    SnackBarAction? action,
    bool showCloseIcon = false,
    Color? closeIconColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    messenger.clearSnackBars();
    return messenger.showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: _NotificationContentWithProgress(
          duration: duration,
          action: action,
          child: content ?? Text(message),
        ),
        duration: duration,
        persist: false,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
      ),
    );
  }
}

class _NotificationContentWithProgress extends StatefulWidget {
  final Widget child;
  final SnackBarAction? action;
  final Duration duration;

  const _NotificationContentWithProgress({
    required this.child,
    required this.duration,
    this.action,
  });

  @override
  State<_NotificationContentWithProgress> createState() =>
      _NotificationContentWithProgressState();
}

class _NotificationContentWithProgressState
    extends State<_NotificationContentWithProgress> {
  static const Duration _tickInterval = Duration(milliseconds: 16);

  Duration? _startTimeStamp;
  Timer? _tickTimer;
  bool _didTriggerDismiss = false;

  double _computeProgress() {
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return 0.0;
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    _startTimeStamp ??= now;
    final elapsedMs = (now - _startTimeStamp!).inMilliseconds;
    return (1.0 - (elapsedMs / totalMs)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _computeProgress();
    if (progress > 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tickTimer?.isActive ?? false) return;
        _tickTimer = Timer(_tickInterval, () {
          if (mounted) {
            setState(() {});
          }
        });
      });
    } else if (!_didTriggerDismiss) {
      _didTriggerDismiss = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      });
    }

    final foregroundColor =
        DefaultTextStyle.of(context).style.color ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            widget.action != null ? 8 : 16,
            10,
          ),
          child: widget.action != null
              ? Row(
                  children: [
                    Expanded(child: widget.child),
                    const SizedBox(width: 8),
                    widget.action!,
                  ],
                )
              : widget.child,
        ),
        SizedBox(
          key: const Key('app_notification_progress_bar'),
          height: 2.5,
          width: double.infinity,
          child: ColoredBox(
            color: foregroundColor.withValues(alpha: 0.16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                key: const Key('app_notification_progress_fill'),
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                heightFactor: 1.0,
                child: ColoredBox(
                  color: foregroundColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
