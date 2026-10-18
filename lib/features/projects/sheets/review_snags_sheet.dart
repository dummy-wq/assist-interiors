import 'package:flutter/material.dart';

import '../../../core/models/project_model.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../dashboard/views/main_dashboard_screen.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

/// Modal bottom sheet to review active site snags, milestones, and delay bottlenecks
/// across the studio portfolio.
class ReviewSnagsSheet extends StatefulWidget {
  final VoidCallback? onUpdated;

  const ReviewSnagsSheet({super.key, this.onUpdated});

  static Future<void> show(BuildContext context, {VoidCallback? onUpdated}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusMd),
        ),
      ),
      builder: (ctx) => ReviewSnagsSheet(onUpdated: onUpdated),
    );
  }

  @override
  State<ReviewSnagsSheet> createState() => _ReviewSnagsSheetState();
}

class _ReviewSnagsSheetState extends State<ReviewSnagsSheet> {
  late List<Map<String, dynamic>> _projects;
  final Map<String, TextEditingController> _snagControllers = {};
  final Map<String, bool> _addingSnagMap = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projects = StorageService.getProjects()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _snagControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _filterMode = 'delayed';

  List<Map<String, dynamic>> get _delayedProjects {
    return _projects.where((p) {
      final isDelayed = p['isDelayed'] == true;
      final status = (p['status'] as String? ?? '').toLowerCase();
      return isDelayed || status.contains('delay');
    }).toList();
  }

  List<Map<String, dynamic>> get _allSnagProjects {
    return _projects.where((p) {
      final isDelayed = p['isDelayed'] == true;
      final status = (p['status'] as String? ?? '').toLowerCase();
      final stages = (p['stages'] as List<dynamic>?) ?? [];
      final hasPending = stages.any((s) => (s['isDone'] as bool? ?? false) == false);
      return isDelayed || status.contains('delay') || hasPending;
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedProjects {
    if (_filterMode == 'delayed') {
      return _delayedProjects;
    }
    return _allSnagProjects;
  }

  int get _totalPendingSnagsCount {
    int count = 0;
    for (final p in _displayedProjects) {
      final stages = (p['stages'] as List<dynamic>?) ?? [];
      count += stages.where((s) => (s['isDone'] as bool? ?? false) == false).length;
    }
    return count;
  }

  void _persistProjects() {
    StorageService.saveProjects(_projects);
    MobileActionSheets.projectUpdatedNotifier.value =
        _projects.isNotEmpty ? _projects.first : null;
    widget.onUpdated?.call();
    if (mounted) setState(() {});
  }

  void _toggleStage(Map<String, dynamic> project, int stageIndex) {
    final stages = (project['stages'] as List<dynamic>?) ?? [];
    if (stageIndex >= 0 && stageIndex < stages.length) {
      final current = stages[stageIndex]['isDone'] as bool? ?? false;
      stages[stageIndex]['isDone'] = !current;

      BackendManager.instance.updateProject(ProjectModel.fromMap(project));
      _persistProjects();

      AppNotification.show(
        context,
        message: !current
            ? 'Snag marked as resolved.'
            : 'Snag reopened as pending inspection.',
      );
    }
  }

  void _addSnagItem(Map<String, dynamic> project) {
    final projId = project['id']?.toString() ?? project['name'].toString();
    final controller = _snagControllers.putIfAbsent(
      projId,
      () => TextEditingController(),
    );
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final stages = (project['stages'] as List<dynamic>?) ?? [];
    stages.add({
      'id': 'snag_${DateTime.now().millisecondsSinceEpoch}',
      'title': text,
      'isDone': false,
    });
    project['stages'] = stages;
    controller.clear();
    _addingSnagMap[projId] = false;

    BackendManager.instance.updateProject(ProjectModel.fromMap(project));
    _persistProjects();

    AppNotification.show(
      context,
      message: 'New snag item added to punch list.',
    );
  }

  void _resolveDelayAndUnflag(Map<String, dynamic> project) {
    project['isDelayed'] = false;
    final stages = (project['stages'] as List<dynamic>?) ?? [];
    final allDone = stages.isNotEmpty && stages.every((s) => s['isDone'] == true);
    project['status'] = allDone ? 'Completed' : 'On Track';

    BackendManager.instance.updateProject(ProjectModel.fromMap(project));
    _persistProjects();

    AppNotification.show(
      context,
      message: 'Delay cleared! "${project['name']}" is now ${project['status']}.',
    );
  }

  void _openInProjectsView(Map<String, dynamic> project) {
    Navigator.of(context).pop();
    MobileActionSheets.projectFilterNotifier.value = 'Delayed';
    MainDashboardScreen.navigateToTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flaggedSites = _displayedProjects;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      minimum: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 8 : 16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Site Snags & Delay Bottlenecks',
                                style: AppTypography.titleMedium(isDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Review active site blockers & punch list rectification',
                                style: AppTypography.bodySmall(isDark).copyWith(
                                  color: isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // KPI / Status Pill Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                        .withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: flaggedSites.isNotEmpty
                            ? AppColors.error
                            : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flaggedSites.isNotEmpty
                            ? '${flaggedSites.length} site(s) requiring attention • $_totalPendingSnagsCount pending snag items'
                            : 'All sites operational • 0 active delay bottlenecks',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLightPrimary
                              : AppColors.textDarkPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (flaggedSites.isNotEmpty
                                ? AppColors.error
                                : AppColors.success)
                            .withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        flaggedSites.isNotEmpty
                            ? 'ACTION REQUIRED'
                            : 'ON TRACK',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: flaggedSites.isNotEmpty
                              ? AppColors.error
                              : AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Filter Tabs
              Row(
                children: [
                  _buildFilterTab(
                    label: 'Delayed Sites (${_delayedProjects.length})',
                    isSelected: _filterMode == 'delayed',
                    isDark: isDark,
                    color: AppColors.error,
                    onTap: () => setState(() => _filterMode = 'delayed'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'All Active Snags (${_allSnagProjects.length})',
                    isSelected: _filterMode == 'all',
                    isDark: isDark,
                    color: AppColors.brandPeach,
                    onTap: () => setState(() => _filterMode = 'all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content List
              Expanded(
                child: flaggedSites.isEmpty
                    ? _buildAllClearState(isDark)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: flaggedSites.length,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 14),
                        itemBuilder: (ctx, idx) =>
                            _buildProjectSnagCard(flaggedSites[idx], isDark),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllClearState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 38,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'All Sites Clear • No Active Snags',
              style: AppTypography.titleMedium(isDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Zero delay bottlenecks or unfinished snag items are currently reported across active studio projects.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(isDark).copyWith(
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                MainDashboardScreen.navigateToTab(2);
              },
              icon: const Icon(Icons.apartment_rounded, size: 16),
              label: const Text(
                'Browse All Projects',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSnagCard(Map<String, dynamic> project, bool isDark) {
    final projId = project['id']?.toString() ?? project['name'].toString();
    final name = project['name'] as String? ?? 'Untitled Project';
    final client = project['client'] as String? ?? 'Client';
    final location = project['location'] as String? ?? 'Site Location';
    final pm = project['pm'] as String? ?? 'Project Lead';
    final supervisor = project['supervisor'] as String? ?? 'Supervisor';
    final handover = project['handover'] as String? ?? 'TBD';
    final isDelayed = project['isDelayed'] == true;
    final stages = (project['stages'] as List<dynamic>?) ?? [];
    final completedCount = stages.where((s) => s['isDone'] == true).length;
    final totalStages = stages.length;
    final isAddingSnag = _addingSnagMap[projId] == true;

    final controller = _snagControllers.putIfAbsent(
      projId,
      () => TextEditingController(),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDelayed
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.8),
          width: isDelayed ? 1.0 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDelayed
                  ? AppColors.error.withValues(alpha: isDark ? 0.12 : 0.06)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.titleMedium(isDark).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDelayed) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              child: const Text(
                                'DELAYED SITE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$client • $location',
                        style: AppTypography.bodySmall(isDark).copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Metadata row (Supervisor, PM, Handover)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildMetaPill(
                  icon: Icons.person_outline_rounded,
                  label: 'PM: $pm',
                  isDark: isDark,
                ),
                _buildMetaPill(
                  icon: Icons.engineering_outlined,
                  label: 'Supervisor: $supervisor',
                  isDark: isDark,
                ),
                _buildMetaPill(
                  icon: Icons.event_available_rounded,
                  label: 'Target: $handover',
                  isDark: isDark,
                  color: isDelayed ? AppColors.error : AppColors.brandPeach,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Snag / Stage Checklist Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE CHECKLIST & SNAG LIST ($completedCount/$totalStages)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.brandPeach,
                  ),
                  onPressed: () {
                    setState(() {
                      _addingSnagMap[projId] = !isAddingSnag;
                    });
                  },
                  icon: Icon(
                    isAddingSnag ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    size: 13,
                  ),
                  label: Text(
                    isAddingSnag ? 'Cancel' : '+ Add Snag',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Inline Add Snag Field (if active)
          if (isAddingSnag) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter snag / punch list item (e.g. Paint touchup)',
                        hintStyle: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: const BorderSide(
                            color: AppColors.brandPeach,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _addSnagItem(project),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () => _addSnagItem(project),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Stages list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: stages.asMap().entries.map((entry) {
                final stageIdx = entry.key;
                final stage = entry.value as Map<String, dynamic>;
                final isDone = stage['isDone'] as bool? ?? false;
                final title = stage['title'] as String? ?? 'Stage';
                final isSnagItem = title.toLowerCase().contains('snag') ||
                    title.toLowerCase().contains('clean') ||
                    title.toLowerCase().contains('rectification') ||
                    !isDone;

                return InkWell(
                  onTap: () => _toggleStage(project, stageIdx),
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: isDone
                              ? AppColors.success
                              : (isSnagItem ? AppColors.error : AppColors.brandPeach),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                              color: isDone
                                  ? (isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted)
                                  : (isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary),
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (!isDone && isSnagItem) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : AppColors.lightBackground.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5.0)),
              border: Border(
                top: BorderSide(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textLightPrimary
                        : AppColors.textDarkPrimary,
                    side: BorderSide(
                      color: (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)
                          .withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  onPressed: () => _openInProjectsView(project),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 14),
                  label: const Text(
                    'Open Site View',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isDelayed) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () => _resolveDelayAndUnflag(project),
                    icon: const Icon(Icons.check_circle_rounded, size: 14),
                    label: const Text(
                      'Clear Delay Flag',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final effectiveColor = color ??
        (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    .withValues(alpha: 0.7),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? color
                : (isDark
                    ? AppColors.textLightPrimary
                    : AppColors.textDarkPrimary),
          ),
        ),
      ),
    );
  }
}
