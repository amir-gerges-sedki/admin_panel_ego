import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/broadcast_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

export 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationCubit(this.notificationRepository)
      : super(const NotificationInitial());

  Future<void> loadBroadcasts() async {
    emit(const NotificationLoading());
    try {
      final broadcasts = await notificationRepository.getBroadcasts();
      emit(NotificationLoaded(
        broadcasts: broadcasts,
        filteredBroadcasts: broadcasts,
      ));
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
