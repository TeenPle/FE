import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/report_summary_model.dart';

final adminReportApiProvider = Provider<AdminReportApi>((ref) {
  return AdminReportApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminReportApi {
  final AppApiClient _client;

  AdminReportApi(this._client);

  Future<int> getPendingReportCount() async {
    final res = await _client.get(
      '/api/admin/reports',
      queryParameters: {'status': 'PENDING', 'page': '0', 'size': '1'},
    );
    final result = res['result'] as Map<String, dynamic>?;
    return (result?['totalElements'] as num?)?.toInt() ??
        ((result?['content'] as List<dynamic>?)?.length ?? 0);
  }

  Future<List<ReportSummaryModel>> getReports({
    required String status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _client.get(
      '/api/admin/reports',
      queryParameters: {
        'status': status,
        'page': '$page',
        'size': '$size',
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
      },
    );
    final content = (res['result']['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => ReportSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReportDetailModel> getReportDetail(int reportId) async {
    final res = await _client.get('/api/admin/reports/$reportId');
    return ReportDetailModel.fromJson(res['result'] as Map<String, dynamic>);
  }

  Future<void> approveReport(
    int reportId,
    int penaltyDays,
    String adminComment,
  ) async {
    await _client.post(
      '/api/admin/reports/$reportId/approve',
      body: {'penaltyDays': penaltyDays, 'adminComment': adminComment},
    );
  }

  Future<void> rejectReport(int reportId, String adminComment) async {
    await _client.post(
      '/api/admin/reports/$reportId/reject',
      body: {'adminComment': adminComment},
    );
  }

  Future<void> warnReport(int reportId, String adminComment) async {
    await _client.post(
      '/api/admin/reports/$reportId/warn',
      body: {'adminComment': adminComment},
    );
  }
}
