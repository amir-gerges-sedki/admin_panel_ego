import 'package:equatable/equatable.dart';
import '../../data/models/broadcast_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<BroadcastModel> broadcasts;
  final List<BroadcastModel>? _filteredBroadcasts;
  final String? _searchQuery;

  List<BroadcastModel> get filteredBroadcasts =>
      _filteredBroadcasts ?? broadcasts;
  String get searchQuery => _searchQuery ?? '';

  const NotificationLoaded({
    this.broadcasts = const [],
    List<BroadcastModel>? filteredBroadcasts,
    String? searchQuery,
  })  : _filteredBroadcasts = filteredBroadcasts ?? broadcasts,
        _searchQuery = searchQuery ?? '';

  NotificationLoaded copyWith({
    List<BroadcastModel>? broadcasts,
    List<BroadcastModel>? filteredBroadcasts,
    String? searchQuery,
  }) {
    final b = broadcasts ?? this.broadcasts;
    return NotificationLoaded(
      broadcasts: b,
      filteredBroadcasts: filteredBroadcasts ?? _filteredBroadcasts ?? b,
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [broadcasts, filteredBroadcasts, searchQuery];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
