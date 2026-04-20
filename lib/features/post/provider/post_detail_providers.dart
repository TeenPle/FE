import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/token_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../api/live_post_repository.dart';
import '../api/post_api.dart';
import '../api/post_repository.dart';
import '../api/temporary_post_repository.dart';
import 'post_detail_provider.dart';
import 'post_detail_state.dart';

class _StorageTokenProvider implements TokenProvider {
  final TokenStorage _storage;
  _StorageTokenProvider(this._storage);

  @override
  Future<String?> getAccessToken() => _storage.getAccessToken();
}

final appApiClientProvider = Provider<AppApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AppApiClient(
    baseUrl: 'http://10.0.2.2:8080',
    tokenProvider: _StorageTokenProvider(tokenStorage),
  );
});

final postApiProvider = Provider<PostApi>((ref) {
  final client = ref.watch(appApiClientProvider);
  return PostApi(client: client);
});

final useMockPostRepositoryProvider = Provider<bool>((ref) => false);

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final useMock = ref.watch(useMockPostRepositoryProvider);

  if (useMock) {
    return const TemporaryPostRepository();
  }

  final api = ref.watch(postApiProvider);
  return LivePostRepository(api: api);
});

final postDetailProvider =
StateNotifierProvider.family<PostDetailNotifier, PostDetailState, int>(
      (ref, postId) {
    final repository = ref.watch(postRepositoryProvider);

    return PostDetailNotifier(
      postId: postId,
      repository: repository,
    );
  },
);