import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../models/models.dart';


class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  String _currentTab = 'friends';
  List<Profile> _searchResults = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user != null) await ref.read(friendsProvider.notifier).fetchAll(user.id);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await ref.read(supabaseServiceProvider).searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results.map((r) => Profile.fromMap(r)).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Friends', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Search
          TextField(
            onChanged: _onSearch,
            decoration: const InputDecoration(hintText: 'Search users by username...'),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _searchResults.map((r) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                      child: Text(r.initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text(
                      '@${r.username ?? 'unknown'}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    onTap: () {},
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _TabButton(label: 'Friends', isActive: _currentTab == 'friends', onTap: () => setState(() => _currentTab = 'friends')),
              const SizedBox(width: 8),
              _TabButton(label: 'Requests', isActive: _currentTab == 'requests', onTap: () => setState(() => _currentTab = 'requests')),
              const SizedBox(width: 8),
              _TabButton(label: 'Sent', isActive: _currentTab == 'sent', onTap: () => setState(() => _currentTab = 'sent')),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: friendsState.loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(friendsState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FriendsState state) {
    if (_currentTab == 'friends') {
      if (state.friends.isEmpty) {
        return const Center(child: Text('No friends yet. Search for users to add!'));
      }
      return ListView.builder(
        itemCount: state.friends.length,
        itemBuilder: (ctx, i) {
          final f = state.friends[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
              child: Text(f.initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
            ),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '@${f.username ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
              onPressed: () async {},
            ),
          );
        },
      );
    } else if (_currentTab == 'requests') {
      if (state.friendRequests.isEmpty) {
        return const Center(child: Text('No pending requests'));
      }
      return ListView.builder(
        itemCount: state.friendRequests.length,
        itemBuilder: (ctx, i) {
          final r = state.friendRequests[i];
          final senderData = r['sender'] as Map<String, dynamic>?;
          final name = senderData?['display_name'] ?? senderData?['username'] ?? 'Unknown';
          final initial = (name as String)[0].toUpperCase();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
              child: Text(initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '@${senderData?['username'] ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider);
                    if (user == null) return;
                    await ref.read(friendsProvider.notifier).acceptRequest(r['id'], r['sender_id'], user.id);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                  onPressed: () async {
                    await ref.read(friendsProvider.notifier).declineRequest(r['id']);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      if (state.sentRequests.isEmpty) {
        return const Center(child: Text('No pending requests'));
      }
      return ListView.builder(
        itemCount: state.sentRequests.length,
        itemBuilder: (ctx, i) {
          final s = state.sentRequests[i];
          final receiverData = s['receiver'] as Map<String, dynamic>?;
          final name = receiverData?['display_name'] ?? receiverData?['username'] ?? 'Unknown';
          final initial = (name as String)[0].toUpperCase();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
              child: Text(initial, style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w600)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '@${receiverData?['username'] ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
              onPressed: () async {
                await ref.read(friendsProvider.notifier).cancelRequest(s['id']);
                _load();
              },
            ),
          );
        },
      );
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.indigo : Theme.of(context).colorScheme.surface,
          foregroundColor: isActive ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: isActive ? AppColors.indigo : Theme.of(context).dividerColor),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
