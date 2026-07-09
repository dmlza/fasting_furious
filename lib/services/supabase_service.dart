import 'package:supabase_flutter/supabase_flutter.dart';

// Demo account IDs — match sql/seed_data.sql
const _seedUserIds = [
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // Eric
  'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', // Ariel
];

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

  Future<void> deleteAccount() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // Delete user data from tables
    await client.from('notifications').delete().eq('user_id', user.id);
    await client.from('reactions').delete().eq('user_id', user.id);
    await client.from('posts').delete().eq('user_id', user.id);
    await client.from('friendships').delete().or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');
    await client.from('habits').delete().eq('user_id', user.id);
    await client.from('active_timers').delete().eq('user_id', user.id);
    await client.from('workout_history').delete().eq('user_id', user.id);
    await client.from('profiles').delete().eq('id', user.id);

    // Delete auth user (requires server-side function or RLS)
    await client.auth.admin.deleteUser(user.id);
  }

  Future<void> resetPassword(String email) {
    return client.auth.resetPasswordForEmail(email);
  }

  /// Auto-friend new users with the demo accounts (Eric & Ariel)
  /// so their feed has content immediately.
  Future<void> autoFriendSeedAccounts(String userId) async {
    await _ensureSeedAccounts();
    for (final seedId in _seedUserIds) {
      try {
        final existing = await client
            .from('friendships')
            .select('id')
            .or('and(sender_id.eq.$userId,receiver_id.eq.$seedId),and(sender_id.eq.$seedId,receiver_id.eq.$userId)')
            .maybeSingle();
        if (existing != null) continue;

        await client.from('friendships').insert({
          'sender_id': userId,
          'receiver_id': seedId,
          'status': 'accepted',
        });
      } catch (_) {}
    }
  }

  bool _seeded = false;

  /// Creates Eric & Ariel accounts + sample data if they don't exist yet.
  Future<void> _ensureSeedAccounts() async {
    if (_seeded) return;
    try {
      // Check if Eric already exists
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', _seedUserIds[0])
          .maybeSingle();
      if (existing != null) {
        _seeded = true;
        return;
      }

      // Create Eric
      final ericRes = await client.auth.signUp(
        email: 'eric@fastingfurious.demo',
        password: 'demo123456',
        data: {'username': 'eric_fasts', 'display_name': 'Eric Torres'},
      );
      if (ericRes.user != null) {
        await client.from('profiles').upsert({
          'id': _seedUserIds[0],
          'username': 'eric_fasts',
          'display_name': 'Eric Torres',
          'bio': '16:8 warrior. Down 15lbs in 2 months. Coffee before noon only.',
        });
      }

      // Create Ariel
      final arielRes = await client.auth.signUp(
        email: 'ariel@fastingfurious.demo',
        password: 'demo123456',
        data: {'username': 'ariel_fit', 'display_name': 'Ariel Chen'},
      );
      if (arielRes.user != null) {
        await client.from('profiles').upsert({
          'id': _seedUserIds[1],
          'username': 'ariel_fit',
          'display_name': 'Ariel Chen',
          'bio': 'Fitness coach. 20:4 OMAD. Runner. Plant-based.',
        });
      }

      // Seed posts for Eric
      final ericId = ericRes.user?.id ?? _seedUserIds[0];
      final arielId = arielRes.user?.id ?? _seedUserIds[1];

      await client.from('posts').insert([
        {'user_id': ericId, 'type': 'fasting_complete', 'content': 'Completed a 16:8 fast! Feeling unstoppable.', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        {'user_id': ericId, 'type': 'exercise', 'content': 'Crushing 30min of chest and triceps today', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': ericId, 'type': 'general', 'content': 'Day 45 of my fasting journey. Down 15lbs total. The energy is unreal.', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      ]);

      // Seed posts for Ariel
      await client.from('posts').insert([
        {'user_id': arielId, 'type': 'fasting_complete', 'content': '20:4 OMAD complete. Bone broth to break the fast.', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        {'user_id': arielId, 'type': 'workout_complete', 'content': 'Just finished a 45min HIIT session. Heart rate peaked at 175.', 'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
        {'user_id': arielId, 'type': 'exercise', 'content': 'Morning run done before sunrise. 5K in 24min.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': arielId, 'type': 'general', 'content': 'Week 3 of 20:4. Sleep has improved dramatically. No more 2am wakes.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': arielId, 'type': 'fasting', 'content': 'Currently fasting. 14 hours in. Black coffee is keeping me going.', 'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()},
      ]);

      // Seed habits for last 7 days
      final today = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        await client.from('habits').upsert({
          'user_id': ericId,
          'date': date,
          'exercise': i % 3 != 0,
          'no_sugar': i >= 2,
          'no_smoking': true,
          'exercise_minutes': i % 3 == 0 ? 0 : 30 + (i * 5) % 20,
          'fasting_hours': i % 4 == 0 ? 14 : 16,
        }, onConflict: 'user_id,date');

        await client.from('habits').upsert({
          'user_id': arielId,
          'date': date,
          'exercise': true,
          'no_sugar': true,
          'no_smoking': true,
          'exercise_minutes': 45 + (i * 7) % 15,
          'fasting_hours': i % 3 == 0 ? 18 : 20,
        }, onConflict: 'user_id,date');
      }

      _seeded = true;
    } catch (_) {}
  }

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

  Future<void> saveFastingHours(String userId, String date, int hours) {
    return client.from('habits').upsert({
      'user_id': userId,
      'date': date,
      'fasting_hours': hours,
    }, onConflict: 'user_id,date');
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
      if (imageUrl != null) 'image_url': imageUrl,
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
