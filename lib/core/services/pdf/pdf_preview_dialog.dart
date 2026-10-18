import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import 'pdf_file_utils.dart';

/// Modal dialog for previewing, saving, and opening generated PDFs.
class PdfPreviewDialog extends StatefulWidget {
  final String title;
  final Future<Uint8List> Function() documentBuilder;

  const PdfPreviewDialog({
    super.key,
    required this.title,
    required this.documentBuilder,
  });

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  File? _savedFile;
  bool _isSaving = false;

  Future<File?> _saveDocument({bool openAfterSave = false}) async {
    if (_isSaving) return null;
    setState(() => _isSaving = true);

    try {
      final bytes = await widget.documentBuilder();
      final file = await PdfFileUtils.savePdfToDisk(
        bytes: bytes,
        fileName: widget.title,
      );

      if (mounted) {
        setState(() {
          _savedFile = file;
          _isSaving = false;
        });
      }

      if (file != null && openAfterSave) {
        await PdfFileUtils.openPdfFile(file.path);
      }
      return file;
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: AppSizes.borderRadiusMd),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 860,
        height: 720,
        child: Column(
          children: [
            // Top Modal Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.brandPeach,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_savedFile == null) ...[
                        ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _saveDocument(openAfterSave: false),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save to Downloads',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPeach,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.borderRadiusSm,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _saveDocument(openAfterSave: true),
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: const Text('Open in Viewer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.borderRadiusSm,
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: AppSizes.borderRadiusSm,
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Saved to Downloads',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              PdfFileUtils.openPdfFile(_savedFile!.path),
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: const Text('Open PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPeach,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.borderRadiusSm,
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // PDF Interactive Preview
            Expanded(
              child: PdfPreview(
                build: (format) => widget.documentBuilder(),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                loadingWidget: const Center(child: CircularProgressIndicator()),
                pdfFileName: '${widget.title.replaceAll(' ', '_')}.pdf',
                onError: (context, error) {
                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: AppSizes.borderRadiusMd,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandPeach.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 48,
                              color: AppColors.brandPeach,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Document ready for export. Save directly to your Downloads folder or open with your system PDF reader.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightSecondary
                                  : AppColors.textDarkSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_savedFile == null) ...[
                                ElevatedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () =>
                                            _saveDocument(openAfterSave: false),
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _isSaving
                                        ? 'Saving...'
                                        : 'Save to Downloads',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandPeach,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSizes.borderRadiusSm,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () =>
                                            _saveDocument(openAfterSave: true),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Open System Viewer'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSizes.borderRadiusSm,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () => PdfFileUtils.openPdfFile(
                                    _savedFile!.path,
                                  ),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Open Saved PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandPeach,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSizes.borderRadiusSm,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
