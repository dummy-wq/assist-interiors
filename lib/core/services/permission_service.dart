import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/studio_dialog.dart';

import '../utils/app_notification.dart';
/// Centralized runtime permission helper for Camera, Photos/Gallery, and Files.
/// Gracefully returns `true` on web, desktop, or headless widget tests where
/// mobile runtime permission channels are unavailable.
class PermissionService {
  PermissionService._();

  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Requests Camera access before opening the camera.
  static Future<bool> requestCamera(BuildContext context) async {
    return _requestPermission(
      context,
      permission: Permission.camera,
      title: 'Camera Access Needed',
      rationale:
          'Assist Interiors needs camera access so you can take site progress photos and QR scans.',
    );
  }

  /// Requests Photos/Media (Android 13+/iOS) or Storage (older Android) access
  /// before picking gallery images, CAD files, or saving ZIP archives.
  static Future<bool> requestMediaOrStorage(BuildContext context) async {
    if (!_isMobilePlatform) return true;
    try {
      // Try Permission.photos first (covers Android 13+ READ_MEDIA_IMAGES and iOS Photos).
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      final requested = await Permission.photos.request();
      if (requested.isGranted || requested.isLimited) {
        return true;
      }

      // Fallback for older Android (API <= 32) where Permission.storage applies.
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
        if (storageStatus.isPermanentlyDenied && context.mounted) {
          await _showSettingsDialog(
            context,
            title: 'Photos & Files Access Needed',
            rationale:
                'Please allow Photos & Files access in Settings so you can attach images, CAD files, and save ZIP archives.',
          );
          return false;
        }
      }

      if (requested.isPermanentlyDenied && context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Photos & Files Access Needed',
          rationale:
              'Please allow Photos & Files access in Settings so you can attach images, CAD files, and save ZIP archives.',
        );
        return false;
      }

      return false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('PermissionService.requestMediaOrStorage notice: $e');
      return true;
    }
  }

  static Future<bool> _requestPermission(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String rationale,
  }) async {
    if (!_isMobilePlatform) return true;
    try {
      final status = await permission.status;
      if (status.isGranted) return true;

      final result = await permission.request();
      if (result.isGranted) return true;

      if ((result.isPermanentlyDenied || result.isRestricted) &&
          context.mounted) {
        await _showSettingsDialog(context, title: title, rationale: rationale);
      } else if (context.mounted) {
        AppNotification.show(context, message: '$title: $rationale');
      }
      return false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('PermissionService notice: $e');
      return true;
    }
  }

  static Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String rationale,
  }) async {
    await showStudioDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
