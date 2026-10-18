import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/services/storage_service.dart';
import '../widgets/mobile_action_sheets.dart';

class ProjectManagerDashboard extends StatefulWidget {
  const ProjectManagerDashboard({super.key});

  @override
  State<ProjectManagerDashboard> createState() =>
      _ProjectManagerDashboardState();
}

class _ProjectManagerDashboardState extends State<ProjectManagerDashboard> {
  final List<Map<String, dynamic>> _milestones = [];
  final List<Map<String, dynamic>> _projects = [];
  final List<Map<String, dynamic>> _designs = [];

  @override
  void initState() {
    super.initState();
    _milestones.addAll(StorageService.getMilestones());
    _projects.addAll(StorageService.getProjects());
    _designs.addAll(StorageService.getDesignItems());

    MobileActionSheets.milestoneCreatedNotifier.addListener(
      _onMilestoneCreated,
    );
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    MobileActionSheets.renderCreatedNotifier.addListener(_onDesignCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.milestoneCreatedNotifier.removeListener(
      _onMilestoneCreated,
    );
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.renderCreatedNotifier.removeListener(_onDesignCreated);
    super.dispose();
  }

  void _onMilestoneCreated() {
    final m = MobileActionSheets.milestoneCreatedNotifier.value;
    if (m != null && mounted) {
      setState(() {
        _milestones.insert(0, Map<String, dynamic>.from(m));
      });
      StorageService.saveMilestones(_milestones);
    }
  }

  void _onProjectCreated() {
    final p = MobileActionSheets.projectCreatedNotifier.value;
    if (p != null && mounted) {
      setState(() {
        if (!_projects.any((existing) => existing['name'] == p['name'])) {
          _projects.add(Map<String, dynamic>.from(p));
        }
      });
    }
  }

  void _onDesignCreated() {
    final d = MobileActionSheets.renderCreatedNotifier.value;
    if (d != null && mounted) {
      setState(() {
        _designs.insert(0, Map<String, dynamic>.from(d));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: isWide ? 40 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Project Milestones & Field Orchestration',
                style: AppTypography.displayMedium(isDark),
              ),
              if (isWide)
                ElevatedButton.icon(
                  onPressed: () =>
                      MobileActionSheets.showAssignMilestoneSheet(context),
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Assign New Milestone'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // High-level Metrics (Compact StatStrip)
          StatStrip(
            cards: [
              StatCard(
                title: 'Active Sites',
                value: '${_projects.length} Active',
                icon: Icons.folder_special_rounded,
                accentColor: AppColors.brandPeach,
              ),
              StatCard(
                title: 'Pending Milestones',
                value: '${_milestones.length} Tasks',
                icon: Icons.timer_rounded,
                accentColor: AppColors.warning,
              ),
              StatCard(
                title: 'Design Approvals',
                value: '${_designs.length} Items',
                icon: Icons.draw_rounded,
                accentColor: AppColors.brandPeach,
              ),
              const StatCard(
                title: 'Material Indents',
                value: '0 Requisitions',
                icon: Icons.inventory_2_rounded,
                accentColor: AppColors.brandPeach,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Active Milestone Timeline',
            style: AppTypography.titleLarge(isDark),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final milestones = _milestones;

              return Container(
                width: double.infinity,
                padding: milestones.isEmpty
                    ? const EdgeInsets.symmetric(vertical: 48, horizontal: 20)
                    : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: milestones.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timeline_outlined,
                            size: 44,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Milestones Scheduled',
                            style: AppTypography.titleMedium(isDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All project milestones have been cleared. Tap "Assign New Milestone" to schedule field work.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(isDark),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                MobileActionSheets.showAssignMilestoneSheet(
                                  context,
                                ),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Assign New Milestone'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: milestones.map((m) {
                          return _buildMilestoneTile(
                            context: context,
                            isDark: isDark,
                            project:
                                (m['project'] as String?) ?? 'General Site',
                            task:
                                (m['task'] ?? m['title']) as String? ??
                                'Milestone Task',
                            assignee: (m['assignee'] as String?) ?? 'Site Team',
                            deadline:
                                (m['deadline'] ?? m['daysLeft']) as String? ??
                                'Pending',
                            status: (m['status'] as String?) ?? 'In Progress',
                            statusColor:
                                (m['statusColor'] ?? m['color']) as Color? ??
                                AppColors.info,
                          );
                        }).toList(),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile({
    required BuildContext context,
    required bool isDark,
    required String project,
    required String task,
    required String assignee,
    required String deadline,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project,
                  style: AppTypography.bodySmall(isDark)
                      .copyWith(color: AppColors.brandPeach),
                ),
                const SizedBox(height: 2),
                Text(task, style: AppTypography.titleMedium(isDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(assignee, style: AppTypography.bodySmall(isDark)),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(deadline, style: AppTypography.bodySmall(isDark)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
