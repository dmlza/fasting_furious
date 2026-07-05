import 'package:flutter/material.dart';
import '../config/theme.dart';
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
  String _selectedBodyPart = 'All';
  List<Exercise> _customExercises = [];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentlySelected);
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await loadCustomExercises();
    if (mounted) setState(() => _customExercises = custom);
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
    final exercises = getExercisesForCategory(
      widget.category,
      bodyPart: _selectedBodyPart,
      customExercises: _customExercises,
    );
    final color = widget.category.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddCustomExercise(),
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Custom Exercise',
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(
              'Done (${_selected.length})',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Body part filter
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: allBodyParts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final part = allBodyParts[index];
                final isSelected = part == _selectedBodyPart;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBodyPart = part),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      part,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                                  if (exercise.isCustom)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Custom', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.purple)),
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
                                  if (exercise.bodyPart != null) ...[
                                    const SizedBox(width: 6),
                                    _buildTag(exercise.bodyPart!, color, theme),
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
          ),
        ],
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

  void _showAddCustomExercise() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final repsController = TextEditingController();
    final durationController = TextEditingController();
    final musclesController = TextEditingController();
    final instructionsController = TextEditingController();
    String? selectedBodyPart;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Exercise name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(hintText: 'Short description'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Reps', suffixText: 'reps'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Duration', suffixText: 'sec'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: musclesController,
                  decoration: const InputDecoration(hintText: 'Muscles (comma separated)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedBodyPart,
                  hint: const Text('Body Part'),
                  items: allBodyParts.where((p) => p != 'All').map((p) =>
                    DropdownMenuItem(value: p, child: Text(p)),
                  ).toList(),
                  onChanged: (v) => setDialogState(() => selectedBodyPart = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(hintText: 'Instructions'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final exercise = Exercise(
                  name: name,
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : 'Custom exercise',
                  category: widget.category,
                  defaultReps: int.tryParse(repsController.text),
                  defaultDurationSeconds: int.tryParse(durationController.text),
                  musclesWorked: musclesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  instructions: instructionsController.text.trim().isNotEmpty
                      ? instructionsController.text.trim()
                      : 'Perform the exercise with proper form.',
                  bodyPart: selectedBodyPart,
                  isCustom: true,
                );
                _customExercises.add(exercise);
                await saveCustomExercises(_customExercises);
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
