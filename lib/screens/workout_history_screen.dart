import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  List<Map<String, dynamic>> _workouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = await ref.read(supabaseServiceProvider).fetchWorkoutHistory(user.id);
    if (mounted) setState(() { _workouts = data; _loading = false; });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _timeAgo(String iso) {
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\u{1F3C3}', style: TextStyle(fontSize: 48, color: theme.textTheme.bodySmall?.color)),
                      const SizedBox(height: 16),
                      Text('No workouts yet', style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color)),
                      const SizedBox(height: 6),
                      Text('Complete a workout to see it here', style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final w = _workouts[index];
                    final elapsed = w['elapsed_seconds'] as int? ?? 0;
                    final target = w['target_minutes'] as int? ?? 0;
                    final exercises = w['exercise_count'] as int? ?? 0;
                    final reps = w['total_reps'] as int? ?? 0;
                    final muscles = w['muscles_worked'] as String? ?? '';
                    final createdAt = w['created_at'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('\u{1F3C3}', style: TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$target Min Workout',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      _timeAgo(createdAt),
                                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMiniStat(Icons.timer_outlined, _formatTime(elapsed), AppColors.indigo),
                              const SizedBox(width: 16),
                              _buildMiniStat(Icons.fitness_center, '$exercises ex', AppColors.emerald),
                              const SizedBox(width: 16),
                              _buildMiniStat(Icons.repeat, '$reps reps', AppColors.amber),
                            ],
                          ),
                          if (muscles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: muscles.split(', ').take(4).map((m) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(m, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
