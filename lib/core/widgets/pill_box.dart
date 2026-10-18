import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_sizes.dart';

/// A sleek, architectural pill box / chip widget with a subtle, dampened
/// micro-bounce animation on tap for adjacent selection lists.
class PillBox extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? activeColor;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final double? iconSize;
  final double? borderRadius;
  final double? minHeight;
  final double? minWidth;

  const PillBox({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.activeColor,
    this.icon,
    this.trailing,
    this.padding,
    this.fontSize,
    this.iconSize,
    this.borderRadius,
    this.minHeight,
    this.minWidth,
  });

  @override
  State<PillBox> createState() => _PillBoxState();
}

class _PillBoxState extends State<PillBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 200),
    );

    // Subtle, gentle dampened compression (0.97 scale)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onSelected();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = widget.activeColor ?? AppColors.brandPeach;

    final resolvedPadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5);
    final resolvedFontSize = widget.fontSize ?? AppSizes.chipFontSize;
    final resolvedIconSize = widget.iconSize ?? AppSizes.chipIconSize;
    final resolvedRadius = widget.borderRadius ?? AppSizes.chipRadius;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(
            minHeight: widget.minHeight ?? AppSizes.chipHeight,
            minWidth: widget.minWidth ?? 0.0,
          ),
          padding: resolvedPadding,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primary.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark ? AppColors.darkCardElevated : AppColors.lightCard),
            borderRadius: BorderRadius.circular(resolvedRadius),
            border: Border.all(
              color: widget.isSelected
                  ? primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: widget.isSelected ? 1.0 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: resolvedIconSize,
                  color: widget.isSelected
                      ? primary
                      : (isDark
                            ? AppColors.textLightSecondary
                            : AppColors.textDarkSecondary),
                ),
                SizedBox(width: resolvedIconSize > 15 ? 8 : 6),
              ],
              Text(
                widget.label,
                style: AppTypography.labelLarge(isDark).copyWith(
                  color: widget.isSelected
                      ? primary
                      : (isDark
                            ? AppColors.textLightSecondary
                            : AppColors.textDarkSecondary),
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: resolvedFontSize,
                  letterSpacing: 0.2,
                  height: 1.25,
                ),
              ),
              if (widget.trailing != null) ...[
                SizedBox(width: resolvedIconSize > 15 ? 8 : 6),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
