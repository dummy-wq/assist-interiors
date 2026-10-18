import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/phone_call_service.dart';

import 'package:provider/provider.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final List<Map<String, dynamic>> _leads = [];
  String _selectedStageFilter = 'All';
  String _selectedReferralFilter = 'All Sources';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLeads();
    MobileActionSheets.leadCreatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.addListener(_onLeadChanged);
  }

  @override
  void dispose() {
    MobileActionSheets.leadCreatedNotifier.removeListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.removeListener(_onLeadChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadLeads() {
    _leads.clear();
    _leads.addAll(StorageService.getLeads());
  }

  void _onLeadChanged() {
    if (mounted) {
      setState(() {
        _loadLeads();
      });
    }
  }

  bool _isDueToday(Map<String, dynamic> lead) {
    final nextCallDate = lead['nextCallDate'] as String? ?? '';
    if (nextCallDate.isEmpty) return false;
    final now = DateTime.now();
    final todayStr1 = DateFormat('dd MMM yyyy').format(now);
    final todayStr2 = DateFormat('yyyy-MM-dd').format(now);
    final todayStr3 = DateFormat('d MMM yyyy').format(now);
    return nextCallDate == todayStr1 ||
        nextCallDate == todayStr2 ||
        nextCallDate == todayStr3;
  }

  bool _isOverdue(Map<String, dynamic> lead) {
    final nextCallDate = lead['nextCallDate'] as String? ?? '';
    if (nextCallDate.isEmpty) return false;
    if (_isDueToday(lead)) return false;
    try {
      DateTime? parsed;
      if (nextCallDate.contains('-')) {
        parsed = DateTime.tryParse(nextCallDate);
      } else {
        parsed = DateFormat('dd MMM yyyy').parse(nextCallDate);
      }
      if (parsed != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        return parsed.isBefore(todayStart);
      }
    } catch (_) {}
    return false;
  }

  Color _getStageColor(String stage) {
    if (stage.contains('Visit') || stage.contains('Recce')) {
      return AppColors.brandOrange;
    }
    if (stage.contains('Proposal') ||
        stage.contains('Pitch') ||
        stage.contains('BOQ')) {
      return AppColors.info;
    }
    if (stage.contains('Negotiation')) {
      return AppColors.warning;
    }
    if (stage.contains('Won') || stage.contains('Advance')) {
      return AppColors.success;
    }
    if (stage.contains('Lost') || stage.contains('Dropped')) {
      return AppColors.error;
    }
    return AppColors.brandPeach;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageSales = AppPermissions.canManageSales(auth.currentRole);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalPipeline = 0;
    int dueRemindersCount = 0;
    int wonCount = 0;

    for (final l in _leads) {
      final raw = (l['estValue'] as String? ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final val = int.tryParse(raw) ?? 0;
      totalPipeline += val;

      if (_isDueToday(l) || _isOverdue(l)) {
        dueRemindersCount++;
      }

      final stg = (l['stage'] ?? l['status'] ?? '') as String;
      if (stg.contains('Won') ||
          stg.contains('Advance') ||
          stg.contains('Converted')) {
        wonCount++;
      }
    }

    final pipelineStr = totalPipeline > 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(totalPipeline)
        : '₹ 0';

    final conversionRateStr = _leads.isEmpty
        ? '0.0%'
        : '${((wonCount / _leads.length) * 100).toStringAsFixed(1)}%';

    // Filter leads
    final filteredLeads = _leads.where((lead) {
      final client = (lead['client'] ?? lead['name'] ?? '')
          .toString()
          .toLowerCase();
      final scope = (lead['scope'] ?? '').toString().toLowerCase();
      final location = (lead['location'] ?? '').toString().toLowerCase();
      final stage = (lead['stage'] ?? lead['status'] ?? '').toString();
      final refSource = (lead['referralSource'] ?? '').toString();

      final matchesSearch =
          _searchQuery.isEmpty ||
          client.contains(_searchQuery.toLowerCase()) ||
          scope.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Stage Filter
      if (_selectedStageFilter == 'Due Reminders') {
        if (!_isDueToday(lead) && !_isOverdue(lead)) return false;
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

    return ScreenScrollView(
      children: [
        const ScreenHeader('Client Acquisition & Sales Pipeline'),
        const SizedBox(height: ScreenLayout.headerGap),

        // KPI Stat Cards (Compact StatStrip)
        StatStrip(
          cards: [
            StatCard(
              title: 'Pipeline Value',
              value: pipelineStr,
              icon: Icons.filter_alt_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Inquiries',
              value: '${_leads.length} Leads',
              icon: Icons.mark_email_unread_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Due Reminders',
              value: '$dueRemindersCount Calls',
              trend: dueRemindersCount > 0 ? 'Urgent' : 'All Clear',
              icon: Icons.phone_callback_rounded,
              accentColor: dueRemindersCount > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
            StatCard(
              title: 'Conversion',
              value: conversionRateStr,
              trend: conversionRateStr != '0.0%' ? conversionRateStr : null,
              icon: Icons.auto_graph_rounded,
              accentColor: AppColors.success,
            ),
          ],
        ),

        // Follow-ups Due Today Alert Strip
        if (dueRemindersCount > 0) ...[
          const SizedBox(height: ScreenLayout.noticeGap),
          _buildDueRemindersBanner(dueRemindersCount),
        ],
        const SizedBox(height: ScreenLayout.sectionGap),

        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search leads by client, scope, or site location...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Stage Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PillBox(
                label: 'All (${_leads.length})',
                isSelected: _selectedStageFilter == 'All',
                activeColor: AppColors.brandPeach,
                onSelected: () => setState(() => _selectedStageFilter = 'All'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Due Calls ($dueRemindersCount)',
                icon: Icons.notifications_active_outlined,
                isSelected: _selectedStageFilter == 'Due Reminders',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedStageFilter = 'Due Reminders'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'New Inquiry',
                isSelected: _selectedStageFilter == 'New Inquiry',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedStageFilter = 'New Inquiry'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Site Visit',
                isSelected: _selectedStageFilter == 'Site Visit Scheduled',
                activeColor: AppColors.brandPeach,
                onSelected: () => setState(
                  () => _selectedStageFilter = 'Site Visit Scheduled',
                ),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Design Pitch',
                isSelected: _selectedStageFilter == 'Design Pitch & BOQ',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedStageFilter = 'Design Pitch & BOQ'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Negotiation',
                isSelected: _selectedStageFilter == 'Negotiation',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedStageFilter = 'Negotiation'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Closed Won',
                isSelected: _selectedStageFilter == 'Closed Won',
                activeColor: AppColors.brandPeach,
                onSelected: () =>
                    setState(() => _selectedStageFilter = 'Closed Won'),
              ),
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Referral Source Breakdown Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final source in const [
                'All Sources',
                'Client Referral',
                'Architect Partner',
                'Real Estate Consultant',
                'Instagram / Social Media',
                'Direct Walk-in',
              ]) ...[
                if (source != 'All Sources') const SizedBox(width: 8),
                _buildReferralFilterChip(source),
              ],
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Leads Feed — animated on filter change
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
                            ? 'All sales leads and inquiries have been cleared. Tap "Add Lead" to record a prospective client.'
                            : 'All sales leads and inquiries have been cleared.')
                      : 'Try adjusting your search, stage, or referral channel filter to view active leads.',
                  action: (_selectedStageFilter != 'All' ||
                          _selectedReferralFilter != 'All' ||
                          _searchQuery.isNotEmpty)
                      ? OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedStageFilter = 'All';
                              _selectedReferralFilter = 'All';
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Show All Leads'),
                        )
                      : null,
                )
              : ListView.separated(
                  key: ValueKey(
                    'leads_${_selectedStageFilter}_$_selectedReferralFilter',
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLeads.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: ScreenLayout.itemGap),
                  itemBuilder: (context, index) {
                    final lead = filteredLeads[index];
                    return _buildLeadPipelineCard(context, lead, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDueRemindersBanner(int dueRemindersCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withValues(alpha: 0.12),
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alarm_on_rounded,
            color: AppColors.brandOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SALES REMINDER: $dueRemindersCount client callback${dueRemindersCount > 1 ? 's' : ''} scheduled for today or overdue.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.brandOrange,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedStageFilter = _selectedStageFilter == 'Due Reminders'
                    ? 'All'
                    : 'Due Reminders';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandOrange,
                borderRadius: AppSizes.borderRadiusSm,
              ),
              child: Text(
                _selectedStageFilter == 'Due Reminders'
                    ? 'Show All'
                    : 'View Due Calls',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralFilterChip(String source) {
    final isSelected = _selectedReferralFilter == source;
    return PillBox(
      label: source,
      isSelected: isSelected,
      activeColor: AppColors.brandPeach,
      onSelected: () => setState(() => _selectedReferralFilter = source),
    );
  }

  Widget _buildLeadPipelineCard(
    BuildContext context,
    Map<String, dynamic> lead,
    bool isDark,
  ) {
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final phone = (lead['phone'] ?? '+91 98000 00000') as String;
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

    final isDue = _isDueToday(lead);
    final isOver = _isOverdue(lead);
    final stageColor = _getStageColor(stage);

    final auth = Provider.of<AuthProvider>(context);
    final canCreateProject = AppPermissions.canCreateProject(auth.currentRole);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDue || isOver
              ? AppColors.brandOrange.withValues(alpha: 0.8)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isDue || isOver ? 1.2 : 0.8,
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
          const SizedBox(height: 10),

          // Row 2: 3-Step Vertical Pipeline Strip (Referral -> Status -> Next Call Date with Reminder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Step 1: Referral Origin
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.brandPeach.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.share_location_rounded,
                            size: 13,
                            color: AppColors.brandPeach,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            referralBy.isNotEmpty
                                ? 'Ref: $referralSource ($referralBy)'
                                : 'Ref: $referralSource',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPeach,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),

                    // Step 2: Current Status (Interactive)
                    InkWell(
                      onTap: () => MobileActionSheets.showUpdateLeadStatusSheet(
                        context,
                        lead,
                        onUpdated: _loadLeads,
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: stageColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: stageColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timeline_rounded,
                              size: 13,
                              color: stageColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              stage,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: stageColor,
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

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),

                    // Step 3: Next Call Date with Reminder (Interactive)
                    InkWell(
                      onTap: () => MobileActionSheets.showScheduleCallSheet(
                        context,
                        lead,
                        onUpdated: _loadLeads,
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDue || isOver
                                      ? AppColors.brandOrange
                                      : AppColors.brandPeach)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: isDue || isOver
                                ? AppColors.brandOrange
                                : AppColors.brandPeach,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOver
                                  ? Icons.warning_amber_rounded
                                  : Icons.alarm_on_rounded,
                              size: 13,
                              color: isDue || isOver
                                  ? AppColors.brandOrange
                                  : AppColors.brandPeach,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              nextCallDate.isNotEmpty
                                  ? (isOver
                                        ? 'Overdue: $nextCallDate, $nextCallTime'
                                        : (isDue
                                              ? 'Due Today: $nextCallTime'
                                              : 'Next Call: $nextCallDate, $nextCallTime'))
                                  : '+ Set Call Reminder',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDue || isOver
                                    ? AppColors.brandOrange
                                    : AppColors.brandPeach,
                              ),
                            ),
                          ],
                        ),
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
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textLightSecondary
                                : AppColors.textDarkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Action Buttons (Call, Update Status, Schedule Call, Launch Project)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.phone_rounded, size: 14),
                label: Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                onPressed: () => PhoneCallService.dialNumber(
                  context,
                  phoneNumber: phone,
                  contactName: clientName,
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                label: const Text(
                  'Schedule Call',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () => MobileActionSheets.showScheduleCallSheet(
                  context,
                  lead,
                  onUpdated: _loadLeads,
                ),
              ),
              const SizedBox(width: 6),
              if (canCreateProject)
                InkWell(
                  onTap: () {
                    MobileActionSheets.showInitiateProjectSheet(
                      context,
                      initialName: '$clientName Residence',
                      initialClient: clientName,
                      initialBudget: estValue.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPeach.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: AppColors.brandPeach,
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          size: 12,
                          color: AppColors.brandPeach,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Launch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPeach,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending Handover',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
