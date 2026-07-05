import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/notifications_provider.dart';
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
    final theme = Theme.of(context);
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.unreadCount;

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
            icon: Badge(
              label: unreadCount > 0 ? Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)) : null,
              isLabelVisible: unreadCount > 0,
              child: Icon(Icons.favorite_outline, color: theme.textTheme.bodySmall?.color),
            ),
            selectedIcon: Badge(
              label: unreadCount > 0 ? Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)) : null,
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.favorite, color: AppColors.coral),
            ),
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
  bool _shareFasting = false;
  bool _shareSmoking = false;
  bool _shareSugar = false;
  bool _shareExercise = false;
  File? _selectedImage;
  bool _uploadingImage = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1080, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;
    setState(() => _uploadingImage = true);
    try {
      final ext = _selectedImage!.path.split('.').last;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await ref.read(supabaseServiceProvider).client.storage
          .from('post-images')
          .upload(path, _selectedImage!);
      final url = ref.read(supabaseServiceProvider).client.storage
          .from('post-images')
          .getPublicUrl(path);
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String _buildContent() {
    final parts = <String>[];
    if (_shareFasting) parts.add('Currently fasting');
    if (_shareSmoking) parts.add('Smoke-free streak alive');
    if (_shareSugar) parts.add('Sugar-free streak alive');
    if (_shareExercise) parts.add('Crushing today\'s workout');
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) parts.add(typed);
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final habitState = ref.watch(habitProvider);
    final habits = habitState.habits;
    final smokingStreak = habitState.getStreak('no_smoking');
    final sugarStreak = habitState.getStreak('no_sugar');

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            Text('Share Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 6),
            Text(
              'Tap stats to include them in your post',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),

            // Stat chips
            Text('Your Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (habits.exerciseMinutes > 0 || habits.exercise)
                  _StatChip(
                    emoji: '\u{1F3C3}',
                    label: '${habitState.habits.exerciseMinutes}min exercise',
                    isSelected: _shareExercise,
                    color: AppColors.emerald,
                    onTap: () => setState(() => _shareExercise = !_shareExercise),
                  ),
                if (smokingStreak > 0)
                  _StatChip(
                    emoji: '\u{1F6AB}',
                    label: '$smokingStreak day${smokingStreak != 1 ? 's' : ''} smoke-free',
                    isSelected: _shareSmoking,
                    color: AppColors.coral,
                    onTap: () => setState(() => _shareSmoking = !_shareSmoking),
                  ),
                if (sugarStreak > 0)
                  _StatChip(
                    emoji: '\u{1F525}',
                    label: '$sugarStreak day${sugarStreak != 1 ? 's' : ''} sugar-free',
                    isSelected: _shareSugar,
                    color: AppColors.amber,
                    onTap: () => setState(() => _shareSugar = !_shareSugar),
                  ),
                _StatChip(
                  emoji: '\u{1F37D}\u{FE0F}',
                  label: 'Fasting',
                  isSelected: _shareFasting,
                  color: AppColors.indigo,
                  onTap: () => setState(() => _shareFasting = !_shareFasting),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type selector
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
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Add a message (optional)"),
            ),
            const SizedBox(height: 12),

            // Image preview + picker
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  if (_uploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                    ),
                ],
              )
            else
              Row(
                children: [
                  _ImagePickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 10),
                  _ImagePickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                  onPressed: user == null
                      ? null
                      : _loading
                          ? null
                          : () async {
                              final content = _buildContent();
                              if (content.trim().isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Select a stat or type a message first')),
                                  );
                                }
                                return;
                              }
                      setState(() => _loading = true);
                      try {
                        String? imageUrl;
                        if (_selectedImage != null) {
                          imageUrl = await _uploadImage(user.id);
                        }
                        await ref.read(supabaseServiceProvider).createPost(
                          user.id,
                          type: _selectedType,
                          content: content.trim(),
                          imageUrl: imageUrl,
                        );
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Posted!')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _loading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to post: $e')),
                                  );
                                }
                              }
                            },
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            if (user == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Not logged in', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
            )),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
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

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }
}
