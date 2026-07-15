import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/notifications_provider.dart';
import '../home/home_screen.dart';
import '../social/friends_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../feed/create_post_screen.dart';
import '../../widgets/floating_pill_nav_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    FriendsScreen(),
    SizedBox.shrink(), // placeholder for create button (index 2)
    FeedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(notificationsProvider.notifier).fetchNotifications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.unreadCount;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _currentIndex,
        unreadCount: unreadCount,
        onItemTapped: (i) {
          if (i == 2) {
            _showCreatePostSheet();
          } else {
            setState(() => _currentIndex = i);
            if (i == 3) {
              final user = ref.read(currentUserProvider);
              if (user != null) ref.read(feedProvider.notifier).fetchFeed(user.id);
            }
            if (i == 4) {
              final user = ref.read(currentUserProvider);
              if (user != null) ref.read(profileProvider.notifier).fetchProfile(user.id);
            }
          }
        },
      ),
    );
  }

  void _showCreatePostSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }
}
