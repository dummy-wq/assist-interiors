import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Displays a centered modal detail box that expands quickly (~170ms) into
/// roughly 75% of the viewport, providing a shared template across all screens
/// for inspecting and acting on any list item or summary card.
/// Supports medium-gesture flick-to-dismiss in any direction.
Future<T?> showExpandedDetailBox<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  IconData? headerIcon,
  Color accentColor = AppColors.brandPeach,
  String? badgeLabel,
  Color? badgeColor,
  required WidgetBuilder bodyBuilder,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
}) {
  HapticFeedback.selectionClick();

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss detail view',
    barrierColor: Colors.black.withValues(alpha: 0.54),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogCtx, _, _) {
      return _ExpandedDetailBoxScaffold(
        title: title,
        subtitle: subtitle,
        headerIcon: headerIcon,
        accentColor: accentColor,
        badgeLabel: badgeLabel,
        badgeColor: badgeColor,
        bodyBuilder: bodyBuilder,
        actionsBuilder: actionsBuilder,
      );
    },
    transitionBuilder: (dialogCtx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          alignment: Alignment.center,
          child: child,
        ),
      );
    },
  );
}

/// Wraps any modal card or dialog so the user can flick or drag it away with a
/// medium gesture in any direction (up, down, left, right) without interfering
/// with normal button taps or inner scroll views.
class FlickDismissibleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;
  final ScrollController? scrollController;

  const FlickDismissibleCard({
    super.key,
    required this.child,
    required this.onDismiss,
    this.scrollController,
  });

  @override
  State<FlickDismissibleCard> createState() => _FlickDismissibleCardState();
}

class _FlickDismissibleCardState extends State<FlickDismissibleCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  Offset _resetStartOffset = Offset.zero;
  Offset? _pointerDownPosition;
  double _pointerDownLocalY = 0.0;
  int? _activePointer;
  VelocityTracker? _velocityTracker;
  bool _isDragging = false;
  bool _isDismissed = false;

  late final AnimationController _resetController;
  late final Animation<double> _resetCurve;

  static const double _dragSlop = 8.0;
  static const double _mediumVelocityThreshold = 340.0;
  static const double _fastFlickVelocityThreshold = 460.0;
  static const double _minFlickDisplacement = 20.0;
  static const double _mediumDistanceThreshold = 70.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addListener(() {
        if (mounted && !_isDismissed) {
          setState(() {
            _dragOffset = Offset.lerp(
              _resetStartOffset,
              Offset.zero,
              _resetCurve.value,
            )!;
          });
        }
      });
    _resetCurve = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  bool _canStartCardDrag(Offset totalDelta, Offset stepDelta, double cardHeight) {
    // 1. Horizontal gesture dominates
    if (totalDelta.dx.abs() > totalDelta.dy.abs() * 1.05) {
      return true;
    }
    // 2. Gesture started on header or footer regions
    if (_pointerDownLocalY <= 72.0 ||
        (cardHeight > 0 && _pointerDownLocalY >= cardHeight - 72.0)) {
      return true;
    }
    // 3. No inner scrollable or content fits without scrolling
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) {
      return true;
    }
    final pos = sc.position;
    if (pos.maxScrollExtent <= 0.5) {
      return true;
    }
    // 4. Inner scroll is at top edge and dragging downward, or at bottom edge and dragging upward
    if (sc.offset <= 0.5 && (stepDelta.dy > 0 || totalDelta.dy > 0)) {
      return true;
    }
    if (sc.offset >= pos.maxScrollExtent - 0.5 &&
        (stepDelta.dy < 0 || totalDelta.dy < 0)) {
      return true;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isDismissed) return;
    _resetController.stop();
    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
    _pointerDownLocalY = event.localPosition.dy;
    _velocityTracker = VelocityTracker.withKind(event.kind);
    _velocityTracker!.addPosition(event.timeStamp, event.position);
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event, double cardHeight) {
    if (_isDismissed || event.pointer != _activePointer) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final downPos = _pointerDownPosition;
    if (downPos == null) return;

    final totalDelta = event.position - downPos;
    if (!_isDragging) {
      if (totalDelta.distance < _dragSlop) return;
      if (_canStartCardDrag(totalDelta, event.delta, cardHeight)) {
        _isDragging = true;
      }
    }

    if (_isDragging) {
      setState(() {
        _dragOffset += event.delta;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isDismissed || event.pointer != _activePointer) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final velocity =
        _velocityTracker?.getVelocity().pixelsPerSecond ?? Offset.zero;
    final totalDelta =
        event.position - (_pointerDownPosition ?? event.position);

    _activePointer = null;
    _pointerDownPosition = null;

    final speed = velocity.distance;
    final draggedDistance = _dragOffset.distance;

    final shouldDismiss = (_isDragging &&
            ((speed >= _mediumVelocityThreshold &&
                    draggedDistance >= _minFlickDisplacement) ||
                draggedDistance >= _mediumDistanceThreshold)) ||
        (speed >= _fastFlickVelocityThreshold && totalDelta.distance >= 36.0);

    _isDragging = false;

    if (shouldDismiss) {
      _isDismissed = true;
      HapticFeedback.lightImpact();
      if (speed > 100.0) {
        final unitVelocity = velocity / speed;
        setState(() {
          _dragOffset += unitVelocity * 36.0;
        });
      }
      widget.onDismiss();
      return;
    }

    if (_dragOffset != Offset.zero) {
      _resetStartOffset = _dragOffset;
      _resetController.forward(from: 0.0);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isDismissed || event.pointer != _activePointer) return;
    _activePointer = null;
    _pointerDownPosition = null;
    _isDragging = false;
    if (_dragOffset != Offset.zero) {
      _resetStartOffset = _dragOffset;
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        final double rotation = (_dragOffset.dx / 1800.0).clamp(-0.07, 0.07);
        final double opacity =
            (1.0 - (_dragOffset.distance / 520.0)).clamp(0.35, 1.0);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: (e) => _onPointerMove(e, cardHeight),
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpandedDetailBoxScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? headerIcon;
  final Color accentColor;
  final String? badgeLabel;
  final Color? badgeColor;
  final WidgetBuilder bodyBuilder;
  final List<Widget> Function(BuildContext dialogContext)? actionsBuilder;

  const _ExpandedDetailBoxScaffold({
    required this.title,
    this.subtitle,
    this.headerIcon,
    required this.accentColor,
    this.badgeLabel,
    this.badgeColor,
    required this.bodyBuilder,
    this.actionsBuilder,
  });

  @override
  State<_ExpandedDetailBoxScaffold> createState() =>
      _ExpandedDetailBoxScaffoldState();
}

class _ExpandedDetailBoxScaffoldState
    extends State<_ExpandedDetailBoxScaffold> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final double targetWidth = size.width >= 600
        ? (size.width * 0.75).clamp(440.0, 900.0)
        : (size.width * 0.88).clamp(280.0, 520.0);
    final double targetHeight =
        ((size.height - viewInsets.bottom) * 0.75).clamp(260.0, 780.0);

    final effectiveBadgeColor = widget.badgeColor ?? widget.accentColor;
    final actions = widget.actionsBuilder?.call(context) ?? const <Widget>[];

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Material(
            color: Colors.transparent,
            child: FlickDismissibleCard(
              scrollController: _scrollController,
              onDismiss: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                key: const Key('expanded_detail_box_container'),
                width: targetWidth,
                height: targetHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar with subtle flick handle
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 10, 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9.0),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 3.5,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted)
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.headerIcon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: widget.accentColor
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: widget.accentColor
                                          .withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.headerIcon,
                                    color: widget.accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleLarge(
                                        isDark,
                                      ).copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (widget.subtitle != null &&
                                        widget.subtitle!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.subtitle!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall(isDark)
                                            .copyWith(fontSize: 11.5),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.badgeLabel != null &&
                                  widget.badgeLabel!.trim().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: effectiveBadgeColor.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color: effectiveBadgeColor.withValues(
                                        alpha: 0.65,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    widget.badgeLabel!,
                                    style: AppTypography.labelSmall(
                                      isDark,
                                    ).copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: effectiveBadgeColor,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 4),
                              IconButton(
                                key: const Key('expanded_detail_close_btn'),
                                icon:
                                    const Icon(Icons.close_rounded, size: 20),
                                tooltip: 'Close',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Detail Body
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: widget.bodyBuilder(context),
                      ),
                    ),

                    // Footer Actions Bar (equal width & equal 40px height buttons)
                    if (actions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightBackground,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(9.0),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)
                                  .withValues(alpha: 0.7),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (int i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: actions[i],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercase section heading for expanded detail cards.
class DetailSectionTitle extends StatelessWidget {
  final String label;
  final bool isDark;

  const DetailSectionTitle({
    super.key,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall(isDark).copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
        ),
      ),
    );
  }
}

/// Key-value metric data for [DetailMetricGrid].
class DetailMetric {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const DetailMetric({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });
}

/// Responsive 2-column metric grid inside expanded detail dialogs.
class DetailMetricGrid extends StatelessWidget {
  final List<DetailMetric> metrics;
  final bool isDark;

  const DetailMetricGrid({
    super.key,
    required this.metrics,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < metrics.length; i += 2) {
      final first = metrics[i];
      final second = i + 1 < metrics.length ? metrics[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _buildTile(first)),
            const SizedBox(width: 8),
            Expanded(
              child: second != null ? _buildTile(second) : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < metrics.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
  }

  Widget _buildTile(DetailMetric m) {
    final valueColor = m.color ??
        (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (m.icon != null) ...[
                Icon(
                  m.icon,
                  size: 12,
                  color: m.color ?? AppColors.brandPeach,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  m.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall(isDark).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              m.value,
              maxLines: 1,
              style: AppTypography.titleMedium(isDark).copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single labeled attribute row inside expanded detail dialogs.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: AppTypography.bodySmall(isDark).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium(isDark).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppColors.textLightPrimary
                        : AppColors.textDarkPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Highlighted note / description box inside expanded detail dialogs.
class DetailNoteBox extends StatelessWidget {
  final String label;
  final String text;
  final bool isDark;

  const DetailNoteBox({
    super.key,
    required this.label,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall(isDark).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.brandPeach,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTypography.bodyMedium(isDark).copyWith(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColors.textLightSecondary
                  : AppColors.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
