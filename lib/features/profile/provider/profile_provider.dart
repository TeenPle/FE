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

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
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
        successMessage: '닉네임이 변경되었습니다.',
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
      state = state.copyWith(
        isSaving: false,
        successMessage: '비밀번호가 변경되었습니다.',
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

  Future<bool> updateProfileImage(File imageFile) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final url = await _api.updateProfileImage(imageFile);
      final updated = await _api.getMyProfile();
      state = state.copyWith(
        isSaving: false,
        profile: updated,
        successMessage: '프로필 사진이 변경되었습니다.',
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

// 내가 쓴 글 목록 — FutureProvider (간단한 단방향 로드)
final myPostsProvider =
    FutureProvider.family<List<MyPostModel>, int>((ref, page) async {
  return ref.watch(profileApiProvider).getMyPosts(page: page);
});

// 내가 쓴 댓글 목록
final myCommentsProvider =
    FutureProvider.family<List<MyCommentModel>, int>((ref, page) async {
  return ref.watch(profileApiProvider).getMyComments(page: page);
});

// 내가 공감한 글 목록
final myLikedPostsProvider =
    FutureProvider.family<List<MyPostModel>, int>((ref, page) async {
  return ref.watch(profileApiProvider).getLikedPosts(page: page);
});
