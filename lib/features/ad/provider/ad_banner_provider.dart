import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/ad_banner_api.dart';
import '../models/ad_banner_model.dart';

final activeAdProvider = FutureProvider.family<AdBannerModel?, String>((
  ref,
  placement,
) {
  return ref.watch(adBannerApiProvider).getActive(placement);
});

class AdminAdListState {
  final List<AdBannerModel> ads;
  final bool isLoading;
  final String? error;

  const AdminAdListState({
    this.ads = const [],
    this.isLoading = false,
    this.error,
  });

  AdminAdListState copyWith({
    List<AdBannerModel>? ads,
    bool? isLoading,
    String? error,
  }) {
    return AdminAdListState(
      ads: ads ?? this.ads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminAdListNotifier extends StateNotifier<AdminAdListState> {
  final AdBannerApi _api;

  AdminAdListNotifier(this._api) : super(const AdminAdListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ads = await _api.getAdminAds();
      state = state.copyWith(ads: ads, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: '광고 목록을 불러오지 못했어요.');
    }
  }

  Future<void> save(AdBannerModel ad) async {
    if (ad.id == 0) {
      await _api.create(ad);
    } else {
      await _api.update(ad);
    }
    await load();
  }

  Future<void> delete(int adId) async {
    await _api.delete(adId);
    await load();
  }
}

final adminAdListProvider =
    StateNotifierProvider<AdminAdListNotifier, AdminAdListState>((ref) {
      return AdminAdListNotifier(ref.watch(adBannerApiProvider));
    });
