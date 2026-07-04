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
  final user = ref.watch(currentUserProvider);
  return ProfileNotifier(ref)..init(user);
});

class ProfileNotifier extends StateNotifier<Profile?> {
  final Ref ref;
  ProfileNotifier(this.ref) : super(null);

  void init(User? user) {
    if (user != null) fetchProfile(user.id);
  }

  Future<void> fetchProfile(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchProfile(userId);
    if (data != null) state = Profile.fromMap(data);
  }

  Future<void> updateProfile(String userId, {String? displayName, String? username, String? bio}) async {
    await ref.read(supabaseServiceProvider).updateProfile(userId, displayName: displayName, username: username, bio: bio);
    await fetchProfile(userId);
  }
}
