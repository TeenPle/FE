import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/admin_audit_log_model.dart';

final adminAuditLogApiProvider = Provider<AdminAuditLogApi>((ref) {
  return AdminAuditLogApi(AppApiClient(ref.watch(dioProvider)));
});

class AdminAuditLogApi {
  final AppApiClient _client;

  const AdminAuditLogApi(this._client);

  Future<List<AdminAuditLogModel>> getLogs({
    int page = 0,
    int size = 20,
    String? action,
    String? targetType,
    int? adminId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _client.get(
      '/api/admin/audit-logs',
      queryParameters: {
        'page': '$page',
        'size': '$size',
        if (action != null && action.isNotEmpty) 'action': action,
        if (targetType != null && targetType.isNotEmpty) 'targetType': targetType,
        if (adminId != null) 'adminId': '$adminId',
        if (from != null) 'from': _dateOnly(from),
        if (to != null) 'to': _dateOnly(to),
      },
    );
    final content = res['result']?['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => AdminAuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
