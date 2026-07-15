import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../models/models.dart';
import '../profile/public_profile_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(notificationsProvider.notifier).fetchNotifications(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: state.loading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _buildNotificationTile(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final theme = Theme.of(context);
    final icon = _getIcon(notification.type);
    final color = _getColor(notification.type);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: notification.read ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        notification.timeAgo,
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
      ),
      trailing: !notification.read
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () => _handleTap(notification),
    );
  }

  void _handleTap(AppNotification notification) {
    if (notification.fromUserId != null && notification.fromUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            userId: notification.fromUserId!,
            username: notification.fromUser!.username,
            displayName: notification.fromUser!.displayName,
          ),
        ),
      );
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accept':
        return Icons.person;
      case 'kudos':
        return Icons.local_fire_department;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accept':
        return AppColors.purple;
      case 'kudos':
        return AppColors.green;
      case 'comment':
        return AppColors.green;
      default:
        return Colors.grey;
    }
  }
}
