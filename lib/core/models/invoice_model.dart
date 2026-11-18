import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class InvoiceModel {
  final String id;
  final String client;
  final String? project;
  final String? projectId;
  final String? leadId;
  final String? leadName;
  final String? title;
  final String date;
  final String amount;
  final String status;
  final Color statusColor;
  final String? qrCodePath;
  final String? qrCodeBase64;
  final String? upiId;
  final String? invoiceNumber;
  final String? dueDate;
  final String? notes;

  const InvoiceModel({
    required this.id,
    required this.client,
    this.project,
    this.projectId,
    this.leadId,
    this.leadName,
    this.title,
    required this.date,
    required this.amount,
    this.status = 'Payment Pending',
    this.statusColor = AppColors.warning,
    this.qrCodePath,
    this.qrCodeBase64,
    this.upiId = AppConstants.defaultUpiId,
    this.invoiceNumber,
    this.dueDate,
    this.notes,
  });

  InvoiceModel copyWith({
    String? id,
    String? client,
    String? project,
    String? projectId,
    String? leadId,
    String? leadName,
    String? title,
    String? date,
    String? amount,
    String? status,
    Color? statusColor,
    String? qrCodePath,
    String? qrCodeBase64,
    String? upiId,
    String? invoiceNumber,
    String? dueDate,
    String? notes,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      client: client ?? this.client,
      project: project ?? this.project,
      projectId: projectId ?? this.projectId,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      title: title ?? this.title,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      qrCodePath: qrCodePath ?? this.qrCodePath,
      qrCodeBase64: qrCodeBase64 ?? this.qrCodeBase64,
      upiId: upiId ?? this.upiId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
    );
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    Color resolvedColor = AppColors.warning;
    if (map['statusColor'] is int) {
      resolvedColor = Color(map['statusColor'] as int);
    } else if (map['statusColor'] is Color) {
      resolvedColor = map['statusColor'] as Color;
    } else if (map['color'] is Color) {
      resolvedColor = map['color'] as Color;
    } else if (map['color'] is int) {
      resolvedColor = Color(map['color'] as int);
    }

    final id = docId ??
        map['id']?.toString() ??
        map['invoiceNumber']?.toString() ??
        'INV-${DateTime.now().millisecondsSinceEpoch}';

    return InvoiceModel(
      id: id,
      client: map['client']?.toString() ?? 'Milestone Billing',
      project: map['project']?.toString(),
      projectId: map['projectId']?.toString() ?? map['project_id']?.toString(),
      leadId: map['leadId']?.toString() ??
          map['lead_id']?.toString() ??
          map['originLeadId']?.toString(),
      leadName: map['leadName']?.toString() ?? map['client']?.toString(),
      title: map['title']?.toString(),
      date: map['date']?.toString() ?? 'Today',
      amount: map['amount']?.toString() ?? '₹ 0',
      status: map['status']?.toString() ?? 'Payment Pending',
      statusColor: resolvedColor,
      qrCodePath: map['qrCodePath']?.toString() ??
          map['qr_code_path']?.toString() ??
          map['qrCodeUrl']?.toString(),
      qrCodeBase64: map['qrCodeBase64']?.toString(),
      upiId: map['upiId']?.toString() ?? AppConstants.defaultUpiId,
      invoiceNumber: map['invoiceNumber']?.toString() ?? id,
      dueDate: map['dueDate']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'project': project,
      'projectId': projectId,
      'leadId': leadId,
      'leadName': leadName,
      'title': title,
      'date': date,
      'amount': amount,
      'status': status,
      'statusColor': statusColor.toARGB32(),
      'qrCodePath': ?qrCodePath,
      'qrCodeBase64': ?qrCodeBase64,
      'upiId': ?upiId,
      'invoiceNumber': ?invoiceNumber,
      'dueDate': ?dueDate,
      'notes': ?notes,
    };
  }
}
