import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/models/user_model.dart';
import '../../auth/state/auth_provider.dart';

/// Shared dialog allowing the Proprietor to reset any staff member's password.
class ResetStaffPasswordDialog {
  ResetStaffPasswordDialog._();

  static Future<void> show(
    BuildContext context, {
    required AppUser targetUser,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ResetPasswordDialogBody(
        targetUser: targetUser,
        parentContext: context,
      ),
    );
  }
}

class _ResetPasswordDialogBody extends StatefulWidget {
  final AppUser targetUser;
  final BuildContext parentContext;

  const _ResetPasswordDialogBody({
    required this.targetUser,
    required this.parentContext,
  });

  @override
  State<_ResetPasswordDialogBody> createState() =>
      _ResetPasswordDialogBodyState();
}

class _ResetPasswordDialogBodyState extends State<_ResetPasswordDialogBody> {
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final p1 = _passCtrl.text.trim();
    final p2 = _confirmCtrl.text.trim();
    if (p1.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.');
      return;
    }
    if (p1 != p2) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = auth.resetStaffPassword(
      userId: widget.targetUser.id,
      newPassword: p1,
    );
    if (ok) {
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        AppNotification.show(
          widget.parentContext,
          message:
              'Password updated for ${widget.targetUser.fullName}. Share the new password with them.',
        );
      }
    } else {
      setState(() {
        _errorMsg = auth.lastAuthError ?? 'Could not reset password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.brandPeach,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr('Reset Password'),
              style: AppTypography.titleLarge(isDark),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set a new login password for ${widget.targetUser.fullName} (${widget.targetUser.email}).',
              style: AppTypography.bodyMedium(isDark).copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColors.textLightSecondary
                    : AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: AppStrings.tr('Enter New Password'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: AppStrings.tr('Confirm New Password'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMsg!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.tr('Cancel')),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: Text(AppStrings.tr('Reset Password')),
          onPressed: _submit,
        ),
      ],
    );
  }
}
