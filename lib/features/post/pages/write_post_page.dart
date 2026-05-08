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
import '../../school/models/board_model.dart';
import 'widgets/crisis_banner.dart';

/// 게시글 작성/수정 페이지
class WritePostPage extends ConsumerStatefulWidget {
  final int? boardId;
  final String boardTitle;
  final List<BoardModel> availableBoards;
  final bool isEditMode;
  final int? postId;
  final String? initialTitle;
  final String? initialContent;
  final bool? initialAnonymous;
  final List<PostMediaItem> initialMediaList;
  final List<String>? initialPollOptions;

  const WritePostPage({
    super.key,
    this.boardId,
    this.boardTitle = '',
    this.availableBoards = const [],
    this.isEditMode = false,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialAnonymous,
    this.initialMediaList = const [],
    this.initialPollOptions,
  });

  @override
  ConsumerState<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends ConsumerState<WritePostPage> {
  static const int _titleLimit = 100;
  static const int _contentLimit = 2000;
  static const int _maxFiles = 5;
  static const int _maxPollOptions = 5;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late bool _anonymous;
  bool _isSubmitting = false;
  late bool _pollEnabled;
  late List<TextEditingController> _pollOptionControllers;
  int? _selectedBoardId;
  late String _selectedBoardTitle;
  List<PlatformFile> _selectedFiles = [];
  late List<PostMediaItem> _existingMedia;
  final List<int> _deletedMediaIds = [];

  int get _titleLength => _titleController.text.trim().length;
  int get _contentLength => _contentController.text.trim().length;
  bool get _showCrisisBanner =>
      CrisisBanner.containsCrisisKeyword(_titleController.text) ||
      CrisisBanner.containsCrisisKeyword(_contentController.text);

  List<String> get _pollOptions => _pollOptionControllers
      .map((controller) => controller.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();

  bool get _isPollValid {
    if (!_pollEnabled) return true;
    return _pollOptions.length >= 2 && _pollOptions.length <= _maxPollOptions;
  }

  bool get _canSubmit {
    return (widget.isEditMode || _selectedBoardId != null) &&
        _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        _titleLength <= _titleLimit &&
        _contentLength <= _contentLimit &&
        _isPollValid &&
        !_isSubmitting;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    _anonymous = widget.isEditMode ? (widget.initialAnonymous ?? true) : true;
    _selectedBoardId = widget.boardId;
    _selectedBoardTitle = widget.boardTitle;
    _existingMedia = List.from(widget.initialMediaList);
    final initialPollOptions = widget.initialPollOptions ?? const [];
    _pollEnabled = initialPollOptions.isNotEmpty;
    final pollTexts = _pollEnabled ? initialPollOptions : ['', ''];
    _pollOptionControllers = pollTexts
        .take(_maxPollOptions)
        .map((text) => TextEditingController(text: text))
        .toList();
    while (_pollOptionControllers.length < 2) {
      _pollOptionControllers.add(TextEditingController());
    }

    _titleController.addListener(_refresh);
    _contentController.addListener(_refresh);
    for (final controller in _pollOptionControllers) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_refresh);
    _contentController.removeListener(_refresh);
    _titleController.dispose();
    _contentController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.removeListener(_refresh);
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _togglePoll() {
    setState(() {
      _pollEnabled = !_pollEnabled;
      if (_pollEnabled && _pollOptionControllers.length < 2) {
        _pollOptionControllers = [TextEditingController(), TextEditingController()];
        for (final controller in _pollOptionControllers) {
          controller.addListener(_refresh);
        }
      }
    });
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= _maxPollOptions) return;
    final controller = TextEditingController()..addListener(_refresh);
    setState(() => _pollOptionControllers.add(controller));
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) return;
    final controller = _pollOptionControllers.removeAt(index);
    controller.removeListener(_refresh);
    controller.dispose();
    setState(() {});
  }

  /// PlatformFile → dio.MultipartFile 변환
  Future<MultipartFile> _toMultipartFile(PlatformFile pf) async {
    final contentType = _guessMediaType(pf.extension);
    if (pf.path != null) {
      return MultipartFile.fromFile(
        pf.path!,
        filename: pf.name,
        contentType: contentType,
      );
    }
    return MultipartFile.fromBytes(
      pf.bytes!,
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
    final remaining = _maxFiles - _selectedFiles.length - _existingMedia.length;
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

    final oversized = result.files
        .where((f) => (f.size) > _maxFileSizeBytes)
        .map((f) => f.name)
        .toList();

    if (oversized.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '파일 크기는 10MB를 초과할 수 없습니다.\n초과 파일: ${oversized.join(', ')}',
          ),
        ),
      );
    }

    final valid = result.files
        .where((f) => f.size <= _maxFileSizeBytes)
        .take(remaining)
        .toList();

    if (valid.isEmpty) return;
    setState(() {
      _selectedFiles = [..._selectedFiles, ...valid];
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
            pollOptions: _pollEnabled ? _pollOptions : <String>[],
          ),
          files: multipartFiles,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final postId = await repository.createPost(
          boardId: _selectedBoardId!,
          request: CreatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            anonymous: _anonymous,
            pollOptions: _pollEnabled ? _pollOptions : null,
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
        (_pollEnabled && _pollOptions.isNotEmpty) ||
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

  Future<void> _showBoardPicker() async {
    if (widget.isEditMode || widget.availableBoards.isEmpty) return;

    final board = await showModalBottomSheet<BoardModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E2EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '게시판 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.availableBoards.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFEAF1F7),
                  ),
                  itemBuilder: (context, index) {
                    final board = widget.availableBoards[index];
                    final selected = board.id == _selectedBoardId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        board.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected
                              ? const Color(0xFF2F80ED)
                              : const Color(0xFF111827),
                        ),
                      ),
                      subtitle: board.description.isEmpty
                          ? null
                          : Text(
                              board.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF2F80ED),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, board),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (board == null || !mounted) return;
    setState(() {
      _selectedBoardId = board.id;
      _selectedBoardTitle = board.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEditMode ? '게시글 수정' : '새 글 작성';
    final submitText = widget.isEditMode ? '수정하기' : '등록하기';
    final attachedCount = _existingMedia.length + _selectedFiles.length;

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
        backgroundColor: const Color(0xFFF7FBFF),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 82,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () async {
                          if (await _onWillPop() && mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 34,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: 0,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2F80ED),
                            disabledBackgroundColor: const Color(0xFFD8E8FA),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSubmitting ? '등록 중...' : submitText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE9F0F7)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                  children: [
                    _WriteCard(
                      height: 82,
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: _showBoardPicker,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Row(
                            children: [
                              _CircleIconBadge(
                                icon: Icons.article_outlined,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _selectedBoardTitle.isEmpty
                                      ? '게시판 선택'
                                      : _selectedBoardTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedBoardId == null
                                        ? const Color(0xFF8B95A1)
                                        : const Color(0xFF111827),
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              if (!widget.isEditMode)
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF2F80ED),
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WriteCard(
                      height: 90,
                      child: InkWell(
                        onTap: () => setState(() => _anonymous = !_anonymous),
                        borderRadius: BorderRadius.circular(18),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '익명',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '닉네임이 노출되지 않아요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8B95A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SquareCheckBox(
                              checked: _anonymous,
                              onTap: () =>
                                  setState(() => _anonymous = !_anonymous),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WriteCard(
                      height: 82,
                      padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              maxLength: _titleLimit,
                              buildCounter: (_, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) =>
                                  const SizedBox.shrink(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                letterSpacing: 0,
                              ),
                              decoration: _plainInputDecoration('제목'),
                            ),
                          ),
                          Text(
                            '$_titleLength/$_titleLimit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _titleLength > _titleLimit
                                  ? const Color(0xFFE14B4B)
                                  : const Color(0xFF8B95A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WriteCard(
                      height: 330,
                      padding: const EdgeInsets.fromLTRB(20, 18, 24, 20),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            maxLength: _contentLimit,
                            buildCounter: (_, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) =>
                                const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.55,
                              color: Color(0xFF2F3740),
                              letterSpacing: 0,
                            ),
                            decoration: _plainInputDecoration('내용을 입력해주세요'),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Text(
                              '$_contentLength/$_contentLimit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _contentLength > _contentLimit
                                    ? const Color(0xFFE14B4B)
                                    : const Color(0xFF8B95A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showCrisisBanner) ...[
                      const SizedBox(height: 14),
                      const CrisisBanner(),
                    ],
                    const SizedBox(height: 14),
                    _WriteCard(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '첨부파일',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '(최대 5개)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B95A1),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$attachedCount/$_maxFiles',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2F80ED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _AttachmentSlots(
                            existingMedia: _existingMedia,
                            selectedFiles: _selectedFiles,
                            isImageExtension: _isImageExtension,
                            onAdd: attachedCount < _maxFiles ? _pickFiles : null,
                            onRemoveExisting: _removeExistingMedia,
                            onRemoveSelected: _removeFile,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '파일당 10MB 이하 | jpg, jpeg, png, gif, webp, pdf',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B95A1),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PollEditorSection(
                      enabled: _pollEnabled,
                      controllers: _pollOptionControllers,
                      maxOptions: _maxPollOptions,
                      isValid: _isPollValid,
                      onToggle: _togglePoll,
                      onAdd: _addPollOption,
                      onRemove: _removePollOption,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _plainInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF8B95A1),
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );
  }
}

class _WriteCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  const _WriteCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const _CircleIconBadge({required this.icon, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F6FC),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF2F80ED), size: size * 0.52),
    );
  }
}

class _SquareCheckBox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const _SquareCheckBox({
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF2F80ED) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? const Color(0xFF2F80ED) : const Color(0xFFD6E0EA),
            width: 2,
          ),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _AttachmentSlots extends StatelessWidget {
  final List<PostMediaItem> existingMedia;
  final List<PlatformFile> selectedFiles;
  final bool Function(String? extension) isImageExtension;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveSelected;

  const _AttachmentSlots({
    required this.existingMedia,
    required this.selectedFiles,
    required this.isImageExtension,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final totalExisting = existingMedia.length;
        final totalSelected = selectedFiles.length;

        Widget child;
        VoidCallback? onTap;
        if (index < totalExisting) {
          final media = existingMedia[index];
          child = _ExistingMediaThumb(
            url: media.url,
            isImage: media.isImage,
            onRemove: () => onRemoveExisting(index),
          );
        } else if (index < totalExisting + totalSelected) {
          final selectedIndex = index - totalExisting;
          final file = selectedFiles[selectedIndex];
          child = _NewFileThumb(
            platformFile: file,
            isImage: isImageExtension(file.extension),
            onRemove: () => onRemoveSelected(selectedIndex),
          );
        } else if (index == totalExisting + totalSelected) {
          child = const _AddFileSlot();
          onTap = onAdd;
        } else {
          child = const _EmptyFileSlot();
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
            child: GestureDetector(
              onTap: onTap,
              child: AspectRatio(aspectRatio: 1, child: child),
            ),
          ),
        );
      }),
    );
  }
}

class _AddFileSlot extends StatelessWidget {
  const _AddFileSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9D9FF), width: 1.4),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Color(0xFF2F80ED), size: 34),
          SizedBox(height: 4),
          Text(
            '파일 추가',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F80ED),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFileSlot extends StatelessWidget {
  const _EmptyFileSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9D9FF), width: 1.2),
      ),
    );
  }
}

class _PollEditorSection extends StatelessWidget {
  final bool enabled;
  final List<TextEditingController> controllers;
  final int maxOptions;
  final bool isValid;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PollEditorSection({
    required this.enabled,
    required this.controllers,
    required this.maxOptions,
    required this.isValid,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _WriteCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CircleIconBadge(
                icon: Icons.bar_chart_rounded,
                size: 50,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '투표 추가',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '투표로 의견을 모아보세요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B95A1),
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF2F80ED),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD7DDE5),
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            ...controllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLength: 100,
                        buildCounter: (_, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => const SizedBox.shrink(),
                        decoration: InputDecoration(
                          hintText: '항목 ${index + 1}',
                          filled: true,
                          fillColor: const Color(0xFFF8FBFE),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '항목 삭제',
                      onPressed: controllers.length > 2
                          ? () => onRemove(index)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: const Color(0xFFE05C5C),
                    ),
                  ],
                ),
              );
            }),
            if (!isValid)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '투표 항목은 최소 2개 입력해야 합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE05C5C),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controllers.length < maxOptions ? onAdd : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('항목 추가 (${controllers.length}/$maxOptions)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F80ED),
                  side: const BorderSide(color: Color(0xFFD3EAFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
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
          width: double.infinity,
          height: double.infinity,
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
          width: double.infinity,
          height: double.infinity,
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
