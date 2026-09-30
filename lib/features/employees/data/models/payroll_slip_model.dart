import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Monthly Payroll Slip Model (مسير / إيصال صرف راتب شهري)
class PayrollSlipModel extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final String jobTitle;
  final String monthPeriod; // Format: "YYYY-MM" e.g., "2026-09"
  final double baseSalary;
  final double totalBonuses;
  final double totalAdvances;
  final double totalDeductions;
  final double netSalary; // baseSalary + totalBonuses - totalAdvances - totalDeductions
  final DateTime paymentDate;
  final String paymentMethod; // "cash", "instapay", "vodafone_cash", "bank_transfer"
  final String notes;
  final String disbursedBy;
  final String? expenseId; // Linked Expense ID in expenses collection
  final DateTime createdAt;

  const PayrollSlipModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.jobTitle,
    required this.monthPeriod,
    required this.baseSalary,
    this.totalBonuses = 0.0,
    this.totalAdvances = 0.0,
    this.totalDeductions = 0.0,
    double? netSalary,
    required this.paymentDate,
    this.paymentMethod = 'cash',
    this.notes = '',
    this.disbursedBy = 'Admin',
    this.expenseId,
    required this.createdAt,
  }) : netSalary = netSalary ??
            (baseSalary + totalBonuses - totalAdvances - totalDeductions);

  factory PayrollSlipModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final payRaw = json['paymentDate'] ?? json['date'];
    DateTime parsedPayDate;
    if (payRaw is Timestamp) {
      parsedPayDate = payRaw.toDate();
    } else if (payRaw is String) {
      parsedPayDate = DateTime.tryParse(payRaw) ?? DateTime.now();
    } else {
      parsedPayDate = DateTime.now();
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

    final base = (json['baseSalary'] as num?)?.toDouble() ?? 0.0;
    final bonuses = (json['totalBonuses'] as num?)?.toDouble() ?? 0.0;
    final advances = (json['totalAdvances'] as num?)?.toDouble() ?? 0.0;
    final deductions = (json['totalDeductions'] as num?)?.toDouble() ?? 0.0;
    final net = (json['netSalary'] as num?)?.toDouble() ?? (base + bonuses - advances - deductions);

    return PayrollSlipModel(
      id: docId ?? json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString() ?? '',
      monthPeriod: json['monthPeriod']?.toString() ??
          '${parsedPayDate.year}-${parsedPayDate.month.toString().padLeft(2, '0')}',
      baseSalary: base,
      totalBonuses: bonuses,
      totalAdvances: advances,
      totalDeductions: deductions,
      netSalary: net,
      paymentDate: parsedPayDate,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      notes: json['notes']?.toString() ?? '',
      disbursedBy: json['disbursedBy']?.toString() ?? 'Admin',
      expenseId: json['expenseId']?.toString(),
      createdAt: parsedCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'jobTitle': jobTitle,
        'monthPeriod': monthPeriod,
        'baseSalary': baseSalary,
        'totalBonuses': totalBonuses,
        'totalAdvances': totalAdvances,
        'totalDeductions': totalDeductions,
        'netSalary': netSalary,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'paymentMethod': paymentMethod,
        'notes': notes,
        'disbursedBy': disbursedBy,
        'expenseId': expenseId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PayrollSlipModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? jobTitle,
    String? monthPeriod,
    double? baseSalary,
    double? totalBonuses,
    double? totalAdvances,
    double? totalDeductions,
    double? netSalary,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    String? disbursedBy,
    String? expenseId,
    DateTime? createdAt,
  }) {
    return PayrollSlipModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      jobTitle: jobTitle ?? this.jobTitle,
      monthPeriod: monthPeriod ?? this.monthPeriod,
      baseSalary: baseSalary ?? this.baseSalary,
      totalBonuses: totalBonuses ?? this.totalBonuses,
      totalAdvances: totalAdvances ?? this.totalAdvances,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      disbursedBy: disbursedBy ?? this.disbursedBy,
      expenseId: expenseId ?? this.expenseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employeeName,
        jobTitle,
        monthPeriod,
        baseSalary,
        totalBonuses,
        totalAdvances,
        totalDeductions,
        netSalary,
        paymentDate,
        paymentMethod,
        notes,
        disbursedBy,
        expenseId,
        createdAt,
      ];
}
