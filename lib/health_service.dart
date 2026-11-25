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
  Future<void> refresh() async {
    if (!isConnected || isLoading) return;
    isLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
      final points = _health.removeDuplicates(await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE, HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      ));
      final heart = points
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .map((p) => HeartSample(p.dateFrom, _number(p.value)))
          .where((h) => h.bpm > 0)
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      final calories = points
          .where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED)
          .fold<double>(0, (s, p) => s + _number(p.value));
      today = DailyHealth(steps: steps, activeCalories: calories, heartRate: heart);
      lastUpdated = now;
      error = null;
    } catch (e) {
      error = 'Could not read Health Connect data.';
    }
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
    final start = now.subtract(const Duration(hours: 3));
    try {
      var ok = await _health.writeHealthData(
        value: 5200,
        type: HealthDataType.STEPS,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      );
      ok &= await _health.writeHealthData(
        value: 320,
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      );
      const bpm = [72, 78, 95, 118, 132, 142, 138, 126, 110, 96, 84, 76];
      for (var i = 0; i < bpm.length; i++) {
        final t = start.add(Duration(minutes: i * 12));
        ok &= await _health.writeHealthData(
          value: bpm[i].toDouble(),
          type: HealthDataType.HEART_RATE,
          startTime: t,
          endTime: t.add(const Duration(minutes: 1)),
        );
      }
      await refresh();
      return ok;
    } catch (e) {
      error = 'Could not write demo data: $e';
      notifyListeners();
      return false;
    }
  }
}
