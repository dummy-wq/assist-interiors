import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/instant_press_feedback.dart';

class _QueuedSitePhoto {
  final String path;
  final Uint8List bytes;
  final DateTime capturedAt;

  const _QueuedSitePhoto({
    required this.path,
    required this.bytes,
    required this.capturedAt,
  });
}

class TakeSitePhotoSheet {
  TakeSitePhotoSheet._();

  /// One-tap entry point used by Supervisors' large "Take Site Photo" button:
  /// picks a project (or uses the only active project) and opens [TakeSitePhotoSheet].
  static void openQuickCapture(BuildContext context) {
    final projects = StorageService.getProjects();
    if (projects.isEmpty) {
      AppNotification.show(
        context,
        message: 'No projects yet. Add a project first, then take site photos.',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    void openForProject(int index) {
      show(
        context,
        project: projects[index],
        onPhotoAdded: (photo) {
          final current = StorageService.getProjects();
          if (index < current.length) {
            final photosRaw = (current[index]['photos'] as List?) ?? [];
            final list = photosRaw
                .map((p) => Map<String, dynamic>.from(p as Map))
                .toList();
            list.insert(0, photo);
            current[index]['photos'] = list;
            StorageService.saveProjects(current);
            StorageService.cloudSyncNotifier.value =
                StorageService.cloudSyncNotifier.value + 1;
          }
          if (context.mounted) {
            AppNotification.show(
              context,
              message:
                  'Site inspection photo added to ${projects[index]['name']}',
              backgroundColor: AppColors.success,
            );
          }
        },
      );
    }

    if (projects.length == 1) {
      openForProject(0);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (pickerCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose Project for Photo',
                  style: AppTypography.titleLarge(isDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select which site you are adding photos to:',
                  style: AppTypography.bodySmall(isDark),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final proj = projects[idx];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side: BorderSide(
                            color: (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        leading: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.brandPeach,
                        ),
                        title: Text(
                          (proj['name'] ?? 'Site').toString(),
                          style: AppTypography.titleMedium(isDark),
                        ),
                        subtitle: Text(
                          (proj['location'] ?? '').toString(),
                          style: AppTypography.bodySmall(isDark),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(pickerCtx).pop();
                          openForProject(idx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show(
    BuildContext context, {
    required Map<String, dynamic> project,
    required void Function(Map<String, dynamic> photo) onPhotoAdded,
    bool initialUploadMode = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectName = project['name'] as String? ?? 'Project Site';

    final textController = TextEditingController();
    final List<_QueuedSitePhoto> queuedPhotos = [];
    bool isCapturing = false;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final latestTime = queuedPhotos.isNotEmpty
                ? queuedPhotos.last.capturedAt
                : DateTime.now();

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: AppSizes.sheetBottomPadding(modalContext),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Take Site Photo',
                                      style: AppTypography.titleLarge(isDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      projectName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (initialUploadMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPeach.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: AppColors.brandPeach.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              size: 14,
                              color: AppColors.brandPeach,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Upload Mode: Choose an existing photo or multiple photos from Gallery or Files',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brandPeach,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Photo Capture & Multi-Select Card (with Date & Time)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.brandPeach.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: AppColors.brandPeach,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    queuedPhotos.isNotEmpty
                                        ? 'CAPTURED AT (${queuedPhotos.length} PHOTO${queuedPhotos.length == 1 ? '' : 'S'})'
                                        : 'CURRENT TIME & DATE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy, hh:mm:ss a',
                                  ).format(latestTime),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color: AppColors.brandPeach,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (queuedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 112,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: queuedPhotos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, idx) {
                                  final item = queuedPhotos[idx];
                                  return SizedBox(
                                    width: 126,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                          child: Image.memory(
                                            item.bytes,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () => setModalState(() {
                                              queuedPhotos.removeAt(idx);
                                            }),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 4,
                                          right: 4,
                                          bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.72,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3.0),
                                            ),
                                            child: Text(
                                              DateFormat(
                                                'dd MMM • hh:mm a',
                                              ).format(item.capturedAt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InstantPressFeedback(
                                  child: ElevatedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              final allowed =
                                                  await PermissionService
                                                      .requestCamera(
                                                        modalContext,
                                                      );
                                              if (!allowed) return;
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final picker = ImagePicker();
                                              final XFile? file =
                                                  await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1920,
                                                maxHeight: 1080,
                                                imageQuality: 85,
                                              );
                                              if (file != null) {
                                                final pickedBytes =
                                                    await file.readAsBytes();
                                                setModalState(() {
                                                  queuedPhotos.add(
                                                    _QueuedSitePhoto(
                                                      path: file.path,
                                                      bytes: pickedBytes,
                                                      capturedAt:
                                                          DateTime.now(),
                                                    ),
                                                  );
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Camera capture error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(
                                                  modalContext,
                                                  message:
                                                      'Camera error: ${e.toString()}',
                                                  backgroundColor:
                                                      AppColors.error,
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.photo_camera_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Take Photo',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandPeach,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InstantPressFeedback(
                                  child: OutlinedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              final allowed =
                                                  await PermissionService
                                                      .requestMediaOrStorage(
                                                        modalContext,
                                                      );
                                              if (!allowed) return;
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final picker = ImagePicker();
                                              final List<XFile> files =
                                                  await picker.pickMultiImage(
                                                maxWidth: 1920,
                                                maxHeight: 1080,
                                                imageQuality: 85,
                                              );
                                              if (files.isNotEmpty) {
                                                final loaded =
                                                    <_QueuedSitePhoto>[];
                                                for (final f in files) {
                                                  final b =
                                                      await f.readAsBytes();
                                                  loaded.add(
                                                    _QueuedSitePhoto(
                                                      path: f.path,
                                                      bytes: b,
                                                      capturedAt:
                                                          DateTime.now(),
                                                    ),
                                                  );
                                                }
                                                setModalState(() {
                                                  queuedPhotos.addAll(loaded);
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Gallery pick error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(
                                                  modalContext,
                                                  message:
                                                      'Gallery error: ${e.toString()}',
                                                  backgroundColor:
                                                      AppColors.error,
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 14,
                                      color: AppColors.brandPeach,
                                    ),
                                    label: Text(
                                      'Gallery',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 0.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InstantPressFeedback(
                                  child: OutlinedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              final allowed =
                                                  await PermissionService
                                                      .requestMediaOrStorage(
                                                        modalContext,
                                                      );
                                              if (!allowed) return;
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final results =
                                                  await FilePicker.pickFiles(
                                                type: FileType.image,
                                              );
                                              if (results.isNotEmpty) {
                                                final loaded =
                                                    <_QueuedSitePhoto>[];
                                                for (final r in results) {
                                                  final b =
                                                      await r.readAsBytes();
                                                  loaded.add(
                                                    _QueuedSitePhoto(
                                                      path: r.path ?? r.name,
                                                      bytes: b,
                                                      capturedAt:
                                                          DateTime.now(),
                                                    ),
                                                  );
                                                }
                                                setModalState(() {
                                                  queuedPhotos.addAll(loaded);
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'File picker photo error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(
                                                  modalContext,
                                                  message:
                                                      'File access error: ${e.toString()}',
                                                  backgroundColor:
                                                      AppColors.error,
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.folder_open_rounded,
                                      size: 14,
                                      color: AppColors.brandPeach,
                                    ),
                                    label: Text(
                                      'Files',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 0.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (queuedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setModalState(() {
                                queuedPhotos.clear();
                              }),
                              borderRadius: BorderRadius.circular(3.0),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 12,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Clear Selected Photos',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Note / Title
                    Text(
                      'PHOTO TITLE / NOTE (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textController,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Optional note for these site photos...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    InstantPressFeedback(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final baseTitle = textController.text.trim().isNotEmpty
                              ? textController.text.trim()
                              : 'Site Photo';
                          final now = DateTime.now();
                          final retentionMonths =
                              StorageService.getPhotoRetentionMonths();
                          final reservedUntil = DateFormat('dd MMM yyyy').format(
                            now.add(Duration(days: retentionMonths * 30)),
                          );
                          final projId = (project['id'] ?? '').toString();

                          final itemsToSave = queuedPhotos.isNotEmpty
                              ? queuedPhotos
                              : <_QueuedSitePhoto>[];

                          if (itemsToSave.isEmpty) {
                            final timestamp = DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(now);
                            final photoPayload = <String, dynamic>{
                              'id': 'photo_${now.millisecondsSinceEpoch}',
                              'title': baseTitle,
                              'tag': 'Site Photo',
                              'timestamp': timestamp,
                              'capturedAt': now.toIso8601String(),
                              'uploadedAt': now.toIso8601String(),
                              'retentionMonths': retentionMonths,
                              'reservedUntil': reservedUntil,
                              'capturedBy': 'Site Supervisor',
                              'imagePath': null,
                              'hasImage': false,
                              'isUploaded': false,
                            };
                            onPhotoAdded(photoPayload);
                            Navigator.pop(modalContext);
                            return;
                          }

                          for (var i = 0; i < itemsToSave.length; i++) {
                            final item = itemsToSave[i];
                            final photoTime = item.capturedAt;
                            final timestamp = DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(photoTime);
                            final photoId =
                                'photo_${now.millisecondsSinceEpoch}_$i';
                            final itemTitle = itemsToSave.length > 1
                                ? '$baseTitle (${i + 1})'
                                : baseTitle;

                            final photoPayload = <String, dynamic>{
                              'id': photoId,
                              'title': itemTitle,
                              'tag': 'Site Photo',
                              'timestamp': timestamp,
                              'capturedAt': photoTime.toIso8601String(),
                              'uploadedAt': now.toIso8601String(),
                              'retentionMonths': retentionMonths,
                              'reservedUntil': reservedUntil,
                              'capturedBy': 'Site Supervisor',
                              'imagePath': item.path,
                              'hasImage': true,
                              'isUploaded': true,
                            };

                            onPhotoAdded(photoPayload);

                            if (CloudStorageService.isAvailable) {
                              CloudStorageService.uploadSitePhoto(
                                projectId: projId,
                                projectName: projectName,
                                filePath: item.path,
                                bytes: item.bytes,
                                title: itemTitle,
                                tag: 'Site Photo',
                                capturedBy: 'Site Supervisor',
                                retentionMonths: retentionMonths,
                              ).then((uploadRes) {
                                if (uploadRes == null) {
                                  if (context.mounted) {
                                    AppNotification.show(
                                      context,
                                      message:
                                          'Photo saved on phone. It will upload when you\'re back online.',
                                      backgroundColor: AppColors.warning,
                                    );
                                  }
                                  return;
                                }
                                final projects = StorageService.getProjects();
                                final pIdx = projects.indexWhere(
                                  (p) =>
                                      p['id'] == project['id'] ||
                                      p['name'] == projectName,
                                );
                                if (pIdx != -1 &&
                                    projects[pIdx]['photos'] is List) {
                                  final photos = List<Map<String, dynamic>>.from(
                                    (projects[pIdx]['photos'] as List).map(
                                      (e) =>
                                          Map<String, dynamic>.from(e as Map),
                                    ),
                                  );
                                  final phIdx = photos.indexWhere(
                                    (ph) => ph['id'] == photoId,
                                  );
                                  if (phIdx != -1) {
                                    photos[phIdx]['storagePath'] =
                                        uploadRes.storagePath;
                                    photos[phIdx]['downloadUrl'] =
                                        uploadRes.downloadUrl;
                                    photos[phIdx]['imageUrl'] =
                                        uploadRes.downloadUrl;
                                    projects[pIdx]['photos'] = photos;
                                    StorageService.saveProjects(projects);
                                    StorageService.cloudSyncNotifier.value =
                                        StorageService.cloudSyncNotifier.value +
                                        1;
                                  }
                                }
                              });
                            }
                          }
                          Navigator.pop(modalContext);
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text(
                          'Save & Attach Photo to Project',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPeach,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
