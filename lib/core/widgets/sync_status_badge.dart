import 'package:flutter/material.dart';

import '../services/backend_manager.dart';
import '../theme/app_colors.dart';

/// Minimal, theme-matched cloud sync icon showing live save/sync state:
/// synced (`cloud_done_outlined`), syncing (gently rotating `sync_rounded`),
/// or offline (`cloud_off_outlined`), with a descriptive tooltip on press/hover.
class SyncStatusBadge extends StatefulWidget {
  final bool compact;
  final double? size;

  const SyncStatusBadge({super.key, this.compact = false, this.size});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  CloudSyncState _resolveState(CloudSyncState rawState) {
    return BackendManager.instance.isCloudConnected
        ? (BackendManager.instance.isAuthenticatedCloud
              ? rawState
              : CloudSyncState.offline)
        : CloudSyncState.offline;
  }

  void _syncSpinAnimation(CloudSyncState state) {
    if (state == CloudSyncState.syncing) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else if (_spinController.isAnimating || _spinController.value != 0.0) {
      _spinController.stop();
      _spinController.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? (widget.compact ? 18.0 : 19.0);

    return ValueListenableBuilder<CloudSyncState>(
      valueListenable: BackendManager.syncStateNotifier,
      builder: (context, rawState, _) {
        final state = _resolveState(rawState);
        _syncSpinAnimation(state);

        final Color color;
        final IconData icon;
        final String tooltipMessage;
        switch (state) {
          case CloudSyncState.synced:
            color = AppColors.success;
            icon = Icons.cloud_done_outlined;
            tooltipMessage = 'Saved · Synced';
            break;
          case CloudSyncState.syncing:
            color = AppColors.brandPeach;
            icon = Icons.sync_rounded;
            tooltipMessage = 'Syncing...';
            break;
          case CloudSyncState.offline:
            color = AppColors.warning;
            icon = Icons.cloud_off_outlined;
            tooltipMessage = 'Offline – will sync later';
            break;
        }

        final Widget iconWidget = state == CloudSyncState.syncing
            ? RotationTransition(
                turns: _spinController,
                child: Icon(icon, size: iconSize, color: color),
              )
            : Icon(
                icon,
                key: ValueKey<CloudSyncState>(state),
                size: iconSize,
                color: color,
              );

        return Tooltip(
          message: tooltipMessage,
          child: Semantics(
            label: tooltipMessage,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: iconWidget,
              ),
            ),
          ),
        );
      },
    );
  }
}
