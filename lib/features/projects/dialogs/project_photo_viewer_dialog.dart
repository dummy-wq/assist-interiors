import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProjectPhotoViewerDialog {
  ProjectPhotoViewerDialog._();

  static void show(
    BuildContext context, {
    required Map<String, dynamic> photo,
    required String projectName,
    required Color projectAccent,
    required bool canDelete,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photoTitle = photo['title'] as String? ?? 'Site Progress Photo';
    final photoTag = photo['tag'] as String? ?? 'General';
    final photoTimestamp = photo['timestamp'] as String? ?? 'Recorded Recently';
    final capturedBy = photo['capturedBy'] as String? ?? 'Site Supervisor';
    final imagePath = photo['imagePath'] as String?;
    final hasRealImage =
        imagePath != null && !kIsWeb && File(imagePath).existsSync();

    showDialog(
      context: context,
      builder: (dialogCtx) {
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Title Bar
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
                              child: Text(
                                photoTag.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: projectAccent,
                                  letterSpacing: 0.5,
                                ),
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Architectural Photo Frame Viewport
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: projectAccent.withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (hasRealImage)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else ...[
                          // Blueprint grid subtle overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BlueprintGridPainter(
                                gridColor: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          // Center icon and title
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: projectAccent.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: projectAccent.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera_rounded,
                                      size: 32,
                                      color: projectAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    photoTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // Top watermark
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: hasRealImage
                                  ? Colors.black.withValues(alpha: 0.75)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 12,
                                  color: projectAccent.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ASSIST INTERIORS • VERIFIED SITE PHOTO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: projectAccent.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom timestamp strip
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasRealImage
                                  ? Colors.black.withValues(alpha: 0.75)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  photoTimestamp,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: hasRealImage
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : (isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted),
                                  ),
                                ),
                                Text(
                                  'by $capturedBy',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: projectAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metadata Details
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)
                            .withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.brandPeach,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Zone: $photoTag',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cloud Synced',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions: Delete (if permitted) & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canDelete) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (confirmCtx) {
                                return AlertDialog(
                                  backgroundColor: isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  title: const Text(
                                    'Delete Site Photo?',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  content: Text(
                                    'Are you sure you want to remove "$photoTitle"? This action cannot be undone.',
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
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(confirmCtx);
                                        Navigator.pop(dialogCtx);
                                        onDelete?.call();
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Remove Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightBackground,
                          foregroundColor: isDark
                              ? AppColors.textLightPrimary
                              : AppColors.textDarkPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
  }
}

class _BlueprintGridPainter extends CustomPainter {
  final Color gridColor;

  _BlueprintGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const step = 20.0;
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
