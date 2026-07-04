import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../models/models.dart';
import '../widgets/fasting_timer_ring.dart';
import '../widgets/health_recovery_timeline.dart';

const _fastingPresets = {
  '16:8': 16 * 60,
  '18:6': 18 * 60,
  '20:4': 20 * 60,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _tickTimer;
  String _selectedPreset = '16:8';
  Duration _timerRemaining = Duration.zero;
  String _timerPhase = 'READY';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(habitProvider.notifier).fetchAll(user.id);
      _startTickIfNeeded();
    }
  }

  void _startTickIfNeeded() {
    _tickTimer?.cancel();
    final timer = ref.read(habitProvider).activeTimer;
    if (timer == null) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final timer = ref.read(habitProvider).activeTimer;
    if (timer == null) return;
    final elapsed = DateTime.now().difference(timer.startedAt);
    final target = Duration(minutes: timer.targetMinutes);
    final remaining = target - elapsed;
    final progress = elapsed.inMinutes / timer.targetMinutes;

    setState(() {
      _timerRemaining = remaining.isNegative ? Duration.zero : remaining;
      _timerPhase = remaining.isNegative ? 'EATING WINDOW' : 'FASTING';
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fasting Furious',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            _buildTimerSection(habitState, isDark),
            const SizedBox(height: 24),
            if (habitState.gridLayout.contains('no_sugar'))
              _buildSugarCard(habitState, isDark),
            if (habitState.gridLayout.contains('no_sugar'))
              const SizedBox(height: 16),
            if (habitState.gridLayout.contains('exercise'))
              _buildExerciseCard(habitState, isDark),
            if (habitState.gridLayout.contains('exercise'))
              const SizedBox(height: 16),
            if (habitState.gridLayout.contains('no_smoking'))
              _buildSmokingCard(habitState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection(HabitState state, bool isDark) {
    final timer = state.activeTimer;
    final isActive = timer != null;
    final preset = _fastingPresets[_selectedPreset] ?? 960;
    final total = Duration(minutes: preset);

    final progress = isActive
        ? min(1.0, DateTime.now().difference(timer.startedAt).inMinutes / timer.targetMinutes)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Ring
            FastingTimerRing(
              progress: progress,
              remaining: _timerRemaining,
              total: total,
              phase: _timerPhase,
              isActive: isActive,
              preset: _selectedPreset,
            ),
            const SizedBox(height: 24),

            // Preset selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _fastingPresets.keys.map((p) {
                final isSelected = p == _selectedPreset;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: isActive ? null : (_) => setState(() => _selectedPreset = p),
                    selectedColor: AppColors.indigo.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.indigo : Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.indigo : Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: !isActive
                  ? ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        final data = await ref.read(supabaseServiceProvider).startTimer(
                          user.id,
                          type: 'fasting',
                          targetMinutes: preset,
                          presetType: _selectedPreset,
                        );
                        ref.read(habitProvider.notifier).setActiveTimer(ActiveTimer.fromMap(data));
                        _startTickIfNeeded();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Start Fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final service = ref.read(supabaseServiceProvider);
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        final elapsed = DateTime.now().difference(timer.startedAt).inSeconds;
                        final type = elapsed >= timer.targetMinutes * 60 ? 'fasting_complete' : 'fasting';
                        await service.stopTimer(timer.id);
                        if (type == 'fasting_complete') {
                          await service.createPost(user.id, type: 'fasting_complete', content: 'Completed a ${_selectedPreset} fast!');
                        } else {
                          await service.createPost(user.id, type: 'fasting', content: 'Broke fast early', durationMinutes: elapsed ~/ 60);
                        }
                        ref.read(habitProvider.notifier).setActiveTimer(null);
                        _tickTimer?.cancel();
                        setState(() {
                          _timerRemaining = Duration.zero;
                          _timerPhase = 'READY';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('End Fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
            ),

            // Science button
            if (isActive) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showFastingScience(state),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Fasting Science'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSugarCard(HabitState state, bool isDark) {
    final streak = state.getStreak('no_sugar');
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final hoursLeft = midnight.difference(now).inHours;
    final pct = ((24 - hoursLeft) / 24 * 100).clamp(0, 100);

    return GestureDetector(
      onTap: () => _showSugarMilestones(state),
      child: Card(
        color: AppColors.amber.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('\u{1F525}', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak Day${streak != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Text('No Sugar Streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                borderRadius: BorderRadius.circular(2),
                minHeight: 4,
              ),
              const SizedBox(height: 6),
              Text(
                '${hoursLeft}h until midnight',
                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(HabitState state, bool isDark) {
    return GestureDetector(
      onTap: () => _showExerciseModal(),
      child: Card(
        color: AppColors.emerald.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('\u{1F3C3}', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.habits.exerciseMinutes} / 30 min',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Text("Today's Workout", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: min(1.0, state.habits.exerciseMinutes / 30.0),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                borderRadius: BorderRadius.circular(2),
                minHeight: 4,
              ),
              const SizedBox(height: 6),
              Text(
                '${max(0, 30 - state.habits.exerciseMinutes)} min remaining',
                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmokingCard(HabitState state, bool isDark) {
    final streak = state.getStreak('no_smoking');
    final timeSinceQuit = Duration(days: streak);

    return GestureDetector(
      onTap: () => _showHealthTimeline(timeSinceQuit),
      child: Card(
        color: AppColors.coral.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('\u{1F6AB}', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak Day${streak != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Text('No Smoking Streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.habits.noSmoking,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.coral,
                    onChanged: (_) {
                      final user = ref.read(currentUserProvider);
                      if (user != null) ref.read(habitProvider.notifier).toggleHabit(user.id, 'no_smoking');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              HealthRecoveryTimeline(
                timeSinceQuit: timeSinceQuit,
                compact: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Timeline',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coral),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.coral),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHealthTimeline(Duration timeSinceQuit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: HealthRecoveryTimeline(
            timeSinceQuit: timeSinceQuit,
            compact: false,
          ),
        ),
      ),
    );
  }

  void _showFastingScience(HabitState state) {
    final timer = state.activeTimer;
    final elapsedH = timer != null
        ? DateTime.now().difference(timer.startedAt).inMinutes / 60.0
        : 0.0;

    final stages = [
      _StageData('\u{1FA78}', 'Blood Sugar Rise / Decline', 'Hours 0-4', 0, 4, elapsedH),
      _StageData('\u26A1', 'Gluconeogenesis', 'Hours 5-12', 5, 12, elapsedH),
      _StageData('\u{1F504}', 'Autophagy Phase', 'Hours 13-16', 13, 16, elapsedH),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('\u{1F9EA} Fasting Science Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...stages.map((s) => _buildScienceStage(s)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScienceStage(_StageData stage) {
    final completed = stage.elapsed >= stage.end;
    final active = stage.elapsed >= stage.start && stage.elapsed < stage.end;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.indigo
            : active
                ? AppColors.indigo.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: active ? Border.all(color: AppColors.indigo, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Text(stage.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: completed ? Colors.white : null,
                  ),
                ),
                Text(
                  stage.range,
                  style: TextStyle(
                    fontSize: 12,
                    color: completed ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            completed ? '\u2705' : active ? '\u25CB' : '\u{1F512}',
            style: TextStyle(fontSize: 16, color: completed ? Colors.white : null),
          ),
        ],
      ),
    );
  }

  void _showSugarMilestones(HabitState state) {
    final streak = state.getStreak('no_sugar');
    final milestones = [
      _MilestoneData('\u26A1', 'The Withdrawal Phase', 'Days 1-3 - Cravings peak, energy dips', 1, 3, streak),
      _MilestoneData('\u2696\uFE0F', 'Stabilization', 'Days 4-7 - Blood sugar normalizes', 4, 7, streak),
      _MilestoneData('\u2728', 'The Gut & Skin Glow', 'Days 8-14 - Digestion improves, skin clears', 8, 14, streak),
      _MilestoneData('\u{1F525}', 'Fat Burning & Habit Shift', 'Days 15-30 - Deep metabolic adaptation', 15, 30, streak),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('\u{1F9EA} No Sugar Milestone Roadmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...milestones.map((m) {
              final completed = m.current >= m.end;
              final active = m.current >= m.start && m.current < m.end;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.amber.withValues(alpha: 0.08)
                      : active
                          ? AppColors.amber.withValues(alpha: 0.04)
                          : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: active ? Border.all(color: AppColors.amber, width: 1.5) : null,
                ),
                child: Row(
                  children: [
                    Text(m.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(m.desc, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                        ],
                      ),
                    ),
                    Text(completed ? '\u2705' : '\u{1F512}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showExerciseModal() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('\u{1F3C3} Log Workout Minutes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [5, 10, 15, 20, 30, 45].map((m) {
                return ActionChip(
                  label: Text('$m min'),
                  onPressed: () => _logExercise(m, ctx),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _logExercise(int minutes, BuildContext ctx) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(habitProvider.notifier).logExerciseMinutes(user.id, minutes);
    if (mounted) Navigator.of(ctx).pop();
  }
}

class _StageData {
  final String icon, label, range;
  final double start, end, elapsed;
  const _StageData(this.icon, this.label, this.range, this.start, this.end, this.elapsed);
}

class _MilestoneData {
  final String icon, label, desc;
  final int start, end, current;
  const _MilestoneData(this.icon, this.label, this.desc, this.start, this.end, this.current);
}
