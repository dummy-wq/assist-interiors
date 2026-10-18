import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A sleek, instantaneous tactile feedback wrapper.
/// Provides a snappy 90ms dampened scale compression (0.985) on tap/press
/// with optional subtle haptic impact without lag or heavy libraries.
class InstantPressFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  final double compressionScale;
  final Duration duration;
  final bool enableHaptic;

  const InstantPressFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.behavior = HitTestBehavior.opaque,
    this.compressionScale = 0.985,
    this.duration = const Duration(milliseconds: 90),
    this.enableHaptic = true,
  });

  @override
  State<InstantPressFeedback> createState() => _InstantPressFeedbackState();
}

class _InstantPressFeedbackState extends State<InstantPressFeedback> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent _) {
    if (mounted) setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent _) {
    if (mounted) setState(() => _isPressed = false);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (mounted) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedScale(
      scale: _isPressed ? widget.compressionScale : 1.0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        behavior: widget.behavior,
        onTap: () {
          if (widget.enableHaptic) {
            HapticFeedback.lightImpact();
          }
          widget.onTap?.call();
        },
        child: content,
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: content,
    );
  }
}
