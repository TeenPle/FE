import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/app_api_client.dart';
import '../models/my_comment_model.dart';
import '../models/my_post_model.dart';
import '../models/profile_model.dart';

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
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    final response = ApiResponse.fromJson(json, (data) => data);
    if (!response.isSuccess) throw Exception(response.message);
  }

  Future<List<MyPostModel>> getMyPosts({int page = 0, int size = 20}) async {
    final json = await client.get(
      '/api/users/me/posts',
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

  Future<List<MyCommentModel>> getMyComments(
      {int page = 0, int size = 20}) async {
    final json = await client.get(
      '/api/users/me/comments',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = ApiResponse.fromJson(json, (data) {
      final list = data as List<dynamic>;
      return list
          .map((e) => MyCommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    if (!response.isSuccess || response.result == null) {
      throw Exception(response.message);
    }
    return response.result!;
  }

  Future<String> updateProfileImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');
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

  Future<List<MyPostModel>> getLikedPosts({int page = 0, int size = 20}) async {
    final json = await client.get(
      '/api/users/me/liked-posts',
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
}
