import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/services/storage_service.dart';
import '../widgets/mobile_action_sheets.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final List<Map<String, dynamic>> _siteLogs = [];
  int _attendanceCount = 0;

  @override
  void initState() {
    super.initState();
    _siteLogs.addAll(StorageService.getSiteLogs());
    _attendanceCount = MobileActionSheets.attendanceCountNotifier.value;
    MobileActionSheets.siteLogCreatedNotifier.addListener(_onSiteLogCreated);
    MobileActionSheets.attendanceCountNotifier.addListener(
      _onAttendanceChanged,
    );
  }

  @override
  void dispose() {
    MobileActionSheets.siteLogCreatedNotifier.removeListener(_onSiteLogCreated);
    MobileActionSheets.attendanceCountNotifier.removeListener(
      _onAttendanceChanged,
    );
    super.dispose();
  }

  void _onSiteLogCreated() {
    final log = MobileActionSheets.siteLogCreatedNotifier.value;
    if (log != null && mounted) {
      setState(() {
        _siteLogs.insert(0, Map<String, dynamic>.from(log));
      });
      StorageService.saveSiteLogs(_siteLogs);
    }
  }

  void _onAttendanceChanged() {
    if (mounted) {
      setState(() {
        _attendanceCount = MobileActionSheets.attendanceCountNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: isWide ? 40 : 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Site Operations & Daily Log',
                style: AppTypography.displayMedium(isDark),
              ),
              if (isWide)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          MobileActionSheets.showLabourAttendanceSheet(context),
                      icon: const Icon(Icons.groups_rounded, size: 16),
                      label: const Text('Log Attendance'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          MobileActionSheets.showSiteLogSheet(context),
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: const Text('Post Daily Site Log'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          // High-level Metrics (Compact StatStrip)
          StatStrip(
            cards: [
              StatCard(
                title: 'Labour On-Site',
                value: _attendanceCount > 0
                    ? '$_attendanceCount Workers'
                    : '0 Workers',
                icon: Icons.groups_rounded,
                accentColor: AppColors.brandPeach,
              ),
              StatCard(
                title: 'Site Report',
                value: _siteLogs.isEmpty
                    ? 'Pending'
                    : '${_siteLogs.length} Logged',
                icon: Icons.check_circle_rounded,
                accentColor: _siteLogs.isEmpty
                    ? AppColors.warning
                    : AppColors.success,
              ),
              const StatCard(
                title: 'Indents',
                value: '0 Raised',
                icon: Icons.local_shipping_rounded,
                accentColor: AppColors.brandPeach,
              ),
              const StatCard(
                title: 'Blockers',
                value: '0 Active',
                icon: Icons.security_rounded,
                accentColor: AppColors.brandPeach,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Today\'s Site Activity Feed & Photos',
            style: AppTypography.titleLarge(isDark),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final activities = _siteLogs;

              return Container(
                width: double.infinity,
                padding: activities.isEmpty
                    ? const EdgeInsets.symmetric(vertical: 48, horizontal: 20)
                    : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: activities.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 44,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Site Logs Today',
                            style: AppTypography.titleMedium(isDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All site reports have been cleared. Tap "Post Daily Site Log" to record on-site progress.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(isDark),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                MobileActionSheets.showSiteLogSheet(context),
                            icon: const Icon(
                              Icons.add_a_photo_rounded,
                              size: 18,
                            ),
                            label: const Text('Post Daily Site Log'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: activities.map((a) {
                          final projectStr = a['project'] != null
                              ? ' (${a['project']})'
                              : '';
                          return _buildActivityTile(
                            isDark: isDark,
                            time: (a['time'] as String?) ?? 'Today',
                            title: '${a['title'] ?? 'Site Update'}$projectStr',
                            description: (a['description'] as String?) ?? '',
                            hasPhotos: (a['hasPhotos'] as bool?) ?? false,
                            photoCount: (a['photoCount'] as int?) ?? 0,
                          );
                        }).toList(),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required bool isDark,
    required String time,
    required String title,
    required String description,
    required bool hasPhotos,
    required int photoCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPeach.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPeach,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium(isDark)),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodyMedium(isDark)),
                if (hasPhotos) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$photoCount site photos attached',
                        style: AppTypography.bodySmall(isDark)
                            .copyWith(color: AppColors.brandPeach),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
