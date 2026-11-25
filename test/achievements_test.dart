import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/achievements.dart';
import 'package:my_app/workout_store.dart';

// Wednesday, 25 Nov 2026.
final now = DateTime(2026, 11, 25, 18);

Workout session(DateTime date, {String weight = '50', int minutes = 45}) => Workout(
      name: 'Test',
      date: date,
      duration: Duration(minutes: minutes),
      exercises: [Exercise(name: 'Bench Press', sets: '4', reps: '10', weight: weight)],
    );

void main() {
  group('Weeks', () {
    test('mondayOf finds the start of the week', () {
      expect(mondayOf(now), DateTime(2026, 11, 23));
      expect(mondayOf(DateTime(2026, 11, 23)), DateTime(2026, 11, 23));
      expect(mondayOf(DateTime(2026, 11, 29)), DateTime(2026, 11, 23));
    });

    test('this week has one bucket per day with the right totals', () {
      final buckets = thisWeekBuckets([
        session(DateTime(2026, 11, 23, 10)), // Mon: 4 x 10 x 50 = 2000
        session(DateTime(2026, 11, 25, 9), minutes: 30), // Wed
        session(DateTime(2026, 11, 16)), // last week, ignored
      ], now: now);
      expect(buckets.length, 7);
      expect(buckets.first.label, 'Mon');
      expect(buckets[0].volume, 2000);
      expect(buckets[2].minutes, 30);
      expect(buckets[1].workouts, 0);
      expect(buckets.fold<int>(0, (s, b) => s + b.workouts), 2);
    });

    test('recent weeks are oldest first and end with this week', () {
      final buckets = recentWeekBuckets([
        session(DateTime(2026, 11, 24)),
        session(DateTime(2026, 10, 27)),
      ], now: now);
      expect(buckets.length, 5);
      expect(buckets.first.workouts, 1); // week of 26 Oct
      expect(buckets.last.workouts, 1); // this week
    });
  });

  group('Streaks', () {
    test('week streak counts weeks in a row', () {
      final workouts = [
        session(DateTime(2026, 11, 24)),
        session(DateTime(2026, 11, 17)),
        session(DateTime(2026, 11, 10)),
        session(DateTime(2026, 10, 20)), // gap before this one
      ];
      expect(weekStreak(workouts, now: now), 3);
    });

    test('an empty current week does not break the streak yet', () {
      final workouts = [session(DateTime(2026, 11, 17)), session(DateTime(2026, 11, 10))];
      expect(weekStreak(workouts, now: now), 2);
    });

    test('day streak counts days in a row', () {
      final workouts = [
        session(DateTime(2026, 11, 25)),
        session(DateTime(2026, 11, 24)),
        session(DateTime(2026, 11, 22)),
      ];
      expect(dayStreak(workouts, now: now), 2);
      expect(dayStreak([], now: now), 0);
    });
  });

  group('Achievements', () {
    test('nothing is unlocked without workouts', () {
      final list = achievements([], now: now);
      expect(list.where((a) => a.unlocked), isEmpty);
    });

    test('first workout and volume badges unlock', () {
      final list = achievements([session(DateTime(2026, 11, 24), weight: '300')], now: now);
      // 4 x 10 x 300 = 12 000 kg
      expect(list.firstWhere((a) => a.title == 'First workout').unlocked, isTrue);
      expect(list.firstWhere((a) => a.badge == '10K').unlocked, isTrue);
      final ten = list.firstWhere((a) => a.title == '10 workouts');
      expect(ten.unlocked, isFalse);
      expect(ten.progress, closeTo(0.1, 1e-9));
    });

    test('sample data unlocks the main badges', () {
      final list = achievements(sampleWorkouts(), now: DateTime.now());
      expect(list.firstWhere((a) => a.title == '10 workouts').unlocked, isTrue);
      expect(list.firstWhere((a) => a.title == 'Record breaker').unlocked, isTrue);
    });
  });
}
