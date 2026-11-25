import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_store.dart';

// Daily goals shown as rings on the Home screen.
const int stepGoal = 8000;
const int calorieGoal = 500;
const int trainingGoalMinutes = 45;

/// Estimated calories of a strength workout: MET x body weight x hours.
/// Strength training is about 5 MET. Body weight is not known yet: 75 kg.
double estimateWorkoutCalories(Duration duration, {double bodyWeightKg = 75, double met = 5}) {
  return met * bodyWeightKg * duration.inSeconds / 3600;
}

/// 0..1 value for a progress ring.
double ringProgress(num value, num goal) => goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0).toDouble();

class HeartSample {
  final DateTime time;
  final double bpm;

  const HeartSample(this.time, this.bpm);
}

/// Today's numbers from Health Connect (phone + watch).
class DailyHealth {
  final int steps;
  final double activeCalories;
  final List<HeartSample> heartRate; // sorted by time

  const DailyHealth({this.steps = 0, this.activeCalories = 0, this.heartRate = const []});

  bool get hasHeartRate => heartRate.isNotEmpty;
  double? get latestBpm => heartRate.isEmpty ? null : heartRate.last.bpm;
  double? get averageBpm => heartRate.isEmpty
      ? null
      : heartRate.fold<double>(0, (s, h) => s + h.bpm) / heartRate.length;
  double? get maxBpm => heartRate.isEmpty ? null : heartRate.map((h) => h.bpm).reduce(math.max);
  double? get minBpm => heartRate.isEmpty ? null : heartRate.map((h) => h.bpm).reduce(math.min);

  /// Summary sent to the AI coach together with a chat message.
  Map<String, num> toCoachJson() => {
        'steps': steps,
        'activeCalories': activeCalories.round(),
        if (latestBpm != null) 'heartRateLatest': latestBpm!.round(),
        if (averageBpm != null) 'heartRateAvg': averageBpm!.round(),
        if (maxBpm != null) 'heartRateMax': maxBpm!.round(),
      };
}

enum HealthStatus { unknown, unavailable, needsUpdate, disconnected, connected }

/// Google Health Connect: reads steps, heart rate and active calories,
/// and saves finished workouts as exercise sessions.
class HealthService extends ChangeNotifier {
  HealthService._();
  static final HealthService instance = HealthService._();

  static const String _prefsKey = 'health_connect_enabled';

  static const List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  // Write access is used to save workouts (and demo data on the emulator).
  static const List<HealthDataAccess> permissions = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];

  final Health _health = Health();

  HealthStatus status = HealthStatus.unknown;
  DailyHealth today = const DailyHealth();
  bool isLoading = false;
  String? error;
  DateTime? lastUpdated;

  bool get isConnected => status == HealthStatus.connected;

  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      status = HealthStatus.unavailable;
      notifyListeners();
      return;
    }
    try {
      await _health.configure();
      final sdk = await _health.getHealthConnectSdkStatus();
      if (sdk == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        status = HealthStatus.needsUpdate;
      } else if (sdk != HealthConnectSdkStatus.sdkAvailable) {
        status = HealthStatus.unavailable;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool(_prefsKey) ?? false;
        final granted =
            enabled && (await _health.hasPermissions(types, permissions: permissions) ?? false);
        status = granted ? HealthStatus.connected : HealthStatus.disconnected;
      }
    } catch (e) {
      status = HealthStatus.unavailable;
      error = 'Health Connect is not available: $e';
    }
    notifyListeners();
    if (isConnected) await refresh();
  }

  /// Shows the Health Connect permission screen.
  Future<bool> connect() async {
    try {
      if (status == HealthStatus.needsUpdate) {
        await _health.installHealthConnect();
        return false;
      }
      final requested = await _health.requestAuthorization(types, permissions: permissions);
      final granted = requested &&
          (await _health.hasPermissions(types, permissions: permissions) ?? requested);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, granted);
      status = granted ? HealthStatus.connected : HealthStatus.disconnected;
      error = granted ? null : 'Permissions were not granted. Tap "Allow all" in Health Connect.';
      notifyListeners();
      if (granted) await refresh();
      return granted;
    } catch (e) {
      error = 'Could not connect to Health Connect: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _health.revokePermissions();
    } catch (_) {
      // Not supported everywhere: the switch in the app is enough.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
    status = HealthStatus.disconnected;
    today = const DailyHealth();
    notifyListeners();
  }

  static double _number(HealthValue value) =>
      value is NumericHealthValue ? value.numericValue.toDouble() : 0;

  /// Reads today's steps, heart rate and active calories.
  /// Each value is read separately, so one problem does not hide the rest.
  Future<void> refresh() async {
    if (!isConnected || isLoading) return;
    isLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final problems = <String>[];

    Future<List<HealthDataPoint>> read(HealthDataType type) async {
      try {
        return _health.removeDuplicates(await _health.getHealthDataFromTypes(
          types: [type],
          startTime: midnight,
          endTime: now,
        ));
      } catch (e) {
        problems.add('${type.name}: $e');
        return [];
      }
    }

    var steps = 0;
    try {
      steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (e) {
      problems.add('steps total: $e');
    }
    if (steps == 0) {
      // Fallback: add up the single step records.
      final stepPoints = await read(HealthDataType.STEPS);
      steps = stepPoints.fold<double>(0, (s, p) => s + _number(p.value)).round();
    }

    final heart = (await read(HealthDataType.HEART_RATE))
        .map((p) => HeartSample(p.dateFrom, _number(p.value)))
        .where((h) => h.bpm > 0)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final calories = (await read(HealthDataType.ACTIVE_ENERGY_BURNED))
        .fold<double>(0, (s, p) => s + _number(p.value));

    today = DailyHealth(steps: steps, activeCalories: calories, heartRate: heart);
    lastUpdated = now;
    error = problems.isEmpty ? null : 'Could not read: ${problems.join(' | ')}';
    debugPrint('Health Connect today: $steps steps, ${calories.round()} kcal, '
        '${heart.length} heart samples. Problems: $problems');
    isLoading = false;
    notifyListeners();
  }

  /// Saves a finished workout to Health Connect as a strength session.
  Future<bool> saveWorkout(Workout workout) async {
    if (!isConnected || workout.duration.inMinutes < 1) return false;
    final now = DateTime.now();
    var start = workout.date;
    var end = start.add(workout.duration);
    if (end.isAfter(now)) {
      // Health Connect does not accept sessions in the future.
      end = now;
      start = now.subtract(workout.duration);
    }
    try {
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: end,
        title: workout.name,
      );
    } catch (_) {
      return false;
    }
  }

  /// The emulator has no watch or step sensor, so for the demo we write some
  /// realistic sample data for today into Health Connect and read it back.
  Future<bool> addDemoData() async {
    if (!isConnected) return false;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    // The last 3 hours, but never before midnight: the rings show "today".
    var start = now.subtract(const Duration(hours: 3));
    if (start.isBefore(midnight)) start = midnight;
    final span = now.subtract(const Duration(seconds: 5)).difference(start);
    if (span.inSeconds < 30) {
      error = 'A new day just started. Try again in a minute.';
      notifyListeners();
      return false;
    }
    Duration part(double fraction) =>
        Duration(milliseconds: (span.inMilliseconds * fraction).round());

    final failed = <String>[];
    Future<void> write(String label, double value, HealthDataType type, DateTime from, DateTime to) async {
      try {
        final ok = await _health.writeHealthData(
          value: value,
          type: type,
          startTime: from,
          endTime: to,
        );
        if (!ok) failed.add('$label (not saved)');
      } catch (e) {
        failed.add('$label: $e');
      }
    }

    await write('steps', 5200, HealthDataType.STEPS, start, start.add(part(0.9)));
    await write('calories', 320, HealthDataType.ACTIVE_ENERGY_BURNED, start, start.add(part(0.9)));
    const bpm = [72, 78, 95, 118, 132, 142, 138, 126, 110, 96, 84, 76];
    for (var i = 0; i < bpm.length; i++) {
      final t = start.add(part(i / bpm.length));
      await write('heart rate', bpm[i].toDouble(), HealthDataType.HEART_RATE, t,
          t.add(part(0.5 / bpm.length)));
    }
    debugPrint('Health Connect demo data from $start to $now. Failed: $failed');

    await refresh();
    if (failed.isNotEmpty) {
      error = 'Could not write: ${failed.toSet().join(' | ')}';
      notifyListeners();
      return false;
    }
    if (today.steps == 0 && !today.hasHeartRate) {
      error = 'Data was written but could not be read back. '
          'Open Settings → Health Connect → App permissions → Repify and check "Allow all".';
      notifyListeners();
      return false;
    }
    return true;
  }
}
