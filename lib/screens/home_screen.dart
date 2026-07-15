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
import 'stats_screen.dart';
import 'sugar_detail_screen.dart';
import 'no_smoke_screen.dart';

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
        title: const Text(
          'Fasting Furious',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
            icon: const Icon(Icons.bar_chart, size: 22),
          ),
        ],
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
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SugarDetailScreen())),
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
    final isCheckedToday = state.habits.noSmoking;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NoSmokeScreen()),
      ),
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
                if (isCheckedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green)),
                      ],
                    ),
                  )
                else
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar to next milestone
            _buildNextMilestoneProgress(streak, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMilestoneProgress(int streak, bool isDark) {
    final timeSinceQuit = Duration(days: streak);
    final milestones = [
      const Duration(minutes: 20),
      const Duration(hours: 24),
      const Duration(hours: 48),
      const Duration(days: 3),
      const Duration(days: 7),
      const Duration(days: 14),
      const Duration(days: 30),
      const Duration(days: 365),
    ];

    Duration? nextMilestone;
    for (final m in milestones) {
      if (timeSinceQuit < m) {
        nextMilestone = m;
        break;
      }
    }

    if (nextMilestone == null) {
      return Text(
        'All milestones achieved!',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green),
      );
    }

    final progress = timeSinceQuit.inSeconds / nextMilestone.inSeconds;
    final remaining = nextMilestone - timeSinceQuit;
    final remainingText = remaining.inDays > 0
        ? '${remaining.inDays}d left'
        : remaining.inHours > 0
            ? '${remaining.inHours}h left'
            : '${remaining.inMinutes}m left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next milestone',
              style: TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            Text(
              remainingText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.greyLight.withValues(alpha: 0.5),
          valueColor: AlwaysStoppedAnimation(AppColors.green),
          borderRadius: BorderRadius.circular(2),
          minHeight: 4,
        ),
      ],
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
              children: [10, 15, 20, 25].map((m) {
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
