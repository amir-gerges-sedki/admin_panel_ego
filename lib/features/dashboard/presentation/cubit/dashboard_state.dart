import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_analytics_model.dart';

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
