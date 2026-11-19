import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/app_modal_sheet.dart';

import '../../../core/utils/app_notification.dart';
class TakeSitePhotoSheet {
  TakeSitePhotoSheet._();

  /// One-tap entry point used by Supervisors' large "Take Site Photo" button:
  /// picks a project (or uses the only active project) and opens [TakeSitePhotoSheet].
  static void openQuickCapture(BuildContext context) {
    final projects = StorageService.getProjects();
    if (projects.isEmpty) {
      ScaffoldMessenger.maybeOf(context)
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No projects yet. Add a project first, then take site photos.',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
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
            ScaffoldMessenger.maybeOf(context)
              ?..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Site inspection photo added to ${projects[index]['name']}',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
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
                  'Select which site you are taking a photo of:',
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
    String selectedTag = 'Living Room';
    String? selectedPreset;
    String? capturedImagePath;
    Uint8List? capturedImageBytes;
    DateTime? capturedAt;
    bool isCapturing = false;

    final tags = [
      'Living Room',
      'Master Bed',
      'Kitchen',
      'Bath',
      'Balcony',
      'MEP & Ceiling',
      'Flooring',
      'Joinery',
      'Entire Site',
    ];

    final presets = [
      'Civil Demolition & Wet Masonry',
      'False Ceiling Framing & Laser Alignment',
      'Electrical Conduiting & Switchbox Grooves',
      'Italian Marble Laying & Leveling',
      'Modular Kitchen Carcass & Countertop Fitting',
      'Wardrobe Carcass & Veneer Pressing',
      'Bathroom Waterproofing & Vitrified Tiling',
      'Wall Primer, Putty & PU Painting',
      'Architectural Lighting & Fixtures',
      'Final Snag Rectification & Deep Clean',
    ];

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom +
                    AppSizes.sheetBottomPadding(modalContext),
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
                                'Upload Mode: Choose an existing photo from Gallery or Files',
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

                    // Photo Capture & Timestamp Card
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
                                    capturedAt != null
                                        ? 'CAPTURED AT'
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
                                  ).format(capturedAt ?? DateTime.now()),
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
                          if (capturedImagePath != null &&
                              !kIsWeb &&
                              File(capturedImagePath!).existsSync()) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 155,
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(capturedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.75),
                                          borderRadius:
                                              BorderRadius.circular(3.0),
                                          border: Border.all(
                                            color: AppColors.brandPeach,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 11,
                                              color: AppColors.brandPeach,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'PHOTO ATTACHED',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                                color: AppColors.brandPeach,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.78),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 10,
                                              color: AppColors.brandPeach,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              DateFormat(
                                                'dd MMM yyyy • hh:mm a',
                                              ).format(
                                                capturedAt ?? DateTime.now(),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Zone: $selectedTag — Tap Take Photo, Gallery, or File below.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLightSecondary
                                    : AppColors.textDarkSecondary,
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
                                                  capturedImagePath =
                                                      file.path;
                                                  capturedImageBytes =
                                                      pickedBytes;
                                                  capturedAt = DateTime.now();
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Camera capture error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(modalContext, message: 'Camera error: ${e.toString()}', backgroundColor: AppColors.error);
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
                                        borderRadius:
                                            BorderRadius.circular(4.0),
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
                                              final XFile? file =
                                                  await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1920,
                                                maxHeight: 1080,
                                                imageQuality: 85,
                                              );
                                              if (file != null) {
                                                final pickedBytes =
                                                    await file.readAsBytes();
                                                setModalState(() {
                                                  capturedImagePath =
                                                      file.path;
                                                  capturedImageBytes =
                                                      pickedBytes;
                                                  capturedAt = DateTime.now();
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Gallery pick error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(modalContext, message: 'Gallery error: ${e.toString()}', backgroundColor: AppColors.error);
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
                                        borderRadius:
                                            BorderRadius.circular(4.0),
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
                                              final result =
                                                  await FilePicker.pickFile(
                                                type: FileType.image,
                                              );
                                              if (result != null) {
                                                final pickedBytes =
                                                    await result.readAsBytes();
                                                setModalState(() {
                                                  capturedImagePath =
                                                      result.path ??
                                                      result.name;
                                                  capturedImageBytes =
                                                      pickedBytes;
                                                  capturedAt = DateTime.now();
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'File picker photo error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                AppNotification.show(modalContext, message: 'File access error: ${e.toString()}', backgroundColor: AppColors.error);
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
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (capturedImagePath != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setModalState(() {
                                capturedImagePath = null;
                                capturedAt = null;
                              }),
                              borderRadius: BorderRadius.circular(3.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 12,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Retake / Clear Photo',
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

                    // Area / Zone Selector
                    Text(
                      'SITE ZONE / ROOM',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tags.map((tag) {
                          final isSelected = selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.black
                                      : (isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.brandPeach,
                              backgroundColor: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightBackground,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.brandPeach
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: 0.8,
                                ),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() => selectedTag = tag);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Milestone Presets
                    Text(
                      'OR CHOOSE INSPECTION MILESTONE PRESET',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: presets.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final item = presets[index];
                          final isSelected = selectedPreset == item;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedPreset = item;
                                textController.text = item;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.camera_alt_outlined,
                                    size: 14,
                                    color: isSelected
                                        ? AppColors.brandPeach
                                        : (isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.brandPeach
                                            : (isDark
                                                ? AppColors.textLightPrimary
                                                : AppColors.textDarkPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Description
                    Text(
                      'CUSTOM PHOTO TITLE / OBSERVATION NOTE',
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
                        hintText: 'e.g. Master bathroom Italian marble tile dry lay...',
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
                          final title = textController.text.trim().isNotEmpty
                              ? textController.text.trim()
                              : (selectedPreset ??
                                  '$selectedTag Inspection Photo');
                          final now = DateTime.now();
                          final photoTime = capturedAt ?? now;
                          final timestamp = DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(photoTime);
                          final retentionMonths =
                              StorageService.getPhotoRetentionMonths();
                          final reservedUntil = DateFormat('dd MMM yyyy').format(
                            now.add(Duration(days: retentionMonths * 30)),
                          );
                          final photoId = 'photo_${now.millisecondsSinceEpoch}';
                          final projId = (project['id'] ?? '').toString();

                          final photoPayload = <String, dynamic>{
                            'id': photoId,
                            'title': title,
                            'tag': selectedTag,
                            'timestamp': timestamp,
                            'capturedAt': photoTime.toIso8601String(),
                            'uploadedAt': now.toIso8601String(),
                            'retentionMonths': retentionMonths,
                            'reservedUntil': reservedUntil,
                            'capturedBy': 'Site Supervisor',
                            'imagePath': capturedImagePath,
                            'hasImage': capturedImagePath != null,
                            'isUploaded': capturedImagePath != null,
                          };

                          onPhotoAdded(photoPayload);

                          if ((capturedImagePath != null ||
                                  capturedImageBytes != null) &&
                              CloudStorageService.isAvailable) {
                            CloudStorageService.uploadSitePhoto(
                              projectId: projId,
                              projectName: projectName,
                              filePath: capturedImagePath,
                              bytes: capturedImageBytes,
                              title: title,
                              tag: selectedTag,
                              capturedBy: 'Site Supervisor',
                              retentionMonths: retentionMonths,
                            ).then((uploadRes) {
                              if (uploadRes == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.maybeOf(context)
                                    ?..clearSnackBars()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Photo saved on phone. It will upload when you\'re back online.',
                                        ),
                                        backgroundColor: AppColors.warning,
                                        behavior: SnackBarBehavior.floating,
                                      ),
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
                                    (e) => Map<String, dynamic>.from(e as Map),
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
