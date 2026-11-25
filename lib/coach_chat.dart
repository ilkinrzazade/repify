import 'package:flutter/foundation.dart';

import 'api_client.dart';

enum CoachRole { user, assistant }

class CoachMessage {
  final CoachRole role;
  final String text;
  final DateTime time;

  /// Shown in the chat but never sent to the AI (greeting, errors).
  final bool localOnly;
  final bool isError;

  CoachMessage(
    this.role,
    this.text, {
    DateTime? time,
    this.localOnly = false,
    this.isError = false,
  }) : time = time ?? DateTime.now();

  bool get fromUser => role == CoachRole.user;
}

/// Sends the chat history to the server and returns the coach's answer.
typedef AskCoachFn = Future<String> Function(
  List<Map<String, String>> history,
  Map<String, num>? health,
);

/// Gemini sometimes answers with Markdown. The chat shows plain text,
/// so bold markers and headings are removed and "*" bullets become "•".
String cleanCoachText(String text) {
  final lines = text.replaceAll('**', '').replaceAll('__', '').split('\n').map((line) {
    var l = line.trimRight();
    final trimmed = l.trimLeft();
    if (trimmed.startsWith('#')) {
      l = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
    } else if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
      l = '• ${trimmed.substring(2)}';
    }
    return l;
  });
  return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// The AI Coach conversation. Kept in memory, so it survives tab switches.
class CoachConversation extends ChangeNotifier {
  CoachConversation({AskCoachFn? ask}) : _ask = ask ?? _askServer {
    _addGreeting();
  }

  static final CoachConversation instance = CoachConversation();

  /// Set by the Health Connect integration: today's steps, heart rate...
  static Map<String, num>? Function()? healthProvider;

  static const int maxHistory = 12;

  static const String greeting =
      "Hi! I'm your Repify coach 💪 I can see your workouts, personal records "
      'and recovery. Ask me what to train today, how to break a plateau '
      'or how many calories you burned.';

  static const List<String> quickQuestions = [
    'What should I train today?',
    'Am I making progress?',
    'How many calories did I burn this week?',
    'Give me a 30-minute leg workout',
    'How do I break a bench press plateau?',
  ];

  final AskCoachFn _ask;
  final List<CoachMessage> messages = [];
  bool isThinking = false;

  static Future<String> _askServer(
    List<Map<String, String>> history,
    Map<String, num>? health,
  ) {
    return ApiClient.instance.coachChat(history, health: health);
  }

  void _addGreeting() {
    messages.add(CoachMessage(CoachRole.assistant, greeting, localOnly: true));
  }

  /// Messages the AI should see: no greeting, no errors, only the last few.
  List<Map<String, String>> historyForApi() {
    final real = messages.where((m) => !m.localOnly && !m.isError).toList();
    final recent = real.length > maxHistory ? real.sublist(real.length - maxHistory) : real;
    return recent
        .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'text': m.text})
        .toList();
  }

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || isThinking) return;
    messages.add(CoachMessage(CoachRole.user, question));
    await _requestAnswer();
  }

  /// Asks again after an error, using the same question.
  Future<void> retry() async {
    if (isThinking) return;
    messages.removeWhere((m) => m.isError);
    if (messages.isEmpty || !messages.last.fromUser) return;
    await _requestAnswer();
  }

  Future<void> _requestAnswer() async {
    isThinking = true;
    notifyListeners();
    try {
      final health = healthProvider?.call();
      final reply = await _ask(historyForApi(), health);
      messages.add(CoachMessage(CoachRole.assistant, cleanCoachText(reply)));
    } catch (e) {
      final message = e is ApiException ? e.message : 'Something went wrong. Please try again.';
      messages.add(CoachMessage(CoachRole.assistant, message, localOnly: true, isError: true));
    } finally {
      isThinking = false;
      notifyListeners();
    }
  }

  void clear() {
    if (isThinking) return;
    messages.clear();
    _addGreeting();
    notifyListeners();
  }
}
