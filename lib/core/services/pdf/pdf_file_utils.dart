import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../utils/currency_utils.dart';

/// Utilities for currency formatting, amount parsing, and PDF file operations.
class PdfFileUtils {
  PdfFileUtils._();

  /// Formats currency safely for standard PDF Helvetica font (avoiding unicode symbol crashes).
  static String formatInr(num amount) =>
      CurrencyUtils.formatInr(amount, symbol: 'INR ');

  /// Parses raw strings like "₹ 3,50,000" or "450000" into a safe double.
  static double parseAmount(String? raw) => CurrencyUtils.parseDouble(raw);

  /// Exports and saves the generated PDF bytes to the user's Downloads or Documents directory.
  static Future<File?> savePdfToDisk({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      Directory? targetDir;
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final downloads = Directory('$home/Downloads');
        if (downloads.existsSync()) {
          targetDir = downloads;
        } else {
          final documents = Directory('$home/Documents');
          if (documents.existsSync()) {
            targetDir = documents;
          }
        }
      }
      targetDir ??= Directory.current;

      final sanitized = fileName
          .replaceAll(RegExp(r'[^\w\.-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final finalName = sanitized.endsWith('.pdf')
          ? sanitized
          : '$sanitized.pdf';
      final file = File('${targetDir.path}/$finalName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error saving PDF to disk: $e');
      return null;
    }
  }

  /// Launches the PDF file with the system default viewer or xdg-open.
  static Future<bool> openPdfFile(String filePath) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [filePath]);
        if (result.exitCode == 0) return true;
      }
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not open file: $e');
    }
    return false;
  }

  /// Displays a clean floating notification indicating the PDF file was saved,
  /// equipped with Open and Dismiss actions plus a dedicated close button.
  static void showExportSuccessSnackBar(BuildContext context, File file) {
    AppNotification.show(
      context,
      message: 'Saved to ${file.path}',
      backgroundColor: AppColors.success,
      showCloseIcon: true,
      closeIconColor: Colors.white,
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved to ${file.path}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        textColor: Colors.white,
        label: 'OPEN',
        onPressed: () => openPdfFile(file.path),
      ),
    );
  }
}
