import 'package:intl/intl.dart';

/// Shared INR currency parsing and formatting utilities.
class CurrencyUtils {
  CurrencyUtils._();

  /// Parses an integer rupee amount from arbitrary display strings (e.g. `'₹ 1,57,500'`)
  /// or numeric values (`int`, `double`). Returns `0` when unparseable.
  static int parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final digits = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) return 0;
    return double.tryParse(digits)?.round() ?? 0;
  }

  /// Parses a numeric double from currency strings or numbers.
  static double parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    final clean = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) return 0.0;
    return double.tryParse(clean) ?? 0.0;
  }

  /// Parses budgets that may contain Indian unit suffixes (`cr`, `l`/`lac`/`lakh`, `k`).
  static int parseBudget(dynamic rawBudget) {
    if (rawBudget == null) return 0;
    final str = rawBudget.toString().trim();
    if (str.isEmpty) return 0;
    final lower = str.toLowerCase();
    final numVal = parseDouble(str);
    if (lower.contains('cr')) {
      return (numVal * 10000000).round();
    } else if (lower.contains('l') ||
        lower.contains('lac') ||
        lower.contains('lakh')) {
      return (numVal * 100000).round();
    } else if (lower.contains('k')) {
      return (numVal * 1000).round();
    }
    return numVal.round();
  }

  /// Formats [amount] using Indian numbering (`en_IN`).
  static String formatInr(
    num amount, {
    String symbol = '₹ ',
    int decimalDigits = 0,
  }) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}
