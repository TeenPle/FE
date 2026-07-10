import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/ios_image_upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snack_bar.dart';
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
  bool _isSubmitting = false;
  int? _selectedBoardId;
  late String _selectedBoardTitle;
  List<String> _pollOptions = [];
  List<PlatformFile> _selectedFiles = [];
  late List<PostMediaItem> _existingMedia;
  final List<int> _deletedMediaIds = [];

  int get _attachedCount => _existingMedia.length + _selectedFiles.length;
  bool get _showCrisisBanner =>
      CrisisBanner.containsCrisisKeyword(_titleController.text) ||
      CrisisBanner.containsCrisisKeyword(_contentController.text);

  String? get _submitValidationMessage {
    if (!widget.isEditMode && _selectedBoardId == null) return '게시판을 선택해 주세요.';
    if (_titleController.text.trim().isEmpty) return '제목을 입력해 주세요.';
    if (_contentController.text.trim().isEmpty) return '내용을 입력해 주세요.';
    if (_titleController.text.trim().length > _titleLimit) {
      return '제목은 $_titleLimit자 이하로 입력해 주세요.';
    }
    if (_contentController.text.trim().length > _contentLimit) {
      return '내용은 $_contentLimit자 이하로 입력해 주세요.';
    }
    return null;
  }

  bool get _canSubmit => _submitValidationMessage == null && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
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

  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    final contentType = _guessMediaType(file.extension);
    if (file.path != null) {
      return MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: contentType,
      );
    }
    return MultipartFile.fromBytes(
      file.bytes!,
      filename: file.name,
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
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  bool _isImageExtension(String? ext) {
    return {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext?.toLowerCase());
  }

  Future<PlatformFile> _normalizeIosHeicFile(PlatformFile file) async {
    if (file.path == null) return file;
    final normalized = await IosImageUploadService.normalizeHeic(file.path!);
    if (normalized == null) return file;
    return PlatformFile(
      name: normalized.name,
      path: normalized.path,
      size: normalized.bytes.length,
      bytes: normalized.bytes,
    );
  }

  Future<void> _pickFiles() async {
    final remaining = _maxFiles - _attachedCount;
    if (remaining <= 0) {
      showAppSnackBar('첨부 파일은 최대 5개까지 가능해요.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;

    late final List<PlatformFile> normalizedFiles;
    try {
      normalizedFiles = await Future.wait(
        result.files.map(_normalizeIosHeicFile),
      );
    } catch (_) {
      showAppSnackBar('일부 이미지를 처리하지 못했어요. 다른 사진을 선택해 주세요.');
      return;
    }
    if (!mounted) return;

    final valid = normalizedFiles
        .where((file) => _isImageExtension(file.extension))
        .where((file) => file.size <= _maxFileSizeBytes)
        .take(remaining)
        .toList();

    if (valid.length != normalizedFiles.length) {
      showAppSnackBar('지원하지 않거나 10MB를 초과한 파일은 제외했어요.');
    }
    if (valid.isEmpty) return;
    setState(() => _selectedFiles = [..._selectedFiles, ...valid]);
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
    if (_isSubmitting) return;
    final validationMessage = _submitValidationMessage;
    if (validationMessage != null) {
      showAppSnackBar(
        validationMessage,
        backgroundColor: const Color(0xFFE05C7B),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final files = await Future.wait(_selectedFiles.map(_toMultipartFile));
      final repository = ref.read(postRepositoryProvider);

      if (widget.isEditMode) {
        await repository.updatePost(
          postId: widget.postId!,
          request: UpdatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            deleteMediaIds: _deletedMediaIds,
            pollOptions: _pollOptions,
          ),
          files: files,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final postId = await repository.createPost(
          boardId: _selectedBoardId!,
          request: CreatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            pollOptions: _pollOptions.isEmpty ? null : _pollOptions,
          ),
          files: files,
        );
        if (mounted) Navigator.pop(context, postId);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        e is ApiException ? e.message : '게시글 저장에 실패했어요.',
        backgroundColor: const Color(0xFFE05C7B),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _onWillPop() async {
    final hasInput =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _selectedFiles.isNotEmpty ||
        _pollOptions.isNotEmpty ||
        _deletedMediaIds.isNotEmpty;
    if (!hasInput) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(widget.isEditMode ? '수정을 취소할까요?' : '작성 중인 글을 나갈까요?'),
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
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.availableBoards.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: context.colors.borderSubtle),
                  itemBuilder: (context, index) {
                    final board = widget.availableBoards[index];
                    final selected = board.id == _selectedBoardId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        board.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: selected
                              ? const Color(0xFF2F80ED)
                              : context.colors.textBody,
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
    final c = context.colors;
    final navigator = Navigator.of(context);
    final titleText = widget.isEditMode ? '게시글 수정' : '글 작성';
    final submitText = _isSubmitting
        ? '저장 중'
        : (widget.isEditMode ? '수정' : '등록');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop() && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: c.pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _WriteHeader(
                title: titleText,
                submitText: submitText,
                canSubmit: _canSubmit,
                isSubmitting: _isSubmitting,
                onClose: () async {
                  if (await _onWillPop() && mounted) navigator.pop();
                },
                onSubmit: _submit,
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                  children: [
                    _BoardSelectorLine(
                      title: _selectedBoardTitle.isEmpty
                          ? '게시판 선택'
                          : _selectedBoardTitle,
                      selected: _selectedBoardId != null,
                      enabled:
                          !widget.isEditMode &&
                          widget.availableBoards.isNotEmpty,
                      onTap: _showBoardPicker,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _titleController,
                      maxLength: _titleLimit,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => const SizedBox.shrink(),
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 18,
                        color: c.textPrimary,
                        height: 1.28,
                      ),
                      decoration: _plainInputDecoration('제목'),
                    ),
                    Divider(height: 24, color: c.divider),
                    TextField(
                      controller: _contentController,
                      minLines: 14,
                      maxLines: null,
                      maxLength: _contentLimit,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => const SizedBox.shrink(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        height: 1.55,
                        color: c.textBody,
                      ),
                      decoration: _plainInputDecoration('내용을 입력해 주세요'),
                    ),
                    if (_showCrisisBanner) ...[
                      const SizedBox(height: 14),
                      const CrisisBanner(),
                    ],
                  ],
                ),
              ),
              const _PostWritingGuidelines(),
              if (_attachedCount > 0)
                _AttachmentPreviewStrip(
                  existingMedia: _existingMedia,
                  selectedFiles: _selectedFiles,
                  isImageExtension: _isImageExtension,
                  onRemoveExisting: (index) => setState(() {
                    final removed = _existingMedia.removeAt(index);
                    _deletedMediaIds.add(removed.mediaId);
                  }),
                  onRemoveSelected: (index) => setState(
                    () =>
                        _selectedFiles = List.from(_selectedFiles)
                          ..removeAt(index),
                  ),
                ),
              if (_pollOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: _PollSummaryStrip(
                    count: _pollOptions.length,
                    onEdit: _openPollForm,
                    onClear: () => setState(() => _pollOptions = []),
                  ),
                ),
              _WriteBottomToolbar(
                attachedCount: _attachedCount,
                maxFiles: _maxFiles,
                pollCount: _pollOptions.length,
                onAttach: _attachedCount < _maxFiles ? _pickFiles : null,
                onPoll: _openPollForm,
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
      hintStyle: AppTextStyles.labelMedium.copyWith(
        fontSize: 14,
        color: context.colors.textTertiary,
      ),
      filled: true,
      fillColor: Colors.transparent,
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
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const _WriteHeader({
    required this.title,
    required this.submitText,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
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
              style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
            ),
          ),
          TextButton(
            onPressed: canSubmit && !isSubmitting ? onSubmit : null,
            child: Text(submitText, style: AppTextStyles.labelMedium),
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
              color: selected
                  ? const Color(0xFF2F80ED)
                  : context.colors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected
                      ? const Color(0xFF2F80ED)
                      : context.colors.textTertiary,
                ),
              ),
            ),
            if (enabled)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF2F80ED),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _PostWritingGuidelines extends StatelessWidget {
  const _PostWritingGuidelines();

  static const List<String> _rules = [
    '실명, 연락처, 주소, 학교 등 개인정보를 올리지 마세요.',
    '욕설, 괴롭힘, 성적 표현, 혐오 표현은 삭제될 수 있어요.',
    '위험한 상황이거나 도움이 필요하면 믿을 수 있는 어른에게 알려주세요.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.divider),
          bottom: BorderSide(color: c.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 15,
                color: Color(0xFF2F80ED),
              ),
              const SizedBox(width: 6),
              Text(
                '게시글 작성 규칙',
                style: AppTextStyles.labelSmall.copyWith(color: c.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '• $rule',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  height: 1.45,
                  color: c.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteBottomToolbar extends StatelessWidget {
  final int attachedCount;
  final int maxFiles;
  final int pollCount;
  final VoidCallback? onAttach;
  final VoidCallback onPoll;

  const _WriteBottomToolbar({
    required this.attachedCount,
    required this.maxFiles,
    required this.pollCount,
    required this.onAttach,
    required this.onPoll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: context.colors.pageBg,
        border: Border(top: BorderSide(color: context.colors.border)),
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
    final c = context.colors;
    final activeColor = const Color(0xFF2F80ED);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? c.tintBg : c.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? activeColor : c.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: onTap == null ? c.iconSecondary : activeColor,
            ),
            if (label != null)
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 9,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index < existingMedia.length) {
              return _PreviewBox(
                label: existingMedia[index].isImage ? null : '파일',
                onRemove: () => onRemoveExisting(index),
                child: existingMedia[index].isImage
                    ? Image.network(
                        existingMedia[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_rounded),
                      )
                    : const Icon(Icons.insert_drive_file_rounded),
              );
            }
            final selectedIndex = index - existingMedia.length;
            final file = selectedFiles[selectedIndex];
            return _PreviewBox(
              label: file.name,
              onRemove: () => onRemoveSelected(selectedIndex),
              child: isImageExtension(file.extension) && file.path != null
                  ? Image.file(File(file.path!), fit: BoxFit.cover)
                  : const Icon(Icons.insert_drive_file_rounded),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback onRemove;

  const _PreviewBox({required this.child, this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 86,
              height: 86,
              color: context.colors.borderSubtle,
              child: child,
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
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
          if (label != null)
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
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
        color: context.colors.tintBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.borderBlue),
      ),
      child: Row(
        children: [
          const Icon(Icons.poll_outlined, color: Color(0xFF2F80ED), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '투표 $count개 항목',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: '수정',
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
              color: Color(0xFF2F80ED),
            ),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: onClear,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFFE05C5C),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollFormPage extends StatefulWidget {
  final List<String> initialOptions;
  final int maxOptions;

  const _PollFormPage({required this.initialOptions, required this.maxOptions});

  @override
  State<_PollFormPage> createState() => _PollFormPageState();
}

class _PollFormPageState extends State<_PollFormPage> {
  late List<TextEditingController> _controllers;

  List<String> get _options => _controllers
      .map((c) => c.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();
  bool get _canSave => _options.length >= 2;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialOptions.isEmpty
        ? ['', '']
        : widget.initialOptions;
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
    setState(
      () => _controllers.add(TextEditingController()..addListener(_refresh)),
    );
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
              isSubmitting: false,
              onClose: () => Navigator.pop(context),
              onSubmit: () => Navigator.pop(
                context,
                _options.take(widget.maxOptions).toList(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: [
                  Text(
                    '투표 항목',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.colors.textPrimary,
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
                              buildCounter:
                                  (
                                    _, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => const SizedBox.shrink(),
                              decoration: InputDecoration(
                                hintText: '항목 ${index + 1}',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: context.colors.inputBg,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '항목 삭제',
                            onPressed: _controllers.length > 2
                                ? () => _removeOption(index)
                                : null,
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: _controllers.length < widget.maxOptions
                        ? _addOption
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      '항목 추가 (${_controllers.length}/${widget.maxOptions})',
                    ),
                  ),
                  if (_options.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, <String>[]),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('투표 제거'),
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
