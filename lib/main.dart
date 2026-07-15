import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/create_post_screen.dart';
import 'widgets/floating_pill_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: FastingFuriousApp()));
}

class FastingFuriousApp extends ConsumerWidget {
  const FastingFuriousApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Fasting Furious',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.session?.user != null) {
          return ProfileLoader(child: const MainShell());
        }
        return const LandingGate();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class LandingGate extends ConsumerWidget {
  const LandingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LandingScreen(
      onGetStarted: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      },
    );
  }
}

class ProfileLoader extends ConsumerStatefulWidget {
  final Widget child;
  const ProfileLoader({super.key, required this.child});

  @override
  ConsumerState<ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends ConsumerState<ProfileLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(profileProvider.notifier).fetchProfile(user.id);
        // Auto-friend with demo accounts so feed has content
        ref.read(supabaseServiceProvider).autoFriendSeedAccounts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
