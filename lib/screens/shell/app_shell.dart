import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/sidebar.dart';
import '../chat_view.dart';
import '../settings_screen.dart';
import '../voice_mode_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth, required this.settings});
  final AuthController auth;
  final SettingsController settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late final ChatController _chat =
      ChatController(widget.settings, widget.auth.user!.id);
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  bool _collapsed = false;

  @override
  void dispose() {
    _chat.dispose();
    _ac.dispose();
    super.dispose();
  }

  void _openDrawer() => _ac.forward();
  void _closeDrawer() => _ac.reverse();

  void _openSettings() {
    if (Responsive.of(context) != ScreenType.desktop) _closeDrawer();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SettingsScreen(
            auth: widget.auth, settings: widget.settings, chat: _chat)));
  }

  Widget _sidebar({required VoidCallback onAction, VoidCallback? onClose}) =>
      Sidebar(
        chat: _chat,
        auth: widget.auth,
        onAction: onAction,
        onSettings: _openSettings,
        onClose: onClose,
      );

  Widget _topBar(bool wide) => ListenableBuilder(
        listenable: _chat,
        builder: (context, _) {
          final s = _chat.current;
          final p = _chat.projectOf(s?.projectId ?? _chat.draftProjectId);
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: GlassContainer(
              radius: 26,
              blur: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(children: [
                GlassIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: 'Menu',
                  onTap: wide
                      ? () => setState(() => _collapsed = !_collapsed)
                      : _openDrawer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      s == null
                          ? ShaderMask(
                              shaderCallback: (r) => const LinearGradient(colors: [
                                AppColors.cyan,
                                AppColors.violet,
                                AppColors.pink
                              ]).createShader(r),
                              child: const Text('Aura',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            )
                          : Text(s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16.5, fontWeight: FontWeight.w700)),
                      if (p != null)
                        Row(children: [
                          const Icon(Icons.folder_rounded,
                              size: 12, color: AppColors.cyan),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.cyan)),
                          ),
                        ]),
                    ],
                  ),
                ),
                GlassIconButton(
                  icon: Icons.graphic_eq_rounded,
                  tooltip: 'Voice mode',
                  filled: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VoiceModeScreen(chat: _chat))),
                ),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: Icons.add_comment_rounded,
                  tooltip: 'New chat',
                  onTap: () => _chat.startNew(projectId: s?.projectId),
                ),
                if (s != null) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'export') {
                        Clipboard.setData(
                            ClipboardData(text: _chat.exportMarkdown(s)));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Chat Markdown ke taur par copy ho gayi')));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'export', child: Text('Copy chat as Markdown')),
                    ],
                    child: const GlassIconButton(icon: Icons.more_horiz_rounded),
                  ),
                ],
              ]),
            ),
          );
        },
      );

  void _end(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v > 300) {
      _ac.fling(velocity: 1);
    } else if (v < -300) {
      _ac.fling(velocity: -1);
    } else {
      _ac.fling(velocity: _ac.value > 0.5 ? 1 : -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.of(context) == ScreenType.desktop;
    final content = Column(children: [
      _topBar(wide),
      Expanded(
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (_, __) => ChatView(
            chat: _chat,
            userName: widget.settings.displayName.isNotEmpty
                ? widget.settings.displayName
                : widget.auth.user!.name,
          ),
        ),
      ),
    ]);
    return Scaffold(body: SafeArea(child: wide ? _wide(content) : _narrow(content)));
  }

  Widget _wide(Widget content) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: _collapsed ? 0 : 316,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 316,
                maxWidth: 316,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _sidebar(
                    onAction: () {},
                    onClose: () => setState(() => _collapsed = true),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );

  Widget _narrow(Widget content) {
    final w = math.min(330.0, MediaQuery.sizeOf(context).width * 0.86);
    return Stack(children: [
      Positioned.fill(child: content),
      // left edge se swipe karke sidebar kholo
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: 20,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) => _ac.value += d.delta.dx / w,
          onHorizontalDragEnd: _end,
        ),
      ),
      AnimatedBuilder(
        animation: _ac,
        builder: (_, __) => Stack(children: [
          if (_ac.value > 0)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDrawer,
                child: ColoredBox(color: Colors.black.withOpacity(0.6 * _ac.value)),
              ),
            ),
          Positioned(
            left: -(1 - _ac.value) * w,
            top: 0,
            bottom: 0,
            width: w,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) => _ac.value += d.delta.dx / w,
              onHorizontalDragEnd: _end,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _sidebar(onAction: _closeDrawer, onClose: _closeDrawer),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}