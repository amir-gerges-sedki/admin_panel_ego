import 'package:equatable/equatable.dart';
import '../../data/models/erp_report_models.dart';

enum ReportPeriod {
  today('today', 'اليوم', 'Today'),
  thisWeek('this_week', 'هذا الأسبوع', 'This Week'),
  thisMonth('this_month', 'هذا الشهر', 'This Month'),
  lastMonth('last_month', 'الشهر الماضي', 'Last Month'),
  thisYear('this_year', 'هذا العام', 'This Year'),
  allTime('all_time', 'كل الفترات', 'All Time'),
  custom('custom', 'فترة مخصصة', 'Custom Period');

  final String code;
  final String arabicLabel;
  final String englishLabel;

  const ReportPeriod(this.code, this.arabicLabel, this.englishLabel);
}

enum ReportTab { sales, inventory, suppliers, expenses }

enum ReportsStatus { initial, loading, loaded, error }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final ComprehensiveErpReportModel report;
  final ReportPeriod selectedPeriod;
  final ReportTab selectedTab;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final String? selectedBranchId;
  final String? errorMessage;

  const ReportsState({
    this.status = ReportsStatus.initial,
    required this.report,
    this.selectedPeriod = ReportPeriod.thisMonth,
    this.selectedTab = ReportTab.sales,
    required this.customStartDate,
    required this.customEndDate,
    this.selectedBranchId,
    this.errorMessage,
  });

  factory ReportsState.initial() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return ReportsState(
      status: ReportsStatus.initial,
      report: ComprehensiveErpReportModel(startDate: startOfMonth, endDate: endOfMonth),
      selectedPeriod: ReportPeriod.thisMonth,
      selectedTab: ReportTab.sales,
      customStartDate: startOfMonth,
      customEndDate: endOfMonth,
    );
  }

  ReportsState copyWith({
    ReportsStatus? status,
    ComprehensiveErpReportModel? report,
    ReportPeriod? selectedPeriod,
    ReportTab? selectedTab,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? selectedBranchId,
    String? errorMessage,
  }) {
    return ReportsState(
      status: status ?? this.status,
      report: report ?? this.report,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedTab: selectedTab ?? this.selectedTab,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        report,
        selectedPeriod,
        selectedTab,
        customStartDate,
        customEndDate,
        selectedBranchId,
        errorMessage,
      ];
}
