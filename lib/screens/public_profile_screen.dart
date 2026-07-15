import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'activity_detail_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? username;
  final String? displayName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.username,
    this.displayName,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  List<Post> _posts = [];
  bool _loading = true;
  bool _isFriend = false;
  bool _requestSent = false;
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    await Future.wait([
      _fetchPosts(),
      if (user != null) _checkFriendship(user.id),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchPosts() async {
    try {
      final data = await ref.read(supabaseServiceProvider).client
          .from('posts')
          .select('*')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(50);
      final posts = (data as List).map((p) => Post.fromMap(p, profileData: {
        'id': widget.userId,
        'username': widget.username,
        'display_name': widget.displayName,
      })).toList();
      if (mounted) setState(() { _posts = posts; _postCount = posts.length; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _checkFriendship(String currentUserId) async {
    try {
      final status = await ref.read(supabaseServiceProvider).fetchFriendshipStatus(currentUserId, widget.userId);
      if (mounted && status != null) {
        setState(() {
          _isFriend = status['status'] == 'accepted';
          _requestSent = status['status'] == 'pending';
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFriend() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      if (_isFriend || _requestSent) {
        // Find the friendship to remove/cancel
        final sent = await ref.read(supabaseServiceProvider).fetchFriendships(user.id, 'accepted', sent: true);
        final pending = await ref.read(supabaseServiceProvider).fetchFriendships(user.id, 'pending', sent: true);
        final received = await ref.read(supabaseServiceProvider).fetchFriendships(user.id, 'accepted', sent: false);
        final receivedPending = await ref.read(supabaseServiceProvider).fetchFriendships(user.id, 'pending', sent: false);

        final all = [...sent, ...pending, ...received, ...receivedPending];
        final match = all.where((f) =>
          (f['sender_id'] == user.id && f['receiver_id'] == widget.userId) ||
          (f['receiver_id'] == user.id && f['sender_id'] == widget.userId));

        if (match.isNotEmpty) {
          final id = match.first['id'];
          final status = match.first['status'];
          if (status == 'accepted') {
            await ref.read(supabaseServiceProvider).removeFriend(id);
          } else {
            await ref.read(supabaseServiceProvider).cancelFriendRequest(id);
          }
          setState(() { _isFriend = false; _requestSent = false; });
        }
      } else {
        await ref.read(supabaseServiceProvider).sendFriendRequest(user.id, widget.userId);
        await ref.read(supabaseServiceProvider).sendNotification(
          widget.userId, user.id, 'friend_request', '${ref.read(profileProvider)?.displayName ?? 'Someone'} sent you a friend request',
        );
        setState(() => _requestSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request sent!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  String get _name => widget.displayName ?? widget.username ?? 'Unknown';
  String get _initial => _name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.read(currentUserProvider);
    final isSelf = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Profile header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                          child: Text(_initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.purple)),
                        ),
                        const SizedBox(height: 12),
                        Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        if (widget.username != null)
                          Text('@${widget.username}', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(height: 16),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatPill(value: '$_postCount', label: 'Posts'),
                            const SizedBox(width: 16),
                            if (isSelf)
                              _StatPill(value: '', label: ''),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Friend button
                        if (!isSelf)
                          SizedBox(
                            width: 200,
                            height: 38,
                            child: _isFriend
                                ? OutlinedButton.icon(
                                    onPressed: _toggleFriend,
                                    icon: const Icon(Icons.check, size: 16, color: AppColors.green),
                                    label: const Text('Friends', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.green),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _toggleFriend,
                                    icon: Icon(_requestSent ? Icons.hourglass_empty : Icons.person_add, size: 16, color: Colors.white),
                                    label: Text(
                                      _requestSent ? 'Requested' : 'Follow',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.purple,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Posts header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Posts',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, letterSpacing: 1),
                    ),
                  ),
                ),

                // Posts list
                if (_posts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('\u{1F4AC}', style: TextStyle(fontSize: 40, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4))),
                          const SizedBox(height: 12),
                          Text('No posts yet', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    sliver: SliverList.separated(
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildPostCard(_posts[index], theme),
                    ),
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActivityDetailScreen(post: post)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(post.timeAgo, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                const Spacer(),
                if (post.hypeCount > 0)
                  Text('\u{1F525} ${post.hypeCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (post.content != null && post.content!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.content!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
            ],
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Icon(Icons.broken_image, color: theme.textTheme.bodySmall?.color)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: value.isEmpty
          ? const SizedBox.shrink()
          : Text(
              '$value $label',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.purple),
            ),
    );
  }
}
