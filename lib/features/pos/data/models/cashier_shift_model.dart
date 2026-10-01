import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a physical store cashier shift session with cash drawer balance reconciliation
class CashierShiftModel extends Equatable {
  final String id;
  final String branchId;
  final String branchName;
  final String cashierId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash; // Opening float in cash drawer
  final double cashSales; // POS cash sales
  final double cardSales; // POS card / visa sales
  final double instapaySales; // POS Instapay transfers
  final double vodafoneCashSales; // POS Vodafone Cash transfers
  final double totalSales; // Total POS revenue
  final double cashIns; // Manual cash additions to drawer
  final double cashOuts; // Manual cash withdrawals / petty cash paid from drawer
  final double cashRefunds; // Cash refunded for returns
  final int ordersCount; // Total completed sales orders
  final double expectedCash; // openingCash + cashSales + cashIns - cashOuts - cashRefunds
  final double? actualCountedCash; // Physical count on shift close
  final double? difference; // actualCountedCash - expectedCash (+ surplus, - shortage)
  final String status; // 'open' | 'closed'
  final String openingNotes;
  final String closingNotes;
  final String closedBy;

  const CashierShiftModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.cashierId,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.cashSales = 0.0,
    this.cardSales = 0.0,
    this.instapaySales = 0.0,
    this.vodafoneCashSales = 0.0,
    this.totalSales = 0.0,
    this.cashIns = 0.0,
    this.cashOuts = 0.0,
    this.cashRefunds = 0.0,
    this.ordersCount = 0,
    required this.expectedCash,
    this.actualCountedCash,
    this.difference,
    this.status = 'open',
    this.openingNotes = '',
    this.closingNotes = '',
    this.closedBy = '',
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get hasDiscrepancy => difference != null && difference!.abs() > 0.01;

  double get calculatedExpectedCash =>
      openingCash + cashSales + cashIns - cashOuts - cashRefunds;

  Duration get duration {
    final end = closedAt ?? DateTime.now();
    return end.difference(openedAt);
  }

  CashierShiftModel copyWith({
    String? id,
    String? branchId,
    String? branchName,
    String? cashierId,
    String? cashierName,
    DateTime? openedAt,
    DateTime? closedAt,
    double? openingCash,
    double? cashSales,
    double? cardSales,
    double? instapaySales,
    double? vodafoneCashSales,
    double? totalSales,
    double? cashIns,
    double? cashOuts,
    double? cashRefunds,
    int? ordersCount,
    double? expectedCash,
    double? actualCountedCash,
    double? difference,
    String? status,
    String? openingNotes,
    String? closingNotes,
    String? closedBy,
  }) {
    return CashierShiftModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
      instapaySales: instapaySales ?? this.instapaySales,
      vodafoneCashSales: vodafoneCashSales ?? this.vodafoneCashSales,
      totalSales: totalSales ?? this.totalSales,
      cashIns: cashIns ?? this.cashIns,
      cashOuts: cashOuts ?? this.cashOuts,
      cashRefunds: cashRefunds ?? this.cashRefunds,
      ordersCount: ordersCount ?? this.ordersCount,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCountedCash: actualCountedCash ?? this.actualCountedCash,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      openingNotes: openingNotes ?? this.openingNotes,
      closingNotes: closingNotes ?? this.closingNotes,
      closedBy: closedBy ?? this.closedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branchId': branchId,
        'branchName': branchName,
        'cashierId': cashierId,
        'cashierName': cashierName,
        'openedAt': Timestamp.fromDate(openedAt),
        'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
        'openingCash': openingCash,
        'cashSales': cashSales,
        'cardSales': cardSales,
        'instapaySales': instapaySales,
        'vodafoneCashSales': vodafoneCashSales,
        'totalSales': totalSales,
        'cashIns': cashIns,
        'cashOuts': cashOuts,
        'cashRefunds': cashRefunds,
        'ordersCount': ordersCount,
        'expectedCash': expectedCash,
        'actualCountedCash': actualCountedCash,
        'difference': difference,
        'status': status,
        'openingNotes': openingNotes,
        'closingNotes': closingNotes,
        'closedBy': closedBy,
      };

  factory CashierShiftModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final opening = (json['openingCash'] as num?)?.toDouble() ?? 0.0;
    final cashS = (json['cashSales'] as num?)?.toDouble() ?? 0.0;
    final cardS = (json['cardSales'] as num?)?.toDouble() ?? 0.0;
    final instaS = (json['instapaySales'] as num?)?.toDouble() ?? 0.0;
    final vfS = (json['vodafoneCashSales'] as num?)?.toDouble() ?? 0.0;
    final totalS = (json['totalSales'] as num?)?.toDouble() ?? (cashS + cardS + instaS + vfS);
    final cIns = (json['cashIns'] as num?)?.toDouble() ?? 0.0;
    final cOuts = (json['cashOuts'] as num?)?.toDouble() ?? 0.0;
    final cRefs = (json['cashRefunds'] as num?)?.toDouble() ?? 0.0;
    final expCash = (json['expectedCash'] as num?)?.toDouble() ??
        (opening + cashS + cIns - cOuts - cRefs);

    return CashierShiftModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? 'Main Branch',
      cashierId: json['cashierId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? 'Store Cashier',
      openedAt: parseDate(json['openedAt']),
      closedAt: json['closedAt'] != null ? parseDate(json['closedAt']) : null,
      openingCash: opening,
      cashSales: cashS,
      cardSales: cardS,
      instapaySales: instaS,
      vodafoneCashSales: vfS,
      totalSales: totalS,
      cashIns: cIns,
      cashOuts: cOuts,
      cashRefunds: cRefs,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      expectedCash: expCash,
      actualCountedCash: (json['actualCountedCash'] as num?)?.toDouble(),
      difference: (json['difference'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'open',
      openingNotes: json['openingNotes']?.toString() ?? '',
      closingNotes: json['closingNotes']?.toString() ?? '',
      closedBy: json['closedBy']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        branchName,
        cashierId,
        cashierName,
        openedAt,
        closedAt,
        openingCash,
        cashSales,
        cardSales,
        instapaySales,
        vodafoneCashSales,
        totalSales,
        cashIns,
        cashOuts,
        cashRefunds,
        ordersCount,
        expectedCash,
        actualCountedCash,
        difference,
        status,
        openingNotes,
        closingNotes,
        closedBy,
      ];
}
