import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/friends_provider.dart';
import 'stats_screen.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(friendsProvider.notifier).fetchAll(user.id);
    await ref.read(habitProvider.notifier).fetchAll(user.id);
    final count = await ref.read(supabaseServiceProvider).getPostCount(user.id);
    if (mounted) setState(() => _postCount = count);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        // Profile Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                  child: Text(
                    profile?.initial ?? '?',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.indigo),
                  ),
                ),
                const SizedBox(height: 12),
                Text(profile?.name ?? 'Anonymous', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(
                  '@${profile?.username ?? 'unknown'}',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                ),
                if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(profile.bio!, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _editing = !_editing),
                      child: const Text('Edit Profile'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async => await ref.read(supabaseServiceProvider).signOut(),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(
          children: [
            _StatCard(value: '${friends.friends.length}', label: 'Friends'),
            _StatCard(value: '${_getMaxStreak()}', label: 'Streak \u{1F525}'),
            _StatCard(value: '$_postCount', label: 'Posts'),
          ],
        ),
        const SizedBox(height: 16),

        // Theme toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        'Toggle dark/light mode',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: themeMode == ThemeMode.dark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.indigo,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stats button
        Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart, color: AppColors.indigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          'View your fasting history & streaks',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                ],
              ),
            ),
          ),
        ),

        // Edit form
        if (_editing) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController..text = profile?.displayName ?? '',
                    decoration: const InputDecoration(hintText: 'Display Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController..text = profile?.username ?? '',
                    decoration: const InputDecoration(hintText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController..text = profile?.bio ?? '',
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
          'Friends (${friends.friends.length})',
          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        if (friends.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No friends yet', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          )
        else
          ...friends.friends.map((f) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                child: Text(f.initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
              ),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: Text(
                '@${f.username ?? 'unknown'}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            );
          }),
      ],
      ),
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
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.indigo)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
