class CreateCommentRequest {
  final String content;
  final bool anonymous;
  final int? parentId;

  const CreateCommentRequest({
    required this.content,
    required this.anonymous,
    required this.parentId,
  });

  Map<String, dynamic> toJson() {
    return {'content': content, 'anonymous': anonymous, 'parentId': parentId};
  }
}
