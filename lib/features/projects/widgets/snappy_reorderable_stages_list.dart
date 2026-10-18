import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assist_interiors_dashboard/core/theme/app_colors.dart';

/// Ultra-snappy, tactile reorderable list for project milestone stages.
/// Replaces Flutter's sluggish 250ms hardcoded ReorderableListView with a crisp,
/// instant magnetic snap (90ms) and 100ms item displacement physics.
class SnappyReorderableStagesList extends StatefulWidget {
  final List<Map<String, dynamic>> stages;
  final Color color;
  final bool isDark;
  final bool isReadOnly;
  final void Function(int stageIndex) onToggleStage;
  final void Function(int stageIndex) onRemoveStage;
  final void Function(int oldIndex, int newIndex) onReorderStage;

  const SnappyReorderableStagesList({
    super.key,
    required this.stages,
    required this.color,
    required this.isDark,
    this.isReadOnly = false,
    required this.onToggleStage,
    required this.onRemoveStage,
    required this.onReorderStage,
  });

  @override
  State<SnappyReorderableStagesList> createState() =>
      _SnappyReorderableStagesListState();
}

class _SnappyReorderableStagesListState
    extends State<SnappyReorderableStagesList>
    with SingleTickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  late final List<GlobalKey> _itemKeys;

  int? _draggingIndex;
  int? _targetIndex;
  double _currentDragY = 0.0;
  double _initialDragY = 0.0;
  double _dragStartY = 0.0;
  double _itemPitch = 44.0; // fallback estimated height + vertical margin

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  bool _isSnapping = false;

  final Map<int, double> _itemTops = {};
  final Map<int, double> _itemHeights = {};

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.stages.length, (_) => GlobalKey());
    _snapController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 90,
          ), // High-speed magnetic snap
        )..addListener(() {
          if (_isSnapping && _snapAnimation != null) {
            setState(() {
              _currentDragY = _snapAnimation!.value;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant SnappyReorderableStagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stages.length != _itemKeys.length) {
      _itemKeys.clear();
      _itemKeys.addAll(List.generate(widget.stages.length, (_) => GlobalKey()));
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _measureItems() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    _itemTops.clear();
    _itemHeights.clear();

    for (int i = 0; i < widget.stages.length; i++) {
      if (i < _itemKeys.length) {
        final itemBox =
            _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (itemBox != null && itemBox.hasSize) {
          final localPos = stackBox.globalToLocal(
            itemBox.localToGlobal(Offset.zero),
          );
          _itemTops[i] = localPos.dy;
          _itemHeights[i] = itemBox.size.height;
        }
      }
    }

    if (_itemHeights.isNotEmpty) {
      final avgHeight =
          _itemHeights.values.reduce((a, b) => a + b) / _itemHeights.length;
      _itemPitch = avgHeight + 6.0; // item height + 6px vertical margin
    }
  }

  void _onDragStart(int index, DragStartDetails details) {
    if (_isSnapping) return;
    _measureItems();

    final startTop = _itemTops[index] ?? (index * _itemPitch);
    HapticFeedback.mediumImpact();
    setState(() {
      _draggingIndex = index;
      _targetIndex = index;
      _initialDragY = startTop;
      _currentDragY = startTop;
      _dragStartY = details.globalPosition.dy;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_draggingIndex == null || _isSnapping) return;

    final dy = details.globalPosition.dy - _dragStartY;
    final newDragY = _initialDragY + dy;

    // Determine target slot
    int bestSlot = _draggingIndex!;
    double minDistance = double.infinity;
    final draggedCenter =
        newDragY + (_itemHeights[_draggingIndex!] ?? _itemPitch) / 2;

    for (int i = 0; i < widget.stages.length; i++) {
      final slotTop = _itemTops[i] ?? (i * _itemPitch);
      final slotHeight = _itemHeights[i] ?? _itemPitch;
      final slotCenter = slotTop + (slotHeight / 2);
      final distance = (draggedCenter - slotCenter).abs();

      if (distance < minDistance) {
        minDistance = distance;
        bestSlot = i;
      }
    }

    bestSlot = bestSlot.clamp(0, widget.stages.length - 1);
    if (bestSlot != _targetIndex) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentDragY = newDragY;
      _targetIndex = bestSlot;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_draggingIndex == null || _isSnapping) return;

    final targetIdx = _targetIndex ?? _draggingIndex!;
    final targetTop = _itemTops[targetIdx] ?? (targetIdx * _itemPitch);

    _isSnapping = true;
    _snapAnimation = Tween<double>(begin: _currentDragY, end: targetTop)
        .animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutQuad),
        );

    _snapController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      final from = _draggingIndex;
      final to = _targetIndex;

      setState(() {
        _draggingIndex = null;
        _targetIndex = null;
        _isSnapping = false;
      });

      if (from != null && to != null && from != to) {
        HapticFeedback.lightImpact();
        widget.onReorderStage(from, to);
      }
    });
  }

  void _onDragCancel() {
    if (_draggingIndex == null || _isSnapping) return;

    final originalTop =
        _itemTops[_draggingIndex!] ?? (_draggingIndex! * _itemPitch);
    _isSnapping = true;
    _snapAnimation = Tween<double>(begin: _currentDragY, end: originalTop)
        .animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutQuad),
        );

    _snapController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _draggingIndex = null;
        _targetIndex = null;
        _isSnapping = false;
      });
    });
  }

  double _computeShiftForIndex(int i) {
    if (_draggingIndex == null || _targetIndex == null) return 0.0;
    if (i == _draggingIndex) return 0.0;

    final shiftAmount =
        (_itemHeights[_draggingIndex!] ?? _itemPitch - 6.0) + 6.0;

    if (_targetIndex! > _draggingIndex!) {
      // Dragging down: items between draggingIndex+1 and targetIndex shift UP
      if (i > _draggingIndex! && i <= _targetIndex!) {
        return -shiftAmount;
      }
    } else if (_targetIndex! < _draggingIndex!) {
      // Dragging up: items between targetIndex and draggingIndex-1 shift DOWN
      if (i >= _targetIndex! && i < _draggingIndex!) {
        return shiftAmount;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = widget.color;
    final stages = widget.stages;

    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        // Static / Displacing List
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(stages.length, (index) {
            final shiftY = _computeShiftForIndex(index);
            final isCurrentDragged = index == _draggingIndex;

            return AnimatedContainer(
              key: index < _itemKeys.length ? _itemKeys[index] : null,
              duration: const Duration(
                milliseconds: 100,
              ), // Crisp 100ms displacement
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, shiftY, 0),
              child: Opacity(
                opacity: isCurrentDragged ? 0.0 : 1.0,
                child: _buildStageItem(index, isFloating: false),
              ),
            );
          }),
        ),

        // Floating Dragged Item (Only during active drag or magnetic snap)
        if (_draggingIndex != null && _draggingIndex! < stages.length)
          Positioned(
            left: 0,
            right: 0,
            top: _currentDragY,
            child: IgnorePointer(
              ignoring: _isSnapping,
              child: Material(
                elevation: 2.5,
                shadowColor: Colors.black.withValues(
                  alpha: isDark ? 0.22 : 0.08,
                ),
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  side: BorderSide(
                    color: color.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1.006, 0.994, 1.0),
                  child: _buildStageItem(_draggingIndex!, isFloating: true),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStageItem(int stageIdx, {required bool isFloating}) {
    final stage = widget.stages[stageIdx];
    final bool isDone = stage['isDone'] as bool;
    final stageId = stage['id'] ?? 'stage_${stageIdx}_${stage['title']}';
    final isDark = widget.isDark;
    final color = widget.color;

    return Container(
      key: ValueKey(stageId),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: BoxDecoration(
        color: isFloating
            ? (isDark ? AppColors.darkCardElevated : AppColors.lightCard)
            : (isDark
                  ? AppColors.darkCard.withValues(alpha: 0.5)
                  : AppColors.lightBackground.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(4.0),
        border: isFloating
            ? null
            : Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.5),
                width: 0.8,
              ),
      ),
      child: Row(
        children: [
          // 3-Line Drag Handle for Ultra-Fast Reordering (hidden in read-only mode)
          if (!widget.isReadOnly)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (details) => _onDragStart(stageIdx, details),
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onVerticalDragCancel: _onDragCancel,
              child: MouseRegion(
                cursor: _draggingIndex != null
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 10,
                    left: 2,
                    top: 4,
                    bottom: 4,
                  ),
                  child: Icon(
                    Icons.reorder_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 4),

          // Square Checkbox Container
          InkWell(
            onTap: (isFloating || widget.isReadOnly)
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onToggleStage(stageIdx);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: isDone
                      ? color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.black,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Stage Step Number
          Text(
            '${(stageIdx + 1).toString().padLeft(2, '0')}.',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: isDone
                  ? (isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted)
                  : (isDark
                        ? AppColors.textLightSecondary
                        : AppColors.textDarkSecondary),
            ),
          ),
          const SizedBox(width: 8),

          // Stage Title with Strikethrough when checked
          Expanded(
            child: InkWell(
              onTap: (isFloating || widget.isReadOnly)
                  ? null
                  : () => widget.onToggleStage(stageIdx),
              child: Text(
                stage['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  decoration: isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: isDark
                      ? AppColors.textLightMuted
                      : AppColors.textDarkMuted,
                  color: isDone
                      ? (isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted)
                      : (isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary),
                  fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
          ),

          // Subtle remove stage button (hidden in read-only mode)
          if (!widget.isReadOnly && widget.stages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 14),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              color: isDark
                  ? AppColors.textLightMuted
                  : AppColors.textDarkMuted,
              onPressed: isFloating
                  ? null
                  : () => widget.onRemoveStage(stageIdx),
            ),
        ],
      ),
    );
  }
}
