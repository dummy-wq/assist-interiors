import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../auth/models/custom_role_model.dart';
import '../../auth/models/user_model.dart';
import '../../auth/state/auth_provider.dart';

import '../../../core/utils/app_notification.dart';
/// Security-hardened Role & Permission configuration screen for the Proprietor.
/// Used to:
/// 1) Authorize a pending team applicant with a pre-existing OR custom checked-off role.
/// 2) Modify an existing team member's role or individual permissions.
/// 3) Create or edit reusable [CustomRoleDefinition] templates.
class RolePermissionConfigDialog {
  RolePermissionConfigDialog._();

  static Future<void> showForApplicantOrStaff(
    BuildContext context, {
    required AppUser targetUser,
    required bool isPendingApproval,
    VoidCallback? onSaved,
  }) {
    final auth = context.read<AuthProvider>();
    if (!auth.canManageTeam) return Future.value();

    final bool useCustomMode = targetUser.hasCustomAccess;
    final UserRole selectedBuiltIn = targetUser.role == UserRole.proprietor
        ? UserRole.supervisor
        : targetUser.role;
    final String? selectedSavedCustomRoleId = targetUser.customRoleId;
    final selectedPermissions = Set<AppPermissionKey>.from(
      targetUser.customPermissions ??
          (targetUser.hasCustomAccess
              ? const <AppPermissionKey>{}
              : AppPermissions.defaultPermissionsForRole(selectedBuiltIn)),
    );

    return _openConfigScreen(
      context: context,
      title: isPendingApproval
          ? 'Authorize ${targetUser.fullName}'
          : 'Configure Access • ${targetUser.fullName}',
      subtitle: targetUser.email,
      badgeLabel: isPendingApproval ? 'Pending Request' : 'Active Staff',
      allowModeSwitch: true,
      initialUseCustomMode: useCustomMode,
      initialBuiltIn: selectedBuiltIn,
      initialSavedCustomRoleId: selectedSavedCustomRoleId,
      initialCustomRoleName: targetUser.customRoleName ?? '',
      initialSelectedPermissions: selectedPermissions,
      initialSaveAsReusable: true,
      confirmLabel: isPendingApproval ? 'Approve & Grant Access' : 'Save Access',
      onConfirm: ({
        required bool isCustomMode,
        required UserRole builtInRole,
        required String? savedCustomRoleId,
        required String customRoleName,
        required Set<AppPermissionKey> permissions,
        required bool saveReusable,
      }) {
        if (!isCustomMode && savedCustomRoleId != null) {
          final saved = auth.customRoles
              .where((r) => r.id == savedCustomRoleId)
              .toList();
          if (saved.isNotEmpty) {
            final def = saved.first;
            if (isPendingApproval) {
              auth.approveUser(
                targetUser.id,
                UserRole.supervisor,
                def.id,
                def.name,
                def.permissions,
              );
            } else {
              auth.updateApprovedUserAccess(
                userId: targetUser.id,
                customRoleId: def.id,
                customRoleName: def.name,
                customPermissions: def.permissions,
              );
            }
            onSaved?.call();
            return null;
          }
        }

        if (!isCustomMode) {
          if (isPendingApproval) {
            auth.approveUser(targetUser.id, builtInRole);
          } else {
            auth.updateApprovedUserAccess(
              userId: targetUser.id,
              presetRole: builtInRole,
            );
          }
          onSaved?.call();
          return null;
        }

        final cleanName = customRoleName.trim();
        if (cleanName.isEmpty) {
          return 'Enter a name for the custom role.';
        }
        if (CustomRoleDefinition.isReservedRoleName(cleanName)) {
          return 'Cannot use reserved executive title "$cleanName".';
        }

        if (isPendingApproval) {
          final ok = auth.approveUser(
            targetUser.id,
            UserRole.supervisor,
            null,
            cleanName,
            permissions,
            saveReusable,
          );
          if (!ok) return auth.lastAuthError ?? 'Could not authorize user.';
        } else {
          final ok = auth.updateApprovedUserAccess(
            userId: targetUser.id,
            customRoleName: cleanName,
            customPermissions: permissions,
            saveAsReusableRole: saveReusable,
          );
          if (!ok) return auth.lastAuthError ?? 'Could not update staff access.';
        }
        onSaved?.call();
        return null;
      },
    );
  }

  static Future<void> showForCustomRoleDefinition(
    BuildContext context, {
    CustomRoleDefinition? existingRole,
    VoidCallback? onSaved,
  }) {
    final auth = context.read<AuthProvider>();
    if (!auth.canManageTeam) return Future.value();

    final selectedPermissions = Set<AppPermissionKey>.from(
      existingRole?.permissions ?? const <AppPermissionKey>{},
    );

    return _openConfigScreen(
      context: context,
      title: existingRole == null
          ? 'Create Custom Role'
          : 'Edit Role • ${existingRole.name}',
      subtitle: 'Check off exact features & controls this role can use',
      badgeLabel: 'Custom RBAC',
      allowModeSwitch: false,
      initialUseCustomMode: true,
      initialBuiltIn: UserRole.supervisor,
      initialSavedCustomRoleId: existingRole?.id,
      initialCustomRoleName: existingRole?.name ?? '',
      initialSelectedPermissions: selectedPermissions,
      initialSaveAsReusable: true,
      confirmLabel: existingRole == null ? 'Create Custom Role' : 'Save Role',
      onConfirm: ({
        required bool isCustomMode,
        required UserRole builtInRole,
        required String? savedCustomRoleId,
        required String customRoleName,
        required Set<AppPermissionKey> permissions,
        required bool saveReusable,
      }) {
        final cleanName = customRoleName.trim();
        if (cleanName.isEmpty) {
          return 'Enter a name for the custom role.';
        }
        if (CustomRoleDefinition.isReservedRoleName(cleanName)) {
          return 'Cannot use reserved executive title "$cleanName".';
        }
        if (existingRole == null) {
          final created = auth.createCustomRole(
            name: cleanName,
            permissions: permissions,
          );
          if (created == null) {
            return auth.lastAuthError ?? 'Failed to create role.';
          }
        } else {
          final ok = auth.updateCustomRole(
            roleId: existingRole.id,
            name: cleanName,
            permissions: permissions,
          );
          if (!ok) {
            return auth.lastAuthError ?? 'Failed to update role.';
          }
        }
        onSaved?.call();
        return null;
      },
    );
  }

  static Future<void> _openConfigScreen({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeLabel,
    required bool allowModeSwitch,
    required bool initialUseCustomMode,
    required UserRole initialBuiltIn,
    required String? initialSavedCustomRoleId,
    required String initialCustomRoleName,
    required Set<AppPermissionKey> initialSelectedPermissions,
    required bool initialSaveAsReusable,
    required String confirmLabel,
    required String? Function({
      required bool isCustomMode,
      required UserRole builtInRole,
      required String? savedCustomRoleId,
      required String customRoleName,
      required Set<AppPermissionKey> permissions,
      required bool saveReusable,
    })
    onConfirm,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 170),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (_, _, _) => _RolePermissionConfigScreen(
          title: title,
          subtitle: subtitle,
          badgeLabel: badgeLabel,
          allowModeSwitch: allowModeSwitch,
          initialUseCustomMode: initialUseCustomMode,
          initialBuiltIn: initialBuiltIn,
          initialSavedCustomRoleId: initialSavedCustomRoleId,
          initialCustomRoleName: initialCustomRoleName,
          initialSelectedPermissions: initialSelectedPermissions,
          initialSaveAsReusable: initialSaveAsReusable,
          confirmLabel: confirmLabel,
          onConfirm: onConfirm,
        ),
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
}

class _RolePermissionConfigScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeLabel;
  final bool allowModeSwitch;
  final bool initialUseCustomMode;
  final UserRole initialBuiltIn;
  final String? initialSavedCustomRoleId;
  final String initialCustomRoleName;
  final Set<AppPermissionKey> initialSelectedPermissions;
  final bool initialSaveAsReusable;
  final String confirmLabel;
  final String? Function({
    required bool isCustomMode,
    required UserRole builtInRole,
    required String? savedCustomRoleId,
    required String customRoleName,
    required Set<AppPermissionKey> permissions,
    required bool saveReusable,
  })
  onConfirm;

  const _RolePermissionConfigScreen({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.allowModeSwitch,
    required this.initialUseCustomMode,
    required this.initialBuiltIn,
    required this.initialSavedCustomRoleId,
    required this.initialCustomRoleName,
    required this.initialSelectedPermissions,
    required this.initialSaveAsReusable,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  State<_RolePermissionConfigScreen> createState() =>
      _RolePermissionConfigScreenState();
}

class _RolePermissionConfigScreenState
    extends State<_RolePermissionConfigScreen> {
  late bool _useCustomMode;
  late UserRole _selectedBuiltIn;
  late String? _selectedSavedCustomRoleId;
  late final TextEditingController _customNameCtrl;
  late final Set<AppPermissionKey> _selectedPermissions;
  late bool _saveAsReusable;
  String? _validationError;

  late final Map<String, List<AppPermissionKey>> _groupedPermissions;

  @override
  void initState() {
    super.initState();
    _useCustomMode = widget.initialUseCustomMode;
    _selectedBuiltIn = widget.initialBuiltIn;
    _selectedSavedCustomRoleId = widget.initialSavedCustomRoleId;
    _customNameCtrl = TextEditingController(text: widget.initialCustomRoleName);
    _selectedPermissions = Set<AppPermissionKey>.from(
      widget.initialSelectedPermissions,
    );
    _saveAsReusable = widget.initialSaveAsReusable;

    _groupedPermissions = {};
    for (final key in AppPermissionKey.values) {
      _groupedPermissions.putIfAbsent(key.category, () => []).add(key);
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final err = widget.onConfirm(
      isCustomMode: _useCustomMode,
      builtInRole: _selectedBuiltIn,
      savedCustomRoleId: _selectedSavedCustomRoleId,
      customRoleName: _customNameCtrl.text,
      permissions: _selectedPermissions,
      saveReusable: _saveAsReusable,
    );
    if (err != null) {
      setState(() => _validationError = err);
      AppNotification.show(
        context,
        message: err,
        backgroundColor: AppColors.error,
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: AppTypography.titleLarge(isDark).copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.subtitle.isNotEmpty)
              Text(
                widget.subtitle,
                style: AppTypography.bodySmall(isDark),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: AppColors.brandPeach.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  widget.badgeLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPeach,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      if (widget.allowModeSwitch) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _ModeTabChip(
                                key: const Key('role_mode_preset_tab'),
                                label: 'Pre-existing Roles',
                                icon: Icons.badge_outlined,
                                selected: !_useCustomMode,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _useCustomMode = false;
                                  _validationError = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeTabChip(
                                key: const Key('role_mode_custom_tab'),
                                label: 'Create Custom Role',
                                icon: Icons.tune_rounded,
                                selected: _useCustomMode,
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _useCustomMode = true;
                                  _validationError = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_validationError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (!_useCustomMode) ...[
                        DetailSectionTitle(
                          label: 'Standard Department Roles',
                          isDark: isDark,
                        ),
                        ...UserRole.values
                            .where((r) => r != UserRole.proprietor)
                            .map((role) {
                          final isSelected =
                              _selectedSavedCustomRoleId == null &&
                              _selectedBuiltIn == role;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() {
                                _selectedBuiltIn = role;
                                _selectedSavedCustomRoleId = null;
                              }),
                              borderRadius: BorderRadius.circular(6.0),
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? role.color.withValues(alpha: 0.14)
                                      : (isDark
                                            ? AppColors.darkCardElevated
                                            : AppColors.lightCard),
                                  borderRadius: BorderRadius.circular(6.0),
                                  border: Border.all(
                                    color: isSelected
                                        ? role.color
                                        : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder)
                                              .withValues(alpha: 0.7),
                                    width: isSelected ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(role.icon, color: role.color, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role.title,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  isSelected ? role.color : null,
                                            ),
                                          ),
                                          Text(
                                            AppPermissions.getRoleAccessSummary(
                                              role,
                                            ),
                                            style: AppTypography.bodySmall(
                                              isDark,
                                            ).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? role.color
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (auth.customRoles.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          DetailSectionTitle(
                            label: 'Saved Studio Custom Roles',
                            isDark: isDark,
                          ),
                          ...auth.customRoles.map((customRole) {
                            final isSelected =
                                _selectedSavedCustomRoleId == customRole.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedSavedCustomRoleId = customRole.id;
                                }),
                                borderRadius: BorderRadius.circular(6.0),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.brandPeach.withValues(
                                            alpha: 0.14,
                                          )
                                        : (isDark
                                              ? AppColors.darkCardElevated
                                              : AppColors.lightCard),
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.brandPeach
                                          : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)
                                                .withValues(alpha: 0.7),
                                      width: isSelected ? 1.2 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tune_rounded,
                                        color: AppColors.brandPeach,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customRole.name,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? AppColors.brandPeach
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              '${customRole.permissions.length} Checked Permission(s)',
                                              style: AppTypography.bodySmall(
                                                isDark,
                                              ).copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        size: 18,
                                        color: isSelected
                                            ? AppColors.brandPeach
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ] else ...[
                        // Custom Role Name + Permissions Checklist
                        TextField(
                          key: const Key('custom_role_name_field'),
                          controller: _customNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Custom Role Name *',
                            hintText: 'e.g. Junior Architect, Procurement Exec',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (widget.allowModeSwitch) ...[
                          Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeThumbColor: AppColors.brandPeach,
                              title: const Text(
                                'Save as reusable studio role',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Makes this role selectable for future team sign-ups',
                                style: AppTypography.bodySmall(isDark).copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              value: _saveAsReusable,
                              onChanged: (v) =>
                                  setState(() => _saveAsReusable = v),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Quick Pre-fill Helpers
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              label: const Text(
                                'Clear All',
                                style: TextStyle(fontSize: 11),
                              ),
                              onPressed: () =>
                                  setState(() => _selectedPermissions.clear()),
                            ),
                            for (final role in UserRole.values.where(
                              (r) => r != UserRole.proprietor,
                            ))
                              ActionChip(
                                label: Text(
                                  'Preset: ${role.shortCode}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () => setState(() {
                                  _selectedPermissions
                                    ..clear()
                                    ..addAll(
                                      AppPermissions.defaultPermissionsForRole(
                                        role,
                                      ),
                                    );
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Security Lockout Notice
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 15,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Security: Team approvals & custom role governance stay locked strictly to the Proprietor.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Categorized Permission Checkboxes
                        for (final entry in _groupedPermissions.entries) ...[
                          DetailSectionTitle(label: entry.key, isDark: isDark),
                          ...entry.value.map((permKey) {
                            final checked = _selectedPermissions.contains(
                              permKey,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: checked
                                    ? AppColors.brandPeach.withValues(
                                        alpha: 0.08,
                                      )
                                    : (isDark
                                          ? AppColors.darkCardElevated
                                          : AppColors.lightCard),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                  side: BorderSide(
                                    color: checked
                                        ? AppColors.brandPeach.withValues(
                                            alpha: 0.5,
                                          )
                                        : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder)
                                              .withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CheckboxListTile(
                                  key: Key('perm_checkbox_${permKey.name}'),
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  activeColor: AppColors.brandPeach,
                                  checkColor: Colors.black,
                                  value: checked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedPermissions.add(permKey);
                                      } else {
                                        _selectedPermissions.remove(permKey);
                                      }
                                    });
                                  },
                                  secondary: Icon(
                                    permKey.icon,
                                    size: 18,
                                    color: checked
                                        ? AppColors.brandPeach
                                        : (isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted),
                                  ),
                                  title: Text(
                                    permKey.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: checked
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Cancel', maxLines: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          key: const Key('role_config_confirm_btn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(widget.confirmLabel, maxLines: 1),
                          ),
                          onPressed: _handleConfirm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeTabChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPeach.withValues(alpha: 0.16)
              : (isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: selected
                ? AppColors.brandPeach
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.7),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.brandPeach : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.brandPeach : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
