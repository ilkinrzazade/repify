import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/api_client.dart';
import 'package:my_app/login_screen.dart';

/// Fake login so widget tests do not need a running server.
Future<void> fakeLoginOk(String email, String password, {required bool createAccount}) async {}

Future<void> fakeLoginWrongPassword(
  String email,
  String password, {
  required bool createAccount,
}) async {
  throw ApiException('Wrong email or password.');
}

Future<void> tapLogIn(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Log In'));
  await tester.tap(find.text('Log In'));
}

void main() {
  testWidgets('Login shows a warning when the fields are empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(authenticate: fakeLoginOk)),
    );

    await tapLogIn(tester);
    await tester.pump();

    expect(find.text('Please fill in both fields'), findsOneWidget);
    expect(find.text('Start new workout'), findsNothing);
  });

  testWidgets('Login opens Home when the server accepts the account', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(authenticate: fakeLoginOk)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'ilkin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tapLogIn(tester);
    await tester.pumpAndSettle();

    expect(find.text('Start new workout'), findsOneWidget);
  });

  testWidgets('Login shows the server error and stays on the login screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(authenticate: fakeLoginWrongPassword)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'ilkin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tapLogIn(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.text('Start new workout'), findsNothing);
  });

  testWidgets('Switches to the create account form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(authenticate: fakeLoginOk)),
    );

    await tester.ensureVisible(find.text('No account? Create one'));
    await tester.tap(find.text('No account? Create one'));
    await tester.pump();

    expect(find.text('Create account'), findsWidgets);
  });
}
