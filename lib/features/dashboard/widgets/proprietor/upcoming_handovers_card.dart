import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/instant_press_feedback.dart';
import '../../../../core/permissions/app_permissions.dart';
import '../../../auth/state/auth_provider.dart';
import '../mobile_action_sheets.dart';

/// Card displaying active project handover schedules, completion readiness, and lead attribution.
class UpcomingHandoversCard extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final VoidCallback? onInitiateProject;
  final VoidCallback? onTap;

  const UpcomingHandoversCard({
    super.key,
    required this.projects,
    this.onInitiateProject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final canCreateProject = AppPermissions.canCreateProject(auth.currentRole);

    final card = Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        Icons.key_rounded,
                        color: AppColors.brandPeach,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Upcoming Handovers',
                      style: AppTypography.titleMedium(isDark),
                    ),
                  ],
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 36.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
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
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 14,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${projects.length} Sites Scheduled',
                        style: AppTypography.labelLarge(isDark).copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.brandPeach,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.door_sliding_outlined,
                      size: 38,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No Upcoming Handovers Scheduled',
                      style: AppTypography.titleMedium(isDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canCreateProject
                          ? 'All project records cleared. Tap "Initiate Project" to launch a turnkey site.'
                          : 'All project records cleared.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(isDark),
                    ),
                    if (canCreateProject) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed:
                            onInitiateProject ??
                            () => MobileActionSheets.showInitiateProjectSheet(
                              context,
                            ),
                        icon: const Icon(Icons.apartment_rounded, size: 16),
                        label: const Text('Initiate Project'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.borderRadiusSm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = projects[index];
                final color = p['color'] as Color? ?? AppColors.brandPeach;
                final handoverDate = p['handover'] as String? ?? 'TBD';
                final stages = (p['stages'] as List?) ?? [];
                final completedStages = stages
                    .where((s) => s['isDone'] == true)
                    .length;
                final totalStages = stages.isEmpty ? 1 : stages.length;
                final progressPercent = stages.isEmpty
                    ? (p['status'] == 'Completed' ? 1.0 : 0.65)
                    : (completedStages / totalStages);

                String readinessTag = 'Site Execution • On Track';
                Color readinessColor = AppColors.info;
                if (p['status'] == 'Completed' || progressPercent >= 1.0) {
                  readinessTag = 'Handed Over • Client Sign-off';
                  readinessColor = AppColors.success;
                } else if (progressPercent >= 0.75) {
                  readinessTag = 'Finishing • Final Snagging';
                  readinessColor = AppColors.brandPeach;
                } else if (p['status'] == 'Delayed') {
                  readinessTag = 'Attention • Snag Resolution';
                  readinessColor = AppColors.error;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: AppSizes.borderRadiusSm,
                            ),
                            child: Icon(
                              Icons.home_work_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] as String,
                                  style: AppTypography.titleMedium(isDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p['location'] ?? 'Site'} • ${p['type'] ?? 'Turnkey Site'}',
                                  style: AppTypography.bodySmall(isDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPeach.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: AppSizes.borderRadiusMd,
                                border: Border.all(
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_available_rounded,
                                    size: 13,
                                    color: AppColors.brandPeach,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Handover: $handoverDate',
                                      style: AppTypography.labelSmall(isDark)
                                          .copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brandPeach,
                                            height: 1.2,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppSizes.borderRadiusSm,
                              child: LinearProgressIndicator(
                                value: progressPercent.clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  readinessColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(progressPercent * 100).toInt()}%',
                            style: AppTypography.labelSmall(isDark).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: readinessColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          InkWell(
                            onTap: () {
                              if (p['status'] == 'Delayed' ||
                                  readinessTag.contains('Snag')) {
                                MobileActionSheets.showReviewSnagsSheet(context);
                              } else {
                                onTap?.call();
                              }
                            },
                            borderRadius: AppSizes.borderRadiusMd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: readinessColor.withValues(alpha: 0.12),
                                borderRadius: AppSizes.borderRadiusMd,
                                border: Border.all(
                                  color: readinessColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                readinessTag,
                                style: AppTypography.labelSmall(isDark).copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: readinessColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Lead: ${p['pm'] ?? 'Unassigned'}',
                            style: AppTypography.bodySmall(isDark)
                                .copyWith(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
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
