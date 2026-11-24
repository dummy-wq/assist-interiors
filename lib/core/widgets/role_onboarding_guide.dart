import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'studio_dialog.dart';

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Short 4-step first-time quick-start carousel tailored to each [UserRole].
/// Shown once per role on first entry (unless suppressed in tests) and
/// re-openable anytime from the side drawer.
class RoleOnboardingGuide {
  RoleOnboardingGuide._();

  static List<_GuideStep> _stepsForRole(UserRole role) {
    final String roleFocus;
    final String mainButtonDesc;
    switch (role) {
      case UserRole.supervisor:
        roleFocus =
            'Track your site stages, capture site inspection photos, and request materials directly from site.';
        mainButtonDesc =
            'Tap the large "Take Site Photo" button right on your Home screen or inside any project\'s Photos tab.';
        break;
      case UserRole.siteEngineer:
        roleFocus =
            'Verify technical drawings, log site inspections & snags, update stage progress, and record roll calls.';
        mainButtonDesc =
            'Tap "Take Site Photo" on your Home screen or open any project to review drawings, progress, and snags.';
        break;
      case UserRole.designer:
        roleFocus =
            'Share 2D layouts, 3D renders, mood boards, and PDFs with site and management.';
        mainButtonDesc =
            'Tap "Upload Drawing" on your Home screen or open a project\'s Files tab to publish files.';
        break;
      case UserRole.accounts:
        roleFocus =
            'Create client bills, upload UPI QR codes, record expenses, and download PDF reports.';
        mainButtonDesc =
            'Tap the large "New Invoice" button to bill any project and track pending payments.';
        break;
      case UserRole.sales:
        roleFocus =
            'Track client inquiries, schedule follow-up calls, and move approved projects into execution.';
        mainButtonDesc =
            'Tap "Add New Lead" to record a new client inquiry with reminder date and time.';
        break;
      case UserRole.projectManager:
        roleFocus =
            'Oversee project progress, assign tasks, upload Excel schedules, and approve material indents.';
        mainButtonDesc =
            'Open any project to switch smoothly between Progress, Photos, Files, and Billing tabs.';
        break;
      case UserRole.proprietor:
        roleFocus =
            'Approve new staff, manage roles & passwords, monitor cash flow, and export full project backups.';
        mainButtonDesc =
            'Use the Team tab to approve staff requests or reset passwords, and Projects to add new sites.';
        break;
    }

    return [
      _GuideStep(
        icon: role.icon,
        title: 'Welcome, ${role.title}',
        body: roleFocus,
      ),
      const _GuideStep(
        icon: Icons.view_carousel_outlined,
        title: 'Simple Bottom Tabs',
        body:
            'Your most-used screens sit right at the bottom of your screen. Tap "More" anytime to open additional studio tools.',
      ),
      _GuideStep(
        icon: Icons.touch_app_rounded,
        title: 'One Big Main Button',
        body: mainButtonDesc,
      ),
      const _GuideStep(
        icon: Icons.cloud_done_rounded,
        title: 'Undo & Auto-Save',
        body:
            'Made a mistake? Look for "Undo" or "Step Back" to reverse changes. Even without internet, photos and updates save on your phone and sync automatically later.',
      ),
    ];
  }

  static Future<void> maybeShowOnFirstVisit(
    BuildContext context, {
    required UserRole role,
  }) async {
    if (StorageService.hasSeenOnboardingTips(role.name)) return;
    await StorageService.markOnboardingTipsSeen(role.name);
    if (!context.mounted) return;
    await show(context, role: role, force: true);
  }

  static Future<void> show(
    BuildContext context, {
    required UserRole role,
    bool force = false,
  }) async {
    if (!force && StorageService.hasSeenOnboardingTips(role.name)) return;
    await StorageService.markOnboardingTipsSeen(role.name);
    if (!context.mounted) return;

    final steps = _stepsForRole(role);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentStep = 0;

    await showStudioDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final step = steps[currentStep];
            final isLast = currentStep == steps.length - 1;

            return Dialog(
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(
                  color: AppColors.brandPeach.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandPeach.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              step.icon,
                              size: 24,
                              color: AppColors.brandPeach,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppStrings.tr('Quick Start Guide')} · ${currentStep + 1}/${steps.length}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandPeach,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.title,
                                  style: AppTypography.titleLarge(isDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          step.body,
                          style: AppTypography.bodyMedium(isDark).copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                            color: isDark
                                ? AppColors.textLightPrimary
                                : AppColors.textDarkPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(steps.length, (idx) {
                          final active = idx == currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.brandPeach
                                  : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(AppStrings.tr('Skip')),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPeach,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              if (isLast) {
                                Navigator.of(dialogCtx).pop();
                              } else {
                                setDialogState(() => currentStep++);
                              }
                            },
                            child: Text(
                              isLast
                                  ? AppStrings.tr('Got It')
                                  : AppStrings.tr('Next'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
