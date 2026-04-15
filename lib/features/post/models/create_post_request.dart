/// 게시글 작성 요청 DTO
class CreatePostRequest {
  final String title;
  final String content;
  final bool anonymous;

  const CreatePostRequest({
    required this.title,
    required this.content,
    required this.anonymous,
  });

  /// 백엔드 요청 바디로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'anonymous': anonymous,
    };
  }
}