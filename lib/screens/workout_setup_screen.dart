import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/exercise.dart';
import 'exercise_list_screen.dart';
import 'workout_player_screen.dart';

class WorkoutSetupScreen extends StatefulWidget {
  final int targetMinutes;

  const WorkoutSetupScreen({super.key, required this.targetMinutes});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final Map<WorkoutCategory, List<Exercise>> _selectedExercises = {
    WorkoutCategory.warmUp: [],
    WorkoutCategory.mainExercise: [],
    WorkoutCategory.coolDown: [],
  };

  int _getTotalExercises() {
    return _selectedExercises.values.fold(0, (sum, list) => sum + list.length);
  }

  bool _canStart() {
    return _selectedExercises.values.any((list) => list.isNotEmpty);
  }

  void _toggleExercise(WorkoutCategory category, Exercise exercise) {
    setState(() {
      final list = _selectedExercises[category]!;
      final index = list.indexWhere((e) => e.name == exercise.name);
      if (index >= 0) {
        list.removeAt(index);
      } else {
        list.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.targetMinutes} Min Workout'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Your Workout',
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 20),
                  ...WorkoutCategory.values.map((category) {
                    return _buildCategorySection(category, theme);
                  }),
                ],
              ),
            ),
          ),
          _buildStartButton(theme),
        ],
      ),
    );
  }

  Widget _buildCategorySection(WorkoutCategory category, ThemeData theme) {
    final selected = _selectedExercises[category]!;
    final color = category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showExercisePicker(category),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          category.description,
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected.isNotEmpty ? color : theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selected.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected.isNotEmpty ? Colors.white : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.add_circle_outline, color: color, size: 22),
                ],
              ),
            ),
          ),
          if (selected.isNotEmpty) ...[
            const Divider(height: 1),
            ...selected.map((exercise) => _buildSelectedExercise(exercise, category, theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedExercise(Exercise exercise, WorkoutCategory category, ThemeData theme) {
    final color = category.color;
    final repsText = exercise.isRepsBased
        ? '${exercise.defaultReps} reps'
        : exercise.isTimeBased
            ? '${exercise.defaultDurationSeconds}s'
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(exercise.name[0], style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '$repsText \u2022 ${exercise.musclesWorked.take(2).join(', ')}',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleExercise(category, exercise),
            child: Icon(Icons.close, size: 18, color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker(WorkoutCategory category) async {
    final selected = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => ExerciseListScreen(
          category: category,
          currentlySelected: _selectedExercises[category]!,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedExercises[category] = selected;
      });
    }
  }

  Widget _buildStartButton(ThemeData theme) {
    final canStart = _canStart();
    final totalExercises = _getTotalExercises();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalExercises > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalExercises exercise${totalExercises != 1 ? 's' : ''} selected',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canStart
                    ? () {
                        final allExercises = [
                          ..._selectedExercises[WorkoutCategory.warmUp]!,
                          ..._selectedExercises[WorkoutCategory.mainExercise]!,
                          ..._selectedExercises[WorkoutCategory.coolDown]!,
                        ];

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => WorkoutPlayerScreen(
                              targetMinutes: widget.targetMinutes,
                              exercises: allExercises,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  canStart ? 'Start Workout' : 'Select Exercises',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
