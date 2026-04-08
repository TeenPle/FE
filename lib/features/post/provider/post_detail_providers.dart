import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/post_repository.dart';
import '../api/temporary_post_repository.dart';
import 'post_detail_provider.dart';
import 'post_detail_state.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return const TemporaryPostRepository();
});

final postDetailProvider = StateNotifierProvider.family<
    PostDetailNotifier, PostDetailState, int>((ref, postId) {
  final repository = ref.watch(postRepositoryProvider);
  return PostDetailNotifier(
    postId: postId,
    repository: repository,
  );
});