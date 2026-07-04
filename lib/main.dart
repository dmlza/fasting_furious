import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_screen.dart';

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
    HomeScreen(),     // 0
    FriendsScreen(),  // 1
    FeedScreen(),     // 3
    ProfileScreen(),  // 4
  ];

  int _getScreenIndex(int navIndex) {
    if (navIndex == 0) return 0;      // Home
    if (navIndex == 1) return 1;      // Search (Friends)
    if (navIndex == 3) return 2;      // Activity (Feed)
    if (navIndex == 4) return 3;      // Profile
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _screens[_getScreenIndex(_currentIndex)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == 2) {
            _showCreatePostSheet();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        height: 70,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: theme.textTheme.bodySmall?.color),
            selectedIcon: const Icon(Icons.home, color: AppColors.indigo),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search, color: theme.textTheme.bodySmall?.color),
            selectedIcon: const Icon(Icons.search, color: AppColors.indigo),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline, color: theme.textTheme.bodySmall?.color),
            selectedIcon: const Icon(Icons.favorite, color: AppColors.coral),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: theme.textTheme.bodySmall?.color),
            selectedIcon: const Icon(Icons.person, color: AppColors.indigo),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreatePostSheet(),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _controller = TextEditingController();
  String _selectedType = 'general';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(currentUserProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Create Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _TypeChip(label: 'General', emoji: '\u{1F4AC}', isSelected: _selectedType == 'general', onTap: () => setState(() => _selectedType = 'general')),
              _TypeChip(label: 'Fasting', emoji: '\u{1F37D}\u{FE0F}', isSelected: _selectedType == 'fasting', onTap: () => setState(() => _selectedType = 'fasting')),
              _TypeChip(label: 'Exercise', emoji: '\u{1F3C3}', isSelected: _selectedType == 'exercise', onTap: () => setState(() => _selectedType = 'exercise')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(hintText: "What's happening?"),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading || user == null
                  ? null
                  : () async {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() => _loading = true);
                      await ref.read(supabaseServiceProvider).createPost(
                        user.id,
                        type: _selectedType,
                        content: _controller.text.trim(),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Posted!')),
                        );
                      }
                    },
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.indigo : Theme.of(context).dividerColor,
          ),
        ),
        child: Text('$emoji $label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.indigo : null)),
      ),
    );
  }
}
