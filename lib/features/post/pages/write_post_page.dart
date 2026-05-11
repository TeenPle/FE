import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/theme/app_colors.dart';
import '../../school/models/board_model.dart';
import '../models/create_post_request.dart';
import '../models/post_media_item.dart';
import '../models/update_post_request.dart';
import '../provider/post_detail_providers.dart';
import 'widgets/crisis_banner.dart';


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
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late bool _anonymous;
  bool _isSubmitting = false;
  int? _selectedBoardId;
  late String _selectedBoardTitle;
  List<String> _pollOptions = [];
  List<PlatformFile> _selectedFiles = [];
  late List<PostMediaItem> _existingMedia;
  final List<int> _deletedMediaIds = [];

  int get _titleLength => _titleController.text.trim().length;
  int get _contentLength => _contentController.text.trim().length;
  int get _attachedCount => _existingMedia.length + _selectedFiles.length;
  bool get _showCrisisBanner =>
      CrisisBanner.containsCrisisKeyword(_titleController.text) ||
          CrisisBanner.containsCrisisKeyword(_contentController.text);

  bool get _canSubmit {
    return (widget.isEditMode || _selectedBoardId != null) &&
        _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        _titleLength <= _titleLimit &&
        _contentLength <= _contentLimit &&
        !_isSubmitting;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _anonymous = widget.isEditMode ? (widget.initialAnonymous ?? true) : true;
    _selectedBoardId = widget.boardId;
    _selectedBoardTitle = widget.boardTitle;
    _existingMedia = List.from(widget.initialMediaList);
    _pollOptions = (widget.initialPollOptions ?? const [])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(_maxPollOptions)
        .toList();

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
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  bool _isImageExtension(String? ext) {
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return imageExts.contains(ext?.toLowerCase());
  }

  Future<void> _pickFiles() async {
    final remaining = _maxFiles - _attachedCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일은 최대 5개까지 가능합니다.')),
      );
      return;
    }

    // FileType.image → 갤러리 바로 오픈
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return;

    final oversized = result.files
        .where((f) => f.size > _maxFileSizeBytes)
        .map((f) => f.name)
        .toList();
    if (oversized.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('10MB를 초과한 파일은 제외됩니다.\n${oversized.join(', ')}')),
      );
    }

    final valid = result.files
        .where((f) => f.size <= _maxFileSizeBytes)
        .take(remaining)
        .toList();
    if (valid.isEmpty) return;
    setState(() => _selectedFiles = [..._selectedFiles, ...valid]);
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles = List.from(_selectedFiles)..removeAt(index));
  }

  void _removeExistingMedia(int index) {
    setState(() {
      final removed = _existingMedia.removeAt(index);
      _deletedMediaIds.add(removed.mediaId);
    });
  }

  Future<void> _openPollForm() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _PollFormPage(
          initialOptions: _pollOptions,
          maxOptions: _maxPollOptions,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _pollOptions = result);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final repository = ref.read(postRepositoryProvider);
    try {
      final multipartFiles = await Future.wait(_selectedFiles.map(_toMultipartFile));

      if (widget.isEditMode) {
        await repository.updatePost(
          postId: widget.postId!,
          request: UpdatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            anonymous: _anonymous,
            deleteMediaIds: _deletedMediaIds,
            pollOptions: _pollOptions,
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
            pollOptions: _pollOptions.isEmpty ? null : _pollOptions,
          ),
          files: multipartFiles,
        );
        if (!mounted) return;
        Navigator.pop(context, postId);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditMode ? '게시글 수정에 실패했습니다.' : '게시글 등록에 실패했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _onWillPop() async {
    final existingMediaChanged = widget.isEditMode && _deletedMediaIds.isNotEmpty;
    final hasInput = _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _selectedFiles.isNotEmpty ||
        _pollOptions.isNotEmpty ||
        existingMediaChanged;
    if (!hasInput) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isEditMode ? '수정을 취소할까요?' : '작성 중인 내용을 나갈까요?'),
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
  }

  Future<void> _showBoardPicker() async {
    if (widget.isEditMode || widget.availableBoards.isEmpty) return;

    final board = await showModalBottomSheet<BoardModel>(
      context: context,
      backgroundColor: context.colors.cardBg,
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
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '게시판 선택',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.availableBoards.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.borderSubtle),
                  itemBuilder: (context, index) {
                    final board = widget.availableBoards[index];
                    final selected = board.id == _selectedBoardId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        board.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected ? const Color(0xFF2F80ED) : context.colors.textBody,
                        ),
                      ),
                      subtitle: board.description.isEmpty
                          ? null
                          : Text(
                        board.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: selected ? const Icon(Icons.check_rounded, color: Color(0xFF2F80ED)) : null,
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
    final titleText = widget.isEditMode ? '게시글 수정' : '글 작성';
    final submitText = widget.isEditMode ? '수정' : '등록';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (!mounted) return;
        if (canLeave) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.colors.pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _WriteHeader(
                title: titleText,
                submitText: _isSubmitting ? '저장 중' : submitText,
                canSubmit: _canSubmit,
                onClose: () async {
                  if (await _onWillPop() && mounted) Navigator.pop(context);
                },
                onSubmit: _submit,
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
                  children: [
                    _BoardSelectorLine(
                      title: _selectedBoardTitle.isEmpty ? '게시판 선택' : _selectedBoardTitle,
                      selected: _selectedBoardId != null,
                      enabled: !widget.isEditMode && widget.availableBoards.isNotEmpty,
                      onTap: _showBoardPicker,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      maxLength: _titleLimit,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                      const SizedBox.shrink(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.28,
                        color: context.colors.textPrimary,
                        letterSpacing: 0,
                      ),
                      decoration: _plainInputDecoration('제목'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: _titleLength > _titleLimit
                                  ? const Color(0xFFE14B4B)
                                  : const Color(0xFFDDEAF6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_titleLength/$_titleLimit',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _titleLength > _titleLimit
                                  ? const Color(0xFFE14B4B)
                                  : const Color(0xFF8B95A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: _contentController,
                      minLines: 14,
                      maxLines: null,
                      maxLength: _contentLimit,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                      const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.58,
                        color: Color(0xFF26323F),
                        letterSpacing: 0,
                      ),
                      decoration: _plainInputDecoration('내용을 입력해주세요'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_contentLength/$_contentLimit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _contentLength > _contentLimit
                              ? const Color(0xFFE14B4B)
                              : const Color(0xFF8B95A1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _PostWritingGuidelines(),
                    if (_showCrisisBanner) ...[
                      const SizedBox(height: 14),
                      const CrisisBanner(),
                    ],
                    if (_attachedCount > 0) ...[
                      const SizedBox(height: 18),
                      _AttachmentPreviewStrip(
                        existingMedia: _existingMedia,
                        selectedFiles: _selectedFiles,
                        isImageExtension: _isImageExtension,
                        onRemoveExisting: _removeExistingMedia,
                        onRemoveSelected: _removeFile,
                      ),
                    ],
                    if (_pollOptions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _PollSummaryStrip(
                        count: _pollOptions.length,
                        onEdit: _openPollForm,
                        onClear: () => setState(() => _pollOptions = []),
                      ),
                    ],
                  ],
                ),
              ),
              _WriteBottomToolbar(
                anonymous: _anonymous,
                attachedCount: _attachedCount,
                maxFiles: _maxFiles,
                pollCount: _pollOptions.length,
                canSubmit: _canSubmit,
                submitText: _isSubmitting ? '저장 중' : submitText,
                onAnonymousChanged: (value) => setState(() => _anonymous = value),
                onAttach: _attachedCount < _maxFiles ? _pickFiles : null,
                onPoll: _openPollForm,
                onSubmit: _submit,
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
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0,
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );
  }
}

class _WriteHeader extends StatelessWidget {
  final String title;
  final String submitText;
  final bool canSubmit;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const _WriteHeader({
    required this.title,
    required this.submitText,
    required this.canSubmit,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 28, color: c.iconPrimary),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: c.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: canSubmit ? onSubmit : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F80ED),
              disabledForegroundColor: const Color(0xFFB8CCDF),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              submitText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardSelectorLine extends StatelessWidget {
  final String title;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _BoardSelectorLine({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: 18,
              color: selected ? const Color(0xFF2F80ED) : const Color(0xFF8B95A1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? const Color(0xFF2F80ED) : const Color(0xFF8B95A1),
                ),
              ),
            ),
            if (enabled)
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2F80ED), size: 22),
          ],
        ),
      ),
    );
  }
}

class _PostWritingGuidelines extends StatelessWidget {
  const _PostWritingGuidelines();

  static const List<String> _rules = [
    '실명, 연락처, 주소, 학교 밖 개인정보는 올리지 마세요.',
    '욕설, 괴롭힘, 성적 표현, 혐오 표현은 삭제될 수 있어요.',
    '친구나 선생님을 특정해 비난하거나 소문을 퍼뜨리지 마세요.',
    '위험한 상황이거나 도움이 필요하면 믿을 수 있는 어른에게 알려주세요.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFDDEAF6)),
          bottom: BorderSide(color: Color(0xFFDDEAF6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: Color(0xFF2F80ED)),
              SizedBox(width: 6),
              Text(
                '게시글 작성 규칙',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27415C),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._rules.map(
                (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.only(top: 6, right: 7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B95A1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667789),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteBottomToolbar extends StatelessWidget {
  final bool anonymous;
  final int attachedCount;
  final int maxFiles;
  final int pollCount;
  final bool canSubmit;
  final String submitText;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback? onAttach;
  final VoidCallback onPoll;
  final VoidCallback onSubmit;

  const _WriteBottomToolbar({
    required this.anonymous,
    required this.attachedCount,
    required this.maxFiles,
    required this.pollCount,
    required this.canSubmit,
    required this.submitText,
    required this.onAnonymousChanged,
    required this.onAttach,
    required this.onPoll,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.colors.pageBg,
        border: const Border(top: BorderSide(color: Color(0xFFE0ECF7))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ToolIconButton(
              icon: Icons.attach_file_rounded,
              label: '$attachedCount/$maxFiles',
              onTap: onAttach,
            ),
            const SizedBox(width: 8),
            _ToolIconButton(
              icon: Icons.poll_outlined,
              label: pollCount > 0 ? '$pollCount' : null,
              selected: pollCount > 0,
              onTap: onPoll,
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => onAnonymousChanged(!anonymous),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 40,
                padding: const EdgeInsets.only(left: 12, right: 8),
                decoration: BoxDecoration(
                  color: anonymous ? const Color(0xFFEAF5FF) : context.colors.cardBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: anonymous ? const Color(0xFFB9D9FF) : const Color(0xFFD9E6F2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '익명',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF27415C),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.74,
                      child: Switch(
                        value: anonymous,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF2F80ED),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFC9D6E2),
                        onChanged: onAnonymousChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: canSubmit ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF2F80ED),
                  disabledBackgroundColor: const Color(0xFFD6E7F8),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(
                  submitText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;

  const _ToolIconButton({
    required this.icon,
    this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : const Color(0xFF596A7A);
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF5FF) : c.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFFB9D9FF) : const Color(0xFFD9E6F2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: onTap == null ? const Color(0xFFB8C6D2) : color),
            if (label != null)
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F80ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreviewStrip extends StatelessWidget {
  final List<PostMediaItem> existingMedia;
  final List<PlatformFile> selectedFiles;
  final bool Function(String? extension) isImageExtension;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveSelected;

  const _AttachmentPreviewStrip({
    required this.existingMedia,
    required this.selectedFiles,
    required this.isImageExtension,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = existingMedia.length + selectedFiles.length;
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < existingMedia.length) {
            final media = existingMedia[index];
            return SizedBox(
              width: 86,
              child: _ExistingMediaThumb(
                url: media.url,
                isImage: media.isImage,
                onRemove: () => onRemoveExisting(index),
              ),
            );
          }
          final selectedIndex = index - existingMedia.length;
          final file = selectedFiles[selectedIndex];
          return SizedBox(
            width: 86,
            child: _NewFileThumb(
              platformFile: file,
              isImage: isImageExtension(file.extension),
              onRemove: () => onRemoveSelected(selectedIndex),
            ),
          );
        },
      ),
    );
  }
}

class _PollSummaryStrip extends StatelessWidget {
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  const _PollSummaryStrip({
    required this.count,
    required this.onEdit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCAE4FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.poll_outlined, color: Color(0xFF2F80ED), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '투표 $count개 항목',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF27415C),
              ),
            ),
          ),
          IconButton(
            tooltip: '수정',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF2F80ED)),
          ),
          IconButton(
            tooltip: '삭제',
            visualDensity: VisualDensity.compact,
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFFE05C5C)),
          ),
        ],
      ),
    );
  }
}

class _PollFormPage extends StatefulWidget {
  final List<String> initialOptions;
  final int maxOptions;

  const _PollFormPage({
    required this.initialOptions,
    required this.maxOptions,
  });

  @override
  State<_PollFormPage> createState() => _PollFormPageState();
}

class _PollFormPageState extends State<_PollFormPage> {
  late List<TextEditingController> _controllers;

  List<String> get _options => _controllers
      .map((controller) => controller.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();

  bool get _canSave => _options.length >= 2;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialOptions.isEmpty ? ['', ''] : widget.initialOptions;
    _controllers = seed
        .take(widget.maxOptions)
        .map((text) => TextEditingController(text: text)..addListener(_refresh))
        .toList();
    while (_controllers.length < 2) {
      _controllers.add(TextEditingController()..addListener(_refresh));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_refresh);
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _addOption() {
    if (_controllers.length >= widget.maxOptions) return;
    setState(() {
      _controllers.add(TextEditingController()..addListener(_refresh));
    });
  }

  void _removeOption(int index) {
    if (_controllers.length <= 2) return;
    final controller = _controllers.removeAt(index);
    controller.removeListener(_refresh);
    controller.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _WriteHeader(
              title: '투표 만들기',
              submitText: '완료',
              canSubmit: _canSave,
              onClose: () => Navigator.pop(context),
              onSubmit: () => Navigator.pop(context, _options.take(widget.maxOptions).toList()),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: [
                  Text(
                    '투표 항목',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: context.colors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLength: 100,
                              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                              const SizedBox.shrink(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: '항목 ${index + 1}',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9AA7B2),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                                filled: true,
                                fillColor: context.colors.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFDDEAF6)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFDDEAF6)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 1.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: '항목 삭제',
                            onPressed: _controllers.length > 2 ? () => _removeOption(index) : null,
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: const Color(0xFFE05C5C),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _controllers.length < widget.maxOptions ? _addOption : null,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('항목 추가 (${_controllers.length}/${widget.maxOptions})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2F80ED),
                      side: const BorderSide(color: Color(0xFFCBE4FF)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (widget.initialOptions.isNotEmpty || _options.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, <String>[]),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('투표 제거'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE05C5C),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return _ThumbFrame(
      onRemove: onRemove,
      label: isImage ? null : _filename,
      child: isImage
          ? CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: context.colors.borderSubtle),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          color: Color(0xFF9AA7B2),
        ),
      )
          : const _FilePlaceholder(),
    );
  }
}

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
    Widget child;
    if (isImage && platformFile.bytes != null) {
      child = Image.memory(platformFile.bytes!, fit: BoxFit.cover);
    } else if (isImage && platformFile.path != null) {
      child = Image.file(File(platformFile.path!), fit: BoxFit.cover);
    } else {
      child = _FilePlaceholder(name: platformFile.name);
    }

    return _ThumbFrame(
      onRemove: onRemove,
      label: platformFile.name,
      child: child,
    );
  }
}

class _ThumbFrame extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback onRemove;

  const _ThumbFrame({
    required this.child,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: context.colors.borderSubtle,
            child: child,
          ),
        ),
        if (label != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
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
        const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF7D8790), size: 28),
        if (name != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Color(0xFF7D8790)),
            ),
          ),
        ],
      ],
    );
  }
}