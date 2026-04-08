import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/school_repository.dart';
import '../models/board_model.dart';
import 'school_state.dart';

class SchoolNotifier extends StateNotifier<SchoolState> {
  final SchoolRepository repository;

  SchoolNotifier(this.repository) : super(SchoolState.initial());

  Future<void> loadInitialSchool(int schoolId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await repository.getSchoolDetail(
        schoolId: schoolId,
        page: 0,
        size: 10,
      );

      final defaultBoard = _findDefaultBoard(result.boards);

      state = state.copyWith(
        schoolId: result.schoolId,
        schoolName: result.name,
        schoolDescription: result.description,
        boards: result.boards,
        selectedBoardId: defaultBoard?.id,
        posts: result.posts,
        hasNext: result.hasNext,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '학교 정보를 불러오지 못했습니다.',
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
      final posts = await repository.getPostsByBoard(
        boardId: boardId,
        page: 0,
        size: 10,
      );

      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '게시글 목록을 불러오지 못했습니다.',
      );
    }
  }

  BoardModel? _findDefaultBoard(List<BoardModel> boards) {
    try {
      return boards.firstWhere((b) => b.title == '자유게시판');
    } catch (_) {
      return boards.isNotEmpty ? boards.first : null;
    }
  }
}