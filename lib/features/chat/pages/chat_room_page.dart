import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/active_page_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';
import '../provider/chat_message_provider.dart';
import '../provider/chat_room_list_provider.dart';
import '../provider/muted_rooms_provider.dart';

const _chatMediaChannel = MethodChannel('teenple/media');

enum _ChatRoomMenuAction { blockToggle, leave }

class ChatRoomPage extends ConsumerStatefulWidget {
  final int roomId;
  final int otherUserId;
  final String displayName;
  final bool initialBlocked;
  final bool initialBlockedByMe;
  final bool initialBlockedByOther;
  final bool initialOtherUserDeleted;
  final bool initialCanSendMessage;
  final bool initialCanReport;
  final bool initialCanBlock;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.otherUserId,
    required this.displayName,
    this.initialBlocked = false,
    this.initialBlockedByMe = false,
    this.initialBlockedByOther = false,
    this.initialOtherUserDeleted = false,
    this.initialCanSendMessage = true,
    this.initialCanReport = true,
    this.initialCanBlock = true,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  // 메시지 전송 후 포커스를 유지해 키보드가 내려가지 않도록 한다.
  final _inputFocusNode = FocusNode();
  late final StateController<ActivePage> _activePageController;
  bool _isLoadingOlder = false;
  _PickedChatImage? _pendingImage;
  bool _isSearchActive = false;
  final _messageSearchController = TextEditingController();
  String _messageSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _activePageController = ref.read(activePageProvider.notifier);
    _scrollController.addListener(_handleScroll);
    _messageSearchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 이 채팅방을 보고 있음을 알림 억제 로직에 알린다.
      _activePageController.state = ActivePage(chatRoomId: widget.roomId);
    });
    Future.microtask(() async {
      if (!mounted) return;
      final notifier = ref.read(
        chatRoomProvider((widget.roomId, widget.otherUserId)).notifier,
      );
      // 목록/유입 경로에서 받은 차단 상태로 입력창을 먼저 잠그고, 메시지 조회 응답으로 최종 보정한다.
      notifier.setBlockState(
        blocked: widget.initialBlocked,
        blockedByMe: widget.initialBlockedByMe,
        blockedByOther: widget.initialBlockedByOther,
        otherUserDeleted: widget.initialOtherUserDeleted,
        canSendMessage: widget.initialCanSendMessage,
        canReport: widget.initialCanReport,
        canBlock: widget.initialCanBlock,
      );
      await notifier.init();
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    // dispose() 중에 Riverpod provider를 직접 수정하면 위젯 트리 언마운트 도중
    // 상태 변경이 금지되어 에러가 발생한다. 언마운트 완료 후 실행되도록 지연한다.
    Future.microtask(() => _activePageController.state = ActivePage.none);
    _scrollController.removeListener(_handleScroll);
    _messageSearchController.removeListener(_handleSearchChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _messageSearchController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _messageSearchQuery = _messageSearchController.text.trim().toLowerCase();
    });
  }

  void _handleScroll() {
    if (!mounted) return;
    _loadOlderIfNeeded();
  }

  Future<void> _loadOlderIfNeeded() async {
    if (!mounted || _isLoadingOlder || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels > 80) return;

    final providerKey = (widget.roomId, widget.otherUserId);
    final state = ref.read(chatRoomProvider(providerKey));
    if (!state.hasMore || state.isLoadingMore || state.messages.isEmpty) return;

    _isLoadingOlder = true;
    final beforeMaxExtent = _scrollController.position.maxScrollExtent;
    await ref.read(chatRoomProvider(providerKey).notifier).loadOlderMessages();
    if (!mounted || !_scrollController.hasClients) {
      _isLoadingOlder = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final delta =
            _scrollController.position.maxScrollExtent - beforeMaxExtent;
        _scrollController.jumpTo(_scrollController.position.pixels + delta);
      }
      _isLoadingOlder = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_pendingImage != null) {
      await _sendPendingImage();
      return;
    }

    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final state = ref.read(
      chatRoomProvider((widget.roomId, widget.otherUserId)),
    );
    if (state.isBlocked || !state.canSendMessage || state.otherUserDeleted) {
      return;
    }
    _inputController.clear();
    await ref
        .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
        .sendMessage(text);
    if (!mounted) return;
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final state = ref.read(
      chatRoomProvider((widget.roomId, widget.otherUserId)),
    );
    if (state.isBlocked ||
        state.isSending ||
        !state.canSendMessage ||
        state.otherUserDeleted) {
      return;
    }

    final result = await _chatMediaChannel.invokeMapMethod<String, Object?>(
      'pickImage',
    );
    if (result == null) return;
    if (!mounted) return;

    final image = _PickedChatImage.fromMap(result);
    if (image.path.isEmpty) return;

    setState(() {
      _pendingImage = image;
    });
  }

  Future<void> _sendPendingImage() async {
    final state = ref.read(
      chatRoomProvider((widget.roomId, widget.otherUserId)),
    );
    if (state.isBlocked ||
        state.isSending ||
        !state.canSendMessage ||
        state.otherUserDeleted) {
      return;
    }

    final picked = _pendingImage;
    if (picked == null) return;

    final ext = picked.extension;
    final contentType = ext == 'png'
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');
    final filename = picked.name.isNotEmpty ? picked.name : 'chat-image.$ext';

    final file = await MultipartFile.fromFile(
      picked.path,
      filename: filename,
      contentType: contentType,
    );

    await ref
        .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
        .sendImage(file);
    if (!mounted) return;
    setState(() {
      _pendingImage = null;
    });
    _scrollToBottom();
  }

  void _clearPendingImage() {
    if (!mounted) return;
    setState(() {
      _pendingImage = null;
    });
  }

  Future<void> _showMoreMenu() async {
    const reasons = [
      ('광고·도배', 'SPAM'),
      ('욕설·비방', 'ABUSE'),
      ('괴롭힘·위협', 'HARASSMENT'),
      ('성적·음란 콘텐츠', 'OBSCENE'),
      ('불법·위험 행위', 'ILLEGAL'),
      ('기타 운영정책 위반', 'ETC'),
    ];
    var selectedReason = reasons.first.$2;
    var showingReportForm = false;

    final action = await showModalBottomSheet<_ChatRoomMenuAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final media = MediaQuery.of(ctx);
            final bottomInset = media.viewInsets.bottom;
            final availableHeight =
                media.size.height - bottomInset - media.padding.top - 24;
            final c = ctx.colors;
            final height = showingReportForm
                ? availableHeight.clamp(360.0, 520.0)
                : null;

            return SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  child: showingReportForm
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: c.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => setModalState(() {
                                          showingReportForm = false;
                                        }),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '신고하기',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '신고 카테고리를 선택해주세요.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: c.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  12,
                                ),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                children: [
                                  Column(
                                    children: reasons.map((reason) {
                                      final selected =
                                          selectedReason == reason.$2;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _ReportReasonTile(
                                          label: reason.$1,
                                          selected: selected,
                                          onTap: () => setModalState(() {
                                            selectedReason = reason.$2;
                                          }),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    FocusScope.of(ctx).unfocus();
                                    Navigator.pop(ctx);
                                    await ref
                                        .read(
                                          chatRoomProvider((
                                            widget.roomId,
                                            widget.otherUserId,
                                          )).notifier,
                                        )
                                        .reportRoom(selectedReason);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('신고가 접수되었습니다.'),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14A3F7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '신고 접수',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: c.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _BottomSheetItem(
                                icon: Icons.report_outlined,
                                label: '신고하기',
                                color: const Color(0xFFF44336),
                                onTap: () => setModalState(() {
                                  showingReportForm = true;
                                }),
                              ),
                              _BottomSheetItem(
                                icon: _blockedByMe
                                    ? Icons.lock_open_rounded
                                    : Icons.block_rounded,
                                label: _blockedByMe ? '차단 해제' : '차단하기',
                                color: _blockedByMe
                                    ? const Color(0xFF1DA1F2)
                                    : const Color(0xFFF44336),
                                onTap: () => Navigator.pop(
                                  ctx,
                                  _ChatRoomMenuAction.blockToggle,
                                ),
                              ),
                              _BottomSheetItem(
                                icon: Icons.exit_to_app_rounded,
                                label: '채팅방 나가기',
                                color: const Color(0xFF7D8790),
                                onTap: () => Navigator.pop(
                                  ctx,
                                  _ChatRoomMenuAction.leave,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ChatRoomMenuAction.blockToggle:
        if (_blockedByMe) {
          _showUnblockConfirm();
        } else {
          _showBlockConfirm();
        }
      case _ChatRoomMenuAction.leave:
        _showLeaveConfirm();
    }
  }

  void _showBlockConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단하기'),
        content: const Text('이 사용자를 차단하면 더 이상 채팅을 주고받을 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(
                    chatRoomProvider((
                      widget.roomId,
                      widget.otherUserId,
                    )).notifier,
                  )
                  .blockRoom();
              if (mounted) {
                ref.read(chatRoomListProvider.notifier).load();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('차단되었습니다.')));
              }
            },
            child: const Text('차단', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단 해제'),
        content: const Text('차단을 해제하면 다시 메시지를 주고받을 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(
                    chatRoomProvider((
                      widget.roomId,
                      widget.otherUserId,
                    )).notifier,
                  )
                  .unblockRoom();
              ref.read(chatRoomListProvider.notifier).load();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('차단이 해제되었습니다.')));
              }
            },
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('채팅방을 나가면 목록에서 숨겨집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(
                    chatRoomProvider((
                      widget.roomId,
                      widget.otherUserId,
                    )).notifier,
                  )
                  .leaveRoom();
              // 채팅 목록 갱신
              ref.read(chatRoomListProvider.notifier).load();
              if (mounted) context.pop();
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      chatRoomProvider((widget.roomId, widget.otherUserId)),
    );
    final isBlocked = state.isBlocked;
    final isMuted = ref.watch(mutedRoomsProvider).contains(widget.roomId);

    // 검색 활성 시 텍스트 메시지만 내용으로 필터링 (이미지는 검색 대상 아님)
    final isSearchFiltered = _messageSearchQuery.isNotEmpty;
    final messages = isSearchFiltered
        ? state.messages
              .where(
                (m) =>
                    !m.isImage &&
                    (m.content?.toLowerCase().contains(_messageSearchQuery) ??
                        false),
              )
              .toList()
        : state.messages;

    // 새 메시지 오면 스크롤
    ref.listen(chatRoomProvider((widget.roomId, widget.otherUserId)), (
      prev,
      next,
    ) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    final c = context.colors;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.iconPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            Text('익명', style: TextStyle(fontSize: 11, color: c.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isMuted
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_rounded,
              color: isMuted ? c.textMuted : c.iconPrimary,
            ),
            onPressed: () =>
                ref.read(mutedRoomsProvider.notifier).toggle(widget.roomId),
          ),
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: c.iconPrimary,
            ),
            onPressed: () => setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _messageSearchQuery = '';
                _messageSearchController.clear();
              }
            }),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: c.iconPrimary),
            onPressed: _showMoreMenu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!_isSearchActive && state.messages.isEmpty)
              const _ChatNoticeBar(),
            if (_isSearchActive)
              Container(
                color: c.cardBg,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: TextField(
                  controller: _messageSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '메시지 검색',
                    hintStyle: TextStyle(fontSize: 13, color: c.textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: c.textMuted,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: c.subtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(fontSize: 13, color: c.textPrimary),
                ),
              ),
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(
                      child: Text(
                        isSearchFiltered ? '검색 결과가 없어요.' : '첫 메시지를 보내보세요!',
                        style: TextStyle(fontSize: 13, color: c.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      // 검색 중에는 페이지네이션 스피너 숨김
                      itemCount:
                          messages.length +
                          (isSearchFiltered
                              ? 0
                              : (state.isLoadingMore ? 1 : 0)),
                      itemBuilder: (context, index) {
                        if (!isSearchFiltered &&
                            state.isLoadingMore &&
                            index == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final messageIndex =
                            !isSearchFiltered && state.isLoadingMore
                            ? index - 1
                            : index;
                        final msg = messages[messageIndex];
                        final isMe = msg.senderId != widget.otherUserId;
                        final previous = messageIndex > 0
                            ? messages[messageIndex - 1]
                            : null;
                        final next = messageIndex < messages.length - 1
                            ? messages[messageIndex + 1]
                            : null;
                        final isFirstInGroup = !_isSameMinuteGroup(
                          previous,
                          msg,
                        );
                        final isLastInGroup = !_isSameMinuteGroup(msg, next);
                        // 내가 보낸 메시지 중 상대방이 아직 안 읽은 것 → "1" 표시
                        final showUnread =
                            isMe &&
                            isLastInGroup &&
                            (state.otherLastReadMessageId == null ||
                                msg.messageId > state.otherLastReadMessageId!);

                        // 날짜가 바뀌는 첫 메시지 앞에 날짜 구분선을 표시한다.
                        final showDateSeparator =
                            msg.createdAt != null &&
                            (previous == null ||
                                previous.createdAt == null ||
                                !_isSameDay(
                                  previous.createdAt!,
                                  msg.createdAt!,
                                ));

                        return Column(
                          children: [
                            if (showDateSeparator && msg.createdAt != null)
                              _DateSeparator(date: msg.createdAt!),
                            _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              showUnread: showUnread,
                              showProfile: !isMe && isFirstInGroup,
                              showMeta: isLastInGroup,
                              isLastInGroup: isLastInGroup,
                            ),
                          ],
                        );
                      },
                    ),
            ),

            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: const Color(0xFFFFEBEE),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF44336),
                  ),
                ),
              ),

            // 입력창
            state.otherUserDeleted
                ? const _DeletedUserInputBar()
                : state.isPenalized
                ? _PenaltyInputBar(expiresAt: state.penaltyExpiresAt)
                : isBlocked
                ? _BlockedInputBar(
                    blockedByMe: state.blockedByMe,
                    blockedByOther: state.blockedByOther,
                    onUnblock: state.blockedByMe ? _showUnblockConfirm : null,
                  )
                : _MessageInputBar(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    isSending: state.isSending,
                    pendingImage: _pendingImage,
                    onClearImage: _clearPendingImage,
                    onImage: _pickImage,
                    onSend: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }

  bool get _blockedByMe {
    final state = ref.read(
      chatRoomProvider((widget.roomId, widget.otherUserId)),
    );
    return state.blockedByMe;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMinuteGroup(ChatMessageModel? current, ChatMessageModel? other) {
    if (current == null || other == null) return false;
    if (current.senderId != other.senderId) return false;

    final a = current.createdAt;
    final b = other.createdAt;
    if (a == null || b == null) return false;

    // 같은 사람이 같은 "분"에 연속으로 보낸 메시지만 하나의 대화 묶음으로 본다.
    // 9:13 메시지 다음 9:14 메시지는 1분 차이이므로 새 프로필/시간 묶음으로 다시 시작한다.
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}

class _PickedChatImage {
  final String path;
  final String name;
  final String extension;
  final Uint8List bytes;

  const _PickedChatImage({
    required this.path,
    required this.name,
    required this.extension,
    required this.bytes,
  });

  factory _PickedChatImage.fromMap(Map<String, Object?> map) {
    final path = map['path'] as String? ?? '';
    final name = map['name'] as String? ?? 'chat-image.jpg';
    final mimeType = map['mimeType'] as String? ?? '';
    final bytes = map['bytes'] as Uint8List? ?? Uint8List(0);
    final extension =
        name.toLowerCase().endsWith('.png') || mimeType == 'image/png'
        ? 'png'
        : 'jpg';
    return _PickedChatImage(
      path: path,
      name: name,
      extension: extension,
      bytes: bytes,
    );
  }
}

void _showChatImageViewer(BuildContext context, {required String imageUrl}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ChatImageViewerPage(imageUrl: imageUrl),
    ),
  );
}

class _ChatImageViewerPage extends StatefulWidget {
  final String imageUrl;

  const _ChatImageViewerPage({required this.imageUrl});

  @override
  State<_ChatImageViewerPage> createState() => _ChatImageViewerPageState();
}

class _ChatImageViewerPageState extends State<_ChatImageViewerPage> {
  bool _isSaving = false;

  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final response = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) {
        throw Exception('empty image');
      }

      final lowerUrl = widget.imageUrl.toLowerCase();
      final isPng = lowerUrl.contains('.png');
      final extension = isPng ? 'png' : 'jpg';
      final mimeType = isPng ? 'image/png' : 'image/jpeg';
      await _chatMediaChannel.invokeMethod<void>('saveImageToGallery', {
        'bytes': bytes,
        'name': 'teenple_${DateTime.now().millisecondsSinceEpoch}.$extension',
        'mimeType': mimeType,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 저장했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 저장에 실패했습니다.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Text(
          '이미지를 불러올 수 없습니다',
          style: TextStyle(color: Colors.white70),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveImage,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(minScale: 0.8, maxScale: 4, child: image),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool showUnread;
  final bool showProfile;
  final bool showMeta;
  final bool isLastInGroup;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showUnread = false,
    this.showProfile = true,
    this.showMeta = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 10 : 3),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showProfile) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFEAF3FB),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFF8EA2B5),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe && showProfile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    '익명',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMe && showMeta)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showUnread)
                            const Text(
                              '1',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFD600),
                              ),
                            ),
                          if (showMeta)
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF1DA1F2) : c.cardBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: message.isImage && message.imageUrl != null
                        ? GestureDetector(
                            onTap: () => _showChatImageViewer(
                              context,
                              imageUrl: message.imageUrl!,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                message.imageUrl!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 180,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color(0xFF1888D0)
                                          : ctx.colors.subtleBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isMe
                                            ? Colors.white70
                                            : ctx.colors.textMuted,
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, error, stackTrace) {
                                  return Container(
                                    width: 180,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color(0xFF1888D0)
                                          : ctx.colors.subtleBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          size: 28,
                                          color: isMe
                                              ? Colors.white60
                                              : ctx.colors.textMuted,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '이미지를 불러올 수 없습니다',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white60
                                                : ctx.colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Text(
                            message.content ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isMe ? Colors.white : c.textBody,
                            ),
                          ),
                  ),
                  if (!isMe && showMeta)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 2),
                      child: Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(fontSize: 10, color: c.textMuted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$period $hour:$m';
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final _PickedChatImage? pendingImage;
  final VoidCallback onClearImage;
  final VoidCallback onImage;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.pendingImage,
    required this.onClearImage,
    required this.onImage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        color: c.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingImage != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        pendingImage!.bytes,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: isSending ? null : onClearImage,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xAA000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: isSending ? null : onImage,
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFF1DA1F2),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.inputBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      // isSending 중에도 enabled를 유지해야 포커스가 빠지지 않고 키보드가 내려가지 않는다.
                      enabled: pendingImage == null,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 500,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: pendingImage == null
                            ? '메시지 입력...'
                            : '사진 전송 대기 중',
                        counterText: '',
                        hintStyle: TextStyle(fontSize: 13, color: c.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(fontSize: 13, color: c.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSending ? null : onSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSending
                          ? const Color(0xFFB0BEC5)
                          : const Color(0xFF1DA1F2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: isSending
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PenaltyInputBar extends StatelessWidget {
  final DateTime? expiresAt;

  const _PenaltyInputBar({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final message = expiresAt == null
        ? '현재 정지 중이라 채팅을 사용할 수 없습니다.'
        : '현재 정지 중이라 채팅을 사용할 수 없습니다.\n해제: ${_formatExpiresAt(expiresAt!)}';

    return SafeArea(
      top: false,
      child: Container(
        color: context.colors.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD7CE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 20,
                color: Color(0xFFD1432F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD1432F),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatExpiresAt(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
  }
}

class _BlockedInputBar extends StatelessWidget {
  final bool blockedByMe;
  final bool blockedByOther;
  final VoidCallback? onUnblock;

  const _BlockedInputBar({
    required this.blockedByMe,
    required this.blockedByOther,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        color: c.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: c.subtleBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  blockedByOther && !blockedByMe
                      ? '현재 이 채팅방에서는 메시지를 보낼 수 없습니다.'
                      : '차단한 사용자와는 채팅할 수 없습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
            ),
            if (blockedByMe) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onUnblock,
                child: const Text(
                  '차단 해제',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeletedUserInputBar extends StatelessWidget {
  const _DeletedUserInputBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.cardBg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.subtleBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '탈퇴한 사용자와는 채팅할 수 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: c.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// 날짜가 바뀌는 시점에 메시지 목록 사이에 삽입되는 날짜 구분선 (예: 5월 20일 (화))
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.divider, thickness: 1)),
          const SizedBox(width: 12),
          Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: c.divider, thickness: 1)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final day = weekdays[dt.weekday - 1];
    return '${dt.month}월 ${dt.day}일 ($day)';
  }
}

class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ReportReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = const Color(0xFF14A3F7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? c.tintBg : c.subtleBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.borderBlue : c.border),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: selected ? accent : c.iconSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? c.textPrimary : c.textBody,
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

// 채팅방 상단 고정 운영 가이드 배너.
// 스크롤과 무관하게 항상 노출되어 이용자가 규칙을 인지할 수 있도록 한다.
class _ChatNoticeBar extends StatelessWidget {
  const _ChatNoticeBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '욕설·비방·음란물·폭력적 내용 등 부적절한 메시지에 대한 책임은 작성자 본인에게 있습니다. '
              '위반 시 신고를 통해 이용이 제한될 수 있습니다.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
