import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../auth/state/auth_provider.dart';
import '../widgets/staff_management_sheet.dart';
import '../../../core/services/phone_call_service.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  String _selectedRoleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMembers = auth.approvedUsers;
    final pendingList = auth.pendingUsers;

    final filteredMembers = _selectedRoleFilter == 'All'
        ? allMembers
        : allMembers
              .where((m) => m.role.title.contains(_selectedRoleFilter))
              .toList();

    return ScreenScrollView(
      children: [
        const ScreenHeader('Team & Workforce'),
        const SizedBox(height: ScreenLayout.headerGap),

        // Live Headcount Stats (Compact StatStrip)
        const StatStrip(
          cards: [
            StatCard(
              title: 'On Sites Today',
              value: '28 Field Staff',
              icon: Icons.engineering_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Design Studio',
              value: '7 Designers',
              icon: Icons.draw_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Sales & Pitches',
              value: '4 Reps',
              icon: Icons.campaign_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Management',
              value: '5 Leads',
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AppColors.brandPeach,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pending Approvals Banner (Proprietor Exclusive)
        if (auth.currentRole == UserRole.proprietor &&
            pendingList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'STAFF ACTION REQUIRED',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${allMembers.length} Active Staff',
                      style: AppTypography.bodySmall(
                        isDark,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${pendingList.length} Staff Registration${pendingList.length == 1 ? '' : 's'} Awaiting Authorization',
                  style: AppTypography.titleMedium(isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFFB37400),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                      ),
                      onPressed: () =>
                          showStaffManagementSheet(context, initialTabIndex: 0),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                      label: Text(
                        'Review & Authorize (${pendingList.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                      ),
                      onPressed: () =>
                          showStaffManagementSheet(context, initialTabIndex: 1),
                      icon: const Icon(Icons.people_outline_rounded, size: 14),
                      label: Text(
                        'View Active Roster (${allMembers.length})',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final u = pendingList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: u.role.color.withValues(
                                  alpha: 0.2,
                                ),
                                child: Icon(
                                  u.role.icon,
                                  color: u.role.color,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.fullName,
                                      style: AppTypography.titleMedium(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${u.email}  ·  ${u.role.title}',
                                      style: AppTypography.bodySmall(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () => auth.rejectUser(u.id),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () => auth.approveUser(u.id),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
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
          ),
          const SizedBox(height: 24),
        ],

        // Role Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  'All',
                  'Proprietor',
                  'Sales',
                  'Project Manager',
                  'Designer',
                  'Accounts',
                  'Supervisor',
                ].map((dept) {
                  final isSelected = _selectedRoleFilter == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PillBox(
                      label: dept,
                      isSelected: isSelected,
                      activeColor: AppColors.brandPeach,
                      onSelected: () =>
                          setState(() => _selectedRoleFilter = dept),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Directory label
        Text(
          'Staff Directory (${filteredMembers.length})',
          style: AppTypography.titleLarge(isDark),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Staff Directory — animated on filter change
        FilterSwitcher(
          child: filteredMembers.isEmpty
              ? EmptyStateCard(
                  key: ValueKey('empty_team_$_selectedRoleFilter'),
                  icon: Icons.badge_outlined,
                  title: 'No Team Members',
                  message:
                      'No personnel found with role "$_selectedRoleFilter".',
                  action: _selectedRoleFilter != 'All'
                      ? OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRoleFilter = 'All');
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Show All Staff'),
                        )
                      : null,
                )
              : ListView.separated(
                  key: ValueKey(_selectedRoleFilter),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMembers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: ScreenLayout.itemGap),
                  itemBuilder: (context, index) {
                    final m = filteredMembers[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.7)
                              : AppColors.lightBorder.withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: m.role.color.withValues(
                              alpha: 0.18,
                            ),
                            child: Icon(
                              m.role.icon,
                              color: m.role.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      m.fullName,
                                      style: AppTypography.titleMedium(isDark),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: m.role.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                      ),
                                      child: Text(
                                        m.role.title,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: m.role.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${m.email}  ·  ${m.phone}',
                                  style: AppTypography.bodySmall(isDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, size: 20),
                            tooltip: 'Dial ${m.fullName}',
                            onPressed: () => PhoneCallService.dialNumber(
                              context,
                              phoneNumber: m.phone,
                              contactName: m.fullName,
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
