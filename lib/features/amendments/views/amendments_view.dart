import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class AmendmentsView extends StatefulWidget {
  const AmendmentsView({super.key});

  static final ValueNotifier<int> openAddModalTrigger = ValueNotifier<int>(0);

  @override
  State<AmendmentsView> createState() => _AmendmentsViewState();
}

class _AmendmentsViewState extends State<AmendmentsView> {
  String _selectedFilter = 'All';
  String _selectedProject = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _amendments = [];

  final List<String> _filterChips = [
    'All',
    'Under Review',
    'Client Approved',
    'In Execution',
    'Completed',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _loadAmendments();
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    AmendmentsView.openAddModalTrigger.addListener(_onOpenAddModalTriggered);
    StorageService.cloudSyncNotifier.addListener(_onProjectCreated);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    AmendmentsView.openAddModalTrigger.removeListener(_onOpenAddModalTriggered);
    _searchController.dispose();
    super.dispose();
  }

  void _onOpenAddModalTriggered() {
    if (mounted) {
      _showAddAmendmentModal(context);
    }
  }

  void _onProjectCreated() {
    if (mounted) {
      _loadAmendments();
    }
  }

  void _loadAmendments() {
    final list = StorageService.getAmendments();
    setState(() {
      _amendments.clear();
      _amendments.addAll(list);
    });
  }

  void _saveAmendments() {
    StorageService.saveAmendments(_amendments);
  }

  String? _previousStatus(String status) {
    switch (status) {
      case 'Client Approved':
        return 'Under Review';
      case 'In Execution':
        return 'Client Approved';
      case 'Completed':
        return 'In Execution';
      default:
        return null;
    }
  }

  void _stepAmendmentBack(Map<String, dynamic> amd) {
    final current = (amd['status'] ?? 'Under Review').toString();
    final prev = _previousStatus(current);
    if (prev == null) return;
    final id = (amd['id'] ?? 'AMD').toString();
    setState(() {
      amd['status'] = prev;
      if (prev == 'Under Review') {
        amd['clientSignOffDate'] = 'Pending Client Sign-off';
      }
    });
    _saveAmendments();
    AppNotification.show(
      context,
      message: 'Amendment $id moved back to $prev.',
    );
  }

  Widget _buildStepBackButton(
    Map<String, dynamic> amd,
    bool isDark, {
    VoidCallback? onBeforeStepBack,
  }) {
    final prev = _previousStatus((amd['status'] ?? '').toString());
    if (prev == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark
            ? AppColors.textLightSecondary
            : AppColors.textDarkSecondary,
        side: BorderSide(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.8),
          width: 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
      onPressed: () {
        onBeforeStepBack?.call();
        _stepAmendmentBack(amd);
      },
      icon: const Icon(Icons.undo_rounded, size: 15),
      label: const Text(
        'Step Back',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approved')) return AppColors.success;
    if (lower.contains('execution')) return AppColors.info;
    if (lower.contains('completed')) return const Color(0xFF9B51E0);
    if (lower.contains('review')) return AppColors.warning;
    return AppColors.textDarkMuted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalApproved = 0;
    int totalNetCostInt = 0;
    int totalDaysImpact = 0;

    for (final a in _amendments) {
      final status = (a['status'] ?? '').toString().toLowerCase();
      if (status.contains('approved') ||
          status.contains('execution') ||
          status.contains('completed')) {
        totalApproved++;
      }

      totalNetCostInt += CurrencyUtils.parseAmount(
        a['costImpact'] ?? a['cost'],
      );
      totalDaysImpact += CurrencyUtils.parseAmount(a['timelineImpact']);
    }

    final totalCostStr = totalNetCostInt > 0
        ? CurrencyUtils.formatInr(totalNetCostInt, symbol: '+₹ ')
        : '₹ 0';

    final filteredAmendments = _amendments.where((a) {
      final status = (a['status'] ?? '').toString();
      final priority = (a['priority'] ?? '').toString();
      final project = (a['project'] ?? '').toString();

      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Urgent') {
          if (!priority.toLowerCase().contains('urgent')) return false;
        } else if (!status.toLowerCase().contains(_selectedFilter.toLowerCase())) {
          return false;
        }
      }

      if (_selectedProject != 'All' && project != _selectedProject) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final title = (a['title'] ?? '').toString().toLowerCase();
        final proj = (a['project'] ?? '').toString().toLowerCase();
        final desc = (a['description'] ?? '').toString().toLowerCase();
        final reqBy = (a['requestedBy'] ?? '').toString().toLowerCase();
        final id = (a['id'] ?? '').toString().toLowerCase();

        if (!title.contains(_searchQuery) &&
            !proj.contains(_searchQuery) &&
            !desc.contains(_searchQuery) &&
            !reqBy.contains(_searchQuery) &&
            !id.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    final projectsList = [
      'All',
      ...AppConstants.preExistingProjects,
    ];

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Amendments & Scope Variations',
          subtitle:
              'Client change orders, architectural deviations, cost & timeline impacts, and sign-offs',
        ),
        const SizedBox(height: ScreenLayout.headerGap),

        // Stat Strip
        StatStrip(
          cards: [
            StatCard(
              title: 'Total Variations',
              value: '${_amendments.length} Logged',
              icon: Icons.published_with_changes_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Net Value Added',
              value: totalCostStr,
              icon: Icons.add_chart_rounded,
              accentColor: AppColors.success,
            ),
            StatCard(
              title: 'Schedule Deviation',
              value: '+$totalDaysImpact Days',
              icon: Icons.schedule_rounded,
              accentColor: AppColors.warning,
            ),
            StatCard(
              title: 'Client Approved',
              value: '$totalApproved Signed',
              icon: Icons.verified_user_rounded,
              accentColor: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: ScreenLayout.sectionGap),

        // Search Bar
        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search variations, project, client or amendment ID...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final filter in _filterChips)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PillBox(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    activeColor: filter == 'Urgent'
                        ? AppColors.error
                        : AppColors.brandPeach,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter =
                            _selectedFilter == filter && filter != 'All'
                                ? 'All'
                                : filter;
                      });
                    },
                  ),
                ),
              if (projectsList.length > 2) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 190,
                  height: AppSizes.chipHeight,
                  child: QuickFadeDropdown<String>(
                    value: _selectedProject,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCard,
                    icon: const Icon(
                      Icons.filter_alt_rounded,
                      size: 14,
                      color: AppColors.brandPeach,
                    ),
                    style: AppTypography.labelSmall(isDark).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                        borderSide: BorderSide(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProject = val);
                      }
                    },
                    items: projectsList.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(
                          p == 'All' ? 'All Projects' : p,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Amendments List
        if (filteredAmendments.isEmpty)
          EmptyStateCard(
            icon: Icons.published_with_changes_outlined,
            title: 'No Scope Amendments Found',
            message: _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No variation orders match your current filter criteria.'
                : 'Log client variation requests, site engineering adjustments, or scope changes.',
            action: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                  _selectedProject = 'All';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Clear Filters & View All',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredAmendments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final amd = filteredAmendments[index];
              return _buildAmendmentCard(context, amd, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildAmendmentCard(
    BuildContext context,
    Map<String, dynamic> amd,
    bool isDark,
  ) {
    final id = (amd['id'] ?? 'AMD-001').toString();
    final title = (amd['title'] ?? 'Scope Amendment').toString();
    final project = (amd['project'] ?? 'General Site').toString();
    final initiatedBy = (amd['initiatedBy'] ?? 'Client Request').toString();
    final costImpact = (amd['costImpact'] ?? '₹ 0').toString();
    final timelineImpact = (amd['timelineImpact'] ?? '+0 Days').toString();
    final priority = (amd['priority'] ?? 'Medium').toString();
    final status = (amd['status'] ?? 'Under Review').toString();
    final requestedBy = (amd['requestedBy'] ?? 'Client').toString();
    final description = (amd['description'] ?? '').toString();
    final signOffDate = (amd['clientSignOffDate'] ?? 'Pending').toString();

    final statusColor = _getStatusColor(status);
    final isUrgent = priority.toLowerCase().contains('urgent');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _showAmendmentExpandedBox(context, amd, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: ID + Priority + Status Badge
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightBackground)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        id,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isUrgent
                                ? AppColors.error
                                : AppColors.brandPeach)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isUrgent
                              ? AppColors.error
                              : AppColors.brandPeach,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title & Project
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textLightPrimary
                  : AppColors.textDarkPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                size: 13,
                color: AppColors.brandPeach,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  project,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textLightSecondary
                        : AppColors.textDarkSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Text(
                  initiatedBy,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPeach,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Cost & Timeline Impact Highlights
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FINANCIAL IMPACT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        costImpact,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SCHEDULE IMPACT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timelineImpact,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description & Scope Narrative
          if (description.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground)
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textLightSecondary
                      : AppColors.textDarkSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Client Sign-off & Requested By Row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusTagPill(label: 'By: $requestedBy'),
              StatusTagPill(
                label: 'Sign-off: $signOffDate',
                accentColor: signOffDate != 'Pending' ? AppColors.success : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Progression Buttons
          Row(
            children: [
              if (status == 'Under Review') ...[
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.55),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _amendments.remove(amd));
                        _saveAmendments();
                        BackendManager.instance.deleteDocument(
                          'amendments',
                          id,
                        );
                        AppNotification.show(
                          context,
                          message: 'Amendment $id declined & archived.',
                        );
                      },
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: Text(
                        'Decline',
                        style: AppTypography.labelSmall(isDark).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          amd['status'] = 'Client Approved';
                          amd['clientSignOffDate'] =
                              DateFormat('dd MMM yyyy').format(DateTime.now());
                        });
                        _saveAmendments();
                        AppNotification.show(
                          context,
                          message: 'Amendment $id approved by client.',
                        );
                      },
                      icon: const Icon(Icons.thumb_up_alt_rounded, size: 15),
                      label: Text(
                        'Client Approved ✓',
                        style: AppTypography.labelSmall(isDark).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'Client Approved') ...[
                _buildStepBackButton(amd, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() => amd['status'] = 'In Execution');
                      _saveAmendments();
                      AppNotification.show(
                        context,
                        message: 'Amendment $id transitioned into Site Execution.',
                      );
                    },
                    icon: const Icon(Icons.construction_rounded, size: 15),
                    label: const Text(
                      'Move to Site Execution',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else if (status == 'In Execution') ...[
                _buildStepBackButton(amd, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() => amd['status'] = 'Completed');
                      _saveAmendments();
                      AppNotification.show(
                        context,
                        message: 'Amendment $id completed and marked for invoicing.',
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 15),
                    label: const Text(
                      'Mark Scope Completed',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else ...[
                _buildStepBackButton(amd, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B51E0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: const Color(0xFF9B51E0).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF9B51E0),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Variation Executed & Completed ✓',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9B51E0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
    ),
    );
  }

  void _showAmendmentExpandedBox(
    BuildContext context,
    Map<String, dynamic> amd,
    bool isDark,
  ) {
    final id = (amd['id'] ?? 'AMD-001').toString();
    final title = (amd['title'] ?? 'Scope Amendment').toString();
    final project = (amd['project'] ?? 'General Site').toString();
    final initiatedBy = (amd['initiatedBy'] ?? 'Client Request').toString();
    final costImpact = (amd['costImpact'] ?? '₹ 0').toString();
    final timelineImpact = (amd['timelineImpact'] ?? '+0 Days').toString();
    final priority = (amd['priority'] ?? 'Medium').toString();
    final status = (amd['status'] ?? 'Under Review').toString();
    final requestedBy = (amd['requestedBy'] ?? 'Client').toString();
    final description = (amd['description'] ?? '').toString();
    final signOffDate = (amd['clientSignOffDate'] ?? 'Pending').toString();
    final statusColor = _getStatusColor(status);

    showExpandedDetailBox(
      context: context,
      title: title,
      subtitle: '$id • $project',
      headerIcon: Icons.published_with_changes_rounded,
      accentColor: statusColor,
      badgeLabel: status,
      badgeColor: statusColor,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Financial Impact',
                value: costImpact,
                color: AppColors.success,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Schedule Impact',
                value: timelineImpact,
                color: AppColors.warning,
                icon: Icons.schedule_rounded,
              ),
              DetailMetric(
                label: 'Priority',
                value: priority,
                color: priority.toLowerCase().contains('urgent')
                    ? AppColors.error
                    : AppColors.brandPeach,
                icon: Icons.priority_high_rounded,
              ),
              DetailMetric(
                label: 'Client Sign-off',
                value: signOffDate,
                color: signOffDate != 'Pending' ? AppColors.success : null,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Variation Details', isDark: isDark),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project Site',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.assignment_ind_outlined,
            label: 'Initiated By',
            value: initiatedBy,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Requested By',
            value: requestedBy,
            isDark: isDark,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            DetailNoteBox(
              label: 'SCOPE DESCRIPTION',
              text: description,
              isDark: isDark,
            ),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        if (status == 'Under Review') ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => _amendments.remove(amd));
              _saveAmendments();
              BackendManager.instance.deleteDocument(
                'amendments',
                id,
              );
              AppNotification.show(
                context,
                message: 'Amendment $id declined & archived.',
              );
            },
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Decline', maxLines: 1),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPeach,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.thumb_up_alt_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Client Approved', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() {
                amd['status'] = 'Client Approved';
                amd['clientSignOffDate'] =
                    DateFormat('dd MMM yyyy').format(DateTime.now());
              });
              _saveAmendments();
              AppNotification.show(
                context,
                message: 'Amendment $id approved by client.',
              );
            },
          ),
        ] else if (status == 'Client Approved') ...[
          _buildStepBackButton(
            amd,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.construction_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Move to Site Execution', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => amd['status'] = 'In Execution');
              _saveAmendments();
              AppNotification.show(
                context,
                message: 'Amendment $id transitioned into Site Execution.',
              );
            },
          ),
        ] else if (status == 'In Execution') ...[
          _buildStepBackButton(
            amd,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Mark Completed', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => amd['status'] = 'Completed');
              _saveAmendments();
              AppNotification.show(
                context,
                message: 'Amendment $id completed and marked for invoicing.',
              );
            },
          ),
        ] else ...[
          _buildStepBackButton(
            amd,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Close', maxLines: 1),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddAmendmentModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '3');
    final reqByCtrl = TextEditingController(text: 'Client Request');
    final descCtrl = TextEditingController();

    String selectedProj = AppConstants.preExistingProjects.isNotEmpty
        ? AppConstants.preExistingProjects.first
        : 'Aurelia Sea-Facing Penthouse 42';
    String selectedReason = 'Client Request';
    String selectedPriority = 'Medium';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Log Scope Amendment / Variation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amendment Title *',
                    hintText: 'e.g. Master Bedroom Motorized Curtain Tracks',
                  ),
                ),
                const SizedBox(height: 12),
                QuickFadeDropdown<String>(
                  initialValue: selectedProj,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Associated Project Site *',
                  ),
                  items: AppConstants.preExistingProjects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedProj = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: QuickFadeDropdown<String>(
                        initialValue: selectedReason,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Variation Trigger *',
                        ),
                        items: [
                          'Client Request',
                          'Site Engineering Condition',
                          'Design Refinement',
                          'Material Upgrade',
                        ]
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedReason = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickFadeDropdown<String>(
                        initialValue: selectedPriority,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Priority *',
                        ),
                        items: [
                          'Urgent',
                          'High',
                          'Medium',
                          'Low',
                        ]
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedPriority = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cost Impact (INR ₹)',
                          hintText: 'e.g. 185000',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: daysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Schedule Impact (+Days)',
                          hintText: 'e.g. 5',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reqByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Requested By / Approver',
                    hintText: 'e.g. Mrs. Ananya Goenka',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Scope Details & Architectural Justification',
                    hintText:
                        'Explain exact changes to drawings, joinery, materials, and automation...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        AppNotification.show(
                          context,
                          message: 'Please provide an amendment title.',
                        );
                        return;
                      }

                      final parsedCost = CurrencyUtils.parseAmount(costCtrl.text);
                      final costFormatted = parsedCost > 0
                          ? CurrencyUtils.formatInr(parsedCost, symbol: '+₹ ')
                          : '₹ 0';

                      final parsedDays = CurrencyUtils.parseAmount(daysCtrl.text);
                      final daysFormatted = '+$parsedDays Days';

                      final newAmd = {
                        'id': 'AMD-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        'title': title,
                        'project': selectedProj,
                        'initiatedBy': selectedReason,
                        'costImpact': costFormatted,
                        'timelineImpact': daysFormatted,
                        'priority': selectedPriority,
                        'status': 'Under Review',
                        'requestedBy': reqByCtrl.text.trim().isEmpty
                            ? 'Client Request'
                            : reqByCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'clientSignOffDate': 'Pending Client Sign-off',
                      };

                      setState(() {
                        _amendments.insert(0, newAmd);
                      });
                      _saveAmendments();

                      Navigator.pop(ctx);
                      AppNotification.show(
                        context,
                        message: 'Scope amendment "$title" logged successfully.',
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text(
                      'Log & Publish Amendment',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
