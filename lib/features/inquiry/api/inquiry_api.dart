import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/inquiry_model.dart';

final inquiryApiProvider = Provider<InquiryApi>((ref) {
  return InquiryApi(AppApiClient(ref.watch(dioProvider)));
});

class InquiryApi {
  final AppApiClient _client;

  const InquiryApi(this._client);

  Future<List<InquirySummaryModel>> getMyInquiries() async {
    final res = await _client.get(
      '/api/inquiries',
      queryParameters: {'page': '0', 'size': '50'},
    );
    final content = res['result']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => InquirySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InquiryDetailModel> getMyInquiry(int inquiryId) async {
    final res = await _client.get('/api/inquiries/$inquiryId');
    return InquiryDetailModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<int> createInquiry({
    required String title,
    required String content,
  }) async {
    final res = await _client.post(
      '/api/inquiries',
      body: {'title': title, 'content': content},
    );
    return (res['result'] as num).toInt();
  }
}
