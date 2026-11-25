import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/project_model.dart';
import '../../../core/permissions/app_permissions.dart';
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
import '../../auth/state/auth_provider.dart';
import '../../dashboard/views/main_dashboard_screen.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';
import '../../projects/dialogs/project_timeline_sheet_dialog.dart';
import '../services/sales_pipeline_service.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final List<Map<String, dynamic>> _leads = [];
  final List<Map<String, dynamic>> _projects = [];
  String _selectedSalesViewTab = 'pipeline'; // 'pipeline' | 'project_report'

  // Pipeline filters
  String _selectedStageFilter = 'All';
  String _selectedReferralFilter = 'All Sources';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Project Report filters
  String _selectedProjectStatusFilter = 'All'; // 'All' | 'Ongoing' | 'Completed' | 'Delayed'
  String _projectSearchQuery = '';
  final TextEditingController _projectSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLeads();
    _loadProjects();
    MobileActionSheets.leadCreatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectChanged);
    MobileActionSheets.projectUpdatedNotifier.addListener(_onProjectChanged);
    MobileActionSheets.invoiceCreatedNotifier.addListener(_onInvoiceChanged);
    MobileActionSheets.invoiceUpdatedNotifier.addListener(_onInvoiceChanged);
    StorageService.cloudSyncNotifier.addListener(_onCloudSync);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onCloudSync);
    MobileActionSheets.leadCreatedNotifier.removeListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.removeListener(_onLeadChanged);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectChanged);
    MobileActionSheets.projectUpdatedNotifier.removeListener(_onProjectChanged);
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceChanged);
    MobileActionSheets.invoiceUpdatedNotifier.removeListener(_onInvoiceChanged);
    _searchController.dispose();
    _projectSearchController.dispose();
    super.dispose();
  }

  void _onInvoiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onCloudSync() {
    if (mounted) {
      setState(() {
        _loadLeads();
        _loadProjects();
      });
    }
  }

  void _loadLeads() {
    _leads.clear();
    _leads.addAll(StorageService.getLeads());
  }

  void _loadProjects() {
    _projects.clear();
    _projects.addAll(StorageService.getProjects());
  }

  void _onLeadChanged() {
    if (mounted) {
      setState(() {
        _loadLeads();
      });
    }
  }

  void _onProjectChanged() {
    if (mounted) {
      setState(() {
        _loadProjects();
      });
    }
  }

  Color _getStageColor(String stage) {
    final lower = stage.toLowerCase().trim();
    if (lower == 'approved' ||
        lower == 'closed won' ||
        lower.contains('approved') ||
        lower.contains('won') ||
        lower.contains('advance')) {
      return AppColors.success;
    }
    if (lower == 'boq' ||
        lower.contains('boq') ||
        lower.contains('pitch') ||
        lower.contains('proposal')) {
      return AppColors.info;
    }
    if (lower == 'site visit' ||
        lower.contains('visit') ||
        lower.contains('recce')) {
      return AppColors.brandOrange;
    }
    if (lower.contains('followup') ||
        lower.contains('follow-up') ||
        lower.contains('call') ||
        lower.contains('negotiation')) {
      return const Color(0xFFD97706);
    }
    if (lower.contains('lost') || lower.contains('dropped')) {
      return AppColors.error;
    }
    return AppColors.brandPeach;
  }

  String _classifyProjectStatus(Map<String, dynamic> project) {
    if (project['isDelayed'] == true || project['status'] == 'Delayed') {
      return 'Delayed';
    }
    final status = (project['status'] ?? '').toString();
    if (status == 'Completed') return 'Completed';
    final stages = project['stages'];
    if (stages is List && stages.isNotEmpty) {
      final doneCount =
          stages.where((s) => s is Map && s['isDone'] == true).length;
      if (doneCount == stages.length) return 'Completed';
    }
    return 'Ongoing';
  }

  Color _getProjectStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Delayed':
        return AppColors.error;
      case 'Ongoing':
      default:
        return AppColors.brandPeach;
    }
  }

  IconData _getProjectStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.verified_rounded;
      case 'Delayed':
        return Icons.warning_amber_rounded;
      case 'Ongoing':
      default:
        return Icons.construction_rounded;
    }
  }

  int _parseBudget(dynamic rawBudget) => CurrencyUtils.parseBudget(rawBudget);

  String _formatCurrency(int amount) =>
      amount <= 0 ? '₹ 0' : CurrencyUtils.formatInr(amount);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageSales = AppPermissions.canManageSales(
      auth.currentRole,
      user: auth.currentUser,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Pipeline Metrics
    int totalPipeline = 0;
    int wonCount = 0;

    for (final l in _leads) {
      final val = _parseBudget(l['estValue']);
      totalPipeline += val;

      final stg = (l['stage'] ?? l['status'] ?? '') as String;
      final lowerStg = stg.toLowerCase();
      if (SalesPipelineService.isApproved(stg) ||
          lowerStg.contains('advance') ||
          lowerStg.contains('converted')) {
        wonCount++;
      }
    }

    final pipelineStr = _formatCurrency(totalPipeline);
    final conversionRateStr = _leads.isEmpty
        ? '0.0%'
        : '${((wonCount / _leads.length) * 100).toStringAsFixed(1)}%';

    // 2. Project Status Report Metrics (Ongoing, Completed, Delayed)
    int ongoingCount = 0;
    int completedCount = 0;
    int delayedCount = 0;
    int ongoingValue = 0;
    int completedValue = 0;
    int delayedValue = 0;
    int totalProjectBudget = 0;

    for (final p in _projects) {
      final status = _classifyProjectStatus(p);
      final budgetVal = _parseBudget(p['budget']);
      totalProjectBudget += budgetVal;

      if (status == 'Completed') {
        completedCount++;
        completedValue += budgetVal;
      } else if (status == 'Delayed') {
        delayedCount++;
        delayedValue += budgetVal;
      } else {
        ongoingCount++;
        ongoingValue += budgetVal;
      }
    }

    return ScreenScrollView(
      children: [
        ScreenHeader(
          _selectedSalesViewTab == 'pipeline'
              ? 'Sales & Client Acquisition'
              : 'Executive Project Status Report',
          subtitle: _selectedSalesViewTab == 'pipeline'
              ? 'Track client inquiries, follow-ups, site visits & conversion pipeline'
              : 'Track active, completed, and delayed turnkey sites with financial totals',
        ),
        const SizedBox(height: ScreenLayout.headerGap),
        // Top View Switcher: Sales Pipeline vs Detailed Project Status Report
        _buildViewSwitcher(isDark),
        const SizedBox(height: ScreenLayout.sectionGap),

        if (_selectedSalesViewTab == 'pipeline')
          ..._buildPipelineViewChildren(
            context: context,
            isDark: isDark,
            canManageSales: canManageSales,
            pipelineStr: pipelineStr,
            conversionRateStr: conversionRateStr,
          )
        else
          ..._buildProjectReportViewChildren(
            context: context,
            isDark: isDark,
            ongoingCount: ongoingCount,
            completedCount: completedCount,
            delayedCount: delayedCount,
            ongoingValue: ongoingValue,
            completedValue: completedValue,
            delayedValue: delayedValue,
            totalProjectBudget: totalProjectBudget,
          ),
      ],
    );
  }

  Widget _buildViewSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildViewTabButton(
              title: 'Sales Pipeline',
              count: '${_leads.length}',
              icon: Icons.filter_alt_rounded,
              isSelected: _selectedSalesViewTab == 'pipeline',
              onTap: () => setState(() => _selectedSalesViewTab = 'pipeline'),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildViewTabButton(
              title: 'Project Status Report',
              count: '${_projects.length}',
              icon: Icons.analytics_outlined,
              isSelected: _selectedSalesViewTab == 'project_report',
              onTap: () =>
                  setState(() => _selectedSalesViewTab = 'project_report'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabButton({
    required String title,
    required String count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(6.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPeach.withValues(alpha: isDark ? 0.22 : 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? AppColors.brandPeach : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppColors.brandPeach
                  : (isDark
                      ? AppColors.textLightSecondary
                      : AppColors.textDarkSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark
                            ? AppColors.textLightSecondary
                            : AppColors.textDarkSecondary),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandPeach
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.black
                      : (isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PIPELINE TAB CHILDREN ====================

  List<Widget> _buildPipelineViewChildren({
    required BuildContext context,
    required bool isDark,
    required bool canManageSales,
    required String pipelineStr,
    required String conversionRateStr,
  }) {
    // Stage counts for canonical 5-stage pipeline
    final leadCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString();
      final lower = stg.toLowerCase();
      if (lower.contains('lost') || lower.contains('dropped')) return false;
      return SalesPipelineService.getStageIndex(stg) == 0;
    }).length;

    final followupCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString();
      final lower = stg.toLowerCase();
      if (lower.contains('lost') || lower.contains('dropped')) return false;
      return SalesPipelineService.getStageIndex(stg) == 1;
    }).length;

    final siteVisitCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString();
      final lower = stg.toLowerCase();
      if (lower.contains('lost') || lower.contains('dropped')) return false;
      return SalesPipelineService.getStageIndex(stg) == 2;
    }).length;

    final boqCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString();
      final lower = stg.toLowerCase();
      if (lower.contains('lost') || lower.contains('dropped')) return false;
      return SalesPipelineService.getStageIndex(stg) == 3;
    }).length;

    final approvedCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString();
      final lower = stg.toLowerCase();
      if (lower.contains('lost') || lower.contains('dropped')) return false;
      return SalesPipelineService.getStageIndex(stg) == 4;
    }).length;

    final lostCount = _leads.where((l) {
      final stg = (l['stage'] ?? l['status'] ?? '').toString().toLowerCase();
      return stg.contains('lost') || stg.contains('dropped');
    }).length;

    final filteredLeads = _leads.where((lead) {
      final client = (lead['client'] ?? lead['name'] ?? '')
          .toString()
          .toLowerCase();
      final scope = (lead['scope'] ?? '').toString().toLowerCase();
      final location = (lead['location'] ?? '').toString().toLowerCase();
      final stage = (lead['stage'] ?? lead['status'] ?? '').toString();
      final refSource = (lead['referralSource'] ?? '').toString();

      final matchesSearch = _searchQuery.isEmpty ||
          client.contains(_searchQuery.toLowerCase()) ||
          scope.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Stage Filter
      if (_selectedStageFilter == 'Lead' ||
          _selectedStageFilter == 'New Inquiry') {
        if (stage.toLowerCase().contains('lost') ||
            stage.toLowerCase().contains('dropped') ||
            SalesPipelineService.getStageIndex(stage) != 0) {
          return false;
        }
      } else if (_selectedStageFilter == 'Followup' ||
          _selectedStageFilter == 'Followup (Call)') {
        if (stage.toLowerCase().contains('lost') ||
            stage.toLowerCase().contains('dropped') ||
            SalesPipelineService.getStageIndex(stage) != 1) {
          return false;
        }
      } else if (_selectedStageFilter == 'Site Visit' ||
          _selectedStageFilter == 'Site Visit Scheduled') {
        if (stage.toLowerCase().contains('lost') ||
            stage.toLowerCase().contains('dropped') ||
            SalesPipelineService.getStageIndex(stage) != 2) {
          return false;
        }
      } else if (_selectedStageFilter == 'BOQ' ||
          _selectedStageFilter == 'Design Pitch' ||
          _selectedStageFilter == 'Design Pitch & BOQ' ||
          _selectedStageFilter == 'Negotiation') {
        if (stage.toLowerCase().contains('lost') ||
            stage.toLowerCase().contains('dropped') ||
            SalesPipelineService.getStageIndex(stage) != 3) {
          return false;
        }
      } else if (_selectedStageFilter == 'Approved' ||
          _selectedStageFilter == 'Closed Won') {
        if (stage.toLowerCase().contains('lost') ||
            stage.toLowerCase().contains('dropped') ||
            SalesPipelineService.getStageIndex(stage) != 4) {
          return false;
        }
      } else if (_selectedStageFilter == 'Lost / Dropped' ||
          _selectedStageFilter == 'Lost') {
        if (!stage.toLowerCase().contains('lost') &&
            !stage.toLowerCase().contains('dropped')) {
          return false;
        }
      } else if (_selectedStageFilter != 'All' &&
          stage != _selectedStageFilter) {
        if (!stage.toLowerCase().contains(_selectedStageFilter.toLowerCase())) {
          return false;
        }
      }

      // Referral Filter
      if (_selectedReferralFilter != 'All Sources' &&
          refSource != _selectedReferralFilter) {
        return false;
      }

      return true;
    }).toList();

    return [
      // Sleek Single-Row KPI Ticker (Pipeline Value, Inquiries, Conv.)
      _buildCompactPipelineKpiStrip(
        isDark: isDark,
        pipelineStr: pipelineStr,
        leadsCount: _leads.length,
        conversionRateStr: conversionRateStr,
      ),
      const SizedBox(height: ScreenLayout.controlGap),

      // Search Bar + Compact Referral Source Filter Button
      Row(
        children: [
          Expanded(
            child: ScreenSearchField(
              controller: _searchController,
              hintText: 'Search leads by client, scope, or site...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          const SizedBox(width: 8),
          _buildReferralSourceMenuButton(isDark),
        ],
      ),
      if (_selectedReferralFilter != 'All Sources') ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandPeach.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: AppColors.brandPeach.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.filter_alt_rounded,
                size: 14,
                color: AppColors.brandPeach,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Source: $_selectedReferralFilter',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPeach,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedReferralFilter = 'All Sources');
                },
                borderRadius: BorderRadius.circular(4.0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPeach,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.brandPeach,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: ScreenLayout.controlGap),

      // Stage Filter Pills (evenly stretched when screen fits, smooth scroll on narrow)
      LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PillBox(
                    label: 'All (${_leads.length})',
                    isSelected: _selectedStageFilter == 'All',
                    activeColor: AppColors.brandPeach,
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'All'),
                  ),
                  const SizedBox(width: 6),
                  PillBox(
                    label: 'Lead ($leadCount)',
                    isSelected: _selectedStageFilter == 'Lead' ||
                        _selectedStageFilter == 'New Inquiry',
                    activeColor: AppColors.brandPeach,
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'Lead'),
                  ),
                  const SizedBox(width: 6),
                  PillBox(
                    label: 'Followup ($followupCount)',
                    isSelected: _selectedStageFilter == 'Followup' ||
                        _selectedStageFilter == 'Followup (Call)',
                    activeColor: const Color(0xFFD97706),
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'Followup'),
                  ),
                  const SizedBox(width: 6),
                  PillBox(
                    label: 'Site Visit ($siteVisitCount)',
                    isSelected: _selectedStageFilter == 'Site Visit' ||
                        _selectedStageFilter == 'Site Visit Scheduled',
                    activeColor: AppColors.brandOrange,
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'Site Visit'),
                  ),
                  const SizedBox(width: 6),
                  PillBox(
                    label: 'BOQ ($boqCount)',
                    isSelected: _selectedStageFilter == 'BOQ' ||
                        _selectedStageFilter == 'Design Pitch & BOQ' ||
                        _selectedStageFilter == 'Design Pitch',
                    activeColor: AppColors.info,
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'BOQ'),
                  ),
                  const SizedBox(width: 6),
                  PillBox(
                    label: 'Approved ($approvedCount)',
                    isSelected: _selectedStageFilter == 'Approved' ||
                        _selectedStageFilter == 'Closed Won',
                    activeColor: AppColors.success,
                    onSelected: () =>
                        setState(() => _selectedStageFilter = 'Approved'),
                  ),
                  if (lostCount > 0) ...[
                    const SizedBox(width: 6),
                    PillBox(
                      label: 'Lost ($lostCount)',
                      isSelected: _selectedStageFilter == 'Lost / Dropped' ||
                          _selectedStageFilter == 'Lost',
                      activeColor: AppColors.error,
                      onSelected: () => setState(
                        () => _selectedStageFilter = 'Lost / Dropped',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: ScreenLayout.listGap),

      // Leads Feed
      FilterSwitcher(
        child: filteredLeads.isEmpty
            ? EmptyStateCard(
                key: ValueKey(
                  'empty_leads_${_selectedStageFilter}_$_selectedReferralFilter',
                ),
                icon: Icons.person_search_outlined,
                title: _leads.isEmpty
                    ? 'No Client Inquiries'
                    : 'No Matching Leads Found',
                message: _leads.isEmpty
                    ? (canManageSales
                        ? AppStrings.tr(
                            'No client leads yet. Tap below to add your first lead.',
                          )
                        : 'No client inquiries yet.')
                    : 'Try adjusting your search, stage, or referral channel filter to view active leads.',
                action: (_selectedStageFilter != 'All' ||
                        _selectedReferralFilter != 'All Sources' ||
                        _searchQuery.isNotEmpty)
                    ? OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedStageFilter = 'All';
                            _selectedReferralFilter = 'All Sources';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Show All Leads'),
                      )
                    : (_leads.isEmpty && canManageSales
                        ? FilledButton.icon(
                            onPressed: () =>
                                MobileActionSheets.showAddLeadSheet(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPeach,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                            ),
                            label: Text(AppStrings.tr('Add New Lead')),
                          )
                        : null),
              )
            : ResponsiveCardGrid(
                key: ValueKey(
                  'leads_${_selectedStageFilter}_$_selectedReferralFilter',
                ),
                children: [
                  for (final lead in filteredLeads)
                    _buildLeadPipelineCard(context, lead, isDark),
                ],
              ),
      ),
    ];
  }

  Widget _buildCompactPipelineKpiStrip({
    required bool isDark,
    required String pipelineStr,
    required int leadsCount,
    required String conversionRateStr,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiTickerCell(
              label: 'Pipeline',
              value: pipelineStr,
              color: AppColors.brandPeach,
              isDark: isDark,
            ),
          ),
          _buildKpiDivider(isDark),
          Expanded(
            child: _buildKpiTickerCell(
              label: 'Inquiries',
              value: '$leadsCount Leads',
              color: isDark ? Colors.white : Colors.black87,
              isDark: isDark,
            ),
          ),
          _buildKpiDivider(isDark),
          Expanded(
            child: _buildKpiTickerCell(
              label: 'Conv.',
              value: conversionRateStr,
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: 0.6),
    );
  }

  Widget _buildKpiTickerCell({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textLightSecondary
                : AppColors.textDarkSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralSourceMenuButton(bool isDark) {
    final isFiltered = _selectedReferralFilter != 'All Sources';
    return PopupMenuButton<String>(
      tooltip: 'Filter by Referral Source',
      initialValue: _selectedReferralFilter,
      onSelected: (source) {
        HapticFeedback.selectionClick();
        setState(() => _selectedReferralFilter = source);
      },
      itemBuilder: (context) => const [
        'All Sources',
        'Client Referral',
        'Architect Partner',
        'Real Estate Consultant',
        'Instagram / Social Media',
        'Direct Walk-in',
      ]
          .map(
            (source) => PopupMenuItem<String>(
              value: source,
              child: Row(
                children: [
                  Icon(
                    _selectedReferralFilter == source
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 16,
                    color: _selectedReferralFilter == source
                        ? AppColors.brandPeach
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(source, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.brandPeach.withValues(alpha: 0.16)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isFiltered
                ? AppColors.brandPeach
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isFiltered ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: isFiltered
                  ? AppColors.brandPeach
                  : (isDark
                      ? AppColors.textLightSecondary
                      : AppColors.textDarkSecondary),
            ),
            if (isFiltered) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.brandPeach,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadPipelineCard(
    BuildContext context,
    Map<String, dynamic> lead,
    bool isDark,
  ) {
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final scope = (lead['scope'] ?? 'Turnkey Scope') as String;
    final location =
        (lead['location'] ?? 'Site Consultation Pending') as String;
    final estValue = (lead['estValue'] ?? '₹ 25L') as String;
    final referralSource =
        (lead['referralSource'] ?? 'Client Referral') as String;
    final referralBy = (lead['referralBy'] ?? '') as String;
    final stage = (lead['stage'] ?? lead['status'] ?? 'New Inquiry') as String;
    final reminderNote = (lead['reminderNote'] ?? '') as String;

    final stageColor = _getStageColor(stage);

    final auth = Provider.of<AuthProvider>(context);
    final canCreateProject = AppPermissions.canCreateProject(
      auth.currentRole,
      user: auth.currentUser,
    );
    final isConverted = lead['isConverted'] == true ||
        (lead['convertedToProject'] as String? ?? '').isNotEmpty;
    final convertedProjectName = (lead['convertedToProject'] as String? ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _showLeadExpandedBox(context, lead, isDark),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Row 1: Client Name, Phone, Budget
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: stageColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clientName,
                            style: AppTypography.titleMedium(isDark).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          estValue,
                          style: AppTypography.titleMedium(isDark).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPeach,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$scope • $location',
                      style: AppTypography.bodySmall(isDark)
                          .copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isConverted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Turnkey Site Launched: "$convertedProjectName"',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Sleek 5-Stage Pipeline Progress Strip
          _buildPipelineStepper(
            context: context,
            lead: lead,
            stage: stage,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Full-Width Metadata Row: Stage Pill
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => MobileActionSheets.showUpdateLeadStatusSheet(
                    context,
                    lead,
                    onUpdated: _loadLeads,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: stageColor.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 12,
                          color: stageColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              stage,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stageColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 14,
                          color: stageColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtle Referral Attribution Line
          Row(
            children: [
              Icon(
                Icons.share_location_rounded,
                size: 12,
                color: isDark
                    ? AppColors.textLightSecondary
                    : AppColors.textDarkSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  referralBy.isNotEmpty
                      ? 'Ref: $referralSource ($referralBy)'
                      : 'Ref: $referralSource',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textLightSecondary
                        : AppColors.textDarkSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (reminderNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 13,
                  color: AppColors.brandPeach,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reminder: "$reminderNote"',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightSecondary
                          : AppColors.textDarkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Mapped Invoices & Payment QR
          Builder(
            builder: (context) {
              final leadId = lead['id']?.toString() ?? '';
              final convertedProj = lead['convertedToProject'] as String?;
              final allInvoices = StorageService.getInvoices();
              final mappedInvoices = allInvoices.where((inv) {
                if (leadId.isNotEmpty && inv['leadId'] == leadId) return true;
                if (convertedProj != null &&
                    convertedProj.isNotEmpty &&
                    inv['project'] == convertedProj) {
                  return true;
                }
                final invClient = inv['client']?.toString().toLowerCase();
                final cName = clientName.toLowerCase();
                return invClient != null && invClient.contains(cName);
              }).toList();

              if (mappedInvoices.isEmpty) return const SizedBox.shrink();

              final latestInv = mappedInvoices.first;
              final invStatus = latestInv['status'] as String? ?? 'Sent';
              final isSettled = invStatus.toLowerCase() == 'settled' ||
                  invStatus.toLowerCase() == 'paid';
              final statusColor =
                  isSettled ? AppColors.success : AppColors.warning;
              final invAmount = latestInv['amount'] as String? ?? '';
              final invTitle = latestInv['title'] as String? ??
                  '${latestInv['id']} Invoice';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppColors.brandPeach.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invTitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$invAmount • Status: $invStatus',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Row 3: Full-Width Project Launch / View Action
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: AppSizes.compactButtonHeight,
                  child: isConverted
                      ? OutlinedButton.icon(
                          style: AppSizes.compactOutlinedStyle(
                            foregroundColor: AppColors.success,
                            borderColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          icon: const Icon(Icons.apartment_rounded, size: 14),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'View in Projects',
                              maxLines: 1,
                              style: AppTypography.labelSmall(isDark).copyWith(
                                fontSize: AppSizes.compactButtonFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            MobileActionSheets.projectFilterNotifier.value =
                                'All';
                            MainDashboardScreen.navigateToTab(2);
                          },
                        )
                      : (canCreateProject
                            ? ElevatedButton.icon(
                                style: AppSizes.compactElevatedStyle(
                                  backgroundColor: AppColors.brandPeach,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                icon: const Icon(
                                  Icons.rocket_launch_rounded,
                                  size: 14,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Launch',
                                    maxLines: 1,
                                    style: AppTypography.labelSmall(
                                      isDark,
                                    ).copyWith(
                                      fontSize: AppSizes.compactButtonFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  MobileActionSheets.showInitiateProjectSheet(
                                    context,
                                    initialName: '$clientName Residence',
                                    initialClient: clientName,
                                    initialBudget: estValue.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    ),
                                    leadId: lead['id'] as String?,
                                  );
                                },
                              )
                            : Container(
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 12,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Pending Handover',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textLightMuted
                                                : AppColors.textDarkMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    ),
    );
  }

  void _showLeadExpandedBox(
    BuildContext context,
    Map<String, dynamic> lead,
    bool isDark,
  ) {
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final scope = (lead['scope'] ?? 'Turnkey Scope') as String;
    final location =
        (lead['location'] ?? 'Site Consultation Pending') as String;
    final estValue = (lead['estValue'] ?? '₹ 25L') as String;
    final referralSource =
        (lead['referralSource'] ?? 'Client Referral') as String;
    final referralBy = (lead['referralBy'] ?? '') as String;
    final stage = (lead['stage'] ?? lead['status'] ?? 'New Inquiry') as String;
    final nextCallDate = (lead['nextCallDate'] ?? '') as String;
    final nextCallTime = (lead['nextCallTime'] ?? '11:00 AM') as String;
    final reminderNote = (lead['reminderNote'] ?? '') as String;
    final stageColor = _getStageColor(stage);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canCreateProject = AppPermissions.canCreateProject(
      auth.currentRole,
      user: auth.currentUser,
    );
    final isConverted = lead['isConverted'] == true ||
        (lead['convertedToProject'] as String? ?? '').isNotEmpty;
    final convertedProjectName = (lead['convertedToProject'] as String? ?? '');

    final leadId = lead['id']?.toString() ?? '';
    final convertedProj = lead['convertedToProject'] as String?;
    final mappedInvoices = StorageService.getInvoices().where((inv) {
      if (leadId.isNotEmpty && inv['leadId'] == leadId) return true;
      if (convertedProj != null &&
          convertedProj.isNotEmpty &&
          inv['project'] == convertedProj) {
        return true;
      }
      final invClient = inv['client']?.toString().toLowerCase();
      return invClient != null && invClient.contains(clientName.toLowerCase());
    }).toList();

    showExpandedDetailBox(
      context: context,
      title: clientName,
      subtitle: '$scope • $location',
      headerIcon: Icons.person_pin_circle_rounded,
      accentColor: stageColor,
      badgeLabel: stage,
      badgeColor: stageColor,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Estimated Value',
                value: estValue,
                color: AppColors.brandPeach,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Follow-Up Reminder',
                value: nextCallDate.isNotEmpty
                    ? '$nextCallDate, $nextCallTime'
                    : 'Not Scheduled',
                color: AppColors.brandPeach,
                icon: Icons.alarm_on_rounded,
              ),
              DetailMetric(
                label: 'Site Status',
                value: isConverted ? 'Site Launched' : 'Pre-Execution',
                color: isConverted ? AppColors.success : AppColors.info,
                icon: Icons.apartment_rounded,
              ),
              DetailMetric(
                label: 'Linked Invoices',
                value: '${mappedInvoices.length} Mapped',
                color: mappedInvoices.isNotEmpty ? AppColors.brandPeach : null,
                icon: Icons.receipt_long_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Pipeline Progression', isDark: isDark),
          _buildPipelineStepper(
            context: dialogCtx,
            lead: lead,
            stage: stage,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Client & Attribution', isDark: isDark),
          DetailInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: (lead['phone'] ?? '+91 98000 00000').toString(),
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.share_location_rounded,
            label: 'Referral Source',
            value: referralBy.isNotEmpty
                ? '$referralSource ($referralBy)'
                : referralSource,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.place_outlined,
            label: 'Site Location',
            value: location,
            isDark: isDark,
          ),
          if (isConverted)
            DetailInfoRow(
              icon: Icons.check_circle_rounded,
              label: 'Linked Site',
              value: convertedProjectName,
              isDark: isDark,
              valueColor: AppColors.success,
            ),
          if (reminderNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            DetailNoteBox(
              label: 'CALL REMINDER NOTE',
              text: reminderNote,
              isDark: isDark,
            ),
          ],
          if (mappedInvoices.isNotEmpty) ...[
            const SizedBox(height: 16),
            DetailSectionTitle(label: 'Mapped Invoices & Payment', isDark: isDark),
            ...mappedInvoices.map((inv) {
              final invStatus = inv['status'] as String? ?? 'Sent';
              final isSettled = invStatus.toLowerCase() == 'settled' ||
                  invStatus.toLowerCase() == 'paid';
              final statusColor =
                  isSettled ? AppColors.success : AppColors.warning;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: AppColors.brandPeach.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv['title'] as String? ??
                                  '${inv['id']} Invoice',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${inv['amount']} • $invStatus',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        if (isConverted)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.apartment_rounded, size: 14),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Projects', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              MobileActionSheets.projectFilterNotifier.value = 'All';
              MainDashboardScreen.navigateToTab(2);
            },
          )
        else if (canCreateProject)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPeach,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.rocket_launch_rounded, size: 14),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Launch', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              MobileActionSheets.showInitiateProjectSheet(
                context,
                initialName: '$clientName Residence',
                initialClient: clientName,
                initialBudget: () {
                  final parsed = CurrencyUtils.parseBudget(estValue);
                  return parsed > 0 ? '$parsed' : '';
                }(),
                leadId: lead['id'] as String?,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPipelineStepper({
    required BuildContext context,
    required Map<String, dynamic> lead,
    required String stage,
    required bool isDark,
  }) {
    final isLost = stage.toLowerCase().contains('lost') ||
        stage.toLowerCase().contains('dropped');
    final currIdx = SalesPipelineService.getStageIndex(stage);
    final stages = SalesPipelineService.pipelineSequence;
    final stageColor = _getStageColor(stage);
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage label + Quick Advance button on one clean line
        Row(
          children: [
            Expanded(
              child: Text(
                isLost
                    ? 'Lost / Dropped'
                    : 'Stage ${currIdx + 1}/5: ${stages[currIdx]}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: stageColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (!isLost && currIdx < 4)
              InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  if (currIdx == 3) {
                    await SalesPipelineService.approveLeadAndMoveToProjects(
                      lead,
                    );
                    if (context.mounted) {
                      AppNotification.show(
                        context,
                        message:
                            'BOQ Approved! "$clientName Residence" moved to Projects, Design, Materials & Accounts.',
                        backgroundColor: AppColors.success,
                      );
                      setState(() {
                        _loadLeads();
                        _loadProjects();
                      });
                    }
                  } else {
                    final nextStage = stages[currIdx + 1];
                    await SalesPipelineService.updateLeadStage(
                      lead: lead,
                      newStage: nextStage,
                    );
                    if (context.mounted) {
                      AppNotification.show(
                        context,
                        message: 'Lead moved to "$nextStage".',
                        backgroundColor: _getStageColor(nextStage),
                      );
                      setState(() {
                        _loadLeads();
                      });
                    }
                  }
                },
                borderRadius: BorderRadius.circular(4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: currIdx == 3
                        ? AppColors.success
                        : AppColors.brandPeach,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currIdx == 3
                            ? Icons.rocket_launch_rounded
                            : Icons.fast_forward_rounded,
                        size: 11,
                        color: currIdx == 3 ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currIdx == 3
                            ? 'Approve BOQ'
                            : 'Next: ${_getShortStageName(stages[currIdx + 1])}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: currIdx == 3 ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (currIdx == 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.55),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Approved & Converted',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Sleek 5-Segment Horizontal Progress Bar
        Row(
          children: [
            for (int i = 0; i < stages.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Tooltip(
                  message: stages[i],
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final currentIdx = isLost ? -1 : currIdx;
                      if (i == currentIdx) {
                        MobileActionSheets.showUpdateLeadStatusSheet(
                          context,
                          lead,
                          onUpdated: _loadLeads,
                        );
                      } else if (i == 4) {
                        await SalesPipelineService.approveLeadAndMoveToProjects(
                          lead,
                        );
                        if (context.mounted) {
                          AppNotification.show(
                            context,
                            message:
                                'BOQ Approved! "$clientName Residence" moved to Projects, Design, Materials & Accounts.',
                            backgroundColor: AppColors.success,
                          );
                          setState(() {
                            _loadLeads();
                            _loadProjects();
                          });
                        }
                      } else {
                        await SalesPipelineService.updateLeadStage(
                          lead: lead,
                          newStage: stages[i],
                        );
                        if (context.mounted) {
                          AppNotification.show(
                            context,
                            message: 'Lead stage set to "${stages[i]}".',
                            backgroundColor: _getStageColor(stages[i]),
                          );
                          setState(() {
                            _loadLeads();
                          });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(3.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 5,
                        decoration: BoxDecoration(
                          color: !isLost && i < currIdx
                              ? AppColors.success
                              : (!isLost && i == currIdx
                                  ? stageColor
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _getShortStageName(String stage) {
    if (stage.contains('Followup')) return 'Followup';
    if (stage.contains('Visit')) return 'Site Visit';
    return stage;
  }

  // ==================== PROJECT STATUS REPORT CHILDREN ====================

  List<Widget> _buildProjectReportViewChildren({
    required BuildContext context,
    required bool isDark,
    required int ongoingCount,
    required int completedCount,
    required int delayedCount,
    required int ongoingValue,
    required int completedValue,
    required int delayedValue,
    required int totalProjectBudget,
  }) {
    // Filter projects based on status and search query
    final filteredProjects = _projects.where((p) {
      final status = _classifyProjectStatus(p);

      // Status chip filter
      if (_selectedProjectStatusFilter != 'All' &&
          status != _selectedProjectStatusFilter) {
        return false;
      }

      // Search filter
      if (_projectSearchQuery.isNotEmpty) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final client = (p['client'] ?? p['clientName'] ?? '')
            .toString()
            .toLowerCase();
        final location = (p['location'] ?? '').toString().toLowerCase();
        final pm = (p['pm'] ?? '').toString().toLowerCase();
        final q = _projectSearchQuery.toLowerCase();

        if (!name.contains(q) &&
            !client.contains(q) &&
            !location.contains(q) &&
            !pm.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    return [
      // Project Status StatStrip: Ongoing, Completed, Delayed, and Portfolio Value
      StatStrip(
        cards: [
          StatCard(
            title: 'Ongoing Projects',
            value: '$ongoingCount Active',
            trend: _formatCurrency(ongoingValue),
            icon: Icons.construction_rounded,
            accentColor: AppColors.brandPeach,
          ),
          StatCard(
            title: 'Completed Projects',
            value: '$completedCount Delivered',
            trend: _formatCurrency(completedValue),
            icon: Icons.verified_rounded,
            accentColor: AppColors.success,
          ),
          StatCard(
            title: 'Delayed Projects',
            value: '$delayedCount Flagged',
            trend: delayedCount > 0 ? 'Critical Schedule' : 'Zero Delays',
            icon: Icons.warning_amber_rounded,
            accentColor: delayedCount > 0
                ? AppColors.error
                : AppColors.success,
          ),
          StatCard(
            title: 'Total Portfolio Value',
            value: _formatCurrency(totalProjectBudget),
            trend: '${_projects.length} Total Projects',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.brandPeach,
          ),
        ],
      ),
      const SizedBox(height: ScreenLayout.sectionGap),

      // Project Report Search Field
      ScreenSearchField(
        controller: _projectSearchController,
        hintText: 'Search report by project name, client, PM, or site location...',
        onChanged: (q) => setState(() => _projectSearchQuery = q),
      ),
      const SizedBox(height: ScreenLayout.controlGap),

      // Project Status Filter Pills: All, Ongoing, Completed, Delayed
      Row(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: PillBox(
                label: 'All (${_projects.length})',
                padding: const EdgeInsets.symmetric(horizontal: 6),
                isSelected: _selectedProjectStatusFilter == 'All',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedProjectStatusFilter = 'All'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: PillBox(
                label: 'Ongoing ($ongoingCount)',
                icon: Icons.construction_rounded,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                isSelected: _selectedProjectStatusFilter == 'Ongoing',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedProjectStatusFilter = 'Ongoing'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: PillBox(
                label: 'Completed ($completedCount)',
                icon: Icons.verified_rounded,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                isSelected: _selectedProjectStatusFilter == 'Completed',
                activeColor: AppColors.success,
                onSelected: () =>
                    setState(() => _selectedProjectStatusFilter = 'Completed'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: PillBox(
                label: 'Delayed ($delayedCount)',
                icon: Icons.warning_amber_rounded,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                isSelected: _selectedProjectStatusFilter == 'Delayed',
                activeColor: AppColors.error,
                onSelected: () =>
                    setState(() => _selectedProjectStatusFilter = 'Delayed'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: ScreenLayout.listGap),

      // Detailed Project Report Cards Feed
      FilterSwitcher(
        child: filteredProjects.isEmpty
            ? EmptyStateCard(
                key: ValueKey(
                  'empty_projects_$_selectedProjectStatusFilter',
                ),
                icon: Icons.assignment_outlined,
                title: _projects.isEmpty
                    ? 'No Active Projects in System'
                    : 'No Matching Projects Found',
                message: _projects.isEmpty
                    ? 'No turnkey interior projects are recorded. When sales leads are closed won, projects appear here automatically.'
                    : 'Try clearing your search query or selecting a different status filter.',
                action: (_selectedProjectStatusFilter != 'All' ||
                        _projectSearchQuery.isNotEmpty)
                    ? OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedProjectStatusFilter = 'All';
                            _projectSearchQuery = '';
                            _projectSearchController.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Show All Projects'),
                      )
                    : null,
              )
            : ListView.separated(
                key: ValueKey(
                  'projects_report_$_selectedProjectStatusFilter',
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProjects.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: ScreenLayout.itemGap),
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  return _buildProjectReportCard(context, project, isDark);
                },
              ),
      ),
    ];
  }

  Widget _buildProjectReportCard(
    BuildContext context,
    Map<String, dynamic> project,
    bool isDark,
  ) {
    final status = _classifyProjectStatus(project);
    final statusColor = _getProjectStatusColor(status);
    final statusIcon = _getProjectStatusIcon(status);

    final projName = (project['name'] ?? 'Project') as String;
    final swatch = AppColors.getProjectSwatch(projName);
    final client =
        (project['client'] ?? project['clientName'] ?? 'Client') as String;
    final location = (project['location'] ?? 'Site Location') as String;
    final budget = (project['budget'] ?? '₹ 0') as String;
    final spent = (project['spent'] ?? '₹ 0') as String;
    final pm = (project['pm'] ?? 'Unassigned') as String;
    final supervisor = (project['supervisor'] ?? 'Unassigned') as String;
    final handover =
        (project['handover'] ?? project['endDate'] ?? 'TBD') as String;
    final originLeadId = project['originLeadId'] as String?;

    // Stage progress calculation
    final stages = (project['stages'] as List?) ?? [];
    int doneStages = 0;
    String currentActiveStage = 'Pending Initiation';

    for (final s in stages) {
      if (s is Map && s['isDone'] == true) {
        doneStages++;
      } else if (currentActiveStage == 'Pending Initiation' && s is Map) {
        currentActiveStage = s['title'] as String? ?? 'In Progress';
      }
    }
    if (doneStages == stages.length && stages.isNotEmpty) {
      currentActiveStage = 'All Execution Milestones Delivered';
    }

    final double progressPercent = stages.isNotEmpty
        ? (doneStages / stages.length)
        : (project['progress'] as double? ?? 0.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _showProjectReportExpandedBox(context, project, isDark),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: status == 'Delayed'
                  ? AppColors.error.withValues(alpha: 0.8)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: status == 'Delayed' ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Row: Swatch, Project Name, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 38,
                decoration: BoxDecoration(
                  color: swatch['color'] as Color? ?? AppColors.brandPeach,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projName,
                      style: AppTypography.titleMedium(isDark).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            client,
                            style: AppTypography.bodySmall(isDark).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location,
                            style: AppTypography.bodySmall(isDark).copyWith(
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill: Ongoing, Completed, Delayed
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: statusColor, width: 0.9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (originLeadId != null && originLeadId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brandPeach.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: AppColors.brandPeach.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 13,
                    color: AppColors.brandPeach,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Originated from Sales Pipeline Lead',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPeach,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Key Project Execution Metrics Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildProjectMetricCell(
                  label: 'Contract Budget',
                  value: budget,
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.brandPeach,
                  isDark: isDark,
                ),
                _buildProjectMetricCell(
                  label: 'Cumulative Spent',
                  value: spent,
                  icon: Icons.receipt_long_outlined,
                  color: Colors.grey,
                  isDark: isDark,
                ),
                _buildProjectMetricCell(
                  key: Key('sales_handover_calendar_${project['id'] ?? projName}'),
                  label: 'Handover Target',
                  value: handover,
                  icon: Icons.calendar_month_rounded,
                  color: status == 'Delayed'
                      ? AppColors.error
                      : AppColors.brandPeach,
                  isDark: isDark,
                  onTap: () => _pickHandoverDate(context, project),
                ),
                _buildProjectMetricCell(
                  label: 'Project Manager',
                  value: pm,
                  icon: Icons.engineering_outlined,
                  color: AppColors.textDarkPrimary,
                  isDark: isDark,
                ),
                _buildProjectMetricCell(
                  label: 'Site Supervisor',
                  value: supervisor,
                  icon: Icons.construction_outlined,
                  color: AppColors.textDarkPrimary,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Milestone Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Milestone Progress: $doneStages of ${stages.length} Completed',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Active Milestone: $currentActiveStage',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textLightSecondary
                      : AppColors.textDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Open Excel Timeline & View in Projects
          Builder(
            builder: (context) {
              return Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.table_chart_rounded,
                          size: 14,
                          color: AppColors.brandPeach,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Excel Timeline',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPeach,
                            ),
                          ),
                        ),
                        onPressed: () {
                          ProjectTimelineSheetDialog.show(
                            context,
                            project: project,
                            projectAccent: statusColor,
                            onSheetUpdated: (updated) async {
                              project['timelineSpreadsheet'] = updated.toMap();
                              final allProjects = StorageService.getProjects();
                              final pIdx = allProjects.indexWhere(
                                (p) =>
                                    p['id'] == project['id'] ||
                                    p['name'] == project['name'],
                              );
                              if (pIdx != -1) {
                                allProjects[pIdx]['timelineSpreadsheet'] =
                                    updated.toMap();
                                await StorageService.saveProjects(allProjects);
                                BackendManager.instance.updateProject(
                                  ProjectModel.fromMap(allProjects[pIdx]),
                                );
                              }
                              if (mounted) {
                                setState(() {
                                  _loadProjects();
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPeach,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.apartment_rounded, size: 14),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'View in Projects',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          MobileActionSheets.projectFilterNotifier.value = 'All';
                          MainDashboardScreen.navigateToTab(2);
                        },
                      ),
                    ),
                  ),
                ],
              );
        },
      ),
    ],
  ),
),
),
);
  }

  void _showProjectReportExpandedBox(
    BuildContext context,
    Map<String, dynamic> project,
    bool isDark,
  ) {
    final status = _classifyProjectStatus(project);
    final statusColor = _getProjectStatusColor(status);
    final projName = (project['name'] ?? 'Project') as String;
    final client =
        (project['client'] ?? project['clientName'] ?? 'Client') as String;
    final location = (project['location'] ?? 'Site Location') as String;
    final budget = (project['budget'] ?? '₹ 0') as String;
    final spent = (project['spent'] ?? '₹ 0') as String;
    final pm = (project['pm'] ?? 'Unassigned') as String;
    final supervisor = (project['supervisor'] ?? 'Unassigned') as String;
    final handover =
        (project['handover'] ?? project['endDate'] ?? 'TBD') as String;
    final stages = (project['stages'] as List?) ?? [];
    int doneStages = 0;
    String currentActiveStage = 'Pending Initiation';
    for (final s in stages) {
      if (s is Map && s['isDone'] == true) {
        doneStages++;
      } else if (currentActiveStage == 'Pending Initiation' && s is Map) {
        currentActiveStage = s['title'] as String? ?? 'In Progress';
      }
    }
    if (doneStages == stages.length && stages.isNotEmpty) {
      currentActiveStage = 'All Execution Milestones Delivered';
    }
    final double progressPercent = stages.isNotEmpty
        ? (doneStages / stages.length)
        : (project['progress'] as double? ?? 0.0);

    showExpandedDetailBox(
      context: context,
      title: projName,
      subtitle: '$client • $location',
      headerIcon: Icons.apartment_rounded,
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
                label: 'Project Budget',
                value: budget,
                color: AppColors.brandPeach,
                icon: Icons.account_balance_wallet_rounded,
              ),
              DetailMetric(
                label: 'Amount Spent',
                value: spent,
                icon: Icons.payments_outlined,
              ),
              DetailMetric(
                label: 'Completion',
                value: '${(progressPercent * 100).round()}%',
                color: statusColor,
                icon: Icons.pie_chart_rounded,
              ),
              DetailMetric(
                label: 'Target Handover',
                value: handover,
                icon: Icons.event_available_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Milestone Progress', isDark: isDark),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          DetailInfoRow(
            icon: Icons.construction_rounded,
            label: 'Active Stage',
            value: '$currentActiveStage ($doneStages/${stages.length})',
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.engineering_rounded,
            label: 'Project Lead',
            value: pm,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.supervisor_account_rounded,
            label: 'Site Supervisor',
            value: supervisor,
            isDark: isDark,
          ),
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        OutlinedButton.icon(
          icon: const Icon(Icons.table_chart_rounded, size: 14),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Excel Timeline', maxLines: 1),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            ProjectTimelineSheetDialog.show(
              context,
              project: project,
              projectAccent: statusColor,
              onSheetUpdated: (updated) async {
                project['timelineSpreadsheet'] = updated.toMap();
                final allProjects = StorageService.getProjects();
                final pIdx = allProjects.indexWhere(
                  (p) =>
                      p['id'] == project['id'] || p['name'] == project['name'],
                );
                if (pIdx != -1) {
                  allProjects[pIdx]['timelineSpreadsheet'] = updated.toMap();
                  await StorageService.saveProjects(allProjects);
                  BackendManager.instance.updateProject(
                    ProjectModel.fromMap(allProjects[pIdx]),
                  );
                }
                if (mounted) {
                  setState(() {
                    _loadProjects();
                  });
                }
              },
            );
          },
        ),
        OutlinedButton.icon(
          key: Key('sales_dialog_handover_calendar_${project['id'] ?? projName}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandPeach,
            side: BorderSide(
              color: AppColors.brandPeach.withValues(alpha: 0.7),
            ),
          ),
          icon: const Icon(Icons.calendar_month_rounded, size: 14),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Handover Date', maxLines: 1),
          ),
          onPressed: () async {
            final updated = await _pickHandoverDate(dialogCtx, project);
            if (updated != null && dialogCtx.mounted) {
              Navigator.of(dialogCtx).pop();
            }
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.apartment_rounded, size: 14),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('View in Projects', maxLines: 1),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            MobileActionSheets.projectFilterNotifier.value = 'All';
            MainDashboardScreen.navigateToTab(2);
          },
        ),
      ],
    );
  }

  Future<String?> _pickHandoverDate(
    BuildContext pickerContext,
    Map<String, dynamic> project,
  ) async {
    final raw = (project['handover'] ?? project['endDate'] ?? '').toString().trim();
    DateTime initialDate = DateTime.now().add(const Duration(days: 60));
    if (raw.isNotEmpty && raw.toUpperCase() != 'TBD') {
      try {
        initialDate = DateFormat('dd MMM yyyy').parseStrict(raw);
      } catch (_) {}
    }
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2035);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: pickerContext,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Target Handover Date',
    );
    if (picked == null) return null;

    final formatted = DateFormat('dd MMM yyyy').format(picked);
    final allProjects = StorageService.getProjects();
    final idx = allProjects.indexWhere(
      (p) =>
          (project['id'] != null && p['id'] == project['id']) ||
          p['name'] == project['name'],
    );
    if (idx != -1) {
      allProjects[idx]['handover'] = formatted;
      await StorageService.saveProjects(allProjects);
      final updated = Map<String, dynamic>.from(allProjects[idx]);
      MobileActionSheets.projectUpdatedNotifier.value = updated;
      BackendManager.instance.updateProject(ProjectModel.fromMap(updated));
    }

    if (mounted) {
      setState(() {
        project['handover'] = formatted;
        _loadProjects();
      });
      AppNotification.show(
        context,
        message: 'Handover target updated to $formatted',
        backgroundColor: AppColors.success,
      );
    }
    return formatted;
  }

  Widget _buildProjectMetricCell({
    Key? key,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textLightSecondary
                    : AppColors.textDarkSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: onTap != null
                        ? AppColors.brandPeach
                        : (isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 11,
                    color: AppColors.brandPeach.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }
}
