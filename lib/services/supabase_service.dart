import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Demo account IDs — match sql/seed_data.sql
const _seedUserIds = [
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', // Eric
  'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', // Ariel
  'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', // Marcus
  'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', // Priya
  'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55', // Jake
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

  /// Set to true while seed accounts are being created to prevent
  /// AuthGate from reacting to temporary sign-out/sign-in cycles.
  bool isSeeding = false;

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

    // Sign out — account deletion requires server-side function with service_role key
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return client.auth.resetPasswordForEmail(email);
  }

  /// Auto-friend new users with the demo accounts so their feed has content immediately.
  Future<void> autoFriendSeedAccounts(String userId) async {
    await ensureSeedAccounts();

    // Find seed users by username (works regardless of auth user IDs)
    final seedProfiles = await client
        .from('profiles')
        .select('id')
        .inFilter('username', ['eric_fasts', 'ariel_fit', 'marcus_run', 'priya_yoga', 'jake_gains']);

    for (final profile in seedProfiles) {
      final seedId = profile['id'] as String;
      if (seedId == userId) continue;
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

  /// Reset the seed flag so seed accounts can be re-created.
  Future<void> resetSeedFlag() async {
    _seeded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ff_seeded');
  }

  /// Creates seed accounts + sample data if they don't exist yet.
  /// Signs out after creation so the real user stays logged in.
  Future<void> ensureSeedAccounts() async {
    if (_seeded) return;

    // Check if we've already seeded before (even if accounts were deleted)
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ff_seeded') == true) {
      _seeded = true;
      return;
    }

    try {
      // Check if seed accounts already exist by username
      final existing = await client
          .from('profiles')
          .select('id')
          .inFilter('username', ['eric_fasts', 'ariel_fit', 'marcus_run', 'priya_yoga', 'jake_gains'])
          .limit(1);
      if (existing.isNotEmpty) {
        _seeded = true;
        await prefs.setBool('ff_seeded', true);
        return;
      }

      isSeeding = true;

      // Save current session
      final currentRefreshToken = client.auth.currentSession?.refreshToken;
      final currentUserId = client.auth.currentUser?.id;

      final seedAccounts = [
        ('eric@fastingfurious.demo', 'eric_fasts', 'Eric Torres', '16:8 warrior. Down 15lbs in 2 months. Coffee before noon only.'),
        ('ariel@fastingfurious.demo', 'ariel_fit', 'Ariel Chen', 'Fitness coach. 20:4 OMAD. Runner. Plant-based.'),
        ('marcus@fastingfurious.demo', 'marcus_run', 'Marcus Webb', 'Marathon runner. 18:6 IF. Chasing a sub-3hr marathon.'),
        ('priya@fastingfurious.demo', 'priya_yoga', 'Priya Sharma', 'Yoga teacher. 16:8. Mindfulness + fasting = clarity.'),
        ('jake@fastingfurious.demo', 'jake_gains', 'Jake Morrison', 'New to fasting. Day 12. 50lbs to lose. Let\'s go.'),
      ];

      final createdIds = <String>[];

      for (final (email, username, displayName, bio) in seedAccounts) {
        try {
          final result = await client.auth.signUp(
            email: email,
            password: 'demo123456',
            data: {'username': username, 'display_name': displayName},
          );
          // Use the ID from the signUp response, not currentUser (which may not be set if email confirmation is required)
          final id = result.user?.id;
          if (id != null) {
            await client.from('profiles').upsert({
              'id': id,
              'username': username,
              'display_name': displayName,
              'bio': bio,
            });
            createdIds.add(id);
          }
          // Sign out regardless
          await client.auth.signOut();
        } catch (_) {
          try { await client.auth.signOut(); } catch (_) {}
        }
      }

      // Restore original user's session
      if (currentRefreshToken != null && currentUserId != null) {
        try {
          await client.auth.setSession(currentRefreshToken);
        } catch (_) {}
      }

      // If we couldn't get real IDs, fall back to hardcoded ones
      final ericId = createdIds.isNotEmpty ? createdIds[0] : _seedUserIds[0];
      final arielId = createdIds.length > 1 ? createdIds[1] : _seedUserIds[1];
      final marcusId = createdIds.length > 2 ? createdIds[2] : _seedUserIds[2];
      final priyaId = createdIds.length > 3 ? createdIds[3] : _seedUserIds[3];
      final jakeId = createdIds.length > 4 ? createdIds[4] : _seedUserIds[4];

      await client.from('posts').insert([
        {'user_id': ericId, 'type': 'fasting_complete', 'content': 'Completed a 16:8 fast! Feeling unstoppable.', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        {'user_id': ericId, 'type': 'exercise', 'content': 'Crushing 30min of chest and triceps today', 'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String()},
        {'user_id': ericId, 'type': 'fasting', 'content': 'Hour 14 of my 16:8. The hunger waves come and go. Black coffee helps.', 'created_at': DateTime.now().subtract(const Duration(hours: 14)).toIso8601String()},
        {'user_id': ericId, 'type': 'general', 'content': 'Day 45 of my fasting journey. Down 15lbs total. The energy is unreal.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': ericId, 'type': 'workout_complete', 'content': 'Leg day done. Squats, lunges, and calf raises. Walking tomorrow will be interesting.', 'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 6)).toIso8601String()},
        {'user_id': ericId, 'type': 'fasting_complete', 'content': '18:6 today. Extended an extra 2 hours. Surprisingly manageable.', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'user_id': ericId, 'type': 'exercise', 'content': 'Morning 5K run. New personal best: 23:42. The fasting clarity is real.', 'created_at': DateTime.now().subtract(const Duration(days: 2, hours: 10)).toIso8601String()},
        {'user_id': ericId, 'type': 'general', 'content': 'No sugar for 30 days. Had to stare down a birthday cake today. Stayed strong.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': ericId, 'type': 'fasting_complete', 'content': '16:8 complete. Broke fast with grilled chicken and avocado.', 'created_at': DateTime.now().subtract(const Duration(days: 3, hours: 4)).toIso8601String()},
        {'user_id': ericId, 'type': 'workout_complete', 'content': 'Push day: bench press, overhead press, tricep dips. 45min total.', 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
        {'user_id': ericId, 'type': 'general', 'content': 'Sleep quality since fasting started: from 5hrs to 7.5hrs. Game changer.', 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
        {'user_id': ericId, 'type': 'fasting', 'content': 'Starting a 24hr fast. Wish me luck. Water and electrolytes only.', 'created_at': DateTime.now().subtract(const Duration(days: 5, hours: 8)).toIso8601String()},
        {'user_id': ericId, 'type': 'exercise', 'content': 'Pull day: deadlifts, rows, bicep curls. Back is feeling strong.', 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
        {'user_id': ericId, 'type': 'fasting_complete', 'content': '24hr fast complete! First one ever. Refeeding carefully tonight.', 'created_at': DateTime.now().subtract(const Duration(days: 6, hours: 4)).toIso8601String()},
        {'user_id': ericId, 'type': 'general', 'content': 'New PR on bench press: 185lbs. Fasting + strength training = gains.', 'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
        {'user_id': ericId, 'type': 'exercise', 'content': 'Quick 20min HIIT session before work. No excuse to skip.', 'created_at': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String()},
      ]);

      // Seed posts for Ariel
      await client.from('posts').insert([
        {'user_id': arielId, 'type': 'fasting_complete', 'content': '20:4 OMAD complete. Bone broth to break the fast.', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        {'user_id': arielId, 'type': 'workout_complete', 'content': 'Just finished a 45min HIIT session. Heart rate peaked at 175.', 'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
        {'user_id': arielId, 'type': 'exercise', 'content': 'Morning run done before sunrise. 5K in 24min.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': arielId, 'type': 'general', 'content': 'Week 3 of 20:4. Sleep has improved dramatically. No more 2am wakes.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': arielId, 'type': 'fasting', 'content': 'Currently fasting. 14 hours in. Black coffee is keeping me going.', 'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()},
        {'user_id': arielId, 'type': 'general', 'content': 'Coach tip: Hydrate before you feel thirsty. Water is your fasting ally.', 'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()},
        {'user_id': arielId, 'type': 'workout_complete', 'content': 'Strength training done. Squats, deadlifts, rows. Feeling powerful.', 'created_at': DateTime.now().subtract(const Duration(hours: 9)).toIso8601String()},
      ]);

      // Seed posts for Marcus
      await client.from('posts').insert([
        {'user_id': marcusId, 'type': 'exercise', 'content': '10K tempo run this morning. Negative splits the whole way. Fasted running hits different.', 'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()},
        {'user_id': marcusId, 'type': 'fasting_complete', 'content': '18:6 done. Refueled with oatmeal and banana. Ready for tomorrow\'s long run.', 'created_at': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String()},
        {'user_id': marcusId, 'type': 'general', 'content': 'Race day in 3 weeks. Peak training week. 60 miles scheduled. Fasting is keeping my energy stable.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': marcusId, 'type': 'workout_complete', 'content': 'Hill repeats x8. Quads are screaming. Worth it.', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'user_id': marcusId, 'type': 'fasting', 'content': 'Hour 16 of 18. The last 2 hours are always the mental game.', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        {'user_id': marcusId, 'type': 'exercise', 'content': 'Easy recovery run. 5K at conversational pace. Legs still sore from yesterday.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': marcusId, 'type': 'general', 'content': 'PR on my 5K: 19:47. Under 20 min for the first time! Fasting + consistent training = results.', 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
        {'user_id': marcusId, 'type': 'exercise', 'content': 'Long run Sunday: 15 miles. Negative splits. Fasted state is my secret weapon.', 'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()},
        {'user_id': marcusId, 'type': 'fasting_complete', 'content': '18:6 window closed. Refueled with protein and carbs. Ready for tomorrow.', 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
      ]);

      // Seed posts for Priya
      await client.from('posts').insert([
        {'user_id': priyaId, 'type': 'general', 'content': 'Morning meditation + 16:8 fasting. My mind has never been this clear. 60 days in.', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        {'user_id': priyaId, 'type': 'exercise', 'content': '90min vinyasa flow. Balance and focus are on another level since I started fasting.', 'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String()},
        {'user_id': priyaId, 'type': 'fasting_complete', 'content': '16:8 complete. Broke fast with a smoothie bowl. Nourish to flourish.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': priyaId, 'type': 'general', 'content': 'Teaching my first class since starting IF. Students noticed the change in my energy. Sharing the practice.', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'user_id': priyaId, 'type': 'fasting', 'content': 'Hour 12. Deep breathing through the hunger. It\'s just a wave. It passes.', 'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()},
        {'user_id': priyaId, 'type': 'general', 'content': 'Day 60 no sugar. My skin is glowing. Cravings are gone. This is freedom.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': priyaId, 'type': 'fasting_complete', 'content': '16:8 complete. Breaking fast with a green smoothie. Nourish to flourish.', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        {'user_id': priyaId, 'type': 'exercise', 'content': 'Morning yoga flow. 30min of sun salutations. The perfect way to start the day.', 'created_at': DateTime.now().subtract(const Duration(hours: 7)).toIso8601String()},
      ]);

      // Seed posts for Jake
      await client.from('posts').insert([
        {'user_id': jakeId, 'type': 'general', 'content': 'Day 12 of 16:8. Down 6lbs already. First week was brutal. Now it\'s routine.', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        {'user_id': jakeId, 'type': 'exercise', 'content': 'Walked 10K steps today. Not much but for a 280lb guy, it\'s a start.', 'created_at': DateTime.now().subtract(const Duration(hours: 7)).toIso8601String()},
        {'user_id': jakeId, 'type': 'fasting_complete', 'content': '16:8 done! Meal prepped for the week. Chicken, rice, broccoli. Simple.', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'user_id': jakeId, 'type': 'general', 'content': 'My doctor said keep going. Blood pressure already improving. This is why I\'m doing this.', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'user_id': jakeId, 'type': 'fasting', 'content': 'Hour 14. Hungry but determined. 50lbs to go. One day at a time.', 'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
        {'user_id': jakeId, 'type': 'exercise', 'content': 'First time in a gym in 2 years. Just did machines. Felt good to be back.', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
        {'user_id': jakeId, 'type': 'general', 'content': 'My wife started fasting too. Couple goals. Accountability is everything.', 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
        {'user_id': jakeId, 'type': 'general', 'content': 'Scale said 274 this morning. Started at 280. 6lbs down. Small wins.', 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
        {'user_id': jakeId, 'type': 'exercise', 'content': 'Walked 12K steps today. Progress is progress. Keep moving.', 'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()},
        {'user_id': jakeId, 'type': 'fasting_complete', 'content': '16:8 done! Meal prepped for the week. Staying consistent.', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
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

        // Marcus — runner, consistent exercise
        await client.from('habits').upsert({
          'user_id': marcusId,
          'date': date,
          'exercise': true,
          'no_sugar': i >= 1,
          'no_smoking': true,
          'exercise_minutes': 40 + (i * 3) % 25,
          'fasting_hours': 18,
        }, onConflict: 'user_id,date');

        // Priya — yoga teacher, very consistent
        await client.from('habits').upsert({
          'user_id': priyaId,
          'date': date,
          'exercise': true,
          'no_sugar': true,
          'no_smoking': true,
          'exercise_minutes': 60 + (i * 5) % 20,
          'fasting_hours': 16,
        }, onConflict: 'user_id,date');

        // Jake — new to this, still building habits
        await client.from('habits').upsert({
          'user_id': jakeId,
          'date': date,
          'exercise': i % 2 == 0,
          'no_sugar': i >= 3,
          'no_smoking': true,
          'exercise_minutes': i % 2 == 0 ? 20 + (i * 5) % 15 : 0,
          'fasting_hours': i >= 1 ? 16 : 14,
        }, onConflict: 'user_id,date');
      }

      _seeded = true;
      await prefs.setBool('ff_seeded', true);
    } catch (_) {}
    isSeeding = false;
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

  Future<List<Map<String, dynamic>>> searchUsers(String query, {String? excludeUserId}) async {
    var queryBuilder = client
        .from('profiles')
        .select('id, username, display_name')
        .ilike('username', '%$query%');
    if (excludeUserId != null) {
      queryBuilder = queryBuilder.neq('id', excludeUserId);
    }
    final data = await queryBuilder.limit(10);
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

  // Smoking Log
  Future<void> saveSmokingLog(String userId, {required String date, required int cigarettes, String? trigger, int? cravingIntensity}) {
    return client.from('smoking_log').upsert({
      'user_id': userId,
      'date': date,
      'cigarettes': cigarettes,
      if (trigger != null) 'trigger': trigger,
      if (cravingIntensity != null) 'craving_intensity': cravingIntensity,
    }, onConflict: 'user_id,date');
  }

  Future<List<Map<String, dynamic>>> fetchSmokingLog(String userId, {int limitDays = 90}) async {
    final start = DateTime.now().subtract(Duration(days: limitDays));
    final data = await client
        .from('smoking_log')
        .select('*')
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .order('date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> deleteSmokingLog(String userId, String date) {
    return client.from('smoking_log').delete().eq('user_id', userId).eq('date', date);
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
