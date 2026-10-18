import 'package:flutter/material.dart';

import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'instant_press_feedback.dart';
import '../../features/dashboard/widgets/mobile_action_sheets.dart';

class ProjectStatusDistributionChart extends StatefulWidget {
  final List<Map<String, dynamic>> projects;
  final VoidCallback? onTap;

  const ProjectStatusDistributionChart({
    super.key,
    required this.projects,
    this.onTap,
  });

  @override
  State<ProjectStatusDistributionChart> createState() =>
      _ProjectStatusDistributionChartState();

  static String resolveStatus(Map<String, dynamic> project) {
    if (project['isDelayed'] == true) {
      return 'Delayed';
    }
    final stages = project['stages'] as List<dynamic>?;
    if (stages != null && stages.isNotEmpty) {
      final allDone = stages.every((s) => s['isDone'] == true);
      if (allDone) {
        return 'Completed';
      }
    }
    final raw = project['status'] as String?;
    if (raw != null && raw.isNotEmpty) {
      if (raw.toLowerCase().contains('design')) return 'Design & Planning';
      if (raw.toLowerCase().contains('delay')) return 'Delayed';
      if (raw.toLowerCase().contains('complete')) return 'Completed';
      return raw;
    }
    return 'On Track';
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'On Track':
      case 'Execution':
      case 'In Progress':
        return AppColors.info;
      case 'Delayed':
        return AppColors.error;
      case 'Design & Planning':
      case 'Design and Planning':
        return AppColors.brandPeach;
      default:
        return AppColors.success;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle_outline_rounded;
      case 'On Track':
      case 'Execution':
      case 'In Progress':
        return Icons.trending_up_rounded;
      case 'Delayed':
        return Icons.warning_amber_rounded;
      case 'Design & Planning':
      case 'Design and Planning':
        return Icons.architecture_rounded;
      default:
        return Icons.lens_rounded;
    }
  }
}

class _StatusSegment {
  final String status;
  final int count;
  final double percentage;
  final Color color;
  final double totalBudget;

  const _StatusSegment({
    required this.status,
    required this.count,
    required this.percentage,
    required this.color,
    required this.totalBudget,
  });
}

class _ProjectStatusDistributionChartState
    extends State<ProjectStatusDistributionChart> {
  String? _selectedFilterStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.projects.length;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 38,
              color: isDark
                  ? AppColors.textLightMuted
                  : AppColors.textDarkMuted,
            ),
            const SizedBox(height: 10),
            Text(
              'No Projects to Analyze',
              style: AppTypography.titleMedium(isDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Status distribution will automatically populate once projects are initiated.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(isDark),
            ),
          ],
        ),
      );
    }

    // Group projects by status
    final Map<String, int> counts = {
      'On Track': 0,
      'Design & Planning': 0,
      'Delayed': 0,
      'Completed': 0,
    };
    final Map<String, double> budgets = {
      'On Track': 0.0,
      'Design & Planning': 0.0,
      'Delayed': 0.0,
      'Completed': 0.0,
    };

    for (final p in widget.projects) {
      final st = ProjectStatusDistributionChart.resolveStatus(p);
      counts[st] = (counts[st] ?? 0) + 1;
      final b = PdfService.parseAmount(p['budget'] as String? ?? '0');
      budgets[st] = (budgets[st] ?? 0.0) + b;
    }

    final List<_StatusSegment> segments = counts.entries.map((e) {
      return _StatusSegment(
        status: e.key,
        count: e.value,
        percentage: total > 0 ? (e.value / total) * 100 : 0.0,
        color: ProjectStatusDistributionChart.getStatusColor(e.key),
        totalBudget: budgets[e.key] ?? 0.0,
      );
    }).toList();

    final delayedCount = counts['Delayed'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
          // Header with Direct Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach.withValues(
                          alpha: isDark ? 0.22 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: AppColors.brandPeach,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Distribution',
                            style: AppTypography.titleMedium(isDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Portfolio distribution across delivery stages',
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
                  ],
                ),
              ),
              if (widget.onTap != null)
                InstantPressFeedback(
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(4.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Projects',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.textLightPrimary
                                : AppColors.textDarkPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Option B: Segmented Proportional Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              child: Row(
                children: segments.where((s) => s.count > 0).map((seg) {
                  final isFiltered = _selectedFilterStatus == seg.status;
                  return Expanded(
                    flex: seg.count,
                    child: Tooltip(
                      message: '${seg.status}: ${seg.count} Sites (${seg.percentage.toStringAsFixed(0)}%)',
                      child: Container(
                        color: seg.color.withValues(
                          alpha:
                              _selectedFilterStatus == null || isFiltered
                                  ? 1.0
                                  : 0.35,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                        child: Center(
                          child: Text(
                            '${seg.percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Status Filter Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterPill(
                isDark: isDark,
                label: 'All Sites',
                count: total,
                percentage: 100,
                color: AppColors.brandPeach,
                isSelected: _selectedFilterStatus == null,
                onTap: () => setState(() => _selectedFilterStatus = null),
              ),
              ...segments.map((seg) {
                return _buildFilterPill(
                  isDark: isDark,
                  label: seg.status,
                  count: seg.count,
                  percentage: seg.percentage,
                  color: seg.color,
                  isSelected: _selectedFilterStatus == seg.status,
                  onTap: () {
                    setState(() {
                      _selectedFilterStatus =
                          _selectedFilterStatus == seg.status
                              ? null
                              : seg.status;
                    });
                  },
                );
              }),
            ],
          ),

          // Delayed Sites Attention / Review Snags Strip
          if (delayedCount > 0) ...[
            const SizedBox(height: 14),
            InstantPressFeedback(
              child: InkWell(
                key: const Key('review_snags_strip'),
                onTap: () => MobileActionSheets.showReviewSnagsSheet(context),
                borderRadius: BorderRadius.circular(4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(
                      alpha: isDark ? 0.16 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$delayedCount site(s) requiring punch list review & snag rectification.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review Snags',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required bool isDark,
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InstantPressFeedback(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.8),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.16),
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Text(
                  '$count (${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
