import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';

class BlockApi {
  final AppApiClient client;

  const BlockApi({required this.client});

  Future<void> blockUser(int userId) async {
    final json = await client.post('/api/blocks/$userId');
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  Future<void> unblockUser(int userId) async {
    final json = await client.delete('/api/blocks/$userId');
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  Future<int> getBlockedCount() async {
    final json = await client.get('/api/blocks');
    final response = ApiResponse.fromJson(json, (data) {
      final map = data as Map<String, dynamic>;
      return (map['blockedCount'] as num?)?.toInt() ?? 0;
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<void> unblockAll() async {
    final json = await client.delete('/api/blocks');
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }
}
