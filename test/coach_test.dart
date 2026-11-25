import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/coach.dart';
import 'package:my_app/workout_store.dart';

Exercise ex(String name, String reps, String weight) =>
    Exercise(name: name, sets: '4', reps: reps, weight: weight);

void main() {
  group('Progressive overload', () {
    test('no history means no suggestion', () {
      expect(suggestNext(null), isNull);
      expect(suggestNext(ex('Plank', '1', '0')), isNull);
    });

    test('8+ reps adds 2.5 kg on upper body lifts', () {
      final s = suggestNext(ex('Bench Press', '8', '82.5'))!;
      expect(s.weight, 85);
      expect(s.reps, 8);
    });

    test('big leg lifts go up by 5 kg', () {
      expect(suggestNext(ex('Squat', '8', '100'))!.weight, 105);
      expect(suggestNext(ex('Deadlift', '10', '120'))!.weight, 125);
    });

    test('fewer than 8 reps keeps the weight and adds one rep', () {
      final s = suggestNext(ex('Bench Press', '6', '90'))!;
      expect(s.weight, 90);
      expect(s.reps, 7);
    });
  });

  group('Muscle recovery', () {
    final now = DateTime(2026, 11, 25, 20);

    test('counts days since each muscle group was trained', () {
      final statuses = muscleRecovery([
        Workout(name: 'Push', date: DateTime(2026, 11, 22, 18), exercises: [ex('Bench Press', '8', '80')]),
        Workout(name: 'Legs', date: DateTime(2026, 11, 25, 9), exercises: [ex('Squat', '8', '100')]),
      ], now: now);
      final byGroup = {for (final s in statuses) s.group: s};

      expect(byGroup['Chest']!.daysSince, 3);
      expect(byGroup['Chest']!.ready, isTrue);
      expect(byGroup['Legs']!.daysSince, 0);
      expect(byGroup['Legs']!.ready, isFalse);
      expect(byGroup['Back']!.trained, isFalse);
    });

    test('suggests the recovered group that rested the longest', () {
      const statuses = [
        MuscleStatus('Chest', 5),
        MuscleStatus('Back', 1),
        MuscleStatus('Legs', 3),
        MuscleStatus('Core', null),
      ];
      expect(suggestedFocus(statuses), 'Chest');
    });

    test('falls back to a never-trained group, then to a rest day', () {
      expect(
        suggestedFocus(const [MuscleStatus('Chest', 0), MuscleStatus('Core', null)]),
        'Core',
      );
      expect(
        suggestedFocus(const [MuscleStatus('Chest', 0), MuscleStatus('Legs', 1)]),
        isNull,
      );
    });

    test('readable labels', () {
      expect(const MuscleStatus('Chest', null).label, 'never');
      expect(const MuscleStatus('Chest', 0).label, 'today');
      expect(const MuscleStatus('Chest', 1).label, '1 day ago');
      expect(const MuscleStatus('Chest', 4).label, '4 days ago');
    });
  });
}
