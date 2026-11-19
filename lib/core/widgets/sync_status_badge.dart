import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../services/backend_manager.dart';
import '../theme/app_colors.dart';

/// Compact, beginner-friendly indicator showing live cloud save/sync state:
/// `✓ Saved · Synced`, `⏳ Syncing...`, or `⚠ Offline – will sync later`.
class SyncStatusBadge extends StatelessWidget {
  final bool compact;

  const SyncStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<CloudSyncState>(
      valueListenable: BackendManager.syncStateNotifier,
      builder: (context, rawState, _) {
        final state = BackendManager.instance.isCloudConnected
            ? (BackendManager.instance.isAuthenticatedCloud
                  ? rawState
                  : CloudSyncState.offline)
            : CloudSyncState.offline;

        final Color color;
        final String label;
        final String compactLabel;
        switch (state) {
          case CloudSyncState.synced:
            color = AppColors.success;
            label = AppStrings.tr('✓ Saved · Synced');
            compactLabel = AppStrings.tr('✓ Synced');
            break;
          case CloudSyncState.syncing:
            color = AppColors.brandPeach;
            label = AppStrings.tr('⏳ Syncing...');
            compactLabel = AppStrings.tr('⏳ Syncing');
            break;
          case CloudSyncState.offline:
            color = AppColors.warning;
            label = AppStrings.tr('⚠ Offline – will sync later');
            compactLabel = AppStrings.tr('⚠ Offline');
            break;
        }

        return Tooltip(
          message: label,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 0.8,
              ),
            ),
            child: Text(
              compact ? compactLabel : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
