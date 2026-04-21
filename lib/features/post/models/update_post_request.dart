/// 게시글 수정 요청 DTO
class UpdatePostRequest {
  final String title;
  final String content;
  final bool anonymous;
  final List<int> deleteMediaIds;

  const UpdatePostRequest({
    required this.title,
    required this.content,
    required this.anonymous,
    this.deleteMediaIds = const [],
  });

  /// 백엔드 요청 바디로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'anonymous': anonymous,
      'deleteMediaIds': deleteMediaIds,
    };
  }
}