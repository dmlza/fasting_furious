import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref);
});

class FeedState {
  final List<Post> posts;
  final bool loading;

  FeedState({this.posts = const [], this.loading = false});

  FeedState copyWith({List<Post>? posts, bool? loading}) {
    return FeedState(posts: posts ?? this.posts, loading: loading ?? this.loading);
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final Ref ref;
  FeedNotifier(this.ref) : super(FeedState());

  static const _typeConfig = {
    'fasting': _TypeConfig('\u{1F37D}\u{FE0F}', 'Fasting', 'indigo'),
    'fasting_complete': _TypeConfig('\u2705', 'Fast Complete', 'indigo'),
    'exercise': _TypeConfig('\u{1F3C3}', 'Exercise', 'emerald'),
    'workout_complete': _TypeConfig('\u{1F3C6}', 'Workout Done', 'emerald'),
    'checkin': _TypeConfig('\u{1F4F8}', 'Check-in', 'neutral'),
    'general': _TypeConfig('\u{1F4AC}', 'Update', 'neutral'),
  };

  _TypeConfig getConfig(String type) => _typeConfig[type] ?? _typeConfig['general']!;

  Future<void> fetchFeed(String userId) async {
    state = state.copyWith(loading: true);
    final service = ref.read(supabaseServiceProvider);

    try {
      // Fetch all posts (simple approach — no friendships dependency)
      final postsData = await service.client
          .from('posts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      // Fetch all profiles for the posts
      final userIds = (postsData as List).map((p) => p['user_id'] as String).toSet().toList();
      final profilesData = userIds.isNotEmpty
          ? await service.client.from('profiles').select('id, username, display_name').inFilter('id', userIds)
          : [];
      final profilesMap = <String, Map<String, dynamic>>{};
      for (final p in profilesData as List) {
        profilesMap[p['id'] as String] = p as Map<String, dynamic>;
      }

      final postIds = postsData.map((p) => p['id'] as String).toList();

      List<Map<String, dynamic>> reactions = [];
      if (postIds.isNotEmpty) {
        reactions = await service.fetchReactions(postIds);
      }

      final reactionsByPost = <String, List<Reaction>>{};
      for (final r in reactions) {
        final reaction = Reaction.fromMap(r);
        reactionsByPost.putIfAbsent(reaction.postId, () => []).add(reaction);
      }

      final posts = postsData.map((p) {
        final postReactions = reactionsByPost[p['id']] ?? [];
        final profileData = profilesMap[p['user_id']];
        return Post.fromMap(p, profileData: profileData).copyWith(
          reactions: postReactions,
          hypeCount: postReactions.where((r) => r.emoji == '\u{1F525}').length,
        );
      }).toList();

      state = FeedState(posts: posts, loading: false);
    } catch (e) {
      state = FeedState(posts: [], loading: false);
    }
  }

  Future<void> toggleReaction(String userId, String postId, String emoji) async {
    final service = ref.read(supabaseServiceProvider);
    final existing = state.posts
        .where((p) => p.id == postId)
        .expand((p) => p.reactions)
        .where((r) => r.userId == userId && r.emoji == emoji)
        .toList();

    if (existing.isNotEmpty) {
      await service.removeReaction(userId, postId);
    } else {
      await service.addReaction(userId, postId, emoji);
    }
  }
}

class _TypeConfig {
  final String emoji;
  final String label;
  final String color;
  const _TypeConfig(this.emoji, this.label, this.color);
}
