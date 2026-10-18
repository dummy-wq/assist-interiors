import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_notification.dart';

/// Central service for native telephony and dialer interactions.
///
/// When [dialNumber] is called with a phone number, it invokes the OS `tel:` scheme
/// using [LaunchMode.externalApplication], which hands off execution directly to the
/// device's phone application (call mode) with the number pre-populated on the keypad.
///
/// Importantly, this uses `ACTION_DIAL` (rather than `ACTION_CALL`), so the number is
/// entered on the dialer without automatically ringing or placing the call, allowing
/// the user to review the number and press call when ready.
class PhoneCallService {
  PhoneCallService._();

  /// Formats and dials [phoneNumber] into the system phone dialer.
  ///
  /// Strips formatting characters (spaces, dashes, parens) while preserving the leading `+`
  /// for international country codes.
  static Future<bool> dialNumber(
    BuildContext context, {
    required String phoneNumber,
    String? contactName,
  }) async {
    final cleanNumber = cleanPhoneNumber(phoneNumber);
    if (cleanNumber.isEmpty) {
      AppNotification.show(
        context,
        message: 'No valid phone number found to dial.',
      );
      return false;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    HapticFeedback.lightImpact();
    try {
      // First attempt with externalApplication to directly transition into native call mode
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback attempt with platformDefault
        final bool fallbackLaunched = await launchUrl(phoneUri);
        if (!fallbackLaunched && context.mounted) {
          _notifyDialAttempt(context, cleanNumber, contactName);
        }
        return fallbackLaunched;
      }
      return true;
    } catch (_) {
      // If running on a desktop, browser, or emulator without a dialer app, notify cleanly
      if (context.mounted) {
        _notifyDialAttempt(context, cleanNumber, contactName);
      }
      return false;
    }
  }

  /// Extracts digits and optional leading '+' from raw phone strings.
  static String cleanPhoneNumber(String raw) {
    return raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static void _notifyDialAttempt(
    BuildContext context,
    String number,
    String? contactName,
  ) {
    final displayName = contactName != null ? '$contactName ($number)' : number;
    AppNotification.show(
      context,
      message: 'Opening phone dialer for $displayName...',
    );
  }
}
