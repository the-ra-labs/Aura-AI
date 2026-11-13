import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import '../services/voice_service.dart';
import 'ai_orb.dart';
import 'buttons.dart';
import 'glass_container.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.streaming = false,
    this.canRegenerate = false,
    this.animate = false,
    this.onRegenerate,
  });
  final ChatMessage message;
  final bool streaming, canRegenerate, animate;
  final VoidCallback? onRegenerate;

  void _copy(BuildContext c) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
        content: Text('Copied'), duration: Duration(seconds: 1)));
  }

  Widget _attachments() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in message.attachments)
            a.isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(a.bytes!, width: 160, fit: BoxFit.cover),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.description_rounded, size: 16),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ]),
                  ),
        ]),
      );

  Widget _user(BuildContext context) {
    final maxW = math.min(600.0, MediaQuery.sizeOf(context).width * 0.78);
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () => _copy(context),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxW),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppColors.brand,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.violet.withOpacity(0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.attachments.isNotEmpty) _attachments(),
              if (message.text.isNotEmpty)
                Text(message.text,
                    style: const TextStyle(
                        fontSize: 15.5, height: 1.45, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ai(BuildContext context) {
    final sheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(fontSize: 15.5, height: 1.55),
      a: const TextStyle(color: AppColors.cyan),
      h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      h2: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      h3: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      strong: const TextStyle(fontWeight: FontWeight.w800),
      code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          color: AppColors.gold,
          backgroundColor: Colors.white.withOpacity(0.08)),
      codeblockPadding: const EdgeInsets.all(14),
      codeblockDecoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
            left: BorderSide(color: AppColors.violet.withOpacity(0.8), width: 3)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 2, right: 10), child: MiniOrb(size: 32)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  radius: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: message.text.isEmpty
                      ? const TypingDots()
                      : MarkdownBody(
                          data: message.text, selectable: true, styleSheet: sheet),
                ),
                if (!streaming && message.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(children: [
                      GlassIconButton(
                          icon: Icons.copy_rounded,
                          size: 34,
                          tooltip: 'Copy',
                          onTap: () => _copy(context)),
                      const SizedBox(width: 8),
                      GlassIconButton(
                          icon: Icons.volume_up_rounded,
                          size: 34,
                          tooltip: 'Read aloud',
                          onTap: () => VoiceService.instance.speak(message.text)),
                      if (canRegenerate) ...[
                        const SizedBox(width: 8),
                        GlassIconButton(
                            icon: Icons.refresh_rounded,
                            size: 34,
                            tooltip: 'Regenerate',
                            onTap: onRegenerate),
                      ],
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = message.isUser ? _user(context) : _ai(context);
    if (!animate) return w;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
      ),
      child: w,
    );
  }
}