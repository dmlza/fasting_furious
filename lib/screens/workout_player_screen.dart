import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/exercise.dart';
import 'workout_summary_screen.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final int targetMinutes;
  final List<Exercise> exercises;

  const WorkoutPlayerScreen({
    super.key,
    required this.targetMinutes,
    required this.exercises,
  });

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  Timer? _tickTimer;
  int _currentExerciseIndex = 0;
  int _repsCompleted = 0;
  int _secondsRemaining = 0;
  bool _isPaused = false;
  bool _hasStarted = false;
  bool _isBreak = false;
  int _breakSeconds = 60;
  int _elapsedSeconds = 0;
  int _restDuration = 60;
  final Map<String, int> _repsPerExercise = {};

  @override
  void initState() {
    super.initState();
    _initExercise();
  }

  void _initExercise() {
    if (_currentExerciseIndex >= widget.exercises.length) {
      _finishWorkout();
      return;
    }

    final exercise = widget.exercises[_currentExerciseIndex];
    _repsCompleted = _repsPerExercise[exercise.name] ?? 0;
    _hasStarted = _repsCompleted > 0;

    if (exercise.isTimeBased) {
      _secondsRemaining = exercise.defaultDurationSeconds ?? 1;
    } else {
      _secondsRemaining = 0;
    }
  }

  void _startExercise() {
    setState(() => _hasStarted = true);
    _startTick();
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isBreak) return;

      final exercise = widget.exercises[_currentExerciseIndex];
      bool shouldComplete = false;

      setState(() {
        _elapsedSeconds++;
        if (exercise.isTimeBased) {
          _secondsRemaining--;
          if (_secondsRemaining <= 0) {
            shouldComplete = true;
          }
        }
      });

      if (shouldComplete) {
        HapticFeedback.heavyImpact();
        _completeExercise();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _resetExercise() {
    final exercise = widget.exercises[_currentExerciseIndex];
    _tickTimer?.cancel();
    setState(() {
      _hasStarted = false;
      _isPaused = false;
      _repsCompleted = 0;
      if (exercise.isTimeBased) {
        _secondsRemaining = exercise.defaultDurationSeconds ?? 1;
      }
    });
  }

  void _completeExercise() {
    _tickTimer?.cancel();

    final exercise = widget.exercises[_currentExerciseIndex];
    if (exercise.isRepsBased) {
      _repsPerExercise[exercise.name] = _repsCompleted;
    }

    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() => _isBreak = true);
      _breakSeconds = _restDuration;

      _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) return;
        setState(() {
          _breakSeconds--;
          if (_breakSeconds <= 0) {
            timer.cancel();
            _isBreak = false;
            _currentExerciseIndex++;
            HapticFeedback.mediumImpact();
            _initExercise();
          }
        });
      });
    } else {
      _finishWorkout();
    }
  }

  void _skipExercise() {
    _tickTimer?.cancel();
    setState(() {
      _isBreak = false;
      _hasStarted = false;
      _currentExerciseIndex++;
    });
    _initExercise();
  }

  void _skipBreak() {
    _tickTimer?.cancel();
    _isBreak = false;
    _currentExerciseIndex++;
    _hasStarted = false;
    _initExercise();
  }

  void _finishWorkout() {
    _tickTimer?.cancel();

    final repsPerExercise = <String, int>{};
    for (final e in widget.exercises) {
      repsPerExercise[e.name] = _repsPerExercise[e.name] ?? (e.isRepsBased ? e.defaultReps ?? 0 : 0);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          targetMinutes: widget.targetMinutes,
          exercises: widget.exercises,
          elapsedSeconds: _elapsedSeconds,
          repsCompleted: repsPerExercise,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No exercises selected')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _isBreak ? _buildBreakView(theme) : _buildExerciseView(theme),
      ),
    );
  }

  Widget _buildBreakView(ThemeData theme) {
    final nextExercise = _currentExerciseIndex + 1 < widget.exercises.length
        ? widget.exercises[_currentExerciseIndex + 1]
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatElapsed(_elapsedSeconds),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            Text(
              'Rest',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              '$_breakSeconds',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            // Rest duration selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [30, 60, 90].map((secs) {
                final isSelected = _restDuration == secs;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _restDuration = secs;
                        if (_isBreak) _breakSeconds = secs;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : theme.dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '${secs}s',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.purple : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (nextExercise != null) ...[
              Text(
                'Up Next',
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              Text(
                nextExercise.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _skipBreak,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Skip Rest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseView(ThemeData theme) {
    final exercise = widget.exercises[_currentExerciseIndex];
    final color = exercise.category.color;
    final progress = (_currentExerciseIndex + 1) / widget.exercises.length;

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showExitDialog,
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Hero timer/counter + exercise info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Hero display — the main thing users see mid-set
                  if (exercise.isTimeBased)
                    _buildHeroTimer(exercise, color, theme)
                  else
                    _buildHeroReps(exercise, color, theme),
                  const SizedBox(height: 16),
                  // Exercise name
                  Text(
                    exercise.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.category.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Demo image (smaller, below the timer)
                  _buildExerciseDemo(exercise, color, theme),
                  const SizedBox(height: 20),
                  // Instructions
                  _buildInstructions(exercise, theme),
                ],
              ),
            ),
          ),

          // Bottom controls
          _buildControls(exercise, theme),
        ],
      ),
    );
  }

  Widget _buildExerciseDemo(Exercise exercise, Color color, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(exercise.name[0], style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.3))),
          const SizedBox(height: 6),
          Text(
            'Demo Image',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 2),
          Text(
            'Add exercise images to assets',
            style: TextStyle(fontSize: 9, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTimer(Exercise exercise, Color color, ThemeData theme) {
    final totalSeconds = exercise.defaultDurationSeconds ?? 1;
    final ringProgress = _secondsRemaining / totalSeconds;
    final isLast10 = _secondsRemaining <= 10 && _hasStarted;
    final timerColor = isLast10 ? AppColors.green : color;

    return Column(
      children: [
        // Elapsed time — small, above the ring
        Text(
          _formatElapsed(_elapsedSeconds),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 12),
        // Big countdown ring
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _hasStarted ? ringProgress.clamp(0.0, 1.0) : 1.0,
                  strokeWidth: 10,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    _hasStarted ? timerColor : color.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: _hasStarted ? timerColor : color.withValues(alpha: 0.5),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPaused ? 'PAUSED' : _hasStarted ? 'remaining' : 'Get Ready',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isPaused
                          ? AppColors.purple
                          : _hasStarted
                              ? timerColor
                              : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroReps(Exercise exercise, Color color, ThemeData theme) {
    final target = exercise.defaultReps ?? 0;
    final isComplete = _repsCompleted >= target;
    final repsColor = isComplete ? AppColors.green : color;

    return Column(
      children: [
        // Elapsed time — small, above the counter
        Text(
          _formatElapsed(_elapsedSeconds),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 12),
        // Big rep counter
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: target > 0 ? (_repsCompleted / target).clamp(0.0, 1.0) : 0.0,
                  strokeWidth: 10,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    _hasStarted ? repsColor : color.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_repsCompleted',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: _hasStarted ? repsColor : color.withValues(alpha: 0.5),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPaused
                        ? 'PAUSED'
                        : _hasStarted
                            ? 'of $target reps'
                            : 'of $target reps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isPaused
                          ? AppColors.purple
                          : _hasStarted
                              ? theme.textTheme.bodySmall?.color
                              : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  if (!_hasStarted) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Get Ready',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(Exercise exercise, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(exercise.category.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('How to do it', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercise.instructions,
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercise.musclesWorked.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: exercise.category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(m, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: exercise.category.color)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(Exercise exercise, ThemeData theme) {
    if (!_hasStarted) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ready to begin?',
              style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startExercise,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Start Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: exercise.category.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isRepsBased = exercise.isRepsBased;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reset
          _buildControlButton(
            icon: Icons.replay,
            label: 'Reset',
            color: Colors.orange,
            onTap: _resetExercise,
          ),
          // Pause/Resume
          _buildControlButton(
            icon: _isPaused ? Icons.play_arrow : Icons.pause,
            label: _isPaused ? 'Resume' : 'Pause',
            color: AppColors.purple,
            onTap: _togglePause,
          ),
          // Rep increment (reps-based) or Skip (time-based)
          if (isRepsBased)
            _buildControlButton(
              icon: Icons.add,
              label: '+1 Rep',
              color: AppColors.green,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _repsCompleted++);
                if (_repsCompleted >= exercise.defaultReps!) {
                  HapticFeedback.heavyImpact();
                  _completeExercise();
                }
              },
              large: true,
            )
          else
            _buildControlButton(
              icon: Icons.skip_next,
              label: 'Skip',
              color: AppColors.purple,
              onTap: _skipExercise,
              large: true,
            ),
          // Next
          _buildControlButton(
            icon: Icons.fast_forward,
            label: 'Next',
            color: theme.textTheme.bodySmall?.color ?? Colors.grey,
            onTap: _skipExercise,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool large = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 72 : 56,
            height: large ? 72 : 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: large ? 32 : 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Your progress won\'t be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('End', style: TextStyle(color: AppColors.green)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
