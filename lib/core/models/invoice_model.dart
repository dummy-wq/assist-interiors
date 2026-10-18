import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class InvoiceModel {
  final String id;
  final String client;
  final String date;
  final String amount;
  final String status;
  final Color statusColor;

  const InvoiceModel({
    required this.id,
    required this.client,
    required this.date,
    required this.amount,
    this.status = 'Payment Pending',
    this.statusColor = AppColors.warning,
  });

  InvoiceModel copyWith({
    String? id,
    String? client,
    String? date,
    String? amount,
    String? status,
    Color? statusColor,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      client: client ?? this.client,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
    );
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    Color resolvedColor = AppColors.warning;
    if (map['statusColor'] is int) {
      resolvedColor = Color(map['statusColor'] as int);
    } else if (map['statusColor'] is Color) {
      resolvedColor = map['statusColor'] as Color;
    }

    return InvoiceModel(
      id:
          docId ??
          map['id']?.toString() ??
          'INV-${DateTime.now().millisecondsSinceEpoch}',
      client: map['client']?.toString() ?? 'Milestone Billing',
      date: map['date']?.toString() ?? 'Today',
      amount: map['amount']?.toString() ?? '₹ 0',
      status: map['status']?.toString() ?? 'Payment Pending',
      statusColor: resolvedColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'date': date,
      'amount': amount,
      'status': status,
      'statusColor': statusColor.toARGB32(),
    };
  }
}
