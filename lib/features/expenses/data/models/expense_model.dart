import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Categories of business operational expenses
enum ExpenseCategory {
  utilities('utilities', 'expense_cat_utilities', Icons.bolt_rounded, Color(0xFFF59E0B)),
  rent('rent', 'expense_cat_rent', Icons.storefront_rounded, Color(0xFF8B5CF6)),
  supplies('supplies', 'expense_cat_supplies', Icons.shopping_bag_outlined, Color(0xFF10B981)),
  maintenance('maintenance', 'expense_cat_maintenance', Icons.build_rounded, Color(0xFFEF4444)),
  transportation('transportation', 'expense_cat_transportation', Icons.local_shipping_rounded, Color(0xFF3B82F6)),
  marketing('marketing', 'expense_cat_marketing', Icons.campaign_rounded, Color(0xFFEC4899)),
  salaries('salaries', 'expense_cat_salaries', Icons.badge_rounded, Color(0xFF06B6D4)),
  government('government', 'expense_cat_government', Icons.account_balance_rounded, Color(0xFF64748B)),
  other('other', 'expense_cat_other', Icons.receipt_long_rounded, Color(0xFF6B7280));

  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.id, this.labelKey, this.icon, this.color);

  static ExpenseCategory fromString(String? val) {
    if (val == null || val.trim().isEmpty) return ExpenseCategory.other;
    final clean = val.trim().toLowerCase();
    for (final cat in ExpenseCategory.values) {
      if (cat.id == clean || cat.name.toLowerCase() == clean) {
        return cat;
      }
    }
    // Intelligent keyword matching (AR & EN)
    if (clean.contains('util') ||
        clean.contains('مرافق') ||
        clean.contains('مياه') ||
        clean.contains('ماء') ||
        clean.contains('كهرب') ||
        clean.contains('غاز') ||
        clean.contains('انترنت') ||
        clean.contains('إنترنت') ||
        clean.contains('فاتور') ||
        clean.contains('bill')) {
      return ExpenseCategory.utilities;
    }
    if (clean.contains('rent') || clean.contains('إيجار') || clean.contains('ايجار')) {
      return ExpenseCategory.rent;
    }
    if (clean.contains('salar') ||
        clean.contains('payroll') ||
        clean.contains('راتب') ||
        clean.contains('مرتب') ||
        clean.contains('رواتب') ||
        clean.contains('أجور') ||
        clean.contains('اجور') ||
        clean.contains('سلف')) {
      return ExpenseCategory.salaries;
    }
    if (clean.contains('suppl') ||
        clean.contains('مستلزم') ||
        clean.contains('تغليف') ||
        clean.contains('اكياس') ||
        clean.contains('أكياس') ||
        clean.contains('مطبوعات') ||
        clean.contains('كرتون')) {
      return ExpenseCategory.supplies;
    }
    if (clean.contains('maint') ||
        clean.contains('صيان') ||
        clean.contains('تصليح') ||
        clean.contains('ترميم') ||
        clean.contains('نظاف')) {
      return ExpenseCategory.maintenance;
    }
    if (clean.contains('trans') ||
        clean.contains('نقل') ||
        clean.contains('شحن') ||
        clean.contains('توصيل') ||
        clean.contains('بنزين') ||
        clean.contains('سولار') ||
        clean.contains('مشوار')) {
      return ExpenseCategory.transportation;
    }
    if (clean.contains('market') ||
        clean.contains('تسويق') ||
        clean.contains('اعلان') ||
        clean.contains('إعلان') ||
        clean.contains('دعاية') ||
        clean.contains('سوشيال') ||
        clean.contains('ads')) {
      return ExpenseCategory.marketing;
    }
    if (clean.contains('gov') ||
        clean.contains('tax') ||
        clean.contains('حكوم') ||
        clean.contains('ضريب') ||
        clean.contains('ضرائب') ||
        clean.contains('رسوم') ||
        clean.contains('تأمين') ||
        clean.contains('رخصة') ||
        clean.contains('ترخيص')) {
      return ExpenseCategory.government;
    }
    return ExpenseCategory.other;
  }
}

DateTime _parseExpenseDate(dynamic date) {
  if (date == null) return DateTime.now();
  if (date is DateTime) return date;
  if (date is Timestamp) return date.toDate();
  if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
  return DateTime.tryParse(date.toString()) ?? DateTime.now();
}

/// Expense record model for store operational costs tracking
class ExpenseModel extends Equatable {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String paymentMethod;
  final String recordedBy;
  final String notes;
  final String? invoiceReceiptUrl;
  final String? treasuryTransactionId;
  final String? shiftId;
  final String? branchId;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod = 'cash',
    this.recordedBy = 'Admin',
    this.notes = '',
    this.invoiceReceiptUrl,
    this.treasuryTransactionId,
    this.shiftId,
    this.branchId,
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel.fromMap(data, doc.id);
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final titleVal = map['title']?.toString() ?? map['reason']?.toString() ?? '';
    final categoryVal = map['category']?.toString() ?? titleVal;
    return ExpenseModel(
      id: docId ?? map['id']?.toString() ?? '',
      title: titleVal,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(categoryVal),
      date: _parseExpenseDate(map['date'] ?? map['createdAt']),
      paymentMethod: map['paymentMethod']?.toString() ?? map['channel']?.toString() ?? 'cash',
      recordedBy: map['recordedBy']?.toString() ?? map['performedBy']?.toString() ?? 'Admin',
      notes: map['notes']?.toString() ?? '',
      invoiceReceiptUrl: map['invoiceReceiptUrl']?.toString(),
      treasuryTransactionId: map['treasuryTransactionId']?.toString() ?? map['treasuryTxId']?.toString(),
      shiftId: map['shiftId']?.toString(),
      branchId: map['branchId']?.toString(),
      createdAt: _parseExpenseDate(map['createdAt'] ?? map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category.id,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'recordedBy': recordedBy,
      'notes': notes,
      if (invoiceReceiptUrl != null) 'invoiceReceiptUrl': invoiceReceiptUrl,
      if (treasuryTransactionId != null) 'treasuryTransactionId': treasuryTransactionId,
      if (shiftId != null) 'shiftId': shiftId,
      if (branchId != null) 'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? paymentMethod,
    String? recordedBy,
    String? notes,
    String? invoiceReceiptUrl,
    String? treasuryTransactionId,
    String? shiftId,
    String? branchId,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      invoiceReceiptUrl: invoiceReceiptUrl ?? this.invoiceReceiptUrl,
      treasuryTransactionId: treasuryTransactionId ?? this.treasuryTransactionId,
      shiftId: shiftId ?? this.shiftId,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        date,
        paymentMethod,
        recordedBy,
        notes,
        invoiceReceiptUrl,
        treasuryTransactionId,
        shiftId,
        branchId,
        createdAt,
      ];
}
