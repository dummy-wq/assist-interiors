import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/instant_press_feedback.dart';

/// Compact metric tile designed for the upper studio dashboard stats column/grid.
class CompactStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const CompactStatTile({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width <= 900;

    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 28 : 34,
            height: isCompact ? 28 : 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: AppSizes.borderRadiusSm,
            ),
            child: Icon(icon, color: accentColor, size: isCompact ? 15 : 17),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall(isDark).copyWith(
                    fontSize: isCompact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.displayMedium(isDark).copyWith(
                      fontSize: isCompact ? 14.5 : 16.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trend != null && !isCompact) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: AppSizes.borderRadiusSm,
              ),
              child: Text(
                trend!,
                style: AppTypography.labelSmall(isDark).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InstantPressFeedback(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSizes.borderRadiusMd,
          child: card,
        ),
      );
    }

    return card;
  }
}
