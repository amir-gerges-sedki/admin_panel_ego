import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/badge_repository.dart';
import 'badge_state.dart';

class BadgeCubit extends Cubit<BadgeState> {
  final BadgeRepository badgeRepository;

  BadgeCubit(this.badgeRepository) : super(const BadgeInitial());

  List<BadgeModel> get currentBadges {
    if (state is BadgeLoaded) {
      return (state as BadgeLoaded).badges;
    }
    return [];
  }

  Future<void> loadBadges() async {
    emit(const BadgeLoading());
    try {
      final badges = await badgeRepository.getBadges();
      emit(BadgeLoaded(badges));
    } catch (e) {
      emit(BadgeError('فشل تحميل قائمة الباتشات: $e'));
    }
  }

  Future<void> addBadge(BadgeModel badge) async {
    try {
      await badgeRepository.addBadge(badge);
      await loadBadges();
    } catch (e) {
      emit(BadgeError('فشل إضافة الباتش: $e'));
    }
  }

  Future<void> updateBadge(BadgeModel badge) async {
    try {
      await badgeRepository.updateBadge(badge);
      await loadBadges();
    } catch (e) {
      emit(BadgeError('فشل تعديل الباتش: $e'));
    }
  }

  Future<void> deleteBadge(String badgeId) async {
    try {
      await badgeRepository.deleteBadge(badgeId);
      await loadBadges();
    } catch (e) {
      emit(BadgeError('فشل حذف الباتش: $e'));
    }
  }
}
