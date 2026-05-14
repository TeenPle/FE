import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/inquiry_model.dart';

final adminInquiryApiProvider = Provider<AdminInquiryApi>((ref) {
  return AdminInquiryApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminInquiryApi {
  final AppApiClient _client;

  const AdminInquiryApi(this._client);

  Future<int> getPendingInquiryCount() async {
    final res = await _client.get(
      '/api/admin/inquiries',
      queryParameters: {'status': 'PENDING', 'page': '0', 'size': '1'},
    );
    final result = res['result'] as Map<String, dynamic>?;
    return (result?['totalElements'] as num?)?.toInt() ?? 0;
  }

  Future<List<InquirySummaryModel>> getInquiries({
    required String status,
  }) async {
    final res = await _client.get(
      '/api/admin/inquiries',
      queryParameters: {'status': status, 'page': '0', 'size': '50'},
    );
    final content = res['result']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => InquirySummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InquiryDetailModel> getInquiry(int inquiryId) async {
    final res = await _client.get('/api/admin/inquiries/$inquiryId');
    return InquiryDetailModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<void> answerInquiry(int inquiryId, String answer) async {
    await _client.post(
      '/api/admin/inquiries/$inquiryId/answer',
      body: {'answer': answer},
    );
  }
}
