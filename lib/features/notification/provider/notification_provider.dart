import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/notification_api.dart';
import '../models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationApi _api;

  NotificationNotifier(this._api) : super(const NotificationState());

  Future<void> loadUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] unread count error: $e');
    }
  }

  Future<void> loadNotifications() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, notifications: [], currentPage: 0, hasMore: true);
    try {
      final (:items, :hasNext) = await _api.getNotifications(page: 0);
      state = state.copyWith(
        notifications: items,
        isLoading: false,
        currentPage: 0,
        hasMore: hasNext,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] loadNotifications error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final (:items, :hasNext) = await _api.getNotifications(page: nextPage);
      state = state.copyWith(
        notifications: [...state.notifications, ...items],
        isLoading: false,
        currentPage: nextPage,
        hasMore: hasNext,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] loadMore error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] markAllAsRead error: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markAsRead(id);
      final updated = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] markAsRead error: $e');
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationApiProvider));
});
