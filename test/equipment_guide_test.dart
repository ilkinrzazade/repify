import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/api_client.dart';
import 'package:my_app/equipment_guide.dart';
import 'package:my_app/exercise_catalog.dart';

void main() {
  test('every exercise in the equipment guide exists in the exercise catalog', () {
    for (final equipment in equipmentGuide) {
      for (final exercise in equipment.exercises) {
        expect(muscleGroupOf(exercise), isNotNull, reason: '$exercise (${equipment.name})');
      }
    }
  });

  test('every catalog exercise has a technique tip', () {
    for (final list in exerciseCatalog.values) {
      for (final exercise in list) {
        expect(tipFor(exercise), isNotNull, reason: exercise);
      }
    }
  });

  test('matches equipment names returned by the AI', () {
    expect(findEquipment('dumbbell')?.name, 'Dumbbells');
    expect(findEquipment('Cable Machine')?.name, 'Cable Machine');
    expect(findEquipment('Spaceship'), isNull);
  });

  test('reads the AI answer from the server', () {
    final result = EquipmentResult.fromJson({
      'equipment': 'Cable Machine',
      'confidence': 0.93,
      'muscles': ['Chest', 'Arms'],
      'exercises': ['Cable Crossover', 'Triceps Pushdown'],
      'tip': 'Keep your elbows slightly bent.',
    });
    expect(result.isUnknown, isFalse);
    expect(result.confidence, 0.93);
    expect(result.exercises, hasLength(2));
    expect(EquipmentResult.fromJson({'equipment': 'Unknown'}).isUnknown, isTrue);
  });
}
