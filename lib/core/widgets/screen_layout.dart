import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_typography.dart';

/// Shared layout primitives for every top-level tab screen.
///
/// Every screen follows the same vertical rhythm:
///
/// ```text
/// ScreenHeader
///   ── headerGap ──
/// StatStrip
///   ── noticeGap ── ReadOnlyNotice (optional)
///   ── sectionGap ──
/// ScreenSearchField (optional)
///   ── controlGap ──
/// Filter pills
///   ── listGap ──
/// FilterSwitcher(list | EmptyStateCard)
/// ```
class ScreenLayout {
  ScreenLayout._();

  /// Horizontal page gutter. Shared with the screen action bar so that the
  /// action bar title and the page content line up on the same edge.
  static const double gutter = 20.0;
  static const double topPadding = 20.0;
  static const double bottomPaddingWide = 40.0;

  /// Leaves room for the floating bottom navigation bar on mobile.
  static const double bottomPaddingNarrow = 120.0;

  static const double headerGap = 12.0;
  static const double noticeGap = 12.0;
  static const double sectionGap = 20.0;
  static const double controlGap = 12.0;
  static const double listGap = 18.0;

  /// Vertical spacing between cards in a list.
  static const double itemGap = 14.0;

  static const Duration switchDuration = Duration(milliseconds: 160);

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 900;
}

/// Standard scrollable page body with consistent gutters.
class ScreenScrollView extends StatelessWidget {
  final List<Widget> children;

  const ScreenScrollView({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isWide = ScreenLayout.isWide(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: ScreenLayout.gutter,
        right: ScreenLayout.gutter,
        top: ScreenLayout.topPadding,
        bottom: isWide
            ? ScreenLayout.bottomPaddingWide
            : ScreenLayout.bottomPaddingNarrow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Page title rendered at the top of every tab screen.
class ScreenHeader extends StatelessWidget {
  final String title;

  const ScreenHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(title, style: AppTypography.displayMedium(isDark));
  }
}

/// Compact lock banner shown to roles with read-only access on a screen.
class ReadOnlyNotice extends StatelessWidget {
  final String message;

  const ReadOnlyNotice(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.brandPeach,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered search input with a clear button, shared by list screens.
class ScreenSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  /// Receives the trimmed, lower-cased query (empty string when cleared).
  final ValueChanged<String> onChanged;

  const ScreenSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textLightMuted
        : AppColors.textDarkMuted;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: (val) => onChanged(val.trim().toLowerCase()),
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textLightPrimary
                  : AppColors.textDarkPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 12.5, color: mutedColor),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: mutedColor,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              isDense: true,
            ),
          );
        },
      ),
    );
  }
}

/// Bordered zero-state card with icon, title, message and optional action.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.7)
              : AppColors.lightBorder.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 44,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Cross-fades (with a subtle upward drift) between list states when a
/// filter, search query, or section toggle changes.
///
/// The [child] must carry a [Key] that changes whenever the content should
/// animate (e.g. `ValueKey('tasks_$filter')`).
class FilterSwitcher extends StatelessWidget {
  final Widget child;

  const FilterSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ScreenLayout.switchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // Align to top so outgoing/incoming lists of different heights don't
      // jump around while cross-fading.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
