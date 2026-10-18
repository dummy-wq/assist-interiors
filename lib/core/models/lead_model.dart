import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

class LeadModel {
  final String id;
  final String client;
  final String phone;
  final String? email;
  final String location;
  final String scope;
  final String estValue;
  final String referralSource;
  final String referralBy;
  final String stage;
  final String nextCallDate;
  final String nextCallTime;
  final String reminderNote;
  final bool hasReminder;
  final bool isReminderDismissed;
  final List<Map<String, dynamic>> notes;
  final String date;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeadModel({
    required this.id,
    required this.client,
    required this.phone,
    this.email,
    required this.location,
    required this.scope,
    required this.estValue,
    this.referralSource = 'Client Referral',
    this.referralBy = '',
    this.stage = 'New Inquiry',
    this.nextCallDate = '',
    this.nextCallTime = '11:00 AM',
    this.reminderNote = '',
    this.hasReminder = false,
    this.isReminderDismissed = false,
    this.notes = const [],
    required this.date,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  String get name => client;
  String get status => stage;

  bool get isDueToday {
    if (nextCallDate.isEmpty) return false;
    final now = DateTime.now();
    final todayStr1 = DateFormat('dd MMM yyyy').format(now);
    final todayStr2 = DateFormat('yyyy-MM-dd').format(now);
    final todayStr3 = DateFormat('d MMM yyyy').format(now);
    return nextCallDate == todayStr1 ||
        nextCallDate == todayStr2 ||
        nextCallDate == todayStr3;
  }

  bool get isOverdue {
    if (nextCallDate.isEmpty) return false;
    if (isDueToday) return false;
    try {
      DateTime? parsed;
      if (nextCallDate.contains('-')) {
        parsed = DateTime.tryParse(nextCallDate);
      } else {
        parsed = DateFormat('dd MMM yyyy').parse(nextCallDate);
      }
      if (parsed != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        return parsed.isBefore(todayStart);
      }
    } catch (_) {}
    return false;
  }

  LeadModel copyWith({
    String? id,
    String? client,
    String? phone,
    String? email,
    String? location,
    String? scope,
    String? estValue,
    String? referralSource,
    String? referralBy,
    String? stage,
    String? nextCallDate,
    String? nextCallTime,
    String? reminderNote,
    bool? hasReminder,
    bool? isReminderDismissed,
    List<Map<String, dynamic>>? notes,
    String? date,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      client: client ?? this.client,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      scope: scope ?? this.scope,
      estValue: estValue ?? this.estValue,
      referralSource: referralSource ?? this.referralSource,
      referralBy: referralBy ?? this.referralBy,
      stage: stage ?? this.stage,
      nextCallDate: nextCallDate ?? this.nextCallDate,
      nextCallTime: nextCallTime ?? this.nextCallTime,
      reminderNote: reminderNote ?? this.reminderNote,
      hasReminder: hasReminder ?? this.hasReminder,
      isReminderDismissed: isReminderDismissed ?? this.isReminderDismissed,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LeadModel.fromMap(Map<String, dynamic> map) {
    Color itemColor = AppColors.brandPeach;
    if (map['color'] is int) {
      itemColor = Color(map['color'] as int);
    } else if (map['color'] is Color) {
      itemColor = map['color'] as Color;
    }

    List<Map<String, dynamic>> notesList = [];
    if (map['notes'] is List) {
      notesList = (map['notes'] as List)
          .map((n) => Map<String, dynamic>.from(n as Map))
          .toList();
    }

    return LeadModel(
      id:
          map['id']?.toString() ??
          'lead_${DateTime.now().millisecondsSinceEpoch}',
      client: (map['client'] ?? map['name'] ?? 'Prospective Client').toString(),
      phone: (map['phone'] ?? '+91 98000 00000').toString(),
      email: map['email']?.toString(),
      location: (map['location'] ?? 'Site Consultation Pending').toString(),
      scope: (map['scope'] ?? 'Turnkey Interior Scope').toString(),
      estValue: (map['estValue'] ?? '₹ 25L').toString(),
      referralSource: (map['referralSource'] ?? 'Client Referral').toString(),
      referralBy: (map['referralBy'] ?? '').toString(),
      stage: (map['stage'] ?? map['status'] ?? 'New Inquiry').toString(),
      nextCallDate: (map['nextCallDate'] ?? '').toString(),
      nextCallTime: (map['nextCallTime'] ?? '11:00 AM').toString(),
      reminderNote: (map['reminderNote'] ?? '').toString(),
      hasReminder:
          map['hasReminder'] as bool? ??
          ((map['nextCallDate']?.toString() ?? '').isNotEmpty),
      isReminderDismissed: map['isReminderDismissed'] as bool? ?? false,
      notes: notesList,
      date: (map['date'] ?? DateFormat('dd MMM yyyy').format(DateTime.now()))
          .toString(),
      color: itemColor,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'name': client,
      'phone': phone,
      'email': email,
      'location': location,
      'scope': scope,
      'estValue': estValue,
      'referralSource': referralSource,
      'referralBy': referralBy,
      'stage': stage,
      'status': stage,
      'nextCallDate': nextCallDate,
      'nextCallTime': nextCallTime,
      'reminderNote': reminderNote,
      'hasReminder': hasReminder,
      'isReminderDismissed': isReminderDismissed,
      'notes': notes,
      'date': date,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
