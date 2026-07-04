import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

enum WorkoutCategory {
  warmUp,
  mainExercise,
  coolDown,
}

extension WorkoutCategoryExtension on WorkoutCategory {
  String get label {
    switch (this) {
      case WorkoutCategory.warmUp:
        return 'Warm Up';
      case WorkoutCategory.mainExercise:
        return 'Main Exercise';
      case WorkoutCategory.coolDown:
        return 'Cool Down';
    }
  }

  String get icon {
    switch (this) {
      case WorkoutCategory.warmUp:
        return '\u{1F525}';
      case WorkoutCategory.mainExercise:
        return '\u{1F4AA}';
      case WorkoutCategory.coolDown:
        return '\u{1F9D8}';
    }
  }

  String get description {
    switch (this) {
      case WorkoutCategory.warmUp:
        return 'Prepare your body for exercise. Increase blood flow and flexibility.';
      case WorkoutCategory.mainExercise:
        return 'The core of your workout. Build strength and endurance.';
      case WorkoutCategory.coolDown:
        return 'Recover and stretch. Reduce soreness and improve flexibility.';
    }
  }

  Color get color {
    switch (this) {
      case WorkoutCategory.warmUp:
        return AppColors.amber;
      case WorkoutCategory.mainExercise:
        return AppColors.emerald;
      case WorkoutCategory.coolDown:
        return AppColors.indigo;
    }
  }
}

class Exercise {
  final String name;
  final String description;
  final WorkoutCategory category;
  final int? defaultReps;
  final int? defaultDurationSeconds;
  final String? imageUrl;
  final List<String> musclesWorked;
  final String difficulty;
  final String instructions;
  final String? bodyPart;
  final bool isCustom;

  const Exercise({
    required this.name,
    required this.description,
    required this.category,
    this.defaultReps,
    this.defaultDurationSeconds,
    this.imageUrl,
    this.musclesWorked = const [],
    this.difficulty = 'Beginner',
    required this.instructions,
    this.bodyPart,
    this.isCustom = false,
  });

  bool get isRepsBased => defaultReps != null;
  bool get isTimeBased => defaultDurationSeconds != null;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.index,
      'defaultReps': defaultReps,
      'defaultDurationSeconds': defaultDurationSeconds,
      'musclesWorked': musclesWorked,
      'difficulty': difficulty,
      'instructions': instructions,
      'bodyPart': bodyPart,
      'isCustom': true,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String,
      description: map['description'] as String,
      category: WorkoutCategory.values[map['category'] as int],
      defaultReps: map['defaultReps'] as int?,
      defaultDurationSeconds: map['defaultDurationSeconds'] as int?,
      musclesWorked: List<String>.from(map['musclesWorked'] ?? []),
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      instructions: map['instructions'] as String,
      bodyPart: map['bodyPart'] as String?,
      isCustom: true,
    );
  }
}

const List<Exercise> allExercises = [
  // Warm Up
  Exercise(
    name: 'Arm Circles',
    description: 'Warm up shoulders and improve range of motion.',
    category: WorkoutCategory.warmUp,
    defaultReps: 20,
    musclesWorked: ['Shoulders', 'Upper Back'],
    difficulty: 'Beginner',
    bodyPart: 'Arms',
    instructions: 'Stand with feet shoulder-width apart. Extend arms out to sides. Make small circles, gradually increasing size. Reverse direction after 10 reps.',
  ),
  Exercise(
    name: 'Leg Swings',
    description: 'Dynamic stretch for hips and hamstrings.',
    category: WorkoutCategory.warmUp,
    defaultReps: 15,
    musclesWorked: ['Hip Flexors', 'Hamstrings', 'Glutes'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand next to a wall for balance. Swing one leg forward and back in a controlled motion. Keep torso upright. Switch legs after reps.',
  ),
  Exercise(
    name: 'High Knees',
    description: 'Elevate heart rate and activate hip flexors.',
    category: WorkoutCategory.warmUp,
    defaultDurationSeconds: 30,
    musclesWorked: ['Hip Flexors', 'Quads', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand tall. Drive knees up toward chest alternately at a quick pace. Pump arms in sync. Stay on balls of feet.',
  ),
  Exercise(
    name: 'Butt Kicks',
    description: 'Dynamic quad stretch with cardio.',
    category: WorkoutCategory.warmUp,
    defaultDurationSeconds: 30,
    musclesWorked: ['Quads', 'Hamstrings'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Jog in place while kicking heels up toward glutes. Keep knees pointing down. Maintain a quick, rhythmic pace.',
  ),
  Exercise(
    name: 'Torso Twists',
    description: 'Mobilize the thoracic spine and core.',
    category: WorkoutCategory.warmUp,
    defaultReps: 20,
    musclesWorked: ['Obliques', 'Spine', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Stand with feet shoulder-width apart, arms bent at 90 degrees. Rotate torso left and right in a controlled motion. Keep hips facing forward.',
  ),
  Exercise(
    name: 'Inchworms',
    description: 'Full body warm up for hamstrings and core.',
    category: WorkoutCategory.warmUp,
    defaultReps: 8,
    musclesWorked: ['Hamstrings', 'Core', 'Shoulders', 'Chest'],
    difficulty: 'Beginner',
    bodyPart: 'Full Body',
    instructions: 'Stand tall, fold forward to touch toes. Walk hands out to plank position. Pause, then walk hands back to feet and stand up.',
  ),
  Exercise(
    name: 'Cat-Cow Stretch',
    description: 'Mobilize the spine and release tension.',
    category: WorkoutCategory.warmUp,
    defaultReps: 12,
    musclesWorked: ['Spine', 'Core', 'Neck'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Start on all fours. Alternate between arching back (cow) and rounding back (cat). Breathe in on cow, exhale on cat.',
  ),
  Exercise(
    name: 'World\'s Greatest Stretch',
    description: 'Multi-joint stretch for hips, thoracic spine, and hamstrings.',
    category: WorkoutCategory.warmUp,
    defaultReps: 8,
    musclesWorked: ['Hip Flexors', 'Hamstrings', 'Thoracic Spine', 'Groin'],
    difficulty: 'Beginner',
    bodyPart: 'Full Body',
    instructions: 'Lunge forward, place same-side elbow on floor inside front foot. Rotate and reach opposite arm to sky. Return and switch sides.',
  ),

  // Main Exercise
  Exercise(
    name: 'Push-Ups',
    description: 'Classic upper body push exercise.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 15,
    musclesWorked: ['Chest', 'Triceps', 'Shoulders', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Chest',
    instructions: 'Start in plank position. Lower chest to floor by bending elbows. Push back up to full arm extension. Keep body in a straight line.',
  ),
  Exercise(
    name: 'Bodyweight Squats',
    description: 'Fundamental lower body movement pattern.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 20,
    musclesWorked: ['Quads', 'Glutes', 'Hamstrings', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand with feet shoulder-width apart. Push hips back and bend knees to lower. Go until thighs are parallel to floor. Drive through heels to stand.',
  ),
  Exercise(
    name: 'Lunges',
    description: 'Unilateral leg strength and balance.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 12,
    musclesWorked: ['Quads', 'Glutes', 'Hamstrings', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Step forward with one leg. Lower back knee toward floor until both knees are at 90 degrees. Push back to start. Alternate legs.',
  ),
  Exercise(
    name: 'Plank',
    description: 'Isometric core stability hold.',
    category: WorkoutCategory.mainExercise,
    defaultDurationSeconds: 45,
    musclesWorked: ['Core', 'Shoulders', 'Glutes'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Start on forearms and toes. Keep body in a straight line from head to heels. Engage core and glutes. Breathe steadily. Do not let hips sag.',
  ),
  Exercise(
    name: 'Glute Bridges',
    description: 'Activate glutes and strengthen posterior chain.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 15,
    musclesWorked: ['Glutes', 'Hamstrings', 'Core'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Lie on back with knees bent, feet flat on floor. Drive through heels to lift hips toward ceiling. Squeeze glutes at top. Lower slowly.',
  ),
  Exercise(
    name: 'Mountain Climbers',
    description: 'Dynamic core and cardio exercise.',
    category: WorkoutCategory.mainExercise,
    defaultDurationSeconds: 30,
    musclesWorked: ['Core', 'Hip Flexors', 'Shoulders', 'Quads'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Start in plank position. Drive one knee toward chest, then switch legs quickly. Keep hips level and core engaged throughout.',
  ),
  Exercise(
    name: 'Dead Bugs',
    description: 'Core stability with contralateral movement.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 12,
    musclesWorked: ['Deep Core', 'Obliques', 'Hip Flexors'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Lie on back, arms extended toward ceiling, knees bent at 90 degrees. Lower opposite arm and leg toward floor simultaneously. Return and switch sides. Keep lower back pressed into floor.',
  ),
  Exercise(
    name: 'Burpees',
    description: 'Full body metabolic conditioning.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 10,
    musclesWorked: ['Full Body'],
    difficulty: 'Intermediate',
    bodyPart: 'Full Body',
    instructions: 'Stand, drop to squat, place hands on floor, jump feet back to plank, do a push-up, jump feet forward, explode up with arms overhead.',
  ),
  Exercise(
    name: 'Step-Ups',
    description: 'Unilateral leg strength using a bench or step.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 12,
    musclesWorked: ['Quads', 'Glutes', 'Calves'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand facing a bench. Step up with one foot, drive knee up at the top. Step back down with control. Complete all reps on one side before switching.',
  ),
  Exercise(
    name: 'Bicycle Crunches',
    description: 'Dynamic core exercise targeting obliques.',
    category: WorkoutCategory.mainExercise,
    defaultReps: 20,
    musclesWorked: ['Obliques', 'Rectus Abdominis', 'Hip Flexors'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Lie on back, hands behind head. Bring opposite elbow to opposite knee while extending other leg. Alternate in a pedaling motion.',
  ),

  // Cool Down
  Exercise(
    name: 'Standing Hamstring Stretch',
    description: 'Static stretch for hamstrings and lower back.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Hamstrings', 'Lower Back'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand tall, extend one leg forward with heel on floor. Hinge at hips and reach toward toes. Hold for 30 seconds. Switch legs.',
  ),
  Exercise(
    name: 'Quad Stretch',
    description: 'Standing stretch for the quadriceps.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Quads', 'Hip Flexors'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Stand on one leg. Grab opposite ankle and pull heel toward glutes. Keep knees together and hips forward. Hold for 30 seconds.',
  ),
  Exercise(
    name: 'Child\'s Pose',
    description: 'Gentle stretch for back, hips, and shoulders.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 45,
    musclesWorked: ['Lower Back', 'Lats', 'Hips', 'Shoulders'],
    difficulty: 'Beginner',
    bodyPart: 'Back',
    instructions: 'Kneel on floor, sit back on heels, fold forward with arms extended. Rest forehead on floor. Breathe deeply and relax into the stretch.',
  ),
  Exercise(
    name: 'Pigeon Pose',
    description: 'Deep hip opener for glutes and hip rotators.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Hip Rotators', 'Glutes', 'Hip Flexors'],
    difficulty: 'Intermediate',
    bodyPart: 'Legs',
    instructions: 'From all fours, bring one knee forward behind wrist. Extend other leg back. Square hips forward. Fold forward for deeper stretch.',
  ),
  Exercise(
    name: 'Seated Spinal Twist',
    description: 'Mobilize the spine and stretch obliques.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Obliques', 'Spine', 'Glutes'],
    difficulty: 'Beginner',
    bodyPart: 'Core',
    instructions: 'Sit with legs extended. Cross one leg over the other. Twist toward the bent knee, using opposite elbow for leverage. Hold and breathe.',
  ),
  Exercise(
    name: 'Chest Opener',
    description: 'Stretch the chest and front shoulders.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Chest', 'Anterior Deltoids'],
    difficulty: 'Beginner',
    bodyPart: 'Chest',
    instructions: 'Clasp hands behind back. Straighten arms and lift hands away from body. Squeeze shoulder blades together. Look slightly upward.',
  ),
  Exercise(
    name: 'Neck Rolls',
    description: 'Release tension in the neck and upper traps.',
    category: WorkoutCategory.coolDown,
    defaultReps: 10,
    musclesWorked: ['Neck', 'Upper Traps'],
    difficulty: 'Beginner',
    bodyPart: 'Arms',
    instructions: 'Slowly roll head in a circular motion. Start with small circles and gradually increase. Reverse direction after 5 reps. Move gently.',
  ),
  Exercise(
    name: '90/90 Stretch',
    description: 'Hip mobility stretch for internal and external rotation.',
    category: WorkoutCategory.coolDown,
    defaultDurationSeconds: 30,
    musclesWorked: ['Hip Rotators', 'Glutes', 'Hip Flexors'],
    difficulty: 'Beginner',
    bodyPart: 'Legs',
    instructions: 'Sit with front leg bent at 90 degrees in front, back leg bent at 90 degrees behind. Lean forward over front shin. Hold, then switch sides.',
  ),
];

const List<String> allBodyParts = [
  'All',
  'Arms',
  'Back',
  'Chest',
  'Core',
  'Full Body',
  'Legs',
];

List<Exercise> getExercisesForCategory(WorkoutCategory category, {String? bodyPart, List<Exercise>? customExercises}) {
  final builtIn = allExercises.where((e) => e.category == category);
  final custom = (customExercises ?? []).where((e) => e.category == category);
  final all = [...builtIn, ...custom];
  if (bodyPart != null && bodyPart != 'All') {
    return all.where((e) => e.bodyPart == bodyPart).toList();
  }
  return all;
}

Future<List<Exercise>> loadCustomExercises() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('ff_custom_exercises');
  if (json == null) return [];
  final list = jsonDecode(json) as List;
  return list.map((e) => Exercise.fromMap(e as Map<String, dynamic>)).toList();
}

Future<void> saveCustomExercises(List<Exercise> exercises) async {
  final prefs = await SharedPreferences.getInstance();
  final json = exercises.map((e) => e.toMap()).toList();
  await prefs.setString('ff_custom_exercises', jsonEncode(json));
}

class WorkoutSession {
  final int targetMinutes;
  final List<Exercise> selectedExercises;
  final Map<String, int> exerciseReps;
  int currentExerciseIndex;
  bool isActive;
  bool isPaused;
  DateTime? startedAt;

  WorkoutSession({
    required this.targetMinutes,
    required this.selectedExercises,
    Map<String, int>? exerciseReps,
    this.currentExerciseIndex = 0,
    this.isActive = false,
    this.isPaused = false,
    this.startedAt,
  }) : exerciseReps = exerciseReps ?? {};

  Exercise? get currentExercise =>
      currentExerciseIndex < selectedExercises.length
          ? selectedExercises[currentExerciseIndex]
          : null;

  bool get isComplete => currentExerciseIndex >= selectedExercises.length;

  int get totalExercises => selectedExercises.length;

  int get completedExercises => currentExerciseIndex;

  double get progress =>
      totalExercises > 0 ? completedExercises / totalExercises : 0.0;

  void nextExercise() {
    currentExerciseIndex++;
  }
}
