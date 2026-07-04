import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/exercise.dart';

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
  int _breakSeconds = 10;
  int _elapsedSeconds = 0;
  final int _restBetweenExercises = 10;

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
    _repsCompleted = 0;
    _hasStarted = false;

    if (exercise.isTimeBased) {
      _secondsRemaining = exercise.defaultDurationSeconds!;
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
        _completeExercise();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _completeExercise() {
    _tickTimer?.cancel();

    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() => _isBreak = true);
      _breakSeconds = _restBetweenExercises;

      _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _breakSeconds--;
          if (_breakSeconds <= 0) {
            timer.cancel();
            _isBreak = false;
            _currentExerciseIndex++;
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

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _buildWorkoutComplete(ctx),
    );
  }

  Widget _buildWorkoutComplete(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final totalMinutes = _elapsedSeconds ~/ 60;
    final totalSeconds = _elapsedSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F3C6}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Workout Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed ${widget.exercises.length} exercises in ${totalMinutes}m ${totalSeconds}s',
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
              'Rest',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              '$_breakSeconds',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800),
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
                  backgroundColor: AppColors.emerald,
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
                const SizedBox(width: 16),
                Text(
                  _formatElapsed(_elapsedSeconds),
                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Exercise content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Exercise demo placeholder
                  _buildExerciseDemo(exercise, color, theme),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 16),
                  // Reps/Timer display
                  if (exercise.isTimeBased)
                    _buildTimerDisplay(color, theme)
                  else
                    _buildRepsDisplay(exercise, color, theme),
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
    // Placeholder for exercise demo image
    // Replace with NetworkImage('your-url') when you have real images
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(exercise.name[0], style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.3))),
          const SizedBox(height: 8),
          Text(
            'Demo Image',
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 4),
          Text(
            'Add exercise images to assets',
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(Color color, ThemeData theme) {
    final exercise = widget.exercises[_currentExerciseIndex];
    final totalSeconds = exercise.defaultDurationSeconds ?? 1;
    final ringProgress = _secondsRemaining / totalSeconds;

    if (!_hasStarted) {
      return Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.3)),
                  ),
                ),
                Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get Ready',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: ringProgress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _secondsRemaining <= 10 ? AppColors.coral : color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isPaused ? 'PAUSED' : 'Time Remaining',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isPaused ? AppColors.amber : theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildRepsDisplay(Exercise exercise, Color color, ThemeData theme) {
    if (!_hasStarted) {
      return Column(
        children: [
          Text(
            '0',
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.5)),
          ),
          Text(
            'of ${exercise.defaultReps} reps',
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 8),
          Text(
            'Get Ready',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          '$_repsCompleted',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            color: _repsCompleted >= exercise.defaultReps! ? AppColors.emerald : color,
          ),
        ),
        Text(
          'of ${exercise.defaultReps} reps',
          style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 8),
        if (_isPaused)
          Text(
            'PAUSED',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber),
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
          // Pause/Resume
          _buildControlButton(
            icon: _isPaused ? Icons.play_arrow : Icons.pause,
            label: _isPaused ? 'Resume' : 'Pause',
            color: AppColors.amber,
            onTap: _togglePause,
          ),
          // Rep increment (reps-based) or Skip (time-based)
          if (isRepsBased)
            _buildControlButton(
              icon: Icons.add,
              label: '+1 Rep',
              color: AppColors.emerald,
              onTap: () {
                setState(() => _repsCompleted++);
                if (_repsCompleted >= exercise.defaultReps!) {
                  _completeExercise();
                }
              },
              large: true,
            )
          else
            _buildControlButton(
              icon: Icons.skip_next,
              label: 'Skip',
              color: AppColors.indigo,
              onTap: _skipExercise,
              large: true,
            ),
          // Skip exercise
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
            child: const Text('End', style: TextStyle(color: AppColors.coral)),
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
