import 'package:equatable/equatable.dart';
import '../../data/models/badge_model.dart';

abstract class BadgeState extends Equatable {
  const BadgeState();

  @override
  List<Object?> get props => [];
}

class BadgeInitial extends BadgeState {
  const BadgeInitial();
}

class BadgeLoading extends BadgeState {
  const BadgeLoading();
}

class BadgeLoaded extends BadgeState {
  final List<BadgeModel> badges;

  const BadgeLoaded(this.badges);

  @override
  List<Object?> get props => [badges];
}

class BadgeError extends BadgeState {
  final String message;

  const BadgeError(this.message);

  @override
  List<Object?> get props => [message];
}
