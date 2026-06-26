class AdminSchoolModel {
  final int id;
  final String name;
  final int? regionId;
  final String? regionName;
  final String? neisOfficeCode;
  final String? neisSchoolCode;

  const AdminSchoolModel({
    required this.id,
    required this.name,
    this.regionId,
    this.regionName,
    this.neisOfficeCode,
    this.neisSchoolCode,
  });

  factory AdminSchoolModel.fromJson(Map<String, dynamic> json) {
    return AdminSchoolModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      regionId: json['regionId'] != null
          ? (json['regionId'] as num).toInt()
          : null,
      regionName: json['regionName'] as String?,
      neisOfficeCode: json['neisOfficeCode'] as String?,
      neisSchoolCode: json['neisSchoolCode'] as String?,
    );
  }
}

class AdminBoardModel {
  final int id;
  final String title;
  final String? description;
  final String scope;
  final bool active;
  final int? schoolId;
  final String? schoolName;
  final int? regionId;
  final String? regionName;
  final int postCount;

  const AdminBoardModel({
    required this.id,
    required this.title,
    this.description,
    required this.scope,
    required this.active,
    this.schoolId,
    this.schoolName,
    this.regionId,
    this.regionName,
    required this.postCount,
  });

  factory AdminBoardModel.fromJson(Map<String, dynamic> json) {
    return AdminBoardModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      scope: json['scope'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      schoolId: json['schoolId'] != null
          ? (json['schoolId'] as num).toInt()
          : null,
      schoolName: json['schoolName'] as String?,
      regionId: json['regionId'] != null
          ? (json['regionId'] as num).toInt()
          : null,
      regionName: json['regionName'] as String?,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get scopeLabel => scope == 'REGION' ? '지역 게시판' : '학교 게시판';
}

class AdminPostSummaryModel {
  final int postId;
  final String title;
  final String contentPreview;
  final String postStatus;
  final bool anonymous;
  final int authorUserId;
  final String authorLabel;
  final int boardId;
  final String boardTitle;
  final int? schoolId;
  final String? schoolName;
  final int? regionId;
  final String? regionName;
  final int viewCount;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final DateTime createdAt;

  const AdminPostSummaryModel({
    required this.postId,
    required this.title,
    required this.contentPreview,
    required this.postStatus,
    required this.anonymous,
    required this.authorUserId,
    required this.authorLabel,
    required this.boardId,
    required this.boardTitle,
    this.schoolId,
    this.schoolName,
    this.regionId,
    this.regionName,
    required this.viewCount,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory AdminPostSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminPostSummaryModel(
      postId: (json['postId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      contentPreview: json['contentPreview'] as String? ?? '',
      postStatus: json['postStatus'] as String? ?? '',
      anonymous: json['anonymous'] as bool? ?? true,
      authorUserId: (json['authorUserId'] as num?)?.toInt() ?? 0,
      authorLabel: json['authorLabel'] as String? ?? '알 수 없음',
      boardId: (json['boardId'] as num).toInt(),
      boardTitle: json['boardTitle'] as String? ?? '',
      schoolId: json['schoolId'] != null
          ? (json['schoolId'] as num).toInt()
          : null,
      schoolName: json['schoolName'] as String?,
      regionId: json['regionId'] != null
          ? (json['regionId'] as num).toInt()
          : null,
      regionName: json['regionName'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminMediaModel {
  final int mediaId;
  final String url;
  final String mediaType;

  const AdminMediaModel({
    required this.mediaId,
    required this.url,
    required this.mediaType,
  });

  factory AdminMediaModel.fromJson(Map<String, dynamic> json) {
    return AdminMediaModel(
      mediaId: (json['mediaId'] as num).toInt(),
      url: json['url'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
    );
  }

  bool get isImage {
    final lower = url.toLowerCase().split('?').first;
    return mediaType.toUpperCase() == 'IMAGE' ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}

class AdminCommentModel {
  final int commentId;
  final int authorUserId;
  final String authorLabel;
  final bool anonymous;
  final String commentStatus;
  final String content;
  final int likeCount;
  final int dislikeCount;
  final int depth;
  final int? parentId;
  final DateTime createdAt;

  const AdminCommentModel({
    required this.commentId,
    required this.authorUserId,
    required this.authorLabel,
    required this.anonymous,
    required this.commentStatus,
    required this.content,
    required this.likeCount,
    required this.dislikeCount,
    required this.depth,
    this.parentId,
    required this.createdAt,
  });

  factory AdminCommentModel.fromJson(Map<String, dynamic> json) {
    return AdminCommentModel(
      commentId: (json['commentId'] as num).toInt(),
      authorUserId: (json['authorUserId'] as num?)?.toInt() ?? 0,
      authorLabel: json['authorLabel'] as String? ?? '알 수 없음',
      anonymous: json['anonymous'] as bool? ?? true,
      commentStatus: json['commentStatus'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] != null
          ? (json['parentId'] as num).toInt()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminPostDetailModel extends AdminPostSummaryModel {
  final String content;
  final List<AdminMediaModel> mediaList;
  final List<AdminCommentModel> comments;

  const AdminPostDetailModel({
    required super.postId,
    required super.title,
    required this.content,
    required super.postStatus,
    required super.anonymous,
    required super.authorUserId,
    required super.authorLabel,
    required super.boardId,
    required super.boardTitle,
    super.schoolId,
    super.schoolName,
    super.regionId,
    super.regionName,
    required super.viewCount,
    required super.likeCount,
    required super.dislikeCount,
    required super.commentCount,
    required super.createdAt,
    required this.mediaList,
    required this.comments,
  }) : super(contentPreview: content);

  factory AdminPostDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminPostDetailModel(
      postId: (json['postId'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      postStatus: json['postStatus'] as String? ?? '',
      anonymous: json['anonymous'] as bool? ?? true,
      authorUserId: (json['authorUserId'] as num?)?.toInt() ?? 0,
      authorLabel: json['authorLabel'] as String? ?? '알 수 없음',
      boardId: (json['boardId'] as num).toInt(),
      boardTitle: json['boardTitle'] as String? ?? '',
      schoolId: json['schoolId'] != null
          ? (json['schoolId'] as num).toInt()
          : null,
      schoolName: json['schoolName'] as String?,
      regionId: json['regionId'] != null
          ? (json['regionId'] as num).toInt()
          : null,
      regionName: json['regionName'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mediaList: (json['mediaList'] as List<dynamic>? ?? [])
          .map((e) => AdminMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => AdminCommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
