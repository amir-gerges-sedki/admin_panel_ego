import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/banner_model.dart';
import '../../data/repositories/banner_repository.dart';

abstract class BannerState extends Equatable {
  const BannerState();
  @override
  List<Object?> get props => [];
}

class BannerInitial extends BannerState {}
class BannerLoading extends BannerState {}
class BannerLoaded extends BannerState {
  final List<BannerModel> banners;
  final List<BannerModel>? _filteredBanners;
  final String? _searchQuery;

  List<BannerModel> get filteredBanners => _filteredBanners ?? banners;
  String get searchQuery => _searchQuery ?? '';

  const BannerLoaded({
    this.banners = const [],
    List<BannerModel>? filteredBanners,
    String? searchQuery,
  })  : _filteredBanners = filteredBanners ?? banners,
        _searchQuery = searchQuery ?? '';

  BannerLoaded copyWith({
    List<BannerModel>? banners,
    List<BannerModel>? filteredBanners,
    String? searchQuery,
  }) {
    final b = banners ?? this.banners;
    return BannerLoaded(
      banners: b,
      filteredBanners: filteredBanners ?? _filteredBanners ?? b,
      searchQuery: searchQuery ?? _searchQuery ?? '',
    );
  }

  @override
  List<Object?> get props => [banners, filteredBanners, searchQuery];
}

class BannerError extends BannerState {
  final String message;
  const BannerError(this.message);
  @override
  List<Object?> get props => [message];
}

class BannerCubit extends Cubit<BannerState> {
  final BannerRepository bannerRepository;

  BannerCubit(this.bannerRepository) : super(BannerInitial());

  Future<void> loadBanners() async {
    emit(BannerLoading());
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
