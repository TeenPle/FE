/// 게시글 수정 요청 DTO
class UpdatePostRequest {
  final String title;
  final String content;
  final bool anonymous;

  const UpdatePostRequest({
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