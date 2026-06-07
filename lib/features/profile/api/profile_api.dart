import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/my_comment_model.dart';
import '../models/my_post_model.dart';
import '../models/profile_model.dart';

class ProfilePageResult<T> {
  final List<T> items;
  final bool hasMore;

  const ProfilePageResult({required this.items, required this.hasMore});
}

class ProfileApi {
  final AppApiClient client;

  const ProfileApi({required this.client});

  Future<ProfileModel> getMyProfile() async {
    final json = await client.get('/api/users/me');
    final response = ApiResponse.fromJson(
      json,
      (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
    );
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<void> updateNickname(String nickname) async {
    final json = await client.patch(
      '/api/users/me/nickname',
      body: {'nickname': nickname},
    );
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final json = await client.patch(
      '/api/users/me/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  Future<ProfilePageResult<MyPostModel>> getMyPosts({
    int page = 0,
    int size = 20,
  }) async {
    final json = await client.get(
      '/api/users/me/posts',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = ApiResponse.fromJson(json, (data) {
      return _parsePage(
        data,
        (e) => MyPostModel.fromJson(e as Map<String, dynamic>),
        pageSize: size,
      );
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<ProfilePageResult<MyCommentModel>> getMyComments({
    int page = 0,
    int size = 20,
  }) async {
    final json = await client.get(
      '/api/users/me/comments',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = ApiResponse.fromJson(json, (data) {
      return _parsePage(
        data,
        (e) => MyCommentModel.fromJson(e as Map<String, dynamic>),
        pageSize: size,
      );
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<String> updateProfileImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => MediaType('image', 'png'),
      'heic' => MediaType('image', 'heic'),
      'heif' => MediaType('image', 'heif'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };
    final multipartFile = await MultipartFile.fromFile(
      imageFile.path,
      filename: 'profile.$ext',
      contentType: contentType,
    );
    final json = await client.patchMultipartFile(
      '/api/users/me/profile-image',
      file: multipartFile,
    );
    final response = ApiResponse.fromJson(json, (data) => data as String);
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<List<MyPostModel>> getMyBookmarks({
    int page = 0,
    int size = 20,
  }) async {
    final json = await client.get(
      '/api/users/me/bookmarks',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = ApiResponse.fromJson(json, (data) {
      final list = data as List<dynamic>;
      return list
          .map((e) => MyPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<void> deleteAccount() async {
    final json = await client.delete('/api/users/me');
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  ProfilePageResult<T> _parsePage<T>(
    dynamic data,
    T Function(dynamic) parser, {
    required int pageSize,
  }) {
    if (data is List<dynamic>) {
      return ProfilePageResult(
        items: data.map(parser).toList(),
        hasMore: data.length >= pageSize,
      );
    }

    final map = data as Map<String, dynamic>;
    final content = map['content'] as List<dynamic>? ?? [];
    return ProfilePageResult(
      items: content.map(parser).toList(),
      hasMore: _hasMore(map),
    );
  }

  bool _hasMore(Map<String, dynamic> map) {
    if (map['hasNext'] is bool) return map['hasNext'] as bool;
    if (map['last'] is bool) return !(map['last'] as bool);
    return false;
  }
}
