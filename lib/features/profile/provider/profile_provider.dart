import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../api/profile_api.dart';
import '../models/my_comment_model.dart';
import '../models/my_post_model.dart';
import 'profile_state.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(client: AppApiClient(ref.watch(dioProvider)));
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref.watch(profileApiProvider));
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileApi _api;

  ProfileNotifier(this._api) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _api.getMyProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> updateNickname(String nickname) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _api.updateNickname(nickname);
      final updated = await _api.getMyProfile();
      state = state.copyWith(
        isSaving: false,
        profile: updated,
        successMessage: '닉네임이 변경됐어요.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _api.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isSaving: false, successMessage: '비밀번호가 변경됐어요.');
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateProfileImage(File imageFile) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _api.updateProfileImage(imageFile);
      final updated = await _api.getMyProfile();
      state = state.copyWith(
        isSaving: false,
        profile: updated,
        successMessage: '프로필 사진이 변경됐어요.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _api.deleteAccount();
      state = state.copyWith(isSaving: false, shouldGoToLogin: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ─────────────────────────────────────────────
// 공통 페이지네이션 상태
// ─────────────────────────────────────────────

class _PagedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;

  const _PagedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
  });

  _PagedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
  }) => _PagedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    currentPage: currentPage ?? this.currentPage,
  );
}

// ─────────────────────────────────────────────
// 내가 쓴 글
// ─────────────────────────────────────────────

typedef MyPostsState = _PagedState<MyPostModel>;

class MyPostsNotifier extends StateNotifier<MyPostsState> {
  final ProfileApi _api;
  MyPostsNotifier(this._api) : super(const _PagedState());

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      items: [],
      currentPage: 0,
      hasMore: true,
    );
    try {
      final items = await _api.getMyPosts(page: 0);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getMyPosts(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final myPostsNotifierProvider =
    StateNotifierProvider<MyPostsNotifier, MyPostsState>((ref) {
      return MyPostsNotifier(ref.watch(profileApiProvider));
    });

// ─────────────────────────────────────────────
// 내가 쓴 댓글
// ─────────────────────────────────────────────

typedef MyCommentsState = _PagedState<MyCommentModel>;

class MyCommentsNotifier extends StateNotifier<MyCommentsState> {
  final ProfileApi _api;
  MyCommentsNotifier(this._api) : super(const _PagedState());

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      items: [],
      currentPage: 0,
      hasMore: true,
    );
    try {
      final items = await _api.getMyComments(page: 0);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getMyComments(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final myCommentsNotifierProvider =
    StateNotifierProvider<MyCommentsNotifier, MyCommentsState>((ref) {
      return MyCommentsNotifier(ref.watch(profileApiProvider));
    });

// ─────────────────────────────────────────────
// 내가 공감한 글
// ─────────────────────────────────────────────

typedef MyLikedPostsState = _PagedState<MyPostModel>;

class MyLikedPostsNotifier extends StateNotifier<MyLikedPostsState> {
  final ProfileApi _api;
  MyLikedPostsNotifier(this._api) : super(const _PagedState());

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      items: [],
      currentPage: 0,
      hasMore: true,
    );
    try {
      final items = await _api.getLikedPosts(page: 0);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getLikedPosts(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final myLikedPostsNotifierProvider =
    StateNotifierProvider<MyLikedPostsNotifier, MyLikedPostsState>((ref) {
      return MyLikedPostsNotifier(ref.watch(profileApiProvider));
    });

// ─────────────────────────────────────────────
// 내 북마크
// ─────────────────────────────────────────────

typedef MyBookmarksState = _PagedState<MyPostModel>;

class MyBookmarksNotifier extends StateNotifier<MyBookmarksState> {
  final ProfileApi _api;
  MyBookmarksNotifier(this._api) : super(const _PagedState());

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      items: [],
      currentPage: 0,
      hasMore: true,
    );
    try {
      final items = await _api.getMyBookmarks(page: 0);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await _api.getMyBookmarks(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final myBookmarksNotifierProvider =
    StateNotifierProvider<MyBookmarksNotifier, MyBookmarksState>((ref) {
      return MyBookmarksNotifier(ref.watch(profileApiProvider));
    });
