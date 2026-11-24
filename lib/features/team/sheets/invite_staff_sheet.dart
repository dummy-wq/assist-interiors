import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../auth/state/auth_provider.dart';

class InviteStaffSheet extends StatefulWidget {
  const InviteStaffSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (_) => const InviteStaffSheet(),
    );
  }

  @override
  State<InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends State<InviteStaffSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91 ');
  String _selectedRoleKey = UserRole.designer.name;

  static const List<UserRole> _selectableRoles = [
    UserRole.sales,
    UserRole.projectManager,
    UserRole.designer,
    UserRole.accounts,
    UserRole.supervisor,
    UserRole.siteEngineer,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleInvite(AuthProvider auth) {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty || !email.contains('@')) {
      AppNotification.show(
        context,
        message: 'Please enter a valid staff name and staff email address.',
      );
      return;
    }

    UserRole resolvedRole = UserRole.designer;
    String? customRoleId;
    String? customRoleName;

    if (_selectedRoleKey.startsWith('CUSTOM:')) {
      customRoleId = _selectedRoleKey.substring('CUSTOM:'.length);
      final customMatch = auth.customRoles
          .where((r) => r.id == customRoleId)
          .toList();
      if (customMatch.isNotEmpty) {
        customRoleName = customMatch.first.name;
      }
      resolvedRole = UserRole.supervisor;
    } else {
      resolvedRole = _selectableRoles.firstWhere(
        (r) => r.name == _selectedRoleKey,
        orElse: () => UserRole.designer,
      );
    }

    final created = auth.inviteStaffMember(
      fullName: fullName,
      email: email,
      phone: phone == '+91' ? '' : phone,
      role: resolvedRole,
      customRoleId: customRoleId,
      customRoleName: customRoleName,
    );

    if (created == null) {
      AppNotification.show(
        context,
        message: auth.lastAuthError ?? 'Could not add staff member.',
      );
      return;
    }

    Navigator.pop(context);
    AppNotification.show(
      context,
      message:
          '${created.fullName} (${created.effectiveRoleTitle}) added to Team & Workforce.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final customRoles = auth.customRoles;

    final dropdownItems = <DropdownMenuItem<String>>[
      for (final role in _selectableRoles)
        DropdownMenuItem<String>(
          value: role.name,
          child: Text(role.title),
        ),
      for (final custom in customRoles)
        DropdownMenuItem<String>(
          value: 'CUSTOM:${custom.id}',
          child: Text('${custom.name} (Custom)'),
        ),
    ];

    final validKeys = dropdownItems.map((e) => e.value).toSet();
    final currentKey = validKeys.contains(_selectedRoleKey)
        ? _selectedRoleKey
        : UserRole.designer.name;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: AppSizes.sheetBottomPadding(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPeach.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.brandPeach,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Invite Staff Member',
                          style: AppTypography.titleLarge(isDark),
                          overflow: TextOverflow.ellipsis,
                        ),
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
            const SizedBox(height: 6),
            Text(
              'Add an authorized team member directly to your workforce directory.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g., Rohan Deshmukh',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Staff Email',
                hintText: 'rohan@assistinteriors.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91 98201 00000',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            QuickFadeDropdown<String>(
              value: currentKey,
              isExpanded: true,
              dropdownColor: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCard,
              decoration: const InputDecoration(
                labelText: 'Department Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: dropdownItems,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRoleKey = val);
                }
              },
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _handleInvite(auth),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Send Authorization Invite',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
