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
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    try {
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
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _postComment() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _commentController.text.trim().isEmpty) return;

    setState(() => _posting = true);
    try {
      await ref.read(supabaseServiceProvider).client.from('comments').insert({
        'user_id': user.id,
        'post_id': widget.post.id,
        'content': _commentController.text.trim(),
      });
      _commentController.clear();
      await _fetchComments();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment. Please try again.')),
        );
      }
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(
                          color: _accentColor(post.type),
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
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
                                backgroundColor: _accentColor(post.type).withValues(alpha: 0.1),
                                child: Text(initial, style: TextStyle(color: _accentColor(post.type), fontWeight: FontWeight.w700, fontSize: 13)),
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
                        // Content
                        Text(post.content ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                        if (post.imageUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ],
                        // Stats
                        if (post.durationMinutes != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
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
                        const SizedBox(height: 12),
                        // Reactions
                        Wrap(
                          spacing: 6,
                          children: _emojis.map((emoji) {
                            final count = reactionCounts[emoji] ?? 0;
                            final isActive = user != null && post.reactions.any((r) => r.userId == user.id && r.emoji == emoji);
                            return ActionChip(
                              label: Text('$emoji ${count > 0 ? count : ''}',
                                style: TextStyle(fontSize: 12, color: isActive ? AppColors.purple : AppColors.textSecondary)),
                              onPressed: user != null
                                  ? () => ref.read(feedProvider.notifier).toggleReaction(user.id, post.id, emoji).then((_) => setState(() {}))
                                  : null,
                              backgroundColor: isActive
                                  ? AppColors.purple.withValues(alpha: 0.1)
                                  : AppColors.surface,
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

          // Comments section (bottom sheet style)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  offset: Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Comments header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_comments.length}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Comments list
                if (_loadingComments)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No comments yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (ctx, i) => _buildComment(_comments[i]),
                    ),
                  ),
                // Comment input
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 12,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            suffixIcon: _posting
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : null,
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _posting ? null : _postComment,
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          iconSize: 18,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.purple.withValues(alpha: 0.1),
            child: Text(initial, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(timeAgo, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.purple)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _TypeConfig {
  final String emoji, label;
  const _TypeConfig(this.emoji, this.label);
}
