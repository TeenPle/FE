import 'board_model.dart';
import 'post_summary.dart';

class SchoolResponse {
  final int schoolId;
  final String name;
  final String description;
  final List<BoardModel> boards;
  final List<PostSummary> posts;
  final bool hasNext;

  const SchoolResponse({
    required this.schoolId,
    required this.name,
    required this.description,
    required this.boards,
    required this.posts,
    required this.hasNext,
  });

  factory SchoolResponse.fromJson(Map<String, dynamic> json) {
    return SchoolResponse(
      schoolId: json['schoolId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      boards: (json['boards'] as List<dynamic>? ?? [])
          .map((e) => BoardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      posts: (json['posts'] as List<dynamic>? ?? [])
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}