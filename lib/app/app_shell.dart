import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../features/chat/pages/chat_room_list_page.dart';
import '../features/chat/provider/chat_room_list_provider.dart';
import '../features/meal/pages/meal_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/school/pages/school_page.dart';
import '../features/timetable/pages/timetable_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const SchoolPage(),
    const ChatRoomListPage(),
    const MealPage(),
    const TimetablePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱 시작 시 채팅 목록 미리 로드 → 하단 뱃지 즉시 표시
    Future.microtask(_refreshChatRooms);
    Future.microtask(() => ref.read(chatRoomListProvider.notifier).startRealtime());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChatRooms();
    }
  }

  void _refreshChatRooms() {
    ref.read(chatRoomListProvider.notifier).load();
  }

  void _onTap(int index) {
    if (index == 1) {
      _refreshChatRooms();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 전체 미읽음 수 집계 → 하단 뱃지에 표시
    final totalUnread = ref.watch(chatRoomListProvider).rooms
        .fold(0, (sum, r) => sum + r.unreadCount);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        chatUnreadCount: totalUnread,
      ),
    );
  }
}
