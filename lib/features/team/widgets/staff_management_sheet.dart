import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../auth/state/auth_provider.dart';

void showStaffManagementSheet(BuildContext context, {int initialTabIndex = 0}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        StaffManagementSheet(initialTabIndex: initialTabIndex),
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

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            onPressed: () {
              auth.dismissStaff(user.id);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Staff access revoked for ${user.fullName}.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.2,
            ),
          ),
          child: SafeArea(
            top: false,
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.brandPeach,
                          borderRadius: BorderRadius.all(Radius.circular(6.0)),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Executive Staff Access & Governance',
                              style: AppTypography.titleLarge(isDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Proprietor Command • View All Staff, Authorize Sign-Ups & Dismiss Personnel',
                              style: AppTypography.bodySmall(isDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

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
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _activeTab == 0
                                      ? AppColors.brandPeach
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.how_to_reg_rounded,
                                    size: 16,
                                    color: _activeTab == 0
                                        ? AppColors.brandPeach
                                        : (isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pending Requests (${pendingList.length})',
                                    style: TextStyle(
                                      fontWeight: _activeTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _activeTab == 0
                                          ? AppColors.brandPeach
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _activeTab == 1
                                      ? AppColors.brandPeach
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 16,
                                    color: _activeTab == 1
                                        ? AppColors.brandPeach
                                        : (isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active Directory (${approvedList.length})',
                                    style: TextStyle(
                                      fontWeight: _activeTab == 1
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: _activeTab == 1
                                          ? AppColors.brandPeach
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab View Content
                Expanded(
                  child: _activeTab == 0
                      ? _buildPendingTab(context, isDark, auth, pendingList)
                      : _buildApprovedTab(context, isDark, auth, approvedList),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: u.role.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'Requested: ${u.role.title}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: u.role.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      auth.rejectUser(u.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Registration for ${u.fullName} dismissed.',
                          ),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Dismiss Request'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      auth.approveUser(u.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${u.fullName} approved as ${u.role.title}!',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve Access'),
                  ),
                ],
              ),
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
        final isProprietorOwner = u.role == UserRole.proprietor;

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
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: u.role.color.withValues(alpha: 0.18),
                child: Icon(u.role.icon, color: u.role.color, size: 20),
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
                            color: u.role.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            u.role.title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: u.role.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${u.email}  ·  ${u.phone}',
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
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
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => _confirmDismissStaff(context, auth, u),
                  icon: const Icon(Icons.person_remove_outlined, size: 16),
                  label: const Text(
                    'Dismiss Staff',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
