import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../models/models.dart';
import '../widgets/skeleton.dart';
import 'public_profile_screen.dart';


class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  String _currentTab = 'friends';
  List<Profile> _searchResults = [];
  Timer? _searchDebounce;
  bool _searchLoading = false;
  final _searchController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user != null) await ref.read(friendsProvider.notifier).fetchAll(user.id);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _searchLoading = false; });
      return;
    }
    setState(() => _searchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await ref.read(supabaseServiceProvider).searchUsers(query.trim(), excludeUserId: ref.read(currentUserProvider)?.id);
        if (mounted) {
          setState(() {
            _searchResults = results.map((r) => Profile.fromMap(r)).toList();
            _searchLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _searchLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Search bar with glassmorphism
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search by username...',
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                        suffixIcon: _searchLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() { _searchResults = []; });
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search results
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text('Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
                          const Spacer(),
                          Text('${_searchResults.length} found', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ..._searchResults.map((r) => _buildSearchResult(r)),
                  ],
                ),
              ),

            // Tabs with gradient active state
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Friends',
                    count: friendsState.friends.length,
                    isActive: _currentTab == 'friends',
                    onTap: () => setState(() => _currentTab = 'friends'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Requests',
                    count: friendsState.friendRequests.length,
                    isActive: _currentTab == 'requests',
                    onTap: () => setState(() => _currentTab = 'requests'),
                    showBadge: friendsState.friendRequests.isNotEmpty,
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Sent',
                    count: friendsState.sentRequests.length,
                    isActive: _currentTab == 'sent',
                    onTap: () => setState(() => _currentTab = 'sent'),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: friendsState.loading
                  ? const FriendsSkeleton()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _buildContent(friendsState),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(Profile r) {
    final theme = Theme.of(context);
    final user = ref.read(currentUserProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: r.id,
              username: r.username,
              displayName: r.displayName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.purple.withValues(alpha: 0.12),
              child: Text(r.initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    '@${r.username ?? 'unknown'}',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            if (r.id != user?.id)
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FriendsState state) {
    if (_currentTab == 'friends') {
      if (state.friends.isEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.people_outline, size: 48, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No friends yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Search for users above to add friends',
                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              ),
            ),
          ],
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: state.friends.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (ctx, i) {
          final f = state.friends[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.purple.withValues(alpha: 0.12),
              child: Text(f.initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              '@${f.username ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: IconButton(
              icon: Icon(Icons.more_horiz, color: Theme.of(context).textTheme.bodySmall?.color),
              onPressed: () => _showFriendOptions(f),
            ),
          );
        },
      );
    } else if (_currentTab == 'requests') {
      if (state.friendRequests.isEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.mail_outline, size: 48, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
          ],
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: state.friendRequests.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (ctx, i) {
          final r = state.friendRequests[i];
          final senderData = r['sender'] as Map<String, dynamic>?;
          final name = (senderData?['display_name'] ?? senderData?['username'] ?? 'Unknown') as String;
          final initial = name[0].toUpperCase();
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.purple.withValues(alpha: 0.12),
              child: Text(initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              '@${senderData?['username'] ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider);
                    if (user == null) return;
                    await ref.read(friendsProvider.notifier).acceptRequest(r['id'], r['sender_id'], user.id);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.green, size: 20),
                  onPressed: () async {
                    await ref.read(friendsProvider.notifier).declineRequest(r['id']);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      if (state.sentRequests.isEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.send_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No sent requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
          ],
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: state.sentRequests.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (ctx, i) {
          final s = state.sentRequests[i];
          final receiverData = s['receiver'] as Map<String, dynamic>?;
          final name = (receiverData?['display_name'] ?? receiverData?['username'] ?? 'Unknown') as String;
          final initial = name[0].toUpperCase();
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.purple.withValues(alpha: 0.12),
              child: Text(initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              'Request pending...',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppColors.green, size: 20),
              alignment: Alignment.center,
              onPressed: () async {
                await ref.read(friendsProvider.notifier).cancelRequest(s['id']);
                _load();
              },
            ),
          );
        },
      );
    }
  }

  void _showFriendOptions(Profile friend) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View Profile'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: AppColors.green),
                title: const Text('Remove Friend', style: TextStyle(color: AppColors.green)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove Friend'),
                      content: Text('Remove ${friend.name} from your friends?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.green),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  try {
                    final friendships = await ref.read(supabaseServiceProvider).fetchFriendships(user.id, 'accepted');
                    final match = friendships.where((fr) =>
                      (fr['sender_id'] == user.id && fr['receiver_id'] == friend.id) ||
                      (fr['receiver_id'] == user.id && fr['sender_id'] == friend.id));
                    if (match.isNotEmpty) {
                      await ref.read(supabaseServiceProvider).removeFriend(match.first['id']);
                      _load();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to remove friend. Please try again.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isActive,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppGradients.purpleGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? Colors.transparent : Theme.of(context).dividerColor,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.25)
                        : showBadge
                            ? AppColors.green
                            : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : showBadge
                              ? Colors.white
                              : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
