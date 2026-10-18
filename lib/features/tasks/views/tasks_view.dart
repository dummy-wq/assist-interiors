import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../dashboard/widgets/mobile_action_sheets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/models/task_model.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/state/auth_provider.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasks.addAll(StorageService.getTasks());
    MobileActionSheets.taskCreatedNotifier.addListener(_onTaskCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.taskCreatedNotifier.removeListener(_onTaskCreated);
    _searchController.dispose();
    super.dispose();
  }

  void _onTaskCreated() {
    final task = MobileActionSheets.taskCreatedNotifier.value;
    if (task != null && mounted) {
      setState(() {
        _tasks.insert(0, Map<String, dynamic>.from(task));
      });
      StorageService.saveTasks(_tasks);
      BackendManager.instance.createTask(TaskModel.fromMap(task));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canUpdateStatus = AppPermissions.canUpdateTaskStatus(
      auth.currentRole,
    );
    final canCreateTask = AppPermissions.canCreateTask(auth.currentRole);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = _tasks.where((t) {
      if (_selectedFilter != 'All' && t['status'] != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        final desc = (t['description'] ?? '').toString().toLowerCase();
        final proj = (t['project'] ?? '').toString().toLowerCase();
        final assignee = (t['assignee'] ?? '').toString().toLowerCase();
        final dept = (t['department'] ?? '').toString().toLowerCase();
        final priority = (t['priority'] ?? '').toString().toLowerCase();
        if (!title.contains(_searchQuery) &&
            !desc.contains(_searchQuery) &&
            !proj.contains(_searchQuery) &&
            !assignee.contains(_searchQuery) &&
            !dept.contains(_searchQuery) &&
            !priority.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    return ScreenScrollView(
      children: [
        ScreenHeader(AppStrings.tasksAndMilestones),
        const SizedBox(height: ScreenLayout.headerGap),

        // Stats Strip (Compact StatStrip)
        StatStrip(
          cards: [
            StatCard(
              title: AppStrings.pending,
              value:
                  '${_tasks.where((t) => !(t['completed'] as bool)).length} Tasks',
              icon: Icons.checklist_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: AppStrings.dueThisWeek,
              value:
                  '${_tasks.where((t) => (t['priority'] == 'Urgent' || t['priority'] == 'High') && !(t['completed'] as bool)).length} Tasks',
              icon: Icons.timer_rounded,
              accentColor: AppColors.warning,
            ),
            StatCard(
              title: 'Awaiting Review',
              value:
                  '${_tasks.where((t) => t['status'] == 'Review Required').length} Tasks',
              icon: Icons.rate_review_outlined,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Completion Rate',
              value: _tasks.isEmpty
                  ? '0%'
                  : '${((_tasks.where((t) => t['completed'] as bool).length / _tasks.length) * 100).toStringAsFixed(0)}%',
              icon: Icons.task_alt_rounded,
              accentColor: AppColors.success,
            ),
          ],
        ),
        if (!canUpdateStatus && !canCreateTask) ...[
          const SizedBox(height: ScreenLayout.noticeGap),
          ReadOnlyNotice(
            'Read-Only Access: Signed in as ${auth.currentRole.title}. Updating milestone deliverables is restricted to Site Supervisors, Designers, and Project Managers.',
          ),
        ],
        const SizedBox(height: ScreenLayout.sectionGap),

        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search tasks by title, scope, project, or assignee...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'In Progress', 'Review Required', 'Completed']
                .map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PillBox(
                      label: filter,
                      isSelected: isSelected,
                      activeColor: AppColors.brandPeach,
                      onSelected: () =>
                          setState(() => _selectedFilter = filter),
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Task List — animated on filter change
        FilterSwitcher(
          child: filteredTasks.isEmpty
              ? EmptyStateCard(
                  key: ValueKey('empty_tasks_$_selectedFilter'),
                  icon: Icons.task_outlined,
                  title: _selectedFilter == 'All'
                      ? 'No Tasks Logged'
                      : 'No $_selectedFilter Tasks',
                  message: _selectedFilter == 'All'
                      ? 'All task entries have been cleared. Tap "Add Task" to record a deliverable.'
                      : 'No tasks match the "$_selectedFilter" filter criteria.',
                  action: (_selectedFilter != 'All' || _searchQuery.isNotEmpty)
                      ? OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = 'All';
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Show All Tasks'),
                        )
                      : null,
                )
              : ListView.separated(
                  key: ValueKey(_selectedFilter),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: ScreenLayout.itemGap),
                  itemBuilder: (context, index) {
                    final t = filteredTasks[index];
                    final bool completed = t['completed'] as bool? ?? false;
                    final Color color =
                        t['color'] as Color? ?? AppColors.brandPeach;
                    final String priority =
                        t['priority'] as String? ?? 'Normal';
                    final bool isUrgent = priority == 'Urgent';
                    final String department =
                        (t['department'] as String?)?.isNotEmpty == true
                        ? t['department'] as String
                        : 'Site & Execution';
                    final String description =
                        (t['description'] as String?) ?? '';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUrgent && !completed
                            ? (isDark
                                  ? AppColors.error.withValues(alpha: 0.08)
                                  : AppColors.error.withValues(alpha: 0.04))
                            : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: isUrgent && !completed
                              ? AppColors.error
                              : (isDark
                                    ? AppColors.darkBorder.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.lightBorder.withValues(
                                        alpha: 0.8,
                                      )),
                          width: isUrgent && !completed ? 1.4 : 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isUrgent && !completed
                                ? AppColors.error.withValues(alpha: 0.12)
                                : Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
                                  ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Checkbox, Title & Project, Priority Tag
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: canUpdateStatus
                                    ? null
                                    : () {
                                        AppNotification.show(
                                          context,
                                          message:
                                              'Action restricted: Signed in as ${auth.currentRole.title}. Updating milestone deliverables requires Supervisor or PM permissions.',
                                        );
                                      },
                                child: AbsorbPointer(
                                  absorbing: !canUpdateStatus,
                                  child: Checkbox(
                                    value: completed,
                                    activeColor: isUrgent
                                        ? AppColors.error
                                        : AppColors.brandPeach,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    onChanged: canUpdateStatus
                                        ? (val) {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              t['completed'] = val ?? false;
                                              t['status'] = (val ?? false)
                                                  ? 'Completed'
                                                  : 'In Progress';
                                            });
                                            StorageService.saveTasks(_tasks);
                                            BackendManager.instance.updateTask(
                                              TaskModel.fromMap(t),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t['title'] as String? ??
                                                'Deliverable',
                                            style:
                                                AppTypography.titleMedium(
                                                  isDark,
                                                ).copyWith(
                                                  decoration: completed
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  fontWeight:
                                                      isUrgent && !completed
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: completed
                                                      ? (isDark
                                                            ? AppColors
                                                                  .textLightMuted
                                                            : AppColors
                                                                  .textDarkMuted)
                                                      : (isUrgent
                                                            ? (isDark
                                                                  ? Colors
                                                                        .redAccent
                                                                        .shade100
                                                                  : AppColors
                                                                        .error)
                                                            : null),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Priority Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isUrgent
                                                        ? AppColors.error
                                                        : color)
                                                    .withValues(
                                                      alpha: isUrgent
                                                          ? 0.18
                                                          : 0.15,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              6.0,
                                            ),
                                            border: isUrgent && !completed
                                                ? Border.all(
                                                    color: AppColors.error
                                                        .withValues(alpha: 0.5),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isUrgent) ...[
                                                const Icon(
                                                  Icons.warning_rounded,
                                                  size: 12,
                                                  color: AppColors.error,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                priority,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isUrgent
                                                      ? AppColors.error
                                                      : color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          t['project'] as String? ??
                                              'General Deliverable',
                                          style: AppTypography.bodySmall(isDark)
                                              .copyWith(
                                                color: AppColors.brandPeach,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkCardElevated
                                                : AppColors.lightBorder
                                                      .withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: Text(
                                            department,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textLightMuted
                                                  : AppColors.textDarkMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Description Callout (if present)
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 48,
                                right: 8,
                              ),
                              child: Text(
                                description,
                                style: AppTypography.bodySmall(isDark).copyWith(
                                  color: isDark
                                      ? AppColors.textLightSecondary
                                      : AppColors.textDarkSecondary,
                                  height: 1.35,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          // Photo / Blueprint Attachment Reference (if present)
                          Builder(
                            builder: (context) {
                              final photoRef =
                                  (t['photoLabel'] as String?) ??
                                  (t['photoUrl'] as String?);
                              if (photoRef == null || photoRef.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 48,
                                  right: 8,
                                  top: 6,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardElevated
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color: AppColors.brandPeach.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.image_outlined,
                                        size: 14,
                                        color: AppColors.brandPeach,
                                      ),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 220,
                                        ),
                                        child: Text(
                                          photoRef,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.textLightPrimary
                                                : AppColors.textDarkPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // Footer Meta: Assignee & Due Date
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 14,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 180,
                                      ),
                                      child: Text(
                                        t['assignee'] as String? ??
                                            'Unassigned',
                                        style: AppTypography.bodySmall(isDark),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: isUrgent && !completed
                                          ? AppColors.error
                                          : (isDark
                                                ? AppColors.textLightMuted
                                                : AppColors.textDarkMuted),
                                    ),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 160,
                                      ),
                                      child: Text(
                                        t['deadline'] as String? ??
                                            (t['dueDate'] as String? ??
                                                'Today'),
                                        style: AppTypography.bodySmall(isDark)
                                            .copyWith(
                                              fontWeight: isUrgent && !completed
                                                  ? FontWeight.w600
                                                  : null,
                                              color: isUrgent && !completed
                                                  ? AppColors.error
                                                  : null,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
