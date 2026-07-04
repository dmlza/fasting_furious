import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../models/models.dart';
import 'public_profile_screen.dart';

const _emojis = ['\u{1F525}', '\u{1F64C}', '\u{1F4AF}', '\u{1F44F}', '\u{1F4AA}'];

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final Post post;
  const ActivityDetailScreen({super.key, required this.post});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    final data = await ref.read(supabaseServiceProvider).client
        .from('comments')
        .select('*, user:user_id(username, display_name)')
        .eq('post_id', widget.post.id)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() {
        _comments = List<Map<String, dynamic>>.from(data);
        _loadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _commentController.text.trim().isEmpty) return;

    setState(() => _posting = true);
    await ref.read(supabaseServiceProvider).client.from('comments').insert({
      'user_id': user.id,
      'post_id': widget.post.id,
      'content': _commentController.text.trim(),
    });
    _commentController.clear();
    await _fetchComments();
    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(currentUserProvider);
    final post = widget.post;
    final config = _getConfig(post.type);
    final name = post.profile?.name ?? 'Someone';
    final initial = name[0].toUpperCase();

    final reactionCounts = <String, int>{};
    for (final r in post.reactions) {
      reactionCounts[r.emoji] = (reactionCounts[r.emoji] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity header
                  GestureDetector(
                    onTap: post.userId != ref.read(currentUserProvider)?.id ? () {
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
                          radius: 22,
                          backgroundColor: _avatarColor(name),
                          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('${config.emoji} ${config.label} \u00B7 ${post.timeAgo}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Activity content
                  Text(post.content ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
                  if (post.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],

                  // Activity stats
                  if (post.durationMinutes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Duration', value: post.durationFormatted),
                          _StatItem(label: 'Type', value: config.label),
                          _StatItem(label: 'Kudos', value: '${post.hypeCount}'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Kudos + Reactions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kudos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: _emojis.map((emoji) {
                            final count = reactionCounts[emoji] ?? 0;
                            final isActive = user != null && post.reactions.any((r) => r.userId == user.id && r.emoji == emoji);
                            return ActionChip(
                              label: Text('$emoji ${count > 0 ? count : ''}',
                                style: TextStyle(fontSize: 13, color: isActive ? AppColors.indigo : null)),
                              onPressed: user != null
                                  ? () => ref.read(feedProvider.notifier).toggleReaction(user.id, post.id, emoji).then((_) => setState(() {}))
                                  : null,
                              backgroundColor: isActive
                                  ? AppColors.indigo.withValues(alpha: 0.1)
                                  : theme.colorScheme.surface,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comments section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments (${_comments.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
                const SizedBox(height: 12),

                if (_loadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No comments yet. Be the first!', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    ),
                  )
                else
                  ..._comments.map((c) => _buildComment(c)),

                const SizedBox(height: 12),

                // Comment input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          suffixIcon: _posting
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _posting ? null : _postComment,
                      icon: Icon(Icons.send, color: AppColors.indigo),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final userData = comment['user'] as Map<String, dynamic>?;
    final name = userData?['display_name'] ?? userData?['username'] ?? 'Unknown';
    final initial = (name as String)[0].toUpperCase();
    final content = comment['content'] as String;
    final createdAt = DateTime.parse(comment['created_at']);

    String timeAgo;
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      timeAgo = 'just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
            child: Text(initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(timeAgo, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _getConfig(String type) {
    const configs = {
      'fasting': _TypeConfig('\u{1F37D}\u{FE0F}', 'Fasting'),
      'fasting_complete': _TypeConfig('\u2705', 'Fast Complete'),
      'exercise': _TypeConfig('\u{1F3C3}', 'Exercise'),
      'workout_complete': _TypeConfig('\u{1F3C6}', 'Workout Done'),
      'general': _TypeConfig('\u{1F4AC}', 'Update'),
    };
    return configs[type] ?? configs['general']!;
  }

  Color _avatarColor(String name) {
    const colors = [AppColors.indigo, AppColors.amber, AppColors.emerald, AppColors.coral];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.indigo)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}

class _TypeConfig {
  final String emoji, label;
  const _TypeConfig(this.emoji, this.label);
}
