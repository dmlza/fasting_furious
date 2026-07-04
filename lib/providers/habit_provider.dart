import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier(ref);
});

class HabitState {
  final Habit habits;
  final List<HabitHistory> history;
  final ActiveTimer? activeTimer;
  final List<String> gridLayout;
  final bool isEditingGrid;

  HabitState({
    this.habits = const Habit(),
    this.history = const [],
    this.activeTimer,
    this.gridLayout = const ['fasting', 'no_sugar', 'exercise', 'no_smoking'],
    this.isEditingGrid = false,
  });

  HabitState copyWith({
    Habit? habits,
    List<HabitHistory>? history,
    ActiveTimer? activeTimer,
    List<String>? gridLayout,
    bool? isEditingGrid,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      history: history ?? this.history,
      activeTimer: activeTimer,
      gridLayout: gridLayout ?? this.gridLayout,
      isEditingGrid: isEditingGrid ?? this.isEditingGrid,
    );
  }

  int getStreak(String habit) {
    if (history.isEmpty) return 0;
    int streak = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (habit == 'exercise' && history[i].exercise) {
        streak++;
      } else if (habit == 'no_sugar' && history[i].noSugar) {
        streak++;
      } else if (habit == 'no_smoking' && history[i].noSmoking) {
        streak++;
      } else {
        return streak;
      }
    }
    return streak;
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  final Ref ref;
  HabitNotifier(this.ref) : super(HabitState()) {
    _loadGridLayout();
  }

  String get _today => DateTime.now().toIso8601String().split('T')[0];

  Future<void> _loadGridLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('ff_grid_layout');
    if (saved != null) state = state.copyWith(gridLayout: saved);
  }

  void setEditingGrid(bool editing) => state = state.copyWith(isEditingGrid: editing);

  void mountHabit(String habitId) {
    if (state.gridLayout.contains(habitId)) return;
    final updated = [...state.gridLayout, habitId];
    state = state.copyWith(gridLayout: updated);
    SharedPreferences.getInstance().then((p) => p.setStringList('ff_grid_layout', updated));
  }

  void unmountHabit(String habitId) {
    if (habitId == 'fasting') return;
    final updated = state.gridLayout.where((id) => id != habitId).toList();
    state = state.copyWith(gridLayout: updated);
    SharedPreferences.getInstance().then((p) => p.setStringList('ff_grid_layout', updated));
  }

  Future<void> fetchAll(String userId) async {
    await Future.wait([
      fetchHabits(userId),
      fetchHabitHistory(userId),
      fetchActiveTimer(userId),
    ]);
  }

  Future<void> fetchHabits(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchHabits(userId, _today);
    if (data != null) state = state.copyWith(habits: Habit.fromMap(data));
  }

  Future<void> fetchHabitHistory(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchHabitHistory(userId, 90);
    state = state.copyWith(
      history: data.map((d) => HabitHistory.fromMap(d)).toList(),
    );
  }

  Future<void> fetchActiveTimer(String userId) async {
    final data = await ref.read(supabaseServiceProvider).fetchActiveTimer(userId);
    state = state.copyWith(activeTimer: data != null ? ActiveTimer.fromMap(data) : null);
  }

  void setActiveTimer(ActiveTimer? timer) => state = state.copyWith(activeTimer: timer);

  Future<void> toggleHabit(String userId, String habit) async {
    final updated = Habit(
      exercise: habit == 'exercise' ? !state.habits.exercise : state.habits.exercise,
      noSugar: habit == 'no_sugar' ? !state.habits.noSugar : state.habits.noSugar,
      noSmoking: habit == 'no_smoking' ? !state.habits.noSmoking : state.habits.noSmoking,
      exerciseMinutes: state.habits.exerciseMinutes,
    );
    state = state.copyWith(habits: updated);

    final upsertData = {
      'user_id': userId,
      'date': _today,
      habit: habit == 'no_sugar' ? updated.noSugar : habit == 'no_smoking' ? updated.noSmoking : updated.exercise,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await ref.read(supabaseServiceProvider).upsertHabit(upsertData);
  }

  Future<void> logExerciseMinutes(String userId, int minutes) async {
    final total = state.habits.exerciseMinutes + minutes;
    final upsertData = {
      'user_id': userId,
      'date': _today,
      'exercise': true,
      'exercise_minutes': total,
      'exercise_updated_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await ref.read(supabaseServiceProvider).upsertHabit(upsertData);
    state = state.copyWith(
      habits: Habit(
        exercise: true,
        noSugar: state.habits.noSugar,
        noSmoking: state.habits.noSmoking,
        exerciseMinutes: total,
      ),
    );
  }
}
