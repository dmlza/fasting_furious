import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../models/models.dart';
import 'activity_detail_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: feedState.loading && feedState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : feedState.posts.isEmpty
              ? const Center(child: Text('No updates yet. Add friends to see their progress!'))
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

    String body;
    switch (post.type) {
      case 'fasting':
        body = '$name is currently Fasting${post.durationFormatted.isNotEmpty ? ' (${post.durationFormatted} in)' : ''}';
      case 'fasting_complete':
        body = '$name completed a Fast${post.durationFormatted.isNotEmpty ? ' (${post.durationFormatted})' : ''}';
      case 'exercise':
        body = '$name is working out${post.durationFormatted.isNotEmpty ? ' (${post.durationFormatted})' : ''}';
      case 'workout_complete':
        body = '$name crushed a Workout!';
      default:
        body = '$name ${post.content ?? ''}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActivityDetailScreen(post: post)),
        );
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
            Row(
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
            const SizedBox(height: 12),
            // Body
            Text(body, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5)),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
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
