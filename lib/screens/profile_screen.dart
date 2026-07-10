import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/skeleton.dart';
import 'stats_screen.dart';
import 'workout_history_screen.dart';
import 'activity_detail_screen.dart';
import '../config/page_transitions.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _editing = false;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  int _postCount = 0;
  List<Post> _myPosts = [];
  bool _loadingPosts = true;
  bool _initialLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _initialLoading = false);
      return;
    }
    try {
      await ref.read(friendsProvider.notifier).fetchAll(user.id);
      await ref.read(habitProvider.notifier).fetchAll(user.id);
      final results = await Future.wait([
        ref.read(supabaseServiceProvider).getPostCount(user.id),
        _fetchMyPosts(user.id),
      ]);
      if (mounted) setState(() { _postCount = results[0] as int; _initialLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(profileProvider.notifier).fetchProfile(user.id);
    await ref.read(friendsProvider.notifier).fetchAll(user.id);
    await ref.read(habitProvider.notifier).fetchAll(user.id);
    final results = await Future.wait([
      ref.read(supabaseServiceProvider).getPostCount(user.id),
      _fetchMyPosts(user.id),
    ]);
    if (mounted) setState(() => _postCount = results[0] as int);
  }

  Future<List<Post>> _fetchMyPosts(String userId) async {
    try {
      final data = await ref.read(supabaseServiceProvider).client
          .from('posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      final profileData = ref.read(profileProvider);
      final posts = (data as List).map((p) {
        return Post.fromMap(p, profileData: profileData != null ? {
          'id': profileData.id,
          'username': profileData.username,
          'display_name': profileData.displayName,
        } : null);
      }).toList();
      if (mounted) setState(() { _myPosts = posts; _loadingPosts = false; });
      return posts;
    } catch (e) {
      if (mounted) setState(() { _loadingPosts = false; });
      return [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final friends = ref.watch(friendsProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.green),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(supabaseServiceProvider).signOut();
              }
            },
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
      body: _initialLoading
          ? const ProfileSkeleton()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Profile header card
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.purpleGradient,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                    child: Text(
                      profile?.initial ?? '?',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(profile?.name ?? 'Anonymous', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  '@${profile?.username ?? 'unknown'}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(profile.bio!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                ],
                const SizedBox(height: 16),
                // Edit/Sign Out buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                      if (!_editing) {
                        _nameController.text = profile?.displayName ?? '';
                        _usernameController.text = profile?.username ?? '';
                        _bioController.text = profile?.bio ?? '';
                      }
                      setState(() => _editing = !_editing);
                    },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(_editing ? 'Cancel' : 'Edit Profile', style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stats row
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: [
              _StatCard(value: '${friends.friends.length}', label: 'Friends', icon: Icons.people_outline),
              const SizedBox(width: 8),
              _StatCard(value: '${_getMaxStreak()}', label: 'Streak', icon: Icons.local_fire_department_outlined),
              const SizedBox(width: 8),
              _StatCard(value: '$_postCount', label: 'Posts', icon: Icons.article_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab bar
        FadeInUp(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _TabButton(
                  label: 'Posts',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _TabButton(
                  label: 'Settings',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tab content
        if (_selectedTab == 0) ...[
          // Posts grid
          if (_loadingPosts)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_myPosts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=200&h=120&fit=crop',
                        height: 100,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          width: 160,
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.article_outlined, size: 32, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('No posts yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Share your progress!', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            )
          else
            ..._myPosts.map((post) => _buildPostCard(post, theme)),
        ],

        if (_selectedTab == 1) ...[
          // Settings content
          _buildSettingsSection(theme, themeMode),
        ],

        // Edit form
        if (_editing) ...[
          const SizedBox(height: 16),
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Display Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(hintText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(hintText: 'Bio'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        await ref.read(profileProvider.notifier).updateProfile(
                          user.id,
                          displayName: _nameController.text.trim(),
                          username: _usernameController.text.trim(),
                          bio: _bioController.text.trim(),
                        );
                        setState(() => _editing = false);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Friends list
        const SizedBox(height: 24),
        Text(
          'FRIENDS',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary, letterSpacing: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (friends.friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text('No friends yet', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...friends.friends.map((f) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                    child: Text(f.initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          '@${f.username ?? 'unknown'}',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
      ),
              ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, ThemeMode themeMode) {
    return Column(
      children: [
        // Theme toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dark_mode_outlined, color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      'Toggle dark/light mode',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: themeMode == ThemeMode.dark,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.purple,
                onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Stats button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(FadeRoute(page: const StatsScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart, color: AppColors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          'View your fasting history & streaks',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Workout History button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(FadeRoute(page: const WorkoutHistoryScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Workout History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          'View past workouts and progress',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Seed demo accounts
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () async {
              try {
                final svc = ref.read(supabaseServiceProvider);
                await svc.resetSeedFlag();
                await svc.ensureSeedAccounts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo accounts created! Search for Eric or Ariel.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add, color: AppColors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seed Demo Accounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          'Create Eric & Ariel profiles',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Danger zone
        Text(
          'DANGER ZONE',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary, letterSpacing: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: _confirmDeleteAccount,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7185).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever, color: Color(0xFFFB7185), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFFB7185))),
                        Text(
                          'Permanently delete your account and all data',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _getMaxStreak() {
    int max = 0;
    for (final h in ['exercise', 'no_sugar', 'no_smoking']) {
      final s = ref.read(habitProvider).getStreak(h);
      if (s > max) max = s;
    }
    return max;
  }

  void _confirmDeleteAccount() {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action is permanent and cannot be undone. All your data will be deleted:'),
            const SizedBox(height: 8),
            Text(
              '• Profile and posts\n• Fasting history\n• Workout history\n• Friends list\n• Habit streaks',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'Type DELETE to confirm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (confirmController.text != 'DELETE') return;
              Navigator.of(ctx).pop();
              try {
                await ref.read(supabaseServiceProvider).deleteAccount();
              } catch (_) {
                // Account may be partially deleted — sign out anyway
              }
              await ref.read(supabaseServiceProvider).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFB7185)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, ThemeData theme) {
    final typeEmoji = {
      'fasting': '\u{1F37D}\u{FE0F}',
      'fasting_complete': '\u2705',
      'exercise': '\u{1F3C3}',
      'workout_complete': '\u{1F3C6}',
      'general': '\u{1F4AC}',
    };
    final emoji = typeEmoji[post.type] ?? '\u{1F4AC}';
    final accent = post.type == 'exercise' || post.type == 'workout_complete'
        ? AppColors.green
        : AppColors.purple;

    return GestureDetector(
        onTap: () {
        Navigator.of(context).push(FadeRoute(page: ActivityDetailScreen(post: post)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accent, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.content ?? 'Post',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(post.timeAgo, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Icon(Icons.broken_image, color: AppColors.textTertiary)),
                  ),
                ),
              ),
            ],
            if (post.hypeCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('\u{1F525}', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${post.hypeCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.purple),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.purple)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.purple : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
