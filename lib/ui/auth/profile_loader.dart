import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';

class ProfileLoader extends ConsumerStatefulWidget {
  final Widget child;
  const ProfileLoader({super.key, required this.child});

  @override
  ConsumerState<ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends ConsumerState<ProfileLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(profileProvider.notifier).fetchProfile(user.id);
        ref.read(supabaseServiceProvider).autoFriendSeedAccounts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
