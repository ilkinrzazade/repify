import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/login_screen.dart';

void main() {
  testWidgets('Login shows a warning when the fields are empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Please fill in both fields'), findsOneWidget);
    expect(find.text('Recent workouts'), findsNothing);
  });

  testWidgets('Login opens Home when both fields are filled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'ilkin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please fill in both fields'), findsNothing);
    expect(find.text('Recent workouts'), findsOneWidget);
  });
}
