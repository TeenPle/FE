import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/home_repository.dart';
import 'home_state.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository repository;

  HomeNotifier(this.repository) : super(HomeState.initial());

  Future<void> loadInitialHome() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await repository.loadInitialHome();

      state = state.copyWith(
        schoolName: result.schoolName,
        boards: result.boards,
        selectedBoardId: result.defaultBoardId,
        posts: result.posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '홈 데이터를 불러오지 못했습니다.',
      );
    }
  }

  Future<void> selectBoard(int boardId) async {
    if (state.selectedBoardId == boardId) return;

    state = state.copyWith(
      selectedBoardId: boardId,
      isLoading: true,
      clearError: true,
    );

    try {
      final posts = await repository.getPostsByBoard(boardId);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '게시판 글을 불러오지 못했습니다.',
      );
    }
  }
}