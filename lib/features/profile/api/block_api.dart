import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/blocked_user_model.dart';

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

  Future<List<BlockedUserModel>> getBlockedUsers() async {
    final json = await client.get('/api/blocks');
    final response = ApiResponse.fromJson(json, (data) {
      final list = data as List<dynamic>;
      return list
          .map((e) => BlockedUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }
}
