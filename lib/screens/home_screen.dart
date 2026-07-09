import 'dart:async';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../models/models.dart';
import '../widgets/fasting_timer_ring.dart';
import '../widgets/health_recovery_timeline.dart';
import '../widgets/metabolic_dashboard.dart';
import 'workout_setup_screen.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  Timer? _tickTimer;
  String _selectedPreset = '16:8';
  Duration _timerRemaining = Duration.zero;
  String _timerPhase = 'READY';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
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

    setState(() {
      _timerRemaining = remaining.isNegative ? Duration.zero : remaining;
      _timerPhase = remaining.isNegative ? 'EATING WINDOW' : 'FASTING';
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildTimerSection(habitState, isDark),
                ),
                const SizedBox(height: 20),
                // Bento grid for habit cards
                _buildBentoGrid(habitState, isDark),
              ],
            ),
          ),
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

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.purpleGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
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
                    selectedColor: Colors.white.withValues(alpha: 0.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
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
                        try {
                          final data = await ref.read(supabaseServiceProvider).startTimer(
                            user.id,
                            type: 'fasting',
                            targetMinutes: preset,
                            presetType: _selectedPreset,
                          );
                          ref.read(habitProvider.notifier).setActiveTimer(ActiveTimer.fromMap(data));
                          _startTickIfNeeded();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to start fast. Please try again.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Start Fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final service = ref.read(supabaseServiceProvider);
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        try {
                          final elapsed = DateTime.now().difference(timer.startedAt).inSeconds;
                          final type = elapsed >= timer.targetMinutes * 60 ? 'fasting_complete' : 'fasting';
                          await service.stopTimer(timer.id);
                          if (type == 'fasting_complete') {
                            final today = DateTime.now().toIso8601String().split('T')[0];
                            final hours = (elapsed ~/ 3600).clamp(1, 72);
                            await service.saveFastingHours(user.id, today, hours);
                            await service.createPost(user.id, type: 'fasting_complete', content: 'Completed a $_selectedPreset fast!');
                          } else {
                            await service.createPost(user.id, type: 'fasting', content: 'Broke fast early', durationMinutes: elapsed ~/ 60);
                          }
                          ref.read(habitProvider.notifier).setActiveTimer(null);
                          _tickTimer?.cancel();
                          setState(() {
                            _timerRemaining = Duration.zero;
                            _timerPhase = 'READY';
                          });
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to end fast. Please try again.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('End Fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
            ),

            // Science button
            if (isActive) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showFastingScience(state),
                icon: const Icon(Icons.science_outlined, size: 18, color: Colors.white),
                label: const Text('Fasting Science', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(HabitState state, bool isDark) {
    final showSugar = state.gridLayout.contains('no_sugar');
    final showExercise = state.gridLayout.contains('exercise');
    final showSmoking = state.gridLayout.contains('no_smoking');

    return Column(
      children: [
        // Row 1: Sugar + Exercise side by side
        if (showSugar || showExercise)
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 100),
            child: Row(
              children: [
                if (showSugar) Expanded(child: _buildSugarBentoTile(state, isDark)),
                if (showSugar && showExercise) const SizedBox(width: 12),
                if (showExercise) Expanded(child: _buildExerciseBentoTile(state, isDark)),
              ],
            ),
          ),
        if ((showSugar || showExercise) && showSmoking)
          const SizedBox(height: 12),
        // Row 2: Smoking full width
        if (showSmoking)
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
            child: _buildSmokingBentoTile(state, isDark),
          ),
      ],
    );
  }

  Widget _buildSugarBentoTile(HabitState state, bool isDark) {
    final streak = state.getStreak('no_sugar');

    return GestureDetector(
      onTap: () => _showSugarMilestones(state),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('\u{1F525}', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 12),
            Text(
              '$streak',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.purple),
            ),
            const SizedBox(height: 2),
            Text(
              'day${streak != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey),
            ),
            const SizedBox(height: 2),
            Text('No Sugar', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseBentoTile(HabitState state, bool isDark) {
    return GestureDetector(
      onTap: () => _showExerciseModal(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('\u{1F3C3}', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${state.habits.exerciseMinutes}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.green),
                ),
                Text(
                  ' / 30',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('minutes', style: TextStyle(fontSize: 12, color: AppColors.grey)),
            const SizedBox(height: 2),
            Text("Today's Workout", style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmokingBentoTile(HabitState state, bool isDark) {
    final streak = state.getStreak('no_smoking');
    final timeSinceQuit = Duration(days: streak);

    return GestureDetector(
      onTap: () => _showHealthTimeline(timeSinceQuit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('\u{1F6AB}', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$streak',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.green),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'day${streak != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey),
                          ),
                        ],
                      ),
                      Text('No Smoking', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: state.habits.noSmoking,
                  activeThumbColor: AppColors.green,
                  onChanged: (_) {
                    final user = ref.read(currentUserProvider);
                    if (user != null) ref.read(habitProvider.notifier).toggleHabit(user.id, 'no_smoking');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.grey),
              ],
            ),
          ],
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
          child: MetabolicDashboard(hoursElapsed: elapsedH),
        ),
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
                      ? AppColors.purple.withValues(alpha: 0.08)
                      : active
                          ? AppColors.purple.withValues(alpha: 0.04)
                          : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: active ? Border.all(color: AppColors.purple, width: 1.5) : null,
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
            const Text('\u{1F3C3} Start Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Choose your workout duration',
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [5, 10, 15, 20, 30, 45].map((m) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WorkoutSetupScreen(targetMinutes: m)),
                    );
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text('$m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.green)),
                        const Text('min', style: TextStyle(fontSize: 12, color: AppColors.green)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                _showCustomDurationPicker();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Duration',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomDurationPicker() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Duration'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Minutes',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WorkoutSetupScreen(targetMinutes: minutes)),
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _MilestoneData {
  final String icon, label, desc;
  final int start, end, current;
  const _MilestoneData(this.icon, this.label, this.desc, this.start, this.end, this.current);
}
