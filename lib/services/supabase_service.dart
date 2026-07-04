import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ubiuoinbhbegznphuwwa.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViaXVvaW5iaGJlZ3pucGh1d3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNzU2MTIsImV4cCI6MjA5Nzk1MTYxMn0.moG7EtjC-1HUM3v6ZTI-NYJVFJLEsM1x4IVBjSS_Fng',
  );
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  final client = Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? username}) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': username},
    );
  }

  Future<void> signOut() => client.auth.signOut();

  // Profiles
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final data = await client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  Future<void> updateProfile(String userId, {String? displayName, String? username, String? bio}) {
    return client.from('profiles').update({
      if (displayName != null) 'display_name': displayName,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
    }).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final data = await client
        .from('profiles')
        .select('id, username, display_name')
        .ilike('username', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(data);
  }

  // Habits
  Future<Map<String, dynamic>?> fetchHabits(String userId, String date) async {
    return client
        .from('habits')
        .select('*')
        .eq('user_id', userId)
        .eq('date', date)
        .maybeSingle();
  }

  Future<void> upsertHabit(Map<String, dynamic> data) {
    return client.from('habits').upsert(data, onConflict: 'user_id,date');
  }

  Future<List<Map<String, dynamic>>> fetchHabitHistory(String userId, int limitDays) async {
    final start = DateTime.now().subtract(Duration(days: limitDays));
    final data = await client
        .from('habits')
        .select('*')
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .order('date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  // Timers
  Future<Map<String, dynamic>?> fetchActiveTimer(String userId) async {
    return client
        .from('active_timers')
        .select('*')
        .eq('user_id', userId)
        .eq('active', true)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> startTimer(String userId, {required String type, required int targetMinutes, String? presetType}) {
    return client.from('active_timers').insert({
      'user_id': userId,
      'type': type,
      'target_minutes': targetMinutes,
      'preset_type': presetType,
      'active': true,
    }).select().single();
  }

  Future<void> stopTimer(String timerId) {
    return client.from('active_timers').update({'active': false}).eq('id', timerId);
  }

  // Posts
  Future<List<Map<String, dynamic>>> fetchFeed(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    final data = await client
        .from('posts')
        .select('*, profile:user_id(username, display_name)')
        .inFilter('user_id', friendIds)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createPost(String userId, {required String type, String? content, String? imageUrl, int? durationMinutes}) {
    return client.from('posts').insert({
      'user_id': userId,
      'type': type,
      'content': content,
      'image_url': imageUrl,
      'duration_minutes': durationMinutes,
    });
  }

  Future<int> getPostCount(String userId) async {
    final data = await client
        .from('posts')
        .select('id')
        .eq('user_id', userId);
    return data.length;
  }

  // Reactions
  Future<List<Map<String, dynamic>>> fetchReactions(List<String> postIds) async {
    if (postIds.isEmpty) return [];
    final data = await client
        .from('reactions')
        .select('*')
        .inFilter('post_id', postIds);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addReaction(String userId, String postId, String emoji) {
    return client.from('reactions').insert({
      'user_id': userId,
      'post_id': postId,
      'emoji': emoji,
    });
  }

  Future<void> removeReaction(String userId, String postId) {
    return client.from('reactions').delete().eq('user_id', userId).eq('post_id', postId);
  }

  // Friendships
  Future<List<Map<String, dynamic>>> fetchFriendships(String userId, String status, {bool sent = true}) async {
    if (sent) {
      return List<Map<String, dynamic>>.from(await client
          .from('friendships')
          .select('*, receiver:receiver_id(username, display_name)')
          .eq('sender_id', userId)
          .eq('status', status));
    } else {
      return List<Map<String, dynamic>>.from(await client
          .from('friendships')
          .select('*, sender:sender_id(username, display_name)')
          .eq('receiver_id', userId)
          .eq('status', status));
    }
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) {
    return client.from('friendships').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) {
    return client.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> declineFriendRequest(String friendshipId) {
    return client.from('friendships').update({'status': 'declined'}).eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendshipId) {
    return client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> cancelFriendRequest(String friendshipId) {
    return client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<Map<String, dynamic>?> fetchFriendshipStatus(String userId, String otherId) async {
    return client
        .from('friendships')
        .select('sender_id, receiver_id, status')
        .or('and(sender_id.eq.$userId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$userId)')
        .maybeSingle();
  }

  Future<int> getFriendCount(String userId) async {
    final sent = await client
        .from('friendships')
        .select('id')
        .eq('sender_id', userId)
        .eq('status', 'accepted');
    final received = await client
        .from('friendships')
        .select('id')
        .eq('receiver_id', userId)
        .eq('status', 'accepted');
    return sent.length + received.length;
  }

  // Notifications
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    return List<Map<String, dynamic>>.from(await client
        .from('notifications')
        .select('*, from_user:from_user_id(username, display_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50));
  }

  Future<void> markNotificationsRead(String userId) {
    return client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  Future<void> sendNotification(String userId, String fromUserId, String type, String message) {
    return client.from('notifications').insert({
      'user_id': userId,
      'from_user_id': fromUserId,
      'type': type,
      'message': message,
    });
  }

  // Workout History
  Future<void> saveWorkoutHistory(String userId, {required int targetMinutes, required int elapsedSeconds, required int exerciseCount, required int totalReps, required String musclesWorked, String? categoryBreakdown}) {
    return client.from('workout_history').insert({
      'user_id': userId,
      'target_minutes': targetMinutes,
      'elapsed_seconds': elapsedSeconds,
      'exercise_count': exerciseCount,
      'total_reps': totalReps,
      'muscles_worked': musclesWorked,
      'category_breakdown': categoryBreakdown,
    });
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutHistory(String userId, {int limit = 50}) async {
    final data = await client
        .from('workout_history')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  // Realtime
  RealtimeChannel subscribeToFeed(void Function() onUpdate) {
    return client.channel('feed-changes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: (_) => onUpdate(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reactions',
        callback: (_) => onUpdate(),
      )
      ..subscribe();
  }

  RealtimeChannel subscribeToNotifications(String userId, void Function(Map<String, dynamic>) onInsert) {
    return client.channel('notifications-$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) => onInsert(payload.newRecord),
      )
      ..subscribe();
  }
}
