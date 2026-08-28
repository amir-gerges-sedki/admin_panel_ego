import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../../data/repositories/dashboard_repository.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardAnalyticsModel analytics;
  const DashboardLoaded(this.analytics);
  @override
  List<Object?> get props => [analytics];
}
class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardCubit(this.dashboardRepository) : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final data = await dashboardRepository.getDashboardAnalytics();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
