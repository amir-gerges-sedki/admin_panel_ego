import 'package:equatable/equatable.dart';
import '../../data/models/profit_loss_model.dart';
import '../../data/models/treasury_summary_model.dart';
import '../../data/models/treasury_transaction_model.dart';

enum AccountingPeriod {
  today('today', 'اليوم', 'Today'),
  yesterday('yesterday', 'أمس', 'Yesterday'),
  thisWeek('this_week', 'هذا الأسبوع', 'This Week'),
  thisMonth('this_month', 'هذا الشهر', 'This Month'),
  lastMonth('last_month', 'الشهر الماضي', 'Last Month'),
  thisYear('this_year', 'هذا العام', 'This Year'),
  allTime('all_time', 'كل الفترات', 'All Time'),
  custom('custom', 'فترة مخصصة', 'Custom Period');

  final String code;
  final String arabicLabel;
  final String englishLabel;

  const AccountingPeriod(this.code, this.arabicLabel, this.englishLabel);
}

enum AccountingStatus { initial, loading, loaded, error }

class AccountingState extends Equatable {
  final AccountingStatus status;
  final TreasurySummaryModel treasurySummary;
  final ProfitLossModel profitLoss;
  final List<TreasuryTransactionModel> transactions;
  final AccountingPeriod selectedPeriod;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final String? selectedBranchId;
  final String? errorMessage;
  final bool isSubmitting;

  const AccountingState({
    this.status = AccountingStatus.initial,
    required this.treasurySummary,
    required this.profitLoss,
    this.transactions = const [],
    this.selectedPeriod = AccountingPeriod.thisMonth,
    required this.customStartDate,
    required this.customEndDate,
    this.selectedBranchId,
    this.errorMessage,
    this.isSubmitting = false,
  });

  factory AccountingState.initial() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return AccountingState(
      status: AccountingStatus.initial,
      treasurySummary: TreasurySummaryModel(lastUpdated: now),
      profitLoss: ProfitLossModel(startDate: startOfMonth, endDate: endOfMonth),
      transactions: const [],
      selectedPeriod: AccountingPeriod.thisMonth,
      customStartDate: startOfMonth,
      customEndDate: endOfMonth,
    );
  }

  AccountingState copyWith({
    AccountingStatus? status,
    TreasurySummaryModel? treasurySummary,
    ProfitLossModel? profitLoss,
    List<TreasuryTransactionModel>? transactions,
    AccountingPeriod? selectedPeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? selectedBranchId,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return AccountingState(
      status: status ?? this.status,
      treasurySummary: treasurySummary ?? this.treasurySummary,
      profitLoss: profitLoss ?? this.profitLoss,
      transactions: transactions ?? this.transactions,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        treasurySummary,
        profitLoss,
        transactions,
        selectedPeriod,
        customStartDate,
        customEndDate,
        selectedBranchId,
        errorMessage,
        isSubmitting,
      ];
}
