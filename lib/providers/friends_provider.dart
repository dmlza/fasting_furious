import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier(ref);
});

class FriendsState {
  final List<Profile> friends;
  final List<Map<String, dynamic>> friendRequests;
  final List<Map<String, dynamic>> sentRequests;
  final bool loading;

  FriendsState({
    this.friends = const [],
    this.friendRequests = const [],
    this.sentRequests = const [],
    this.loading = false,
  });

  FriendsState copyWith({
    List<Profile>? friends,
    List<Map<String, dynamic>>? friendRequests,
    List<Map<String, dynamic>>? sentRequests,
    bool? loading,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      loading: loading ?? this.loading,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final Ref ref;
  FriendsNotifier(this.ref) : super(FriendsState());

  Future<void> fetchFriends(String userId) async {
    state = state.copyWith(loading: true);
    final sent = await ref.read(supabaseServiceProvider).fetchFriendships(userId, 'accepted', sent: true);
    final received = await ref.read(supabaseServiceProvider).fetchFriendships(userId, 'accepted', sent: false);

    final friends = <Profile>[];
    for (final f in sent) {
      final userData = f['receiver'] as Map<String, dynamic>?;
      if (userData != null) {
        friends.add(Profile(
          id: userData['id'] as String? ?? '',
          username: userData['username'] as String?,
          displayName: userData['display_name'] as String?,
        ));
      }
    }
    for (final f in received) {
      final userData = f['sender'] as Map<String, dynamic>?;
      if (userData != null) {
        friends.add(Profile(
          id: userData['id'] as String? ?? '',
          username: userData['username'] as String?,
          displayName: userData['display_name'] as String?,
        ));
      }
    }
    state = FriendsState(friends: friends, loading: false);
  }

  Future<void> fetchFriendRequests(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchFriendships(userId, 'pending', sent: false);
    state = state.copyWith(friendRequests: data);
  }

  Future<void> fetchSentRequests(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchFriendships(userId, 'pending', sent: true);
    state = state.copyWith(sentRequests: data);
  }

  Future<void> fetchAll(String userId) async {
    state = state.copyWith(loading: true);
    await Future.wait([
      fetchFriends(userId),
      fetchFriendRequests(userId),
      fetchSentRequests(userId),
    ]);
    state = state.copyWith(loading: false);
  }

  Future<void> acceptRequest(String friendshipId, String fromUserId, String currentUserId) async {
    await ref.read(supabaseServiceProvider).acceptFriendRequest(friendshipId);
    await ref.read(supabaseServiceProvider).sendNotification(
      fromUserId, currentUserId, 'friend_accept', 'accepted your friend request');
  }

  Future<void> declineRequest(String friendshipId) async {
    await ref.read(supabaseServiceProvider).declineFriendRequest(friendshipId);
  }

  Future<void> removeFriend(String friendshipId) async {
    await ref.read(supabaseServiceProvider).removeFriend(friendshipId);
  }

  Future<void> cancelRequest(String friendshipId) async {
    await ref.read(supabaseServiceProvider).cancelFriendRequest(friendshipId);
  }
}
