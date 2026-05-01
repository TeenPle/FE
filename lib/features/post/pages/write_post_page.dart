import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../models/create_post_request.dart';
import '../models/post_media_item.dart';
import '../models/update_post_request.dart';
import '../provider/post_detail_providers.dart';

/// 게시글 작성/수정 페이지
class WritePostPage extends ConsumerStatefulWidget {
  final int boardId;
  final String boardTitle;
  final bool isEditMode;
  final int? postId;
  final String? initialTitle;
  final String? initialContent;
  final bool? initialAnonymous;
  final List<PostMediaItem> initialMediaList;

  const WritePostPage({
    super.key,
    required this.boardId,
    required this.boardTitle,
    this.isEditMode = false,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialAnonymous,
    this.initialMediaList = const [],
  });

  @override
  ConsumerState<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends ConsumerState<WritePostPage> {
  static const int _titleLimit = 60;
  static const int _contentLimit = 2000;
  static const int _maxFiles = 5;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late bool _anonymous;
  bool _isSubmitting = false;
  List<PlatformFile> _selectedFiles = [];
  late List<PostMediaItem> _existingMedia;
  final List<int> _deletedMediaIds = [];

  int get _titleLength => _titleController.text.trim().length;
  int get _contentLength => _contentController.text.trim().length;

  bool get _canSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        _titleLength <= _titleLimit &&
        _contentLength <= _contentLimit &&
        !_isSubmitting;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    _anonymous = widget.initialAnonymous ?? true;
    _existingMedia = List.from(widget.initialMediaList);

    _titleController.addListener(_refresh);
    _contentController.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refresh);
    _contentController.removeListener(_refresh);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// PlatformFile → dio.MultipartFile 변환
  Future<MultipartFile> _toMultipartFile(PlatformFile pf) async {
    final contentType = _guessMediaType(pf.extension);
    final bytes = pf.path != null
        ? await File(pf.path!).readAsBytes()
        : pf.bytes!;
    return MultipartFile.fromBytes(
      bytes,
      filename: pf.name,
      contentType: contentType,
    );
  }

  MediaType _guessMediaType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  bool _isImageExtension(String? ext) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return imageExts.contains(ext?.toLowerCase());
  }

  Future<void> _pickFiles() async {
    final remaining = _maxFiles - _selectedFiles.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('첨부파일은 최대 $_maxFiles개까지 가능합니다.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final toAdd = result.files.take(remaining).toList();
    setState(() {
      _selectedFiles = [..._selectedFiles, ...toAdd];
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles = List.from(_selectedFiles)..removeAt(index);
    });
  }

  void _removeExistingMedia(int index) {
    setState(() {
      final removed = _existingMedia.removeAt(index);
      _deletedMediaIds.add(removed.mediaId);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final repository = ref.read(postRepositoryProvider);

    try {
      final multipartFiles = await Future.wait(
        _selectedFiles.map(_toMultipartFile),
      );

      if (widget.isEditMode) {
        await repository.updatePost(
          postId: widget.postId!,
          request: UpdatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            anonymous: _anonymous,
            deleteMediaIds: _deletedMediaIds,
          ),
          files: multipartFiles,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final postId = await repository.createPost(
          boardId: widget.boardId,
          request: CreatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            anonymous: _anonymous,
          ),
          files: multipartFiles,
        );

        if (!mounted) return;
        Navigator.pop(context, postId);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode ? '게시글 수정에 실패했습니다.' : '게시글 등록에 실패했습니다.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _onWillPop() async {
    final existingMediaChanged =
        widget.isEditMode && _deletedMediaIds.isNotEmpty;
    final hasInput = _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _selectedFiles.isNotEmpty ||
        existingMediaChanged;

    if (!hasInput) return true;

    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text(widget.isEditMode ? '수정을 취소할까요?' : '작성 중인 내용을 나갈까요?'),
            content: const Text('저장되지 않은 내용은 사라집니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('나가기'),
              ),
            ],
          ),
        ) ??
        false;

    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEditMode ? '게시글 수정' : '글쓰기';
    final submitText = widget.isEditMode ? '수정' : '등록';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        if (canLeave) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF7FAFC),
          foregroundColor: const Color(0xFF111111),
          title: Text(
            titleText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(
                  _isSubmitting
                      ? (widget.isEditMode ? '수정 중...' : '등록 중...')
                      : submitText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _canSubmit
                        ? const Color(0xFF14A3F7)
                        : const Color(0xFF9AA7B2),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 게시판 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD3EAFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dashboard_customize_rounded,
                      size: 18,
                      color: Color(0xFF14A3F7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '게시판: ${widget.boardTitle}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF167FC1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 작성 설정 (익명 토글)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6EDF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '작성 설정',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => setState(() => _anonymous = !_anonymous),
                      borderRadius: BorderRadius.circular(999),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            height: 28,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _anonymous
                                  ? const Color(0xFF14A3F7)
                                  : const Color(0xFFD7E0E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Align(
                              alignment: _anonymous
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '익명으로 작성',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '익명 커뮤니티 규칙에 따라 이름 대신 익명으로 표시됩니다.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7D8790),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 제목 + 본문 입력
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6EDF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldHeader(
                      title: '제목',
                      trailing: '$_titleLength/$_titleLimit',
                      isError: _titleLength > _titleLimit,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      maxLength: _titleLimit,
                      buildCounter: (_, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                      decoration: InputDecoration(
                        hintText: '제목을 입력하세요',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA7B2),
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FBFE),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldHeader(
                      title: '본문',
                      trailing: '$_contentLength/$_contentLimit',
                      isError: _contentLength > _contentLimit,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contentController,
                      maxLines: 14,
                      minLines: 10,
                      maxLength: _contentLimit,
                      buildCounter: (_, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Color(0xFF2F3740),
                      ),
                      decoration: InputDecoration(
                        hintText: '학교 생활, 질문, 정보 공유 등 자유롭게 작성해보세요.',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA7B2),
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FBFE),
                        contentPadding:
                            const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 첨부파일 섹션
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6EDF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '첨부파일',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedFiles.length}/$_maxFiles',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7D8790),
                          ),
                        ),
                      ],
                    ),
                    // 수정 모드에서 기존 첨부파일 표시
                    if (widget.isEditMode &&
                        _existingMedia.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '기존 첨부파일',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7D8790),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingMedia.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final media = _existingMedia[i];
                            return _ExistingMediaThumb(
                              url: media.url,
                              isImage: media.isImage,
                              onRemove: () => _removeExistingMedia(i),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 새로 선택된 파일 미리보기
                    if (_selectedFiles.isNotEmpty) ...[
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedFiles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final pf = _selectedFiles[i];
                            return _NewFileThumb(
                              platformFile: pf,
                              isImage: _isImageExtension(pf.extension),
                              onRemove: () => _removeFile(i),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectedFiles.length < _maxFiles
                            ? _pickFiles
                            : null,
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: const Text('파일 첨부'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF14A3F7),
                          side: const BorderSide(color: Color(0xFFD3EAFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 등록/수정 버튼
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF14A3F7),
                    disabledBackgroundColor: const Color(0xFFD9EAF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _isSubmitting
                        ? (widget.isEditMode ? '게시글 수정 중...' : '게시글 등록 중...')
                        : (widget.isEditMode ? '수정 완료' : '게시글 등록'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 수정 모드에서 기존 서버 이미지 썸네일 (삭제 버튼 포함)
class _ExistingMediaThumb extends StatelessWidget {
  final String url;
  final bool isImage;
  final VoidCallback onRemove;

  const _ExistingMediaThumb({
    required this.url,
    required this.isImage,
    required this.onRemove,
  });

  String get _filename {
    final decoded = Uri.decodeFull(url);
    return decoded.split('/').last.split('?').first;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6DEE7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isImage
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFF0F4F8)),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Color(0xFF9AA7B2),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_rounded,
                        color: Color(0xFF7D8790),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _filename,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF7D8790),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 새로 선택된 파일 썸네일 (삭제 버튼 포함)
class _NewFileThumb extends StatelessWidget {
  final PlatformFile platformFile;
  final bool isImage;
  final VoidCallback onRemove;

  const _NewFileThumb({
    required this.platformFile,
    required this.isImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6DEE7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isImage && platformFile.bytes != null
                ? Image.memory(
                    platformFile.bytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FilePlaceholder(),
                  )
                : isImage && platformFile.path != null
                    ? Image.file(
                        File(platformFile.path!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _FilePlaceholder(),
                      )
                    : _FilePlaceholder(name: platformFile.name),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        // 파일명 레이블
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Text(
              platformFile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  final String? name;
  const _FilePlaceholder({this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.insert_drive_file_rounded,
          color: Color(0xFF7D8790),
          size: 28,
        ),
        if (name != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF7D8790),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 입력 영역 제목과 글자 수를 표시하는 위젯
class _FieldHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final bool isError;

  const _FieldHeader({
    required this.title,
    required this.trailing,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final trailingColor =
        isError ? const Color(0xFFE14B4B) : const Color(0xFF7D8790);

    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: trailingColor,
          ),
        ),
      ],
    );
  }
}
