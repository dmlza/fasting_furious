import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

export '../services/supabase_service.dart' show SupabaseService;

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService.instance);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

final profileProvider = StateNotifierProvider<ProfileNotifier, Profile?>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<Profile?> {
  final Ref ref;
  ProfileNotifier(this.ref) : super(null);

  void init(User? user) {
    if (user != null) fetchProfile(user.id);
  }

  Future<void> fetchProfile(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchProfile(userId);
    if (data != null) {
      state = Profile.fromMap(data);
    } else {
      // Profile doesn't exist yet - create it from user metadata
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final username = user.userMetadata?['username'] as String? ?? user.email?.split('@').first;
        final displayName = user.userMetadata?['display_name'] as String? ?? username;
        await ref.read(supabaseServiceProvider).client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'display_name': displayName,
        }, onConflict: 'id');
        state = Profile(id: user.id, username: username, displayName: displayName);
      }
    }
  }

  Future<void> updateProfile(String userId, {String? displayName, String? username, String? bio}) async {
    await ref.read(supabaseServiceProvider).updateProfile(userId, displayName: displayName, username: username, bio: bio);
    await fetchProfile(userId);
  }
}
