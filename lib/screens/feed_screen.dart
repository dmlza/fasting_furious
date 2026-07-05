import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/notifications_provider.dart';
import '../models/models.dart';
import '../widgets/skeleton.dart';
import 'activity_detail_screen.dart';
import 'public_profile_screen.dart';
import 'notifications_screen.dart';
import '../config/page_transitions.dart';

const _emojis = ['\u{1F525}', '\u{1F64C}', '\u{1F4AF}', '\u{1F44F}', '\u{1F4AA}'];

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = ref.read(currentUserProvider);
    if (user != null) await ref.read(feedProvider.notifier).fetchFeed(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final user = ref.read(currentUserProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.unreadCount;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Badge(
              label: unreadCount > 0 ? Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)) : null,
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: feedState.loading && feedState.posts.isEmpty
          ? const FeedSkeleton()
          : feedState.error != null && feedState.posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 48, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text(feedState.error!, style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _fetch,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : feedState.posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('No activity yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            'Add friends to see their progress,\nor share your own!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to search tab
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('Find Friends'),
                          ),
                        ],
                      ),
                    )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Stories bar
                      _buildStoriesBar(feedState, user),
                      const SizedBox(height: 8),
                      // Feed posts
                      ...feedState.posts.map((post) => _buildPostCard(post, user)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStoriesBar(FeedState state, User? user) {
    final seen = <String>{};
    final recent = state.posts.where((p) {
      if (seen.contains(p.userId)) return false;
      if (DateTime.now().difference(p.createdAt).inHours > 24) return false;
      seen.add(p.userId);
      return true;
    }).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recent.length,
        itemBuilder: (ctx, i) {
          final post = recent[i];
          final name = post.profile?.name ?? '?';
          return GestureDetector(
            onTap: () => _showStoryPopup(post),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _avatarColor(post.type),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Text(name[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      name.split(' ').first,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Post post, User? user) {
    final config = _getConfig(post.type);
    final name = post.profile?.name ?? 'Someone';
    final initial = name[0].toUpperCase();

    final reactionCounts = <String, int>{};
    for (final r in post.reactions) {
      reactionCounts[r.emoji] = (reactionCounts[r.emoji] ?? 0) + 1;
    }

    final hasKudoed = user != null && post.reactions.any((r) => r.userId == user.id && r.emoji == '\u{1F525}');

    final stats = _parseStats(post.content ?? '');
    final hasContent = post.content != null && post.content!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(SlideUpRoute(page: ActivityDetailScreen(post: post)));
      },
      child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _cardColor(config.color, context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GestureDetector(
              onTap: post.userId != user?.id ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PublicProfileScreen(
                    userId: post.userId,
                    username: post.profile?.username,
                    displayName: post.profile?.displayName,
                  )),
                );
              } : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _avatarColor(name),
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${config.emoji} ${config.label}',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  Text(post.timeAgo, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Stat badges
            if (stats.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: stats.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${s.emoji} ${s.label}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.color),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),
            ],
            // Body text (skip if it's just stats repeated)
            if (hasContent && stats.isEmpty)
              Text(post.content!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5)),
            if (hasContent && stats.isNotEmpty)
              Text(post.content!, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4)),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons (Join)
            if (stats.isNotEmpty) ...[
              ...stats.map((s) => s.actionLabel != null ? Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleStatAction(s, context),
                    icon: Icon(s.actionIcon, size: 16, color: s.color),
                    label: Text(s.actionLabel!, style: TextStyle(color: s.color, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: s.color.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ) : const SizedBox.shrink()),
            ],
            // Reactions
            Wrap(
              spacing: 6,
              children: _emojis.map((emoji) {
                final count = reactionCounts[emoji] ?? 0;
                final isActive = user != null && post.reactions.any((r) => r.userId == user.id && r.emoji == emoji);
                return ActionChip(
                  label: Text('$emoji ${count > 0 ? count : ''}',
                    style: TextStyle(fontSize: 13, color: isActive ? Theme.of(context).colorScheme.primary : null)),
                  onPressed: user != null ? () => ref.read(feedProvider.notifier).toggleReaction(user.id, post.id, emoji) : null,
                  backgroundColor: isActive
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Kudos button
            SizedBox(
              width: double.infinity,
              child: ActionChip(
                label: Text(
                  '\u{1F525} Send Kudos${post.hypeCount > 0 ? ' (${post.hypeCount})' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasKudoed ? AppColors.hype : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onPressed: user != null
                    ? () async {
                        await ref.read(feedProvider.notifier).toggleReaction(user.id, post.id, '\u{1F525}');
                        if (mounted && !hasKudoed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('\u{1F525} Kudos sent to ${post.profile?.name ?? 'someone'}!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }
                    : null,
                backgroundColor: hasKudoed ? AppColors.hype.withValues(alpha: 0.06) : Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: hasKudoed ? AppColors.hype.withValues(alpha: 0.2) : Theme.of(context).dividerColor,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<_PostStat> _parseStats(String content) {
    final stats = <_PostStat>[];
    if (content.contains('smoke-free')) {
      final match = RegExp(r'(\d+) day').firstMatch(content);
      final days = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      stats.add(_PostStat(
        emoji: '\u{1F6AB}',
        label: '$days day${days != 1 ? 's' : ''} smoke-free',
        color: AppColors.coral,
        actionLabel: 'Quit Smoking',
        actionIcon: Icons.smoke_free,
      ));
    }
    if (content.contains('sugar-free')) {
      final match = RegExp(r'(\d+) day').firstMatch(content);
      final days = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      stats.add(_PostStat(
        emoji: '\u{1F525}',
        label: '$days day${days != 1 ? 's' : ''} sugar-free',
        color: AppColors.amber,
        actionLabel: 'Go Sugar Free',
        actionIcon: Icons.no_food,
      ));
    }
    if (content.contains('Currently fasting')) {
      stats.add(_PostStat(
        emoji: '\u{1F37D}\u{FE0F}',
        label: 'Currently fasting',
        color: AppColors.indigo,
        actionLabel: 'Start Fast',
        actionIcon: Icons.timer,
      ));
    }
    if (content.contains('Crushing') || content.contains('exercise')) {
      final match = RegExp(r'(\d+)min').firstMatch(content);
      final mins = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      stats.add(_PostStat(
        emoji: '\u{1F3C3}',
        label: mins > 0 ? '$mins min exercise' : 'Exercise done',
        color: AppColors.emerald,
        actionLabel: 'Log Exercise',
        actionIcon: Icons.fitness_center,
      ));
    }
    return stats;
  }

  void _handleStatAction(_PostStat stat, BuildContext context) {
    // Navigate based on stat type
    Navigator.of(context).popUntil((route) => route.isFirst);
    // The MainShell will show — user can tap the appropriate card
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Head to Home to ${(stat.actionLabel ?? 'get started').toLowerCase()}!'),
        action: SnackBarAction(
          label: 'Home',
          onPressed: () {
            // Already at root, tab switch happens via MainShell
          },
        ),
      ),
    );
  }

  void _showStoryPopup(Post post) {
    final name = post.profile?.name ?? 'Someone';
    final config = _getConfig(post.type);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('${config.label} \u00B7 ${post.timeAgo}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
            const SizedBox(height: 12),
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.imageUrl!, width: double.infinity),
              ),
            if (post.imageUrl == null)
              Text(post.content ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  _TypeConfig _getConfig(String type) {
    const configs = {
      'fasting': _TypeConfig('\u{1F37D}\u{FE0F}', 'Fasting', 'indigo'),
      'fasting_complete': _TypeConfig('\u2705', 'Fast Complete', 'indigo'),
      'exercise': _TypeConfig('\u{1F3C3}', 'Exercise', 'emerald'),
      'workout_complete': _TypeConfig('\u{1F3C6}', 'Workout Done', 'emerald'),
      'checkin': _TypeConfig('\u{1F4F8}', 'Check-in', 'neutral'),
      'general': _TypeConfig('\u{1F4AC}', 'Update', 'neutral'),
    };
    return configs[type] ?? configs['general']!;
  }

  Color _cardColor(String color, BuildContext context) {
    switch (color) {
      case 'indigo': return AppColors.indigo.withValues(alpha: 0.06);
      case 'emerald': return AppColors.emerald.withValues(alpha: 0.06);
      case 'amber': return AppColors.amber.withValues(alpha: 0.06);
      case 'coral': return AppColors.coral.withValues(alpha: 0.06);
      default: return Theme.of(context).colorScheme.surface;
    }
  }

  Color _avatarColor(String name) {
    const colors = [AppColors.indigo, AppColors.amber, AppColors.emerald, AppColors.coral, Colors.grey];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }
}

class _TypeConfig {
  final String emoji, label, color;
  const _TypeConfig(this.emoji, this.label, this.color);
}

class _PostStat {
  final String emoji;
  final String label;
  final Color color;
  final String? actionLabel;
  final IconData? actionIcon;

  const _PostStat({
    required this.emoji,
    required this.label,
    required this.color,
    this.actionLabel,
    this.actionIcon,
  });
}
