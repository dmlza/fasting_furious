import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final int targetMinutes;
  final List<Exercise> exercises;
  final int elapsedSeconds;
  final Map<String, int> repsCompleted;

  const WorkoutSummaryScreen({
    super.key,
    required this.targetMinutes,
    required this.exercises,
    required this.elapsedSeconds,
    required this.repsCompleted,
  });

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;
  bool _shared = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _confettiAnimation = CurvedAnimation(parent: _confettiController, curve: Curves.easeOut);
    _confettiController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  int get _totalReps => widget.repsCompleted.values.fold(0, (sum, r) => sum + r);

  List<String> get _musclesWorked {
    final muscles = <String>{};
    for (final e in widget.exercises) {
      muscles.addAll(e.musclesWorked);
    }
    return muscles.toList()..sort();
  }

  Map<WorkoutCategory, int> get _categoryBreakdown {
    final map = <WorkoutCategory, int>{};
    for (final e in widget.exercises) {
      map[e.category] = (map[e.category] ?? 0) + 1;
    }
    return map;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  Future<void> _shareToFeed() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final content = 'Completed a ${widget.targetMinutes}-min workout! '
          '${widget.exercises.length} exercises, $_totalReps reps. '
          'Muscles: ${_musclesWorked.take(3).join(', ')}';

      await ref.read(supabaseServiceProvider).createPost(
        user.id,
        type: 'exercise',
        content: content,
        durationMinutes: widget.elapsedSeconds ~/ 60,
      );

      if (mounted) {
        setState(() {
          _shared = true;
          _sharing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Complete'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildConfetti(theme),
            const SizedBox(height: 24),
            _buildMainStats(theme),
            const SizedBox(height: 24),
            _buildCategoryBreakdown(theme),
            const SizedBox(height: 16),
            _buildMusclesWorked(theme),
            const SizedBox(height: 24),
            _buildShareButton(theme),
            const SizedBox(height: 12),
            _buildDoneButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti(ThemeData theme) {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _confettiAnimation.value,
          child: Column(
            children: [
              Text(
                '\u{1F3C6}',
                style: TextStyle(fontSize: 64 - (1 - _confettiAnimation.value) * 20),
              ),
              const SizedBox(height: 12),
              Text(
                'Nice Work!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: _formatTime(widget.elapsedSeconds),
            label: 'Duration',
            color: AppColors.indigo,
            theme: theme,
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '${widget.exercises.length}',
            label: 'Exercises',
            color: AppColors.emerald,
            theme: theme,
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          _buildStatItem(
            icon: Icons.repeat,
            value: '$_totalReps',
            label: 'Total Reps',
            color: AppColors.amber,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme) {
    final breakdown = _categoryBreakdown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final total = widget.exercises.length;
            final fraction = count / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(category.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$count exercise${count != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(category.color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMusclesWorked(ThemeData theme) {
    final muscles = _musclesWorked;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muscles Targeted', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: muscles.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.indigo)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    if (_shared) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Shared to Activity Feed',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emerald),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _sharing ? null : _shareToFeed,
        icon: _sharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.share_outlined, color: Colors.white),
        label: Text(
          _sharing ? 'Sharing...' : 'Share to Activity Feed',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.indigo.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildDoneButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Done',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
        ),
      ),
    );
  }
}
