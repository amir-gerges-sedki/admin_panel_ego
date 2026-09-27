import 'package:equatable/equatable.dart';
import '../../data/models/banner_model.dart';

abstract class BannerState extends Equatable {
  const BannerState();
  @override
  List<Object?> get props => [];
}

class BannerInitial extends BannerState {
  const BannerInitial();
}

class BannerLoading extends BannerState {
  const BannerLoading();
}

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
