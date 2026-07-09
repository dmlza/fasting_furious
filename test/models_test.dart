import 'package:flutter_test/flutter_test.dart';
import 'package:fasting_furious/models/models.dart';
import 'package:fasting_furious/models/exercise.dart';
import 'package:fasting_furious/providers/habit_provider.dart';

void main() {
  group('Profile', () {
    test('fromMap creates profile correctly', () {
      final map = {
        'id': 'user-1',
        'username': 'testuser',
        'display_name': 'Test User',
        'bio': 'Hello world',
      };
      final profile = Profile.fromMap(map);
      expect(profile.id, 'user-1');
      expect(profile.username, 'testuser');
      expect(profile.displayName, 'Test User');
      expect(profile.bio, 'Hello world');
    });

    test('fromMap handles null fields', () {
      final map = {'id': 'user-2'};
      final profile = Profile.fromMap(map);
      expect(profile.username, isNull);
      expect(profile.displayName, isNull);
      expect(profile.bio, isNull);
    });

    test('initial returns first char of displayName', () {
      final profile = Profile(id: '1', displayName: 'Alice');
      expect(profile.initial, 'A');
    });

    test('initial falls back to username', () {
      final profile = Profile(id: '1', username: 'bob');
      expect(profile.initial, 'B');
    });

    test('initial returns ? when no name', () {
      final profile = Profile(id: '1');
      expect(profile.initial, '?');
    });

    test('name returns displayName', () {
      final profile = Profile(id: '1', displayName: 'Alice', username: 'alice1');
      expect(profile.name, 'Alice');
    });

    test('name falls back to username', () {
      final profile = Profile(id: '1', username: 'bob1');
      expect(profile.name, 'bob1');
    });

    test('name returns Anonymous when empty', () {
      final profile = Profile(id: '1');
      expect(profile.name, 'Anonymous');
    });

    test('toMap roundtrips correctly', () {
      final profile = Profile(id: '1', username: 'u', displayName: 'D', bio: 'b');
      final map = profile.toMap();
      final restored = Profile.fromMap(map);
      expect(restored.id, profile.id);
      expect(restored.username, profile.username);
      expect(restored.displayName, profile.displayName);
      expect(restored.bio, profile.bio);
    });
  });

  group('Habit', () {
    test('defaults are all false and 0', () {
      const habit = Habit();
      expect(habit.exercise, false);
      expect(habit.noSugar, false);
      expect(habit.noSmoking, false);
      expect(habit.exerciseMinutes, 0);
    });

    test('fromMap parses correctly', () {
      final map = {
        'exercise': true,
        'no_sugar': false,
        'no_smoking': true,
        'exercise_minutes': 45,
      };
      final habit = Habit.fromMap(map);
      expect(habit.exercise, true);
      expect(habit.noSugar, false);
      expect(habit.noSmoking, true);
      expect(habit.exerciseMinutes, 45);
    });

    test('fromMap handles nulls', () {
      final habit = Habit.fromMap({});
      expect(habit.exercise, false);
      expect(habit.noSugar, false);
      expect(habit.noSmoking, false);
      expect(habit.exerciseMinutes, 0);
    });
  });

  group('HabitHistory', () {
    test('fromMap parses correctly', () {
      final map = {
        'date': '2026-07-09',
        'exercise': true,
        'no_sugar': true,
        'no_smoking': false,
        'exercise_minutes': 30,
        'fasting_hours': 16,
      };
      final h = HabitHistory.fromMap(map);
      expect(h.date, '2026-07-09');
      expect(h.exercise, true);
      expect(h.noSugar, true);
      expect(h.noSmoking, false);
      expect(h.exerciseMinutes, 30);
      expect(h.fastingHours, 16);
    });
  });

  group('ActiveTimer', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'timer-1',
        'type': 'fasting',
        'target_minutes': 960,
        'preset_type': '16:8',
        'active': true,
        'started_at': '2026-07-09T10:00:00.000Z',
      };
      final t = ActiveTimer.fromMap(map);
      expect(t.id, 'timer-1');
      expect(t.type, 'fasting');
      expect(t.targetMinutes, 960);
      expect(t.presetType, '16:8');
      expect(t.active, true);
      expect(t.startedAt, DateTime.parse('2026-07-09T10:00:00.000Z'));
    });
  });

  group('Post', () {
    test('timeAgo returns correct strings', () {
      final post = Post(
        id: '1',
        userId: 'u1',
        type: 'general',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(post.timeAgo, '5m ago');
    });

    test('timeAgo returns just now for < 1 min', () {
      final post = Post(
        id: '1',
        userId: 'u1',
        type: 'general',
        createdAt: DateTime.now(),
      );
      expect(post.timeAgo, 'just now');
    });

    test('durationFormatted returns correct format', () {
      final post = Post(id: '1', userId: 'u1', type: 'general', durationMinutes: 90, createdAt: DateTime.now());
      expect(post.durationFormatted, '1h 30m');
    });

    test('durationFormatted returns hours only', () {
      final post = Post(id: '1', userId: 'u1', type: 'general', durationMinutes: 60, createdAt: DateTime.now());
      expect(post.durationFormatted, '1h');
    });

    test('durationFormatted returns minutes only', () {
      final post = Post(id: '1', userId: 'u1', type: 'general', durationMinutes: 45, createdAt: DateTime.now());
      expect(post.durationFormatted, '45m');
    });

    test('durationFormatted returns empty for null', () {
      final post = Post(id: '1', userId: 'u1', type: 'general', createdAt: DateTime.now());
      expect(post.durationFormatted, '');
    });

    test('copyWith preserves fields', () {
      final post = Post(id: '1', userId: 'u1', type: 'general', content: 'hi', createdAt: DateTime.now());
      final copy = post.copyWith(content: 'bye');
      expect(copy.content, 'bye');
      expect(copy.id, '1');
      expect(copy.userId, 'u1');
    });
  });

  group('AppNotification', () {
    test('timeAgo returns correct strings', () {
      final n = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'friend_request',
        message: 'test',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(n.timeAgo, '3h ago');
    });
  });

  group('HabitState', () {
    test('getStreak returns 0 for empty history', () {
      final state = HabitState();
      expect(state.getStreak('no_sugar'), 0);
    });

    test('getStreak counts consecutive days', () {
      final state = HabitState(
        history: [
          HabitHistory(date: '2026-07-07', noSugar: true),
          HabitHistory(date: '2026-07-08', noSugar: true),
          HabitHistory(date: '2026-07-09', noSugar: true),
        ],
      );
      expect(state.getStreak('no_sugar'), 3);
    });

    test('getStreak stops at broken streak', () {
      final state = HabitState(
        history: [
          HabitHistory(date: '2026-07-07', noSugar: true),
          HabitHistory(date: '2026-07-08', noSugar: false),
          HabitHistory(date: '2026-07-09', noSugar: true),
        ],
      );
      expect(state.getStreak('no_sugar'), 1);
    });

    test('getStreak works for exercise', () {
      final state = HabitState(
        history: [
          HabitHistory(date: '2026-07-07', exercise: true),
          HabitHistory(date: '2026-07-08', exercise: true),
        ],
      );
      expect(state.getStreak('exercise'), 2);
    });

    test('getStreak works for no_smoking', () {
      final state = HabitState(
        history: [
          HabitHistory(date: '2026-07-07', noSmoking: true),
          HabitHistory(date: '2026-07-08', noSmoking: true),
          HabitHistory(date: '2026-07-09', noSmoking: true),
        ],
      );
      expect(state.getStreak('no_smoking'), 3);
    });
  });

  group('Exercise', () {
    test('built-in exercises have all categories', () {
      final warmup = allExercises.where((e) => e.category == WorkoutCategory.warmUp);
      final main_ = allExercises.where((e) => e.category == WorkoutCategory.mainExercise);
      final cooldown = allExercises.where((e) => e.category == WorkoutCategory.coolDown);
      expect(warmup.length, 8);
      expect(main_.length, 10);
      expect(cooldown.length, 8);
    });

    test('exercise has required fields', () {
      final ex = allExercises.first;
      expect(ex.name.isNotEmpty, true);
      expect(ex.bodyPart, isNotNull);
    });
  });
}
