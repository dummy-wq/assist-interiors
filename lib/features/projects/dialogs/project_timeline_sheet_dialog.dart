import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/spreadsheet_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/studio_dialog.dart';

import '../../../core/utils/app_notification.dart';
/// Compact dialog for linking a project timeline Excel (.xlsx, .xls, .csv)
/// file and opening it externally in Excel, Google Sheets, or the system viewer.
class ProjectTimelineSheetDialog {
  ProjectTimelineSheetDialog._();

  static const Color excelGreen = Color(0xFF107C41);
  static const Color excelDarkGreen = Color(0xFF0C5A2F);

  /// Returns true only when [rawSheet] represents an actual user-linked file
  /// rather than an empty or legacy auto-generated placeholder.
  static bool hasLinkedExcelFile(dynamic rawSheet) {
    if (rawSheet is! Map) return false;
    if (rawSheet['removed'] == true) return false;
    final downloadUrl = (rawSheet['downloadUrl'] ?? rawSheet['fileUrl'] ?? '')
        .toString()
        .trim();
    final localPath = (rawSheet['localPath'] ?? rawSheet['filePath'] ?? '')
        .toString()
        .trim();
    final isUserUploaded = rawSheet['isUserUploaded'] == true;
    return isUserUploaded || downloadUrl.isNotEmpty || localPath.isNotEmpty;
  }

  static void show(
    BuildContext context, {
    required Map<String, dynamic> project,
    required Color projectAccent,
    void Function(SpreadsheetData updatedSheet)? onSheetUpdated,
    VoidCallback? onSheetRemoved,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectName = project['name'] as String? ?? 'Project Site';

    Map<String, dynamic>? linkedFile;
    final rawSheet = project['timelineSpreadsheet'];
    if (hasLinkedExcelFile(rawSheet)) {
      linkedFile = Map<String, dynamic>.from(rawSheet as Map);
    }

    bool isUploading = false;

    showStudioDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setDialogState) {
            final fileName =
                (linkedFile?['fileName'] ?? 'Project_Timeline.xlsx').toString();
            final downloadUrl =
                (linkedFile?['downloadUrl'] ?? linkedFile?['fileUrl'] ?? '')
                    .toString()
                    .trim();
            final localPath =
                (linkedFile?['localPath'] ?? linkedFile?['filePath'] ?? '')
                    .toString()
                    .trim();
            final fileSize = (linkedFile?['fileSize'] ?? '').toString().trim();
            final storagePath =
                (linkedFile?['storagePath'] ?? '').toString().trim();

            Future<void> uploadExcelFile() async {
              if (isUploading) return;
              try {
                final allowed =
                    await PermissionService.requestMediaOrStorage(modalCtx);
                if (!allowed) return;
                setDialogState(() => isUploading = true);
                final picked = await FilePicker.pickFile(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx', 'xls', 'csv'],
                );
                if (picked == null) return;

                final bytes = await picked.readAsBytes();
                final sizeKb = (bytes.length / 1024).toStringAsFixed(1);
                final formattedSize = bytes.length >= 1024 * 1024
                    ? '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB'
                    : '$sizeKb KB';

                CloudUploadResult? cloudRes;
                if (CloudStorageService.isAvailable) {
                  cloudRes = await CloudStorageService.uploadDesignAsset(
                    projectId: project['id']?.toString(),
                    projectName: projectName,
                    filePath: picked.path,
                    bytes: bytes,
                    fileName: picked.name,
                    originalFileName: picked.name,
                    title: '$projectName - Timeline Schedule',
                    assetType: 'Excel Timeline',
                    contentType: picked.name.toLowerCase().endsWith('.csv')
                        ? 'text/csv'
                        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  );
                }

                final newSheetData = SpreadsheetData(
                  fileName: picked.name,
                  sheetName: 'Linked Excel File',
                  headers: const [],
                  rows: const [],
                  lastUpdated: DateTime.now().toIso8601String(),
                );

                final updatedMap = <String, dynamic>{
                  ...newSheetData.toMap(),
                  'fileName': picked.name,
                  'fileSize': formattedSize,
                  'isUserUploaded': true,
                  if (picked.path != null && picked.path!.isNotEmpty)
                    'localPath': picked.path,
                  if (cloudRes != null) ...{
                    'storagePath': cloudRes.storagePath,
                    'downloadUrl': cloudRes.downloadUrl,
                    'fileUrl': cloudRes.downloadUrl,
                  },
                };

                setDialogState(() {
                  linkedFile = updatedMap;
                });
                project['timelineSpreadsheet'] = updatedMap;
                onSheetUpdated?.call(newSheetData);

                if (modalCtx.mounted) {
                  AppNotification.show(modalCtx, message: 'Linked Excel file "${picked.name}".', backgroundColor: AppColors.success);
                }
              } catch (e) {
                debugPrint('Error linking Excel file: $e');
              } finally {
                if (modalCtx.mounted) {
                  setDialogState(() => isUploading = false);
                }
              }
            }

            Future<void> openExternally() async {
              try {
                if (downloadUrl.startsWith('http://') ||
                    downloadUrl.startsWith('https://')) {
                  final uri = Uri.parse(downloadUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return;
                }
                if (!kIsWeb && localPath.isNotEmpty) {
                  final uri = Uri.file(localPath);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return;
                }
                if (modalCtx.mounted) {
                  AppNotification.show(modalCtx, message: 'File URL not available yet. Please re-upload the Excel file to sync it to cloud storage.', backgroundColor: AppColors.warning);
                }
              } catch (e) {
                if (modalCtx.mounted) {
                  AppNotification.show(modalCtx, message: 'Could not launch external viewer: $e', backgroundColor: AppColors.error);
                }
              }
            }

            Future<void> removeExcelFile() async {
              if (storagePath.isNotEmpty || downloadUrl.isNotEmpty) {
                CloudStorageService.deleteFile(
                  storagePath: storagePath.isNotEmpty ? storagePath : null,
                  downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : null,
                );
              }
              setDialogState(() {
                linkedFile = null;
              });
              project['timelineSpreadsheet'] = {'removed': true};
              onSheetRemoved?.call();
            }

            return Dialog(
              backgroundColor:
                  isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
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
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? excelDarkGreen : excelGreen,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: const Icon(
                              Icons.table_chart_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'PROJECT TIMELINE SPREADSHEET',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.22),
                                        borderRadius:
                                            BorderRadius.circular(3.0),
                                      ),
                                      child: const Text(
                                        'EXCEL .XLSX',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  projectName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: linkedFile != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardElevated
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: excelGreen.withValues(alpha: 0.45),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: excelGreen.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6.0),
                                        ),
                                        child: const Icon(
                                          Icons.description_rounded,
                                          color: excelGreen,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fileName,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.textLightPrimary
                                                    : AppColors.textDarkPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (fileSize.isNotEmpty)
                                                  fileSize,
                                                downloadUrl.isNotEmpty
                                                    ? 'Synced to Cloud'
                                                    : 'Saved Locally',
                                              ].join(' • '),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.textLightMuted
                                                    : AppColors.textDarkMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InstantPressFeedback(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: excelGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed: openExternally,
                                    icon: const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 17,
                                    ),
                                    label: const Text(
                                      'Open Externally in Excel / Viewer',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            isUploading ? null : uploadExcelFile,
                                        icon: const Icon(
                                          Icons.file_upload_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          isUploading
                                              ? 'Uploading...'
                                              : 'Replace File',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: BorderSide(
                                            color: AppColors.error
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        onPressed: removeExcelFile,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                        label: const Text(
                                          'Remove File',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardElevated
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.table_view_rounded,
                                        size: 36,
                                        color:
                                            excelGreen.withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No Excel Timeline File Linked',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.textLightPrimary
                                              : AppColors.textDarkPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Upload an Excel (.xlsx, .xls) or .csv file to link it to this project for external viewing.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InstantPressFeedback(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: excelGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    onPressed:
                                        isUploading ? null : uploadExcelFile,
                                    icon: isUploading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.file_upload_outlined,
                                            size: 17,
                                          ),
                                    label: Text(
                                      isUploading
                                          ? 'Uploading Excel File...'
                                          : 'Upload & Link Excel File (.xlsx)',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
