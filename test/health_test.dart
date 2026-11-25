import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/health_service.dart';

void main() {
  final morning = DateTime(2026, 11, 25, 9);
  final health = DailyHealth(
    steps: 6400,
    activeCalories: 312.6,
    heartRate: [
      HeartSample(morning, 70),
      HeartSample(morning.add(const Duration(minutes: 30)), 140),
      HeartSample(morning.add(const Duration(hours: 1)), 90),
    ],
  );

  test('heart rate statistics', () {
    expect(health.latestBpm, 90);
    expect(health.averageBpm, 100);
    expect(health.maxBpm, 140);
    expect(health.minBpm, 70);
  });

  test('no heart rate data gives no numbers', () {
    const empty = DailyHealth();
    expect(empty.hasHeartRate, isFalse);
    expect(empty.latestBpm, isNull);
    expect(empty.averageBpm, isNull);
  });

  test('summary for the AI coach', () {
    expect(health.toCoachJson(), {
      'steps': 6400,
      'activeCalories': 313,
      'heartRateLatest': 90,
      'heartRateAvg': 100,
      'heartRateMax': 140,
    });
    expect(const DailyHealth().toCoachJson().containsKey('heartRateAvg'), isFalse);
  });

  test('ring progress stays between 0 and 1', () {
    expect(ringProgress(4000, stepGoal), 0.5);
    expect(ringProgress(20000, stepGoal), 1);
    expect(ringProgress(0, stepGoal), 0);
    expect(ringProgress(10, 0), 0);
  });

  test('calorie estimate: 5 MET x 75 kg x 1 hour', () {
    expect(estimateWorkoutCalories(const Duration(hours: 1)), 375);
    expect(estimateWorkoutCalories(const Duration(minutes: 30), bodyWeightKg: 80), 200);
  });
}
