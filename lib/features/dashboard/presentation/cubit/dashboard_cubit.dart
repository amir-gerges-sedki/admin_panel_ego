import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

export 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository dashboardRepository;
  DashboardPeriodType _currentPeriod = DashboardPeriodType.allTime;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardCubit(this.dashboardRepository) : super(DashboardInitial());

  DashboardPeriodType get currentPeriod => _currentPeriod;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  Future<void> loadDashboard({
    DashboardPeriodType? period,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (period != null) _currentPeriod = period;
    if (customStart != null) _customStart = customStart;
    if (customEnd != null) _customEnd = customEnd;

    emit(DashboardLoading());
    try {
      final data = await dashboardRepository.getDashboardAnalytics(
        periodType: _currentPeriod,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      );
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> changePeriod(
    DashboardPeriodType period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    _currentPeriod = period;
    _customStart = customStart;
    _customEnd = customEnd;

    emit(DashboardLoading());
    try {
      final data = await dashboardRepository.getDashboardAnalytics(
        periodType: _currentPeriod,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      );
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
