/// 댓글 수정 요청 DTO
class UpdateCommentRequest {
  final String content;
  final bool anonymous;

  const UpdateCommentRequest({
    required this.content,
    required this.anonymous,
  });

  /// 백엔드 요청 바디로 변환
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'anonymous': anonymous,
    };
  }
}