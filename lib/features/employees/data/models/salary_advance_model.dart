import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Salary Advance Model (سُلفة موظف)
class SalaryAdvanceModel extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime date;
  final String monthPeriod; // Format: "YYYY-MM" e.g., "2026-09"
  final String paymentMethod; // "cash", "instapay", "vodafone_cash", "bank_transfer"
  final String notes;
  final String disbursedBy;
  final bool isDeductedFromPayroll;
  final String? payrollSlipId;
  final DateTime createdAt;

  const SalaryAdvanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.date,
    required this.monthPeriod,
    this.paymentMethod = 'cash',
    this.notes = '',
    this.disbursedBy = 'Admin',
    this.isDeductedFromPayroll = false,
    this.payrollSlipId,
    required this.createdAt,
  });

  factory SalaryAdvanceModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final dateRaw = json['date'];
    DateTime parsedDate;
    if (dateRaw is Timestamp) {
      parsedDate = dateRaw.toDate();
    } else if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final createdRaw = json['createdAt'];
    DateTime parsedCreated;
    if (createdRaw is Timestamp) {
      parsedCreated = createdRaw.toDate();
    } else if (createdRaw is String) {
      parsedCreated = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      parsedCreated = DateTime.now();
    }

    final monthStr = json['monthPeriod']?.toString() ??
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}';

    return SalaryAdvanceModel(
      id: docId ?? json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      monthPeriod: monthStr,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      notes: json['notes']?.toString() ?? '',
      disbursedBy: json['disbursedBy']?.toString() ?? 'Admin',
      isDeductedFromPayroll: json['isDeductedFromPayroll'] as bool? ?? false,
      payrollSlipId: json['payrollSlipId']?.toString(),
      createdAt: parsedCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'monthPeriod': monthPeriod,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'disbursedBy': disbursedBy,
        'isDeductedFromPayroll': isDeductedFromPayroll,
        'payrollSlipId': payrollSlipId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  SalaryAdvanceModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    DateTime? date,
    String? monthPeriod,
    String? paymentMethod,
    String? notes,
    String? disbursedBy,
    bool? isDeductedFromPayroll,
    String? payrollSlipId,
    DateTime? createdAt,
  }) {
    return SalaryAdvanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      monthPeriod: monthPeriod ?? this.monthPeriod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      disbursedBy: disbursedBy ?? this.disbursedBy,
      isDeductedFromPayroll: isDeductedFromPayroll ?? this.isDeductedFromPayroll,
      payrollSlipId: payrollSlipId ?? this.payrollSlipId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employeeName,
        amount,
        date,
        monthPeriod,
        paymentMethod,
        notes,
        disbursedBy,
        isDeductedFromPayroll,
        payrollSlipId,
        createdAt,
      ];
}
