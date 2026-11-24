import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/studio_dialog.dart';
import '../../auth/models/custom_role_model.dart';
import '../../auth/models/user_model.dart';
import '../../auth/state/auth_provider.dart';
import 'reset_password_dialog.dart';
import 'role_permission_config_dialog.dart';

void showStaffManagementSheet(BuildContext context, {int initialTabIndex = 0}) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (!auth.canManageTeam) {
    AppNotification.show(
      context,
      message:
          'Security restriction: Only the Proprietor can manage team access and roles.',
    );
    return;
  }
  auth.markPendingRequestsSeen();
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 170),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, _, _) =>
          StaffManagementSheet(initialTabIndex: initialTabIndex),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        );
      },
    ),
  );
}

class StaffManagementSheet extends StatefulWidget {
  final int initialTabIndex;

  const StaffManagementSheet({super.key, this.initialTabIndex = 0});

  @override
  State<StaffManagementSheet> createState() => _StaffManagementSheetState();
}

class _StaffManagementSheetState extends State<StaffManagementSheet> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
  }

  void _confirmDismissStaff(
    BuildContext context,
    AuthProvider auth,
    AppUser user,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showStudioDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusMd,
        ),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Revoke Staff Access?',
                style: AppTypography.titleLarge(isDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to dismiss ${user.fullName} (${user.role.title})?',
              style: AppTypography.titleMedium(isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Their system access will be immediately terminated. They will be logged out and prohibited from accessing all project sites, BOQs, client invoices, and muster rolls.',
              style: AppTypography.bodySmall(isDark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              auth.dismissStaff(user.id);
              Navigator.pop(dialogCtx);
              AppNotification.show(
                context,
                message: 'Staff access revoked for ${user.fullName}.',
                backgroundColor: AppColors.error,
              );
            },
            child: const Text('Confirm Dismissal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingList = auth.pendingUsers;
    final approvedList = auth.approvedUsers;
    final customRoles = auth.customRoles;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.brandPeach,
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Executive Staff Access & Governance',
                    style: AppTypography.titleLarge(isDark).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Proprietor Command • View All Staff, Authorize Sign-Ups & Dismiss Personnel',
                    style: AppTypography.bodySmall(isDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                // Segmented Tabs
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildSheetTabItem(
                        tabIndex: 0,
                        icon: Icons.how_to_reg_rounded,
                        label: 'Pending Requests (${pendingList.length})',
                        isDark: isDark,
                      ),
                      _buildSheetTabItem(
                        tabIndex: 1,
                        icon: Icons.people_outline_rounded,
                        label: 'Active Directory (${approvedList.length})',
                        isDark: isDark,
                      ),
                      _buildSheetTabItem(
                        tabIndex: 2,
                        icon: Icons.tune_rounded,
                        label: 'Custom Roles (${customRoles.length})',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Tab View Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey('staff_sheet_tab_$_activeTab'),
                      child: _activeTab == 0
                          ? _buildPendingTab(context, isDark, auth, pendingList)
                          : (_activeTab == 1
                                ? _buildApprovedTab(
                                    context,
                                    isDark,
                                    auth,
                                    approvedList,
                                  )
                                : _buildCustomRolesTab(
                                    context,
                                    isDark,
                                    auth,
                                    customRoles,
                                  )),
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

  Widget _buildPendingTab(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    List<AppUser> pendingList,
  ) {
    if (pendingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: AppColors.brandPeach.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Text(
                'No Pending Staff Requests',
                style: AppTypography.titleMedium(isDark),
              ),
              const SizedBox(height: 6),
              Text(
                'All employee registration requests have been authorized or dismissed.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(isDark),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: pendingList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final u = pendingList[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: u.role.color.withValues(alpha: 0.2),
                    child: Icon(u.role.icon, color: u.role.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.fullName,
                          style: AppTypography.titleMedium(isDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${u.email} • ${u.phone}',
                          style: AppTypography.bodySmall(isDark),
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
                        color: u.role.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        'Requested: ${u.effectiveRoleTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: u.role.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PendingApprovalActionRow(user: u, auth: auth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovedTab(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    List<AppUser> approvedList,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: approvedList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = approvedList[index];
        final isProprietorOwner =
            u.role == UserRole.proprietor && !u.hasCustomAccess;
        final roleColor = u.hasCustomAccess
            ? AppColors.brandPeach
            : u.role.color;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: roleColor.withValues(alpha: 0.18),
                    child: Icon(
                      u.hasCustomAccess ? Icons.tune_rounded : u.role.icon,
                      color: roleColor,
                      size: 20,
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
                              u.fullName,
                              style: AppTypography.titleMedium(isDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                u.effectiveRoleTitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${u.email}  ·  ${AppPermissions.getRoleAccessSummary(u.role, user: u)}',
                          style: AppTypography.bodySmall(isDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isProprietorOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.brandPeach.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: AppColors.brandPeach,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Master Owner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPeach,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (!isProprietorOwner) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: AppColors.brandPeach,
                          borderColor: AppColors.brandPeach,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () {
                          RolePermissionConfigDialog.showForApplicantOrStaff(
                            context,
                            targetUser: u,
                            isPendingApproval: false,
                          );
                        },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Edit Role & Access',
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: AppColors.warning,
                          borderColor: AppColors.warning.withValues(alpha: 0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () =>
                            ResetStaffPasswordDialog.show(context, targetUser: u),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_reset_rounded, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Reset Password',
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: AppColors.error,
                          borderColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => _confirmDismissStaff(context, auth, u),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_remove_outlined, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Dismiss Staff',
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
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetTabItem({
    required int tabIndex,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _activeTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.brandPeach : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? AppColors.brandPeach
                        : (isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppColors.brandPeach
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRolesTab(
    BuildContext context,
    bool isDark,
    AuthProvider auth,
    List<CustomRoleDefinition> customRoles,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            key: const Key('create_custom_role_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPeach,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              RolePermissionConfigDialog.showForCustomRoleDefinition(context);
            },
            icon: const Icon(Icons.add_moderator_rounded, size: 18),
            label: const Text(
              'Create New Custom Role',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: customRoles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 46,
                          color: AppColors.brandPeach.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Custom Roles Created Yet',
                          style: AppTypography.titleMedium(isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create tailored roles (e.g. Junior Architect or Site Coordinator) and check off their exact permissions.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(isDark),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: customRoles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final role = customRoles[idx];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPeach.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    role.shortCode,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandPeach,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    role.name,
                                    style: AppTypography.titleMedium(isDark),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Role Permissions',
                                  onPressed: () {
                                    RolePermissionConfigDialog
                                        .showForCustomRoleDefinition(
                                      context,
                                      existingRole: role,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Delete Role',
                                  onPressed: () =>
                                      auth.deleteCustomRole(role.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (role.permissions.isEmpty)
                              Text(
                                'Read-only access (0 action permissions enabled)',
                                style: AppTypography.bodySmall(isDark),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: role.permissions.map((perm) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? AppColors.darkCardElevated
                                              : AppColors.lightBackground),
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(
                                        color: (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder)
                                            .withValues(alpha: 0.7),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      perm.label,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Standardized full-width equal-proportion action bar for onboarding / pending
/// account requests (`Dismiss Request` · `Assign / Custom Role` · `Approve Access`).
/// Used identically across both [StaffManagementSheet] and [TeamView].
class PendingApprovalActionRow extends StatelessWidget {
  final AppUser user;
  final AuthProvider auth;
  final String dismissLabel;
  final String assignLabel;
  final String approveLabel;

  const PendingApprovalActionRow({
    super.key,
    required this.user,
    required this.auth,
    this.dismissLabel = 'Dismiss Request',
    this.assignLabel = 'Assign / Custom Role',
    this.approveLabel = 'Approve Access',
  });

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: 6);
    const labelStyle = TextStyle(
      fontSize: AppSizes.compactButtonFontSize,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: AppSizes.compactOutlinedStyle(
              foregroundColor: AppColors.error,
              borderColor: AppColors.error,
              padding: pad,
            ),
            onPressed: () {
              auth.rejectUser(user.id);
              AppNotification.show(
                context,
                message: 'Registration for ${user.fullName} dismissed.',
                backgroundColor: AppColors.error,
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(dismissLabel, maxLines: 1, style: labelStyle),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            style: AppSizes.compactOutlinedStyle(
              foregroundColor: AppColors.brandPeach,
              borderColor: AppColors.brandPeach,
              padding: pad,
            ),
            onPressed: () {
              RolePermissionConfigDialog.showForApplicantOrStaff(
                context,
                targetUser: user,
                isPendingApproval: true,
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(assignLabel, maxLines: 1, style: labelStyle),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: AppSizes.compactElevatedStyle(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: pad,
            ),
            onPressed: () {
              auth.approveUser(user.id);
              AppNotification.show(
                context,
                message:
                    '${user.fullName} approved as ${user.effectiveRoleTitle}!',
                backgroundColor: AppColors.success,
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(approveLabel, maxLines: 1, style: labelStyle),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
