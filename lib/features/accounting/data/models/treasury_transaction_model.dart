import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TreasuryTransactionType {
  cashIn('cash_in', 'إيداع نقدي / وارد للخزينة', 'Cash In / Deposit'),
  cashOut('cash_out', 'سحب نقدي / مصروف مباشر', 'Cash Out / Withdrawal'),
  safeTransfer('safe_transfer', 'تحويل بين الخزائن / البنك', 'Transfer Between Channels'),
  capitalInjection('capital_injection', 'ضخ رأس مال', 'Capital Injection'),
  ownerWithdrawal('owner_withdrawal', 'مسحوبات شخصية / شركاء', 'Owner / Dividend Withdrawal');

  final String code;
  final String arabicLabel;
  final String englishLabel;

  const TreasuryTransactionType(this.code, this.arabicLabel, this.englishLabel);

  static TreasuryTransactionType fromString(String? val) {
    if (val == null) return TreasuryTransactionType.cashIn;
    final clean = val.trim().toLowerCase();
    if (clean == 'expense' || clean == 'withdrawal' || clean == 'cash_out' || clean == 'cashout') {
      return TreasuryTransactionType.cashOut;
    }
    if (clean == 'cash_in' || clean == 'cashin' || clean == 'deposit') {
      return TreasuryTransactionType.cashIn;
    }
    for (final t in TreasuryTransactionType.values) {
      if (t.code == clean || t.name.toLowerCase() == clean) return t;
    }
    return TreasuryTransactionType.cashIn;
  }
}

enum PaymentChannelType {
  cash('cash', 'الخزينة النقدية (كاش)', 'Cash Safe / Drawer'),
  card('card', 'حساب الفيزا / البنك', 'Bank / POS Card'),
  instapay('instapay', 'إنستاباي (Instapay)', 'Instapay Account'),
  vodafoneCash('vodafone_cash', 'فودافون كاش / محافظ إلكترونية', 'Vodafone Cash / Wallets');

  final String code;
  final String arabicLabel;
  final String englishLabel;

  const PaymentChannelType(this.code, this.arabicLabel, this.englishLabel);

  static PaymentChannelType fromString(String? val) {
    if (val == null) return PaymentChannelType.cash;
    final clean = val.trim().toLowerCase();
    for (final c in PaymentChannelType.values) {
      if (c.code == clean || c.name.toLowerCase() == clean) return c;
    }
    return PaymentChannelType.cash;
  }
}

class TreasuryTransactionModel extends Equatable {
  final String id;
  final TreasuryTransactionType type;
  final PaymentChannelType channel;
  final double amount;
  final String reason;
  final String referenceNumber;
  final String branchId;
  final String branchName;
  final String performedBy;
  final DateTime createdAt;

  const TreasuryTransactionModel({
    required this.id,
    required this.type,
    required this.channel,
    required this.amount,
    required this.reason,
    this.referenceNumber = '',
    this.branchId = '',
    this.branchName = '',
    this.performedBy = '',
    required this.createdAt,
  });

  TreasuryTransactionModel copyWith({
    String? id,
    TreasuryTransactionType? type,
    PaymentChannelType? channel,
    double? amount,
    String? reason,
    String? referenceNumber,
    String? branchId,
    String? branchName,
    String? performedBy,
    DateTime? createdAt,
  }) {
    return TreasuryTransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      performedBy: performedBy ?? this.performedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TreasuryTransactionModel.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is Timestamp) return date.toDate();
      if (date is num) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
      return DateTime.tryParse(date.toString()) ?? DateTime.now();
    }

    return TreasuryTransactionModel(
      id: id ?? json['id']?.toString() ?? '',
      type: TreasuryTransactionType.fromString(json['type']?.toString()),
      channel: PaymentChannelType.fromString(json['channel']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      performedBy: json['performedBy']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.code,
      'channel': channel.code,
      'amount': amount,
      'reason': reason,
      'referenceNumber': referenceNumber,
      'branchId': branchId,
      'branchName': branchName,
      'performedBy': performedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        channel,
        amount,
        reason,
        referenceNumber,
        branchId,
        branchName,
        performedBy,
        createdAt,
      ];
}
