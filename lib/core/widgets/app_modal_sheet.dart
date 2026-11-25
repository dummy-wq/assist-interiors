import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

/// Displays a modal bottom sheet that reliably supports swipe-down dismissal,
/// both via direct vertical drag on non-scrollable areas (including the top
/// drag handle and headers) AND when swiping downward inside scrollable
/// content ([SingleChildScrollView], [ListView], etc.) once scrolled to top.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  double? elevation,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool showDragHandleBar = true,
}) {
  final isTransparent = backgroundColor == Colors.transparent;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: null,
    clipBehavior: Clip.none,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    // SwipeDismissibleSheet is the single drag owner so Flutter's built-in
    // BottomSheet drag handler never fights or double-translates the sheet.
    enableDrag: false,
    useSafeArea: useSafeArea,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 220),
      reverseDuration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final theme = Theme.of(ctx);
      final content = builder(ctx);
      final sheetBody = showDragHandleBar && !isTransparent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetDragHandle(isDark: isDark),
                Flexible(child: content),
              ],
            )
          : content;

      // Render the opaque sheet surface inside SwipeDismissibleSheet so the
      // entire card (not just its inner widgets) physically slides downward.
      final decoratedSheet = isTransparent
          ? sheetBody
          : Material(
              color:
                  backgroundColor ??
                  theme.bottomSheetTheme.modalBackgroundColor ??
                  theme.bottomSheetTheme.backgroundColor ??
                  theme.colorScheme.surface,
              elevation: elevation ?? 0,
              shape: shape ?? AppSizes.sheetShape,
              clipBehavior: clipBehavior ?? Clip.antiAlias,
              child: sheetBody,
            );

      return ScrollConfiguration(
        behavior: const _SheetScrollBehavior(),
        child: SwipeDismissibleSheet(
          enabled: enableDrag && isDismissible,
          child: decoratedSheet,
        ),
      );
    },
  );
}

/// Clamping scroll behavior for modal bottom sheets so pulling down at the top
/// hands off 1:1 to [SwipeDismissibleSheet] without double-bouncing inner lists.
class _SheetScrollBehavior extends MaterialScrollBehavior {
  const _SheetScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class _SheetDragHandle extends StatelessWidget {
  final bool isDark;

  const _SheetDragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ),
    );
  }
}

/// Wraps modal bottom sheet content so a downward swipe either on a
/// non-scrollable area or started/carried to the top of an inner vertical
/// [Scrollable] smoothly translates the entire sheet downward and dismisses it
/// via [Navigator.maybePop].
class SwipeDismissibleSheet extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const SwipeDismissibleSheet({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<SwipeDismissibleSheet> createState() => _SwipeDismissibleSheetState();
}

class _SwipeDismissibleSheetState extends State<SwipeDismissibleSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  late final Animation<double> _resetCurve;

  double _dragOffset = 0.0;
  double _resetStartOffset = 0.0;
  bool _dragStartedAtTop = false;
  bool _isPullingDown = false;
  bool _isDismissing = false;
  double _lastVelocityY = 0.0;
  DateTime? _lastMoveTime;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _resetCurve = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    )..addListener(() {
        if (mounted && !_isDismissing) {
          setState(() {
            _dragOffset = lerpDouble(_resetStartOffset, 0.0, _resetCurve.value)!;
          });
        }
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _animateBackToZero() {
    final start = _dragOffset;
    if (start <= 0.0) {
      if (_dragOffset != 0.0) {
        setState(() => _dragOffset = 0.0);
      }
      return;
    }

    _resetStartOffset = start;
    _resetController.forward(from: 0.0);
  }

  void _recordVelocity(DragUpdateDetails? dragDetails) {
    final now = DateTime.now();
    if (dragDetails != null && _lastMoveTime != null) {
      final dtMs = now.difference(_lastMoveTime!).inMicroseconds / 1000.0;
      if (dtMs > 0) {
        _lastVelocityY = (dragDetails.delta.dy / dtMs) * 1000.0;
      }
    }
    _lastMoveTime = now;
  }

  void _finishPull([double? releaseVelocityY]) {
    if (_isDismissing) return;

    final velocityY = releaseVelocityY ?? _lastVelocityY;
    final sheetHeight = context.size?.height ?? 400.0;
    final dismissDistance = (sheetHeight * 0.18).clamp(64.0, 104.0);
    final shouldDismiss =
        _dragOffset >= dismissDistance ||
        (_dragOffset >= 40.0 && velocityY >= 320.0);

    _dragStartedAtTop = false;
    _isPullingDown = false;
    _lastVelocityY = 0.0;
    _lastMoveTime = null;

    if (shouldDismiss) {
      _isDismissing = true;
      Navigator.of(context).maybePop().then((popped) {
        if (!popped && mounted) {
          _isDismissing = false;
          _animateBackToZero();
        }
      });
    } else {
      _animateBackToZero();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.enabled || _isDismissing) return false;
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _resetController.stop();
      _dragStartedAtTop =
          notification.dragDetails != null && notification.metrics.pixels <= 0.5;
      _isPullingDown = false;
      _lastVelocityY = 0.0;
      _lastMoveTime = _dragStartedAtTop ? DateTime.now() : null;
      return false;
    }

    if (!_dragStartedAtTop) {
      if (notification is OverscrollNotification &&
          notification.overscroll < 0 &&
          notification.dragDetails != null) {
        _dragStartedAtTop = true;
      } else {
        return false;
      }
    }

    if (notification is OverscrollNotification) {
      if (notification.overscroll < 0 && notification.dragDetails != null) {
        _recordVelocity(notification.dragDetails);
        setState(() {
          _isPullingDown = true;
          _dragOffset = (_dragOffset + (-notification.overscroll)).clamp(
            0.0,
            double.infinity,
          );
        });
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0 && notification.dragDetails != null) {
        _recordVelocity(notification.dragDetails);
        setState(() {
          _isPullingDown = true;
          _dragOffset = (-notification.metrics.pixels).clamp(
            0.0,
            double.infinity,
          );
        });
      } else if (_isPullingDown && notification.dragDetails == null) {
        _finishPull();
      } else if (_isPullingDown && (notification.scrollDelta ?? 0) > 0) {
        final nextOffset = (_dragOffset - notification.scrollDelta!).clamp(
          0.0,
          double.infinity,
        );
        setState(() {
          _dragOffset = nextOffset;
          if (_dragOffset <= 0.0) {
            _isPullingDown = false;
          }
        });
      } else if (!_isPullingDown && notification.metrics.pixels > 2.0) {
        _dragStartedAtTop = false;
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_isPullingDown) {
        _finishPull(notification.dragDetails?.velocity.pixelsPerSecond.dy);
      } else {
        _dragStartedAtTop = false;
        _lastVelocityY = 0.0;
        _lastMoveTime = null;
      }
      return false;
    }

    return false;
  }

  void _handleDirectDragStart(DragStartDetails details) {
    if (!widget.enabled || _isDismissing) return;
    _resetController.stop();
    _dragStartedAtTop = false;
    _isPullingDown = false;
  }

  void _handleDirectDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isDismissing) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _handleDirectDragEnd(DragEndDetails details) {
    if (!widget.enabled || _isDismissing) return;
    if (_dragOffset > 0.0 || details.velocity.pixelsPerSecond.dy >= 240.0) {
      _finishPull(details.velocity.pixelsPerSecond.dy);
    }
  }

  void _handleDirectDragCancel() {
    if (!widget.enabled || _isDismissing) return;
    if (_dragOffset > 0.0) {
      _animateBackToZero();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: widget.enabled ? _handleDirectDragStart : null,
      onVerticalDragUpdate: widget.enabled ? _handleDirectDragUpdate : null,
      onVerticalDragEnd: widget.enabled ? _handleDirectDragEnd : null,
      onVerticalDragCancel: widget.enabled ? _handleDirectDragCancel : null,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: widget.child,
        ),
      ),
    );
  }
}
