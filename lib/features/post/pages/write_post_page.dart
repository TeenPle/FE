import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_post_request.dart';
import '../provider/post_detail_providers.dart';
import '../models/update_post_request.dart';

/// 게시글 작성/수정 페이지
class WritePostPage extends ConsumerStatefulWidget {
  final int boardId;
  final String boardTitle;
  final bool isEditMode;
  final int? postId;
  final String? initialTitle;
  final String? initialContent;
  final bool? initialAnonymous;

  const WritePostPage({
    super.key,
    required this.boardId,
    required this.boardTitle,
    this.isEditMode = false,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialAnonymous,
  });

  @override
  ConsumerState<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends ConsumerState<WritePostPage> {
  static const int _titleLimit = 60;
  static const int _contentLimit = 2000;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late bool _anonymous;
  bool _isSubmitting = false;

  /// 현재 제목 글자 수 반환
  int get _titleLength => _titleController.text.trim().length;

  /// 현재 본문 글자 수 반환
  int get _contentLength => _contentController.text.trim().length;

  /// 현재 입력 상태로 저장 가능한지 판단
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
    _titleController =
        TextEditingController(text: widget.initialTitle ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    _anonymous = widget.initialAnonymous ?? true;

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

  /// 입력값이 바뀔 때 화면을 다시 그림
  void _refresh() {
    setState(() {});
  }

  /// 작성/수정 모드에 따라 저장 요청을 보냄
  Future<void> _submit() async {
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final repository = ref.read(postRepositoryProvider);

    try {
      if (widget.isEditMode) {
        await repository.updatePost(
          postId: widget.postId!,
          request: UpdatePostRequest(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            anonymous: _anonymous,
          ),
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
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// 작성 중인 내용이 있을 때 뒤로가기 전 확인 다이얼로그를 띄움
  Future<bool> _onWillPop() async {
    final hasInput = _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    if (!hasInput) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    ) ??
        false;

    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEditMode ? '게시글 수정' : '글쓰기';
    final submitText = widget.isEditMode ? '수정 완료' : '게시글 등록';

    return PopScope(
      canPop: false,

      /// 시스템 뒤로가기 시 입력 내용이 있는지 확인
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (!mounted) return;
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(
                  _isSubmitting
                      ? (widget.isEditMode ? '수정 중...' : '등록 중...')
                      : (widget.isEditMode ? '수정' : '등록'),
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
                      onTap: () {
                        setState(() {
                          _anonymous = !_anonymous;
                        });
                      },
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
                      }) {
                        return const SizedBox.shrink();
                      },
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
                      }) {
                        return const SizedBox.shrink();
                      },
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
                        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                        : submitText,
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