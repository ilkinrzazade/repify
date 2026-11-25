import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/exercise_catalog.dart';
import 'package:my_app/exercise_library.dart';

void main() {
  test('every catalog exercise has pictures in the exercise library', () {
    for (final list in exerciseCatalog.values) {
      for (final exercise in list) {
        expect(exerciseDbId(exercise), isNotNull, reason: exercise);
        expect(exerciseImageUrls(exercise), hasLength(2), reason: exercise);
      }
    }
  });

  test('picture urls point to the start and end position', () {
    final urls = exerciseImageUrls('bench press');
    expect(urls.first, endsWith('/Barbell_Bench_Press_-_Medium_Grip/0.jpg'));
    expect(urls.last, endsWith('/Barbell_Bench_Press_-_Medium_Grip/1.jpg'));
    expect(exerciseImageUrls('My Custom Move'), isEmpty);
  });

  test('video tutorial link searches for the exercise', () {
    final uri = videoTutorialUri('Squat');
    expect(uri.host, 'www.youtube.com');
    expect(uri.queryParameters['search_query'], contains('Squat'));
  });

  test('reads exercise details from the dataset format', () {
    final details = ExerciseDetails.fromJson({
      'id': 'Plank',
      'level': 'beginner',
      'equipment': 'body only',
      'primaryMuscles': ['abdominals'],
      'secondaryMuscles': [],
      'instructions': ['Get into a prone position.', 'Hold your body straight.'],
    });
    expect(details.level, 'beginner');
    expect(details.primaryMuscles, ['abdominals']);
    expect(details.instructions, hasLength(2));
  });
}
