/// 게시글 작성 요청 DTO
class CreatePostRequest {
  final String title;
  final String content;
  final bool anonymous;
  final List<String>? pollOptions;

  const CreatePostRequest({
    required this.title,
    required this.content,
    required this.anonymous,
    this.pollOptions,
  });

  /// 백엔드 요청 바디로 변환
  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'content': content,
      'anonymous': anonymous,
    };
    if (pollOptions != null) {
      json['pollOptions'] = pollOptions!;
    }
    return json;
  }
}
