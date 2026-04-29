import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_message_model.dart';
import '../provider/chat_message_provider.dart';
import '../provider/chat_room_list_provider.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final int roomId;
  final int otherUserId;
  final String displayName;
  final bool initialBlocked;
  final bool initialBlockedByMe;
  final bool initialBlockedByOther;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.otherUserId,
    required this.displayName,
    this.initialBlocked = false,
    this.initialBlockedByMe = false,
    this.initialBlockedByOther = false,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier =
          ref.read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier);
      // 목록/유입 경로에서 받은 차단 상태로 입력창을 먼저 잠그고, 메시지 조회 응답으로 최종 보정한다.
      notifier.setBlockState(
        blocked: widget.initialBlocked,
        blockedByMe: widget.initialBlockedByMe,
        blockedByOther: widget.initialBlockedByOther,
      );
      await notifier.init();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (ref.read(chatRoomProvider((widget.roomId, widget.otherUserId))).isBlocked) {
      return;
    }
    _inputController.clear();
    await ref.read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _BottomSheetItem(
                icon: Icons.report_outlined,
                label: '신고하기',
                color: const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportSheet();
                },
              ),
              _BottomSheetItem(
                icon: _blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded,
                label: _blockedByMe ? '차단 해제' : '차단하기',
                color: _blockedByMe
                    ? const Color(0xFF1DA1F2)
                    : const Color(0xFFF44336),
                onTap: () {
                  Navigator.pop(ctx);
                  if (_blockedByMe) {
                    _showUnblockConfirm();
                  } else {
                    _showBlockConfirm();
                  }
                },
              ),
              _BottomSheetItem(
                icon: Icons.exit_to_app_rounded,
                label: '채팅방 나가기',
                color: const Color(0xFF7D8790),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLeaveConfirm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportSheet() {
    final reasons = ['스팸', '욕설/비방', '음란물', '폭력', '기타'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '신고 사유 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
                        .reportRoom(reason);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('신고가 접수되었습니다.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
                  .blockRoom();
              if (mounted) {
                ref.read(chatRoomListProvider.notifier).load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('차단되었습니다.')),
                );
              }
            },
            child: const Text(
              '차단',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
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
                  .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
                  .unblockRoom();
              ref.read(chatRoomListProvider.notifier).load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('차단이 해제되었습니다.')),
                );
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
                  .read(chatRoomProvider((widget.roomId, widget.otherUserId)).notifier)
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
    final state = ref.watch(chatRoomProvider((widget.roomId, widget.otherUserId)));
    final isBlocked = state.isBlocked;

    // 새 메시지 오면 스크롤
    ref.listen(chatRoomProvider((widget.roomId, widget.otherUserId)), (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFECF6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF111111), size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const Text(
              '익명',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9AA7B2),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF111111)),
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? const Center(
                        child: Text(
                          '첫 메시지를 보내보세요!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9AA7B2),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isMe = msg.senderId != widget.otherUserId;
                          final previous =
                              index > 0 ? state.messages[index - 1] : null;
                          final next = index < state.messages.length - 1
                              ? state.messages[index + 1]
                              : null;
                          final isFirstInGroup =
                              !_isSameMinuteGroup(previous, msg);
                          final isLastInGroup = !_isSameMinuteGroup(msg, next);
                          // 내가 보낸 메시지 중 상대방이 아직 안 읽은 것 → "1" 표시
                          final showUnread = isMe &&
                              isLastInGroup &&
                              (state.otherLastReadMessageId == null ||
                                  msg.messageId > state.otherLastReadMessageId!);
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            showUnread: showUnread,
                            showProfile: !isMe && isFirstInGroup,
                            showMeta: isLastInGroup,
                            isLastInGroup: isLastInGroup,
                          );
                        },
                      ),
          ),

          // 오류 메시지
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFFFEBEE),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFF44336)),
              ),
            ),

          // 입력창
          isBlocked
              ? _BlockedInputBar(
                  blockedByMe: state.blockedByMe,
                  blockedByOther: state.blockedByOther,
                  onUnblock: state.blockedByMe ? _showUnblockConfirm : null,
                )
              : _MessageInputBar(
                  controller: _inputController,
                  isSending: state.isSending,
                  onSend: _sendMessage,
                ),
        ],
      ),
    );
  }

  bool get _blockedByMe {
    final state = ref.read(chatRoomProvider((widget.roomId, widget.otherUserId)));
    return state.blockedByMe;
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
    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 10 : 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showProfile) ...[
            // 상대방 아바타
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFF8EA2B5),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            // 같은 사람이 같은 분에 이어 보낸 메시지는 프로필을 숨기되 말풍선 시작 위치는 유지한다.
            const SizedBox(width: 40),
          ],
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && showProfile)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    '익명',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7D8790),
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
                          // 상대방이 안 읽으면 "1" 표시
                          if (showUnread)
                            const Text(
                              '1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFD600),
                              ),
                            ),
                          if (showMeta)
                            Text(
                              _formatTime(message.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9AA7B2),
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
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1DA1F2)
                          : Colors.white,
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
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              message.imageUrl!,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            message.content ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: isMe
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                  ),
                  if (!isMe && showMeta)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 2),
                      child: Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9AA7B2),
                        ),
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
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '메시지 입력...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF9AA7B2),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111111),
                ),
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
    );
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                blockedByOther && !blockedByMe
                    ? '현재 이 채팅방에서는 메시지를 보낼 수 없습니다.'
                    : '차단한 사용자와는 채팅할 수 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
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
    );
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}
