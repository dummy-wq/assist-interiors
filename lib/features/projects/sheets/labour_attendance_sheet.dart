import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class LabourAttendanceSheet {
  LabourAttendanceSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: AppSizes.sheetBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'On-Site Attendance Roll Call',
                    style: AppTypography.titleLarge(isDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAttendanceCounter('Carpentry Crew', 14, isDark),
              _buildAttendanceCounter('Electrical / Wiring', 6, isDark),
              _buildAttendanceCounter('Masonry & Civil', 6, isDark),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPeach,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Verify & Submit Daily Muster Roll'),
                onPressed: () {
                  MobileActionSheets.attendanceCountNotifier.value = 26;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance recorded for 26 workers!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAttendanceCounter(String title, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyLarge(isDark)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPeach.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '$count Present',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandPeach,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
