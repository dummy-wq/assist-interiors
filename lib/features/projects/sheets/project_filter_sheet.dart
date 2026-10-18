import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class ProjectFilterSheet {
  ProjectFilterSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFilter = MobileActionSheets.projectFilterNotifier.value;
    final projects = StorageService.getProjects();

    final filterOptions = <Map<String, dynamic>>[
      {
        'status': 'All',
        'label': 'All Projects',
        'icon': Icons.apartment_rounded,
        'count': projects.length,
      },
      {
        'status': 'On Track',
        'label': 'On Track',
        'icon': Icons.trending_up_rounded,
        'count': projects
            .where(
              (p) => (p['status'] as String? ?? '').toLowerCase() == 'on track',
            )
            .length,
      },
      {
        'status': 'Design and Planning',
        'label': 'Design & Planning',
        'icon': Icons.design_services_rounded,
        'count': projects.where((p) {
          final s = (p['status'] as String? ?? '').toLowerCase().replaceAll(
            '&',
            'and',
          );
          return s == 'design and planning';
        }).length,
      },
      {
        'status': 'Delayed',
        'label': 'Delayed',
        'icon': Icons.warning_amber_rounded,
        'count': projects
            .where(
              (p) => (p['status'] as String? ?? '').toLowerCase() == 'delayed',
            )
            .length,
      },
      {
        'status': 'Completed',
        'label': 'Completed',
        'icon': Icons.task_alt_rounded,
        'count': projects
            .where(
              (p) =>
                  (p['status'] as String? ?? '').toLowerCase() == 'completed',
            )
            .length,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMd),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          minimum: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.brandPeach,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter Projects',
                              style: AppTypography.titleMedium(isDark),
                            ),
                            Text(
                              'Select status to refine project portfolio',
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : AppColors.textDarkMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...filterOptions.map((opt) {
                  final status = opt['status'] as String;
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final count = opt['count'] as int;
                  final isSelected = currentFilter == status;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        MobileActionSheets.projectFilterNotifier.value = status;
                        AppNotification.show(
                          context,
                          message: status == 'All'
                              ? 'Showing all $count projects'
                              : 'Filter applied: "$label" ($count projects found)',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPeach.withValues(
                                  alpha: isDark ? 0.20 : 0.12,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandPeach
                                : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.5),
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.brandPeach
                                  : (isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary)
                                      : (isDark
                                            ? AppColors.textLightSecondary
                                            : AppColors.textDarkSecondary),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brandPeach
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted),
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.brandPeach,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                if (currentFilter != 'All')
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      MobileActionSheets.projectFilterNotifier.value = 'All';
                      AppNotification.show(
                        context,
                        message: 'Filters reset. Showing all projects.',
                      );
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Reset to All Projects'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
