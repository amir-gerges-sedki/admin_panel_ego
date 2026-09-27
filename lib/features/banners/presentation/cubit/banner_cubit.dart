import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/banner_model.dart';
import '../../data/repositories/banner_repository.dart';
import 'banner_state.dart';

export 'banner_state.dart';

class BannerCubit extends Cubit<BannerState> {
  final BannerRepository bannerRepository;

  BannerCubit(this.bannerRepository) : super(const BannerInitial());

  Future<void> loadBanners() async {
    emit(const BannerLoading());
    try {
      final banners = await bannerRepository.getBanners();
      emit(BannerLoaded(banners: banners, filteredBanners: banners));
    } catch (e) {
      emit(BannerError(e.toString()));
    }
  }

  void filterBanners(String query) {
    if (state is! BannerLoaded) return;
    final currentState = state as BannerLoaded;
    final q = query.trim().toLowerCase();

    final filtered = currentState.banners.where((b) {
      return q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.targetScreen.toLowerCase().contains(q) ||
          (b.productId != null && b.productId!.toLowerCase().contains(q)) ||
          (b.productTitle != null && b.productTitle!.toLowerCase().contains(q)) ||
          b.id.toLowerCase().contains(q);
    }).toList();

    emit(currentState.copyWith(
      filteredBanners: filtered,
      searchQuery: query.trim(),
    ));
  }

  Future<void> addBanner(BannerModel banner) async {
    try {
      await bannerRepository.addBanner(banner);
      await loadBanners();
    } catch (e) {
      emit(BannerError(e.toString()));
    }
  }

  Future<void> updateBanner(BannerModel banner) async {
    try {
      await bannerRepository.updateBanner(banner);
      await loadBanners();
    } catch (e) {
      emit(BannerError(e.toString()));
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    try {
      await bannerRepository.deleteBanner(bannerId);
      await loadBanners();
    } catch (e) {
      emit(BannerError(e.toString()));
    }
  }
}
