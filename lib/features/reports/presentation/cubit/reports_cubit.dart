import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository repository;

  ReportsCubit({required this.repository})
      : super(ReportsState.initial());

  void setTab(ReportTab tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  Future<void> loadReport({
    ReportPeriod? period,
    DateTime? customStart,
    DateTime? customEnd,
    String? branchId,
  }) async {
    final effectivePeriod = period ?? state.selectedPeriod;
    final range = _resolveDateRange(
      effectivePeriod,
      customStart ?? state.customStartDate,
      customEnd ?? state.customEndDate,
    );

    emit(state.copyWith(
      status: ReportsStatus.loading,
      selectedPeriod: effectivePeriod,
      selectedBranchId: branchId ?? state.selectedBranchId,
      customStartDate: range.$1,
      customEndDate: range.$2,
    ));

    try {
      final report = await repository.getComprehensiveReport(
        startDate: range.$1,
        endDate: range.$2,
        branchId: state.selectedBranchId,
      );

      emit(state.copyWith(
        status: ReportsStatus.loaded,
        report: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  (DateTime, DateTime) _resolveDateRange(
    ReportPeriod period,
    DateTime customStart,
    DateTime customEnd,
  ) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
      case ReportPeriod.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final cleanStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
        final cleanEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (cleanStart, cleanEnd);
      case ReportPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);
      case ReportPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start, end);
      case ReportPeriod.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);
      case ReportPeriod.allTime:
        final start = DateTime(2020, 1, 1, 0, 0, 0);
        final end = DateTime(now.year + 1, 1, 1, 23, 59, 59);
        return (start, end);
      case ReportPeriod.custom:
        return (customStart, customEnd);
    }
  }
}
