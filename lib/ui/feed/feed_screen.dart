import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../models/models.dart';
import '../../widgets/skeleton.dart';
import '../workouts/activity_detail_screen.dart';
import '../profile/public_profile_screen.dart';
import '../social/notifications_screen.dart';
import '../../config/page_transitions.dart';

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
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: Stack(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: feedState.posts.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == 0) return _buildStoriesBar(feedState, user);
                              final post = feedState.posts[i - 1];
                              return FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(milliseconds: (i - 1) * 60),
                                child: _buildPostCard(post, user),
                              );
                            },
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.people_outline, size: 40, color: AppColors.purple.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('No activity yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Add friends to see their progress,\nor share your own!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Find Friends'),
                style: AppDecorations.elevatedButton,
              ),
            ),
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

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: SizedBox(
        height: 76,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recent.length,
          itemBuilder: (ctx, i) {
            final post = recent[i];
            final name = post.profile?.name ?? '?';
            final config = _getConfig(post.type);
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
                          color: _accentColor(post.type),
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Text(name[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _accentColor(post.type),
                          )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${config.emoji} ${name.split(' ').first}',
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
      ),
    );
  }

  Widget _buildPostCard(Post post, User? user) {
    final config = _getConfig(post.type);
    final name = post.profile?.name ?? 'Someone';
    final initial = name[0].toUpperCase();
    final accent = _accentColor(post.type);

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: accent, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      radius: 16,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      child: Text(initial, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${config.emoji} ${config.label}',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(post.timeAgo, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
              // Body text
              if (hasContent && stats.isEmpty)
                Text(post.content!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
              if (hasContent && stats.isNotEmpty)
                Text(post.content!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              // Action buttons
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...stats.map((s) => s.actionLabel != null ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleStatAction(s, context),
                      icon: Icon(s.actionIcon, size: 16, color: accent),
                      label: Text(s.actionLabel!, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ) : const SizedBox.shrink()),
              ],
              const SizedBox(height: 8),
              // Reactions row
              Row(
                children: [
                  ..._emojis.map((emoji) {
                    final count = reactionCounts[emoji] ?? 0;
                    final isActive = user != null && post.reactions.any((r) => r.userId == user.id && r.emoji == emoji);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text('$emoji ${count > 0 ? count : ''}',
                          style: TextStyle(fontSize: 12, color: isActive ? accent : AppColors.textSecondary)),
                        onPressed: user != null ? () => ref.read(feedProvider.notifier).toggleReaction(user.id, post.id, emoji) : null,
                        backgroundColor: isActive
                            ? accent.withValues(alpha: 0.1)
                            : AppColors.surface,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }),
                  const Spacer(),
                  // Kudos
                  GestureDetector(
                    onTap: user != null ? () async {
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
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasKudoed ? AppColors.green.withValues(alpha: 0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('\u{1F525}', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            '${post.hypeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasKudoed ? AppColors.green : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      final match = RegExp(r'(\d+) day.*smoke-free').firstMatch(content);
      final days = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      stats.add(_PostStat(
        emoji: '\u{1F6AB}',
        label: '$days day${days != 1 ? 's' : ''} smoke-free',
        color: AppColors.green,
        actionLabel: 'Quit Smoking',
        actionIcon: Icons.smoke_free,
      ));
    }
    if (content.contains('sugar-free')) {
      final match = RegExp(r'(\d+) day.*sugar-free').firstMatch(content);
      final days = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      stats.add(_PostStat(
        emoji: '\u{1F525}',
        label: '$days day${days != 1 ? 's' : ''} sugar-free',
        color: AppColors.purple,
        actionLabel: 'Go Sugar Free',
        actionIcon: Icons.no_food,
      ));
    }
    if (content.contains('Currently fasting')) {
      stats.add(_PostStat(
        emoji: '\u{1F37D}\u{FE0F}',
        label: 'Currently fasting',
        color: AppColors.purple,
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
        color: AppColors.green,
        actionLabel: 'Log Exercise',
        actionIcon: Icons.fitness_center,
      ));
    }
    return stats;
  }

  void _handleStatAction(_PostStat stat, BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Head to Home to ${(stat.actionLabel ?? 'get started').toLowerCase()}!'),
        action: SnackBarAction(
          label: 'Home',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('${config.label} \u00B7 ${post.timeAgo}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
      'fasting': _TypeConfig('\u{1F37D}\u{FE0F}', 'Fasting', 'fasting'),
      'fasting_complete': _TypeConfig('\u2705', 'Fast Complete', 'fasting'),
      'exercise': _TypeConfig('\u{1F3C3}', 'Exercise', 'exercise'),
      'workout_complete': _TypeConfig('\u{1F3C6}', 'Workout Done', 'exercise'),
      'checkin': _TypeConfig('\u{1F4F8}', 'Check-in', 'general'),
      'general': _TypeConfig('\u{1F4AC}', 'Update', 'general'),
    };
    return configs[type] ?? configs['general']!;
  }

  Color _accentColor(String type) {
    switch (type) {
      case 'fasting':
      case 'fasting_complete':
        return AppColors.purple;
      case 'exercise':
      case 'workout_complete':
        return AppColors.green;
      default:
        return AppColors.textSecondary;
    }
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
