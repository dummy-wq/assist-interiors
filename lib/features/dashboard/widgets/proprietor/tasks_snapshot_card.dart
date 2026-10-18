import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/instant_press_feedback.dart';

/// Hub element representing the Tasks & Site Execution screen.
/// Displays deliverable counts, completion status, and active site task previews.
class TasksSnapshotCard extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final VoidCallback? onTap;

  const TasksSnapshotCard({super.key, required this.tasks, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int inProgressCount = 0;
    int reviewRequiredCount = 0;
    int completedCount = 0;

    for (final t in tasks) {
      final status = t['status'] as String? ?? 'In Progress';
      if (status == 'Completed') {
        completedCount++;
      } else if (status == 'Review Required') {
        reviewRequiredCount++;
      } else {
        inProgressCount++;
      }
    }

    final previewTasks = tasks.take(2).toList();

    return InstantPressFeedback(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusMd,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppSizes.borderRadiusMd,
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: AppSizes.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            color: AppColors.brandPeach,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Site Tasks',
                          style: AppTypography.titleMedium(isDark),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 32.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            borderRadius: AppSizes.borderRadiusMd,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tasks.length} Deliverables',
                                style: AppTypography.labelLarge(isDark)
                                    .copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.brandPeach,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // KPI Summary Strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'In Progress',
                        value: '$inProgressCount',
                        isDark: isDark,
                        valueColor: inProgressCount > 0 ? AppColors.info : null,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Review Needed',
                        value: '$reviewRequiredCount',
                        isDark: isDark,
                        valueColor: reviewRequiredCount > 0
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Completed',
                        value: '$completedCount',
                        isDark: isDark,
                        valueColor: completedCount > 0
                            ? AppColors.success
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Task Previews or Zero State
              if (previewTasks.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.8),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: previewTasks.map((t) {
                      final title = t['title'] as String? ?? 'Site Deliverable';
                      final project = t['project'] as String? ?? 'Active Site';
                      final assignee = t['assignee'] as String? ?? 'Unassigned';
                      final priority = t['priority'] as String? ?? 'Medium';
                      final hasPhoto = t['photoUrl'] != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground.withValues(alpha: 0.5)
                              : AppColors.lightBackground.withValues(
                                  alpha: 0.7,
                                ),
                          borderRadius: AppSizes.borderRadiusSm,
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              t['status'] == 'Completed'
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: t['status'] == 'Completed'
                                  ? AppColors.success
                                  : (isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textLightPrimary
                                                : AppColors.textDarkPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hasPhoto) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.photo_camera_rounded,
                                          size: 13,
                                          color: AppColors.brandPeach,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '$project • $assignee',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (priority == 'High'
                                            ? AppColors.error
                                            : AppColors.brandPeach)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priority == 'High'
                                      ? AppColors.error
                                      : AppColors.brandPeach,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Center(
                    child: Text(
                      'All deliverables up to date • Tap to manage Tasks',
                      style: AppTypography.bodySmall(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  (isDark
                      ? AppColors.textLightPrimary
                      : AppColors.textDarkPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
