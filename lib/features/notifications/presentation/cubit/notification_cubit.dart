import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/broadcast_model.dart';
import '../../data/repositories/notification_repository.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationLoaded extends NotificationState {
  final List<BroadcastModel> broadcasts;
  final List<BroadcastModel>? _filteredBroadcasts;
  final String? _searchQuery;

  List<BroadcastModel> get filteredBroadcasts => _filteredBroadcasts ?? broadcasts;
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

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationCubit(this.notificationRepository) : super(NotificationInitial());

  Future<void> loadBroadcasts() async {
    emit(NotificationLoading());
    try {
      final broadcasts = await notificationRepository.getBroadcasts();
      emit(NotificationLoaded(broadcasts: broadcasts, filteredBroadcasts: broadcasts));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void filterBroadcasts(String query) {
    if (state is! NotificationLoaded) return;
    final currentState = state as NotificationLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.broadcasts.where((b) {
      return q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.body.toLowerCase().contains(q) ||
          b.targetAudience.toLowerCase().contains(q) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredBroadcasts: filtered,
      searchQuery: query.trim(),
    ));
  }

  Future<int> sendBroadcast(BroadcastModel broadcast) async {
    try {
      final count = await notificationRepository.sendBroadcast(broadcast);
      await loadBroadcasts();
      return count;
    } catch (e) {
      emit(NotificationError(e.toString()));
      return 0;
    }
  }
}
