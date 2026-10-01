import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ShiftTransactionType {
  cashIn('cash_in', 'وارد نقدية (إيداع)', 'Cash In'),
  cashOut('cash_out', 'منصرف نقدية (سحب)', 'Cash Out');

  final String id;
  final String arabicLabel;
  final String englishLabel;

  const ShiftTransactionType(this.id, this.arabicLabel, this.englishLabel);

  static ShiftTransactionType fromString(String? val) {
    if (val == 'cash_out') return ShiftTransactionType.cashOut;
    return ShiftTransactionType.cashIn;
  }
}

/// Records petty cash movements (Cash In / Cash Out) directly tied to an active shift
class ShiftTransactionModel extends Equatable {
  final String id;
  final String shiftId;
  final ShiftTransactionType type;
  final double amount;
  final String reason;
  final DateTime createdAt;
  final String performedBy;

  const ShiftTransactionModel({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.performedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shiftId': shiftId,
        'type': type.id,
        'amount': amount,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
        'performedBy': performedBy,
      };

  factory ShiftTransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ShiftTransactionModel(
      id: json['id']?.toString() ?? '',
      shiftId: json['shiftId']?.toString() ?? '',
      type: ShiftTransactionType.fromString(json['type']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      performedBy: json['performedBy']?.toString() ?? 'Store Staff',
    );
  }

  @override
  List<Object?> get props => [
        id,
        shiftId,
        type,
        amount,
        reason,
        createdAt,
        performedBy,
      ];
}
