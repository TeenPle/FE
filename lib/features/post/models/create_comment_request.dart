class CreateCommentRequest {
  final String content;
  final bool anonymous;
  final int? parentId;

  const CreateCommentRequest({
    required this.content,
    this.anonymous = false,
    required this.parentId,
  });

  Map<String, dynamic> toJson() {
    return {'content': content, 'anonymous': false, 'parentId': parentId};
  }
}
