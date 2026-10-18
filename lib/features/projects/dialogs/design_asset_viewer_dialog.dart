import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instant_press_feedback.dart';

/// Modal dialog for inspecting architectural CAD drawings, 3D renders, and BOQs.
class DesignAssetViewerDialog {
  DesignAssetViewerDialog._();

  static void show(
    BuildContext context, {
    required Map<String, dynamic> asset,
    required String projectName,
    required Color projectAccent,
    required bool canManage,
    required bool canDelete,
    VoidCallback? onDelete,
    ValueChanged<String>? onStatusChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = asset['title'] as String? ?? 'Design Deliverable';
    final type = asset['type'] as String? ?? 'CAD Drawing';
    final format = asset['format'] as String? ?? '.DWG';
    final version = asset['version'] as String? ?? 'v1.0';
    final fileSize = asset['fileSize'] as String? ?? '12.4 MB';
    var status = asset['status'] as String? ?? 'Under Client Review';
    final date = asset['date'] as String? ?? 'Recently';
    final designer = asset['designer'] as String? ?? 'Priya Sharma';
    final fileName = asset['fileName'] as String?;
    final filePath = asset['filePath'] as String?;
    final isUploaded = asset['isUploaded'] as bool? ?? false;
    final notes = asset['notes'] as String? ??
        'Architectural deliverable generated for client coordination and site execution.';

    Color getStatusColor(String st) {
      if (st.toLowerCase().contains('approv')) return AppColors.success;
      if (st.toLowerCase().contains('revis')) return AppColors.error;
      return AppColors.brandPeach;
    }

    IconData getTypeIcon(String t) {
      final lower = t.toLowerCase();
      if (lower.contains('cad') || lower.contains('dwg') || lower.contains('plan')) {
        return Icons.architecture_rounded;
      }
      if (lower.contains('render') || lower.contains('3d') || lower.contains('max')) {
        return Icons.view_in_ar_rounded;
      }
      if (lower.contains('boq') || lower.contains('spec') || lower.contains('material')) {
        return Icons.table_chart_rounded;
      }
      if (lower.contains('mood') || lower.contains('board')) {
        return Icons.palette_rounded;
      }
      return Icons.description_rounded;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final statusColor = getStatusColor(status);

            return Dialog(
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: projectAccent.withValues(
                                      alpha: isDark ? 0.22 : 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(
                                      color: projectAccent.withValues(
                                        alpha: isDark ? 0.5 : 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getTypeIcon(type),
                                        size: 13,
                                        color: projectAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: projectAccent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    projectName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Deliverable Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textLightPrimary
                              : AppColors.textDarkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Version, Format, and Size
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.8),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              version,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '$format • $fileSize • Uploaded $date',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textLightMuted
                                  : AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Architectural Blueprint / 3D Render Preview Widget
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F1722)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: projectAccent.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Blueprint grid lines background
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BlueprintGridPainter(
                                  gridColor: (isDark
                                          ? AppColors.info
                                          : Colors.blueGrey)
                                      .withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    getTypeIcon(type),
                                    size: 42,
                                    color: projectAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$format DELIVERABLE CONTAINER',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Architectural CAD / 3D Spec Sheet',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Corner tech indicators
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(3.0),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Text(
                                'LEAD: $designer',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (isUploaded || fileName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attachment_rounded,
                                size: 15,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName ?? 'Local Deliverable Asset',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (filePath != null)
                                      Text(
                                        filePath,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontFamily: 'monospace',
                                          color: isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                child: const Text(
                                  'STORAGE SYNCED',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Deliverable Notes & Attribution
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: AppColors.brandPeach,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Toggle & Quick Actions Row
                      if (canManage) ...[
                        Text(
                          'CLIENT SIGN-OFF & APPROVAL STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatusActionButton(
                              label: 'Mark Approved',
                              targetStatus: 'Approved',
                              currentStatus: status,
                              color: AppColors.success,
                              icon: Icons.check_circle_outline_rounded,
                              onTap: () {
                                setDialogState(() => status = 'Approved');
                                onStatusChanged?.call('Approved');
                              },
                            ),
                            _buildStatusActionButton(
                              label: 'Client Review',
                              targetStatus: 'Under Client Review',
                              currentStatus: status,
                              color: AppColors.brandPeach,
                              icon: Icons.hourglass_top_rounded,
                              onTap: () {
                                setDialogState(
                                  () => status = 'Under Client Review',
                                );
                                onStatusChanged?.call('Under Client Review');
                              },
                            ),
                            _buildStatusActionButton(
                              label: 'Request Revision',
                              targetStatus: 'Revision Requested',
                              currentStatus: status,
                              color: AppColors.error,
                              icon: Icons.edit_note_rounded,
                              onTap: () {
                                setDialogState(
                                  () => status = 'Revision Requested',
                                );
                                onStatusChanged?.call('Revision Requested');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Bottom Action Buttons
                      Row(
                        children: [
                          if (canDelete) ...[
                            InstantPressFeedback(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: dialogCtx,
                                    builder: (confirmCtx) => AlertDialog(
                                      backgroundColor: isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.0),
                                      ),
                                      title: const Text(
                                        'Delete Deliverable?',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      content: Text(
                                        'Are you sure you want to remove "$title"? This action cannot be undone.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(confirmCtx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(confirmCtx);
                                            Navigator.pop(dialogCtx);
                                            onDelete?.call();
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: InstantPressFeedback(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandPeach,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Exported $title ($format) successfully.',
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.file_download_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  'Download / Export $format',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  static Widget _buildStatusActionButton({
    required String label,
    required String targetStatus,
    required String currentStatus,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = currentStatus == targetStatus;
    return InstantPressFeedback(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.35),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  final Color gridColor;

  const _BlueprintGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
