import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool loading;

  NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.loading = false,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? loading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref ref;
  NotificationsNotifier(this.ref) : super(NotificationsState());

  Future<void> fetchNotifications(String userId) async {
    state = state.copyWith(loading: true);
    final service = ref.read(supabaseServiceProvider);
    final data = await service.fetchNotifications(userId);

    final notifications = data.map((n) {
      final fromUser = n['from_user'] as Map<String, dynamic>?;
      return AppNotification.fromMap(n, fromUser: fromUser);
    }).toList();

    final unread = notifications.where((n) => !n.read).length;
    state = NotificationsState(notifications: notifications, unreadCount: unread, loading: false);
  }

  Future<void> markAllRead(String userId) async {
    await ref.read(supabaseServiceProvider).markNotificationsRead(userId);
    state = state.copyWith(
      notifications: state.notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        fromUserId: n.fromUserId,
        type: n.type,
        message: n.message,
        read: true,
        createdAt: n.createdAt,
        fromUser: n.fromUser,
      )).toList(),
      unreadCount: 0,
    );
  }

  void addNotification(Map<String, dynamic> data) {
    final fromUser = data['from_user'] as Map<String, dynamic>?;
    final notification = AppNotification.fromMap(data, fromUser: fromUser);
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }
}
