import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/ad_banner_model.dart';

final adBannerApiProvider = Provider<AdBannerApi>((ref) {
  return AdBannerApi(AppApiClient(ref.watch(dioProvider)));
});

class AdBannerApi {
  final AppApiClient _client;

  const AdBannerApi(this._client);

  Future<AdBannerModel?> getActive(String placement) async {
    final json = await _client.get(
      '/api/ads/active',
      queryParameters: {'placement': placement},
    );
    final response = ApiResponse.fromJson(json, (data) {
      if (data == null) return null;
      return AdBannerModel.fromJson(data as Map<String, dynamic>);
    });
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return response.result;
  }

  Future<List<AdBannerModel>> getAdminAds() async {
    final json = await _client.get('/api/admin/ads');
    final response = ApiResponse.fromJson(
      json,
      (data) => (data as List<dynamic>)
          .map((e) => AdBannerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<void> create(AdBannerModel ad) async {
    await _client.post('/api/admin/ads', body: ad.toRequestJson());
  }

  Future<void> update(AdBannerModel ad) async {
    await _client.patch('/api/admin/ads/${ad.id}', body: ad.toRequestJson());
  }

  Future<void> delete(int adId) async {
    await _client.delete('/api/admin/ads/$adId');
  }
}
