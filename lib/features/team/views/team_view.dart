import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../auth/models/user_model.dart';
import '../../auth/state/auth_provider.dart';
import '../widgets/reset_password_dialog.dart';
import '../widgets/role_permission_config_dialog.dart';
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
        : _selectedRoleFilter == 'Custom'
        ? allMembers.where((m) => m.hasCustomAccess).toList()
        : allMembers
              .where(
                (m) =>
                    m.role.title.contains(_selectedRoleFilter) ||
                    m.effectiveRoleTitle.contains(_selectedRoleFilter),
              )
              .toList();

    final supervisorsCount = allMembers
        .where(
          (m) =>
              m.role == UserRole.supervisor || m.role == UserRole.siteEngineer,
        )
        .length;
    final designersCount =
        allMembers.where((m) => m.role == UserRole.designer).length;
    final salesCount =
        allMembers.where((m) => m.role == UserRole.sales).length;
    final leadsCount = allMembers
        .where(
          (m) =>
              m.role == UserRole.proprietor ||
              m.role == UserRole.projectManager ||
              m.role == UserRole.accounts,
        )
        .length;

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Team & Staff Directory',
          subtitle:
              'Manage approved staff, reset passwords & check new access requests',
        ),
        const SizedBox(height: ScreenLayout.headerGap),

        // Live Headcount Stats (Computed dynamically from team roster)
        StatStrip(
          cards: [
            StatCard(
              title: 'Field Staff',
              value: '$supervisorsCount Staff',
              icon: Icons.engineering_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Design Studio',
              value: '$designersCount Designers',
              icon: Icons.draw_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Sales',
              value: '$salesCount Reps',
              icon: Icons.campaign_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Management',
              value: '$leadsCount Leads',
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AppColors.brandPeach,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pending Approvals Banner (Master Proprietor Exclusive)
        if (auth.canManageTeam && pendingList.isNotEmpty) ...[
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final u = pendingList[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(4.0),
                      onTap: () =>
                          showStaffManagementSheet(context, initialTabIndex: 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightBackground)
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
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
                                    '${u.email}  ·  ${u.effectiveRoleTitle}',
                                    style: AppTypography.bodySmall(isDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 0.7,
                                ),
                              ),
                              child: const Text(
                                'Pending Review',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: AppSizes.compactElevatedStyle(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () =>
                            showStaffManagementSheet(context, initialTabIndex: 0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.how_to_reg_rounded, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'Review & Authorize (${pendingList.length})',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.compactButtonFontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          borderColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        onPressed: () =>
                            showStaffManagementSheet(context, initialTabIndex: 1),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'View Active Roster (${allMembers.length})',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Role Filter Pills — stretched across full section width with zero dead space
        LayoutBuilder(
          builder: (context, constraints) {
            const filters = [
              'All',
              'Proprietor',
              'Sales',
              'Project Manager',
              'Designer',
              'Accounts',
              'Supervisor',
            ];

            Widget buildPill(String dept) {
              final isSelected = _selectedRoleFilter == dept;
              return Expanded(
                child: PillBox(
                  label: dept,
                  isSelected: isSelected,
                  activeColor: AppColors.brandPeach,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onSelected: () => setState(() => _selectedRoleFilter = dept),
                ),
              );
            }

            if (constraints.maxWidth >= 720) {
              return Row(
                children: [
                  for (int i = 0; i < filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    buildPill(filters[i]),
                  ],
                ],
              );
            }

            const firstRow = ['All', 'Proprietor', 'Sales', 'Project Manager'];
            const secondRow = ['Designer', 'Accounts', 'Supervisor'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (int i = 0; i < firstRow.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      buildPill(firstRow[i]),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < secondRow.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      buildPill(secondRow[i]),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Directory Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Staff Directory (${filteredMembers.length})',
                style: AppTypography.titleLarge(isDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (auth.canManageTeam)
              OutlinedButton(
                style: AppSizes.compactOutlinedStyle(
                  foregroundColor: AppColors.brandPeach,
                  borderColor: AppColors.brandPeach,
                ),
                onPressed: () =>
                    showStaffManagementSheet(context, initialTabIndex: 1),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Manage Roles & Access',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: AppSizes.compactButtonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6.0),
                        onTap: () =>
                            _showMemberExpandedBox(context, m, auth, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                                radius: 20,
                                backgroundColor: m.role.color.withValues(
                                  alpha: 0.18,
                                ),
                                child: Icon(
                                  m.role.icon,
                                  color: m.role.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.fullName,
                                      style: AppTypography.titleMedium(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${m.email}  ·  ${m.phone}',
                                      style: AppTypography.bodySmall(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                flex: 0,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 150,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.role.color.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(
                                        color: m.role.color.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      m.effectiveRoleTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: m.role.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    backgroundColor: (isDark
                                            ? AppColors.darkCardElevated
                                            : AppColors.lightBackground)
                                        .withValues(alpha: 0.9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: BorderSide(
                                        color: (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder)
                                            .withValues(alpha: 0.8),
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 17,
                                  ),
                                  tooltip: 'Dial ${m.fullName}',
                                  onPressed: () => PhoneCallService.dialNumber(
                                    context,
                                    phoneNumber: m.phone,
                                    contactName: m.fullName,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showMemberExpandedBox(
    BuildContext context,
    AppUser m,
    AuthProvider auth,
    bool isDark,
  ) {
    final canEditMember =
        auth.canManageTeam &&
        !(m.role == UserRole.proprietor && !m.hasCustomAccess);

    showExpandedDetailBox(
      context: context,
      title: m.fullName,
      subtitle: m.effectiveRoleTitle,
      headerIcon: m.role.icon,
      accentColor: m.role.color,
      badgeLabel: m.effectiveRoleShortCode,
      badgeColor: m.role.color,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Department Role',
                value: m.effectiveRoleTitle,
                color: m.role.color,
                icon: m.role.icon,
              ),
              const DetailMetric(
                label: 'Directory Status',
                value: 'Active Authorized',
                color: AppColors.success,
                icon: Icons.verified_user_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Contact & Access Details', isDark: isDark),
          DetailInfoRow(
            icon: Icons.email_outlined,
            label: 'Work Email',
            value: m.email,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: m.phone,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.badge_outlined,
            label: 'Role Code',
            value: m.effectiveRoleShortCode,
            isDark: isDark,
          ),
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        OutlinedButton.icon(
          icon: const Icon(Icons.close_rounded, size: 15),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Close', maxLines: 1),
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(),
        ),
        if (canEditMember) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPeach,
              side: const BorderSide(color: AppColors.brandPeach),
            ),
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.tr('Edit Role & Access'), maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              RolePermissionConfigDialog.showForApplicantOrStaff(
                context,
                targetUser: m,
                isPendingApproval: false,
              );
            },
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: BorderSide(color: AppColors.warning.withValues(alpha: 0.7)),
            ),
            icon: const Icon(Icons.lock_reset_rounded, size: 15),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.tr('Reset Password'), maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ResetStaffPasswordDialog.show(context, targetUser: m);
            },
          ),
        ],
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.phone_rounded, size: 15),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Dial Staff', maxLines: 1),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            PhoneCallService.dialNumber(
              context,
              phoneNumber: m.phone,
              contactName: m.fullName,
            );
          },
        ),
      ],
    );
  }
}
