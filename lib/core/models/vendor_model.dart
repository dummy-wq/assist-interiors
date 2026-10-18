import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class VendorModel {
  final String id;
  final String name;
  final String category;
  final String contactPerson;
  final String phone;
  final String email;
  final String city;
  final String paymentStatus;
  final String amountDue;
  final String notes;
  final String rating;
  final String onTime;
  final String activeOrders;
  final String status;
  final int openPOs;
  final String outstanding;
  final Color color;

  const VendorModel({
    required this.id,
    required this.name,
    required this.category,
    this.contactPerson = 'Site Rep',
    this.phone = '+91 98000 00000',
    this.email = '',
    this.city = 'Delhi NCR',
    this.paymentStatus = 'Pending',
    this.amountDue = '₹ 0',
    this.notes = '',
    this.rating = '5.0',
    this.onTime = '100%',
    this.activeOrders = '0 Active Purchase Orders',
    this.status = 'Active',
    this.openPOs = 0,
    this.outstanding = '₹ 0',
    this.color = AppColors.info,
  });

  VendorModel copyWith({
    String? id,
    String? name,
    String? category,
    String? contactPerson,
    String? phone,
    String? email,
    String? city,
    String? paymentStatus,
    String? amountDue,
    String? notes,
    String? rating,
    String? onTime,
    String? activeOrders,
    String? status,
    int? openPOs,
    String? outstanding,
    Color? color,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountDue: amountDue ?? this.amountDue,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      onTime: onTime ?? this.onTime,
      activeOrders: activeOrders ?? this.activeOrders,
      status: status ?? this.status,
      openPOs: openPOs ?? this.openPOs,
      outstanding: outstanding ?? this.outstanding,
      color: color ?? this.color,
    );
  }

  factory VendorModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    Color resolvedColor = AppColors.info;
    if (map['color'] is int) {
      resolvedColor = Color(map['color'] as int);
    } else if (map['color'] is Color) {
      resolvedColor = map['color'] as Color;
    }

    return VendorModel(
      id:
          docId ??
          map['id']?.toString() ??
          'vendor_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Trade Partner',
      category: map['category']?.toString() ?? 'General Works',
      contactPerson: map['contactPerson']?.toString() ?? 'Site Rep',
      phone: map['phone']?.toString() ?? '+91 98000 00000',
      email: map['email']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Delhi NCR',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Pending',
      amountDue:
          map['amountDue']?.toString() ??
          map['outstanding']?.toString() ??
          '₹ 0',
      notes: map['notes']?.toString() ?? '',
      rating: map['rating']?.toString() ?? '5.0',
      onTime: map['onTime']?.toString() ?? '100%',
      activeOrders:
          map['activeOrders']?.toString() ?? '0 Active Purchase Orders',
      status: map['status']?.toString() ?? 'Active',
      openPOs: (map['openPOs'] as num?)?.toInt() ?? 0,
      outstanding:
          map['outstanding']?.toString() ??
          map['amountDue']?.toString() ??
          '₹ 0',
      color: resolvedColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'city': city,
      'paymentStatus': paymentStatus,
      'amountDue': amountDue,
      'notes': notes,
      'rating': rating,
      'onTime': onTime,
      'activeOrders': activeOrders,
      'status': status,
      'openPOs': openPOs,
      'outstanding': outstanding,
      'color': color.toARGB32(),
    };
  }
}
