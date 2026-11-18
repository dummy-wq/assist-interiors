import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/blueprint_grid_painter.dart';
import '../../../core/widgets/cloud_network_image.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';

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
    final imagePath =
        (photo['imagePath'] ?? photo['localPath'] ?? photo['path']) as String?;
    final imageUrl = (photo['downloadUrl'] ?? photo['imageUrl']) as String?;
    final hasLocalImage = imagePath != null &&
        !imagePath.startsWith('http') &&
        !kIsWeb &&
        File(imagePath).existsSync();
    final hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasRealImage = hasLocalImage || hasNetworkImage;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final screenHeight = MediaQuery.of(dialogCtx).size.height;
        final viewportHeight = (screenHeight * 0.56).clamp(320.0, 520.0);

        return FlickDismissibleCard(
          onDismiss: () {
            if (Navigator.of(dialogCtx).canPop()) {
              Navigator.of(dialogCtx).pop();
            }
          },
          child: Dialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
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

                  // Architectural Photo Frame Viewport (full uncropped image view)
                  Container(
                    height: viewportHeight,
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
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: hasLocalImage
                                    ? Image.file(
                                        File(imagePath),
                                        fit: BoxFit.contain,
                                      )
                                    : CloudNetworkImage(
                                        url: imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 42,
                                            color: projectAccent,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          )
                        else ...[
                          // Blueprint grid subtle overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BlueprintGridPainter(
                                step: 20.0,
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
                                Flexible(
                                  child: Text(
                                    photoTimestamp,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: hasRealImage
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : (isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${AppStrings.tr('Captured By')}: $capturedBy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: projectAccent,
                                    ),
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
                                size: 15,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${AppStrings.tr('Zone')}: $photoTag',
                                style: TextStyle(
                                  fontSize: 12.5,
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
                                size: 15,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.tr('Cloud Synced'),
                                style: const TextStyle(
                                  fontSize: 12,
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

                    // Actions: Remove (with Undo in caller) & Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canDelete) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              onDelete?.call();
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            label: Text(
                              AppStrings.tr('Remove Photo'),
                              style: const TextStyle(
                                fontSize: 12.5,
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
                                horizontal: 14,
                                vertical: 11,
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
                              horizontal: 18,
                              vertical: 11,
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
                          child: Text(
                            AppStrings.tr('Close'),
                            style: const TextStyle(
                              fontSize: 12.5,
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
        ),
        );
      },
    );
  }
}
