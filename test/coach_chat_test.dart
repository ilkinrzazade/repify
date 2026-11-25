import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/api_client.dart';
import 'package:my_app/coach_chat.dart';
import 'package:my_app/coach_chat_screen.dart';

void main() {
  group('Coach conversation', () {
    test('starts with a greeting that is not sent to the AI', () {
      final chat = CoachConversation(ask: (history, health) async => 'ok');
      expect(chat.messages.length, 1);
      expect(chat.historyForApi(), isEmpty);
    });

    test('sends the question and adds the answer', () async {
      List<Map<String, String>>? sent;
      final chat = CoachConversation(ask: (history, health) async {
        sent = history;
        return '**Legs** today.';
      });

      await chat.send('What should I train?');

      expect(sent, [
        {'role': 'user', 'text': 'What should I train?'},
      ]);
      expect(chat.messages.last.text, 'Legs today.');
      expect(chat.isThinking, isFalse);
      expect(chat.historyForApi().length, 2);
    });

    test('an error can be retried with the same question', () async {
      var calls = 0;
      final chat = CoachConversation(ask: (history, health) async {
        calls++;
        if (calls == 1) throw ApiException('The AI service is busy right now.');
        return 'Back online!';
      });

      await chat.send('Hi');
      expect(chat.messages.last.isError, isTrue);
      expect(chat.historyForApi().length, 1); // the error is not sent

      await chat.retry();
      expect(calls, 2);
      expect(chat.messages.where((m) => m.isError), isEmpty);
      expect(chat.messages.last.text, 'Back online!');
    });

    test('empty messages are ignored', () async {
      var calls = 0;
      final chat = CoachConversation(ask: (history, health) async {
        calls++;
        return 'x';
      });
      await chat.send('   ');
      expect(calls, 0);
    });

    test('only the last messages are sent', () async {
      final chat = CoachConversation(ask: (history, health) async => 'answer');
      for (var i = 0; i < 10; i++) {
        await chat.send('question $i');
      }
      final history = chat.historyForApi();
      expect(history.length, CoachConversation.maxHistory);
      expect(history.last['text'], 'answer');
    });
  });

  test('Markdown from the AI becomes plain text', () {
    expect(
      cleanCoachText('## Plan\n* **Squat** 4x8\n- Leg press'),
      'Plan\n• Squat 4x8\n• Leg press',
    );
  });

  testWidgets('Quick question shows the coach answer', (tester) async {
    final chat = CoachConversation(ask: (history, health) async => 'Train legs today.');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CoachChatScreen(conversation: chat)),
    ));

    expect(find.text('AI Coach'), findsOneWidget);
    await tester.tap(find.text('What should I train today?'));
    await tester.pumpAndSettle();

    expect(find.text('Train legs today.'), findsOneWidget);
  });
}
