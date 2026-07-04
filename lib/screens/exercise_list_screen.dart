import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseListScreen extends StatefulWidget {
  final WorkoutCategory category;
  final List<Exercise> currentlySelected;

  const ExerciseListScreen({
    super.key,
    required this.category,
    required this.currentlySelected,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  late List<Exercise> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentlySelected);
  }

  bool _isSelected(Exercise exercise) {
    return _selected.any((e) => e.name == exercise.name);
  }

  void _toggle(Exercise exercise) {
    setState(() {
      if (_isSelected(exercise)) {
        _selected.removeWhere((e) => e.name == exercise.name);
      } else {
        _selected.add(exercise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = getExercisesForCategory(widget.category);
    final color = widget.category.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(
              'Done (${_selected.length})',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final selected = _isSelected(exercise);
          final repsText = exercise.isRepsBased
              ? '${exercise.defaultReps} reps'
              : exercise.isTimeBased
                  ? '${exercise.defaultDurationSeconds}s'
                  : '';

          return GestureDetector(
            onTap: () => _toggle(exercise),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.06) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? color : theme.dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        exercise.name[0],
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_circle, color: color, size: 20),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          exercise.description,
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTag(repsText, color, theme),
                            const SizedBox(width: 6),
                            _buildTag(exercise.difficulty, color, theme),
                            if (exercise.musclesWorked.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildTag(exercise.musclesWorked.first, color, theme),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
