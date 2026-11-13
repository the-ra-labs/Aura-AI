import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../core/theme/app_colors.dart';
import '../models/chat_session.dart';
import '../widgets/ai_orb.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.chat, required this.userName});
  final ChatController chat;
  final String userName;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _scroll = ScrollController();

  static const _cards = [
    (Icons.auto_awesome_rounded, 'Brainstorm', 'Ideas, naam, plans',
        'Give me 5 creative app ideas', [AppColors.violet, AppColors.purple]),
    (Icons.edit_note_rounded, 'Write', 'Emails, reports, posts',
        'Write a professional email asking for a deadline extension',
        [AppColors.cyan, AppColors.violet]),
    (Icons.code_rounded, 'Code', 'Likho, samjho, debug karo',
        'Explain Flutter state management with an example',
        [AppColors.gold, AppColors.pink]),
    (Icons.school_rounded, 'Learn', 'Koi bhi topic aasan karo',
        'Explain how operating system scheduling works like I am a beginner',
        [AppColors.pink, AppColors.purple]),
  ];

  @override
  void initState() {
    super.initState();
    widget.chat.addListener(_toBottom);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    widget.chat.removeListener(_toBottom);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chat;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final s = c.current;
        return Column(children: [
          Expanded(child: s == null ? _welcome(c) : _list(c, s)),
          if (c.error != null) _errorBanner(c),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ChatInputBar(
                  onSend: (t, f) => c.send(t, attachments: f),
                  onStop: c.stop,
                  generating: c.isGenerating),
            ),
          ),
        ]);
      },
    );
  }

  Widget _errorBanner(ChatController c) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassContainer(
              radius: 18,
              tint: AppColors.pink,
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.pink),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(c.error!, maxLines: 4, overflow: TextOverflow.ellipsis)),
                TextButton(onPressed: c.regenerate, child: const Text('Retry')),
              ]),
            ),
          ),
        ),
      );

  Widget _list(ChatController c, ChatSession s) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: s.messages.length,
          itemBuilder: (_, i) {
            final m = s.messages[i];
            final last = i == s.messages.length - 1;
            return MessageBubble(
              message: m,
              animate: last,
              streaming: last && !m.isUser && c.isGenerating,
              canRegenerate: last && !m.isUser && !c.isGenerating,
              onRegenerate: c.regenerate,
            );
          },
        ),
      ),
    );
  }

  String get _greet {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
  }

  Widget _welcome(ChatController c) {
    final first = widget.userName.trim().split(' ').first;
    final p = c.projectOf(c.draftProjectId);
    return LayoutBuilder(builder: (context, b) {
      final cols = b.maxWidth > 900 ? 4 : 2;
      const gap = 12.0;
      final contentW = (b.maxWidth - 40).clamp(0.0, 900.0);
      final cardW = (contentW - gap * (cols - 1)) / cols;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(children: [
              const SizedBox(height: 8),
              AiOrb(size: b.maxWidth < 600 ? 230 : 300),
              const SizedBox(height: 4),
              Text('$_greet,',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                        colors: [AppColors.cyan, AppColors.violet, AppColors.pink])
                    .createShader(r),
                child: Text(first.isEmpty ? 'there' : first,
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(height: 4),
              const Text('What shall we explore today?',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              if (p != null) ...[
                const SizedBox(height: 12),
                Chip(
                    avatar: const Icon(Icons.folder_rounded, size: 16),
                    label: Text('Project: ${p.name}')),
              ],
              const SizedBox(height: 28),
              Wrap(spacing: gap, runSpacing: gap, children: [
                for (var i = 0; i < _cards.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 450 + i * 90),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                          offset: Offset(0, 26 * (1 - v)), child: child),
                    ),
                    child: SizedBox(width: cardW, child: _card(c, _cards[i])),
                  ),
              ]),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      );
    });
  }

  Widget _card(ChatController c,
      (IconData, String, String, String, List<Color>) k) {
    return GlassContainer(
      onTap: () => c.send(k.$4),
      glow: k.$5.first,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: k.$5),
                boxShadow: [
                  BoxShadow(
                      color: k.$5.first.withOpacity(0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(k.$1, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.north_east_rounded,
                size: 18, color: AppColors.textSecondary),
          ]),
          const SizedBox(height: 14),
          Text(k.$2,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 3),
          Text(k.$3,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ]),
      ),
    );
  }
}