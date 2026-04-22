import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../api/live_post_repository.dart';
import '../api/post_api.dart';
import '../api/post_repository.dart';
import '../api/temporary_post_repository.dart';
import 'post_detail_provider.dart';
import 'post_detail_state.dart';

final appApiClientProvider = Provider<AppApiClient>((ref) {
  return AppApiClient(ref.watch(dioProvider));
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