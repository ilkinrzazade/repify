import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'coach_chat.dart';

/// Chat with the AI coach. The server gives the AI a summary of the user's
/// workouts, so the answers are personal.
class CoachChatScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final CoachConversation? conversation;

  const CoachChatScreen({super.key, this.onOpenMenu, this.conversation});

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  late final CoachConversation chat = widget.conversation ?? CoachConversation.instance;
  int _shownMessages = 0;

  @override
  void initState() {
    super.initState();
    chat.addListener(_onChatChanged);
    _shownMessages = chat.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(animate: false));
  }

  @override
  void dispose() {
    chat.removeListener(_onChatChanged);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (chat.messages.length != _shownMessages || chat.isThinking) {
      _shownMessages = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd({bool animate = true}) {
    if (!scroll.hasClients) return;
    final end = scroll.position.maxScrollExtent;
    if (animate) {
      scroll.animateTo(end, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      scroll.jumpTo(end);
    }
  }

  void _send([String? text]) {
    final message = text ?? input.text;
    if (message.trim().isEmpty || chat.isThinking) return;
    input.clear();
    chat.send(message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final items = chat.messages;
        return Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: items.length + (chat.isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= items.length) return const _TypingBubble();
                  final message = items[index];
                  return _MessageBubble(
                    message: message,
                    onRetry: message.isError ? chat.retry : null,
                  );
                },
              ),
            ),
            _buildQuickQuestions(),
            _buildInput(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          if (widget.onOpenMenu != null) ...[
            IconButton(
              onPressed: widget.onOpenMenu,
              icon: const Icon(Icons.menu, color: AppColors.text),
            ),
            const SizedBox(width: 4),
          ],
          const _CoachAvatar(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Online · knows your workouts',
                  style: TextStyle(color: AppColors.lime, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: chat.isThinking ? null : chat.clear,
            icon: const Icon(Icons.refresh, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: CoachConversation.quickQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = CoachConversation.quickQuestions[index];
          return Material(
            color: AppColors.lime.withAlpha(18),
            shape: StadiumBorder(side: BorderSide(color: AppColors.lime.withAlpha(110))),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: chat.isThinking ? null : () => _send(question),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  question,
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Ask your AI coach...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.lime),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            height: 54,
            child: ElevatedButton(
              onPressed: chat.isThinking ? null : _send,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.onLime,
                disabledBackgroundColor: AppColors.cardHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lime, AppColors.limeDark],
              ),
              boxShadow: [BoxShadow(color: AppColors.lime.withAlpha(90), blurRadius: 14)],
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.onLime),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF3DDC84),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class _MessageBubble extends StatelessWidget {
  final CoachMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    final error = message.isError;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mine ? AppColors.lime : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(mine ? 20 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 20),
                ),
                border: mine
                    ? null
                    : Border.all(
                        color: error ? AppColors.danger : AppColors.lime.withAlpha(60),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    ),
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: mine ? AppColors.onLime : AppColors.text,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (onRetry != null)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try again'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _clock(message.time),
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Three bouncing dots while the coach is "typing".
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: AppColors.lime.withAlpha(60)),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Opacity(
                  opacity: 0.3 + 0.7 * _wave(controller.value, i),
                  child: Transform.translate(
                    offset: Offset(0, -4 * _wave(controller.value, i)),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 0..1..0 pulse, each dot a little later than the previous one.
  double _wave(double t, int index) {
    final phase = (t - index * 0.2) % 1.0;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  }
}
