import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/services/storage_service.dart';
import '../widgets/mobile_action_sheets.dart';

class DesignerDashboard extends StatefulWidget {
  const DesignerDashboard({super.key});

  @override
  State<DesignerDashboard> createState() => _DesignerDashboardState();
}

class _DesignerDashboardState extends State<DesignerDashboard> {
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll(StorageService.getDesignItems());
    MobileActionSheets.renderCreatedNotifier.addListener(_onRenderCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.renderCreatedNotifier.removeListener(_onRenderCreated);
    super.dispose();
  }

  void _onRenderCreated() {
    final render = MobileActionSheets.renderCreatedNotifier.value;
    if (render != null && mounted) {
      setState(() {
        _items.insert(0, Map<String, dynamic>.from(render));
      });
      StorageService.saveDesignItems(_items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    final boardsCount = _items.where((i) {
      final t = (i['type'] as String? ?? '').toLowerCase();
      final title = (i['title'] as String? ?? '').toLowerCase();
      return t.contains('board') ||
          t.contains('2d') ||
          title.contains('board') ||
          title.contains('2d');
    }).length;

    final rendersCount = _items.where((i) {
      final t = (i['type'] as String? ?? '').toLowerCase();
      final title = (i['title'] as String? ?? '').toLowerCase();
      return t.contains('3d') ||
          t.contains('render') ||
          title.contains('3d') ||
          title.contains('render');
    }).length;

    final boqCount = _items.where((i) {
      final t = (i['type'] as String? ?? '').toLowerCase();
      final title = (i['title'] as String? ?? '').toLowerCase();
      return t.contains('boq') ||
          t.contains('material') ||
          title.contains('boq') ||
          title.contains('material');
    }).length;

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
                'Design Studio & Deliverables Hub',
                style: AppTypography.displayMedium(isDark),
              ),
              if (isWide)
                ElevatedButton.icon(
                  onPressed: () =>
                      MobileActionSheets.showUploadRenderSheet(context),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Upload Render / BOQ'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // High-level Metrics (Compact StatStrip)
          StatStrip(
            cards: [
              StatCard(
                title: 'Active Boards',
                value: '$boardsCount Sets',
                icon: Icons.palette_rounded,
                accentColor: AppColors.brandPeach,
              ),
              StatCard(
                title: '3D Renders',
                value: '$rendersCount Views',
                icon: Icons.view_in_ar_rounded,
                accentColor: AppColors.brandPeach,
              ),
              StatCard(
                title: 'BOQ Indents',
                value: '$boqCount Pending',
                icon: Icons.format_list_numbered_rounded,
                accentColor: AppColors.warning,
              ),
              StatCard(
                title: 'Approval Rate',
                value: _items.isEmpty ? '0.0%' : '100%',
                trend: _items.isNotEmpty ? '100%' : null,
                icon: Icons.verified_rounded,
                accentColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Recent Design Deliverables & Mood Boards',
            style: AppTypography.titleLarge(isDark),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final items = _items;

              return Container(
                width: double.infinity,
                padding: items.isEmpty
                    ? const EdgeInsets.symmetric(vertical: 48, horizontal: 20)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: items.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            size: 44,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Design Deliverables',
                            style: AppTypography.titleMedium(isDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All mood boards and renders have been cleared. Tap "Upload Render / BOQ" to add design assets.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(isDark),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                MobileActionSheets.showUploadRenderSheet(
                                  context,
                                ),
                            icon: const Icon(
                              Icons.cloud_upload_rounded,
                              size: 18,
                            ),
                            label: const Text('Upload Render / BOQ'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.4 : 2.0,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final statusColor =
                              (item['statusColor'] as Color?) ??
                              AppColors.brandPeach;
                          return Container(
                            padding: const EdgeInsets.all(16),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandPeach.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: AppColors.brandPeach,
                                        size: 20,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                      ),
                                      child: Text(
                                        item['status'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: AppTypography.titleMedium(isDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['project'] as String,
                                      style: AppTypography.bodySmall(
                                        isDark,
                                      ).copyWith(color: AppColors.brandPeach),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['format'] as String,
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('View Render'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
