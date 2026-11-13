import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../core/theme/app_colors.dart';
import '../models/chat_session.dart';
import '../models/project.dart';
import 'ai_orb.dart';
import 'buttons.dart';
import 'dialogs.dart';
import 'glass_container.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.chat,
    required this.auth,
    required this.onAction,
    required this.onSettings,
    this.onClose,
  });
  final ChatController chat;
  final AuthController auth;
  final VoidCallback onAction;
  final VoidCallback onSettings;
  final VoidCallback? onClose;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _q = '';
  final _open = <String>{};
  ChatController get c => widget.chat;

  static const _pal = [AppColors.violet, AppColors.cyan, AppColors.gold, AppColors.pink];

  int _cmp(ChatSession a, ChatSession b) => b.updated.compareTo(a.updated);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 32,
      opacity: 0.06,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final q = _q.trim().toLowerCase();
          return Column(children: [
            Row(children: [
              const MiniOrb(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.cyan, AppColors.violet, AppColors.pink])
                      .createShader(r),
                  child: const Text('Aura',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white)),
                ),
              ),
              if (widget.onClose != null)
                GlassIconButton(
                    icon: Icons.chevron_left_rounded,
                    size: 38,
                    onTap: widget.onClose),
            ]),
            const SizedBox(height: 16),
            GradientButton(
              label: 'New chat',
              icon: Icons.add_rounded,
              onTap: () {
                c.startNew();
                widget.onAction();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                hintText: 'Search chats',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                children: q.isNotEmpty
                    ? [for (final s in c.search(q)) _chatTile(s)]
                    : _sections(),
              ),
            ),
            const SizedBox(height: 8),
            _footer(),
          ]);
        },
      ),
    );
  }

  List<Widget> _sections() {
    final pinned =
        c.sessions.where((s) => s.pinned && s.projectId == null).toList()..sort(_cmp);
    final recent =
        c.sessions.where((s) => !s.pinned && s.projectId == null).toList()..sort(_cmp);
    return [
      _header('Projects',
          trailing: GestureDetector(
              onTap: _newProject,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.add_circle_outline_rounded,
                    size: 20, color: AppColors.cyan),
              ))),
      if (c.projects.isEmpty) _hint('Projects se chats organize karo'),
      for (var i = 0; i < c.projects.length; i++) _projectTile(c.projects[i], i),
      if (pinned.isNotEmpty) ...[
        _header('Pinned'),
        for (final s in pinned) _chatTile(s),
      ],
      _header('Recent'),
      if (recent.isEmpty) _hint('Abhi koi chat nahi'),
      for (final s in recent) _chatTile(s),
    ];
  }

  Widget _header(String t, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 0, 4),
        child: Row(children: [
          Expanded(
              child: Text(t.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700))),
          if (trailing != null) trailing,
        ]),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Text(t,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      );

  Widget _chatTile(ChatSession s) {
    final sel = s.id == c.currentId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.violet.withOpacity(0.15),
          onTap: () {
            c.select(s.id);
            widget.onAction();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: sel ? Colors.white.withOpacity(0.10) : Colors.transparent,
              border: Border.all(
                  color: sel ? Colors.white.withOpacity(0.14) : Colors.transparent),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 3,
                height: sel ? 18 : 0,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    gradient: AppColors.brand,
                    borderRadius: BorderRadius.circular(3)),
              ),
              if (s.pinned) ...[
                const Icon(Icons.push_pin_rounded, size: 13, color: AppColors.gold),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                onSelected: (v) => _chatMenu(v, s),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'pin', child: Text(s.pinned ? 'Unpin' : 'Pin')),
                  const PopupMenuItem(value: 'move', child: Text('Move to project')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _chatMenu(String v, ChatSession s) async {
    switch (v) {
      case 'rename':
        final t = await promptText(context, title: 'Rename chat', initial: s.title);
        if (t != null) c.rename(s.id, t);
      case 'pin':
        c.togglePin(s.id);
      case 'move':
        final id = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            backgroundColor: const Color(0xFF16133A),
            title: const Text('Move to project'),
            children: [
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('No project')),
              for (final p in c.projects)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, p.id), child: Text(p.name)),
            ],
          ),
        );
        if (id != null) c.moveToProject(s.id, id.isEmpty ? null : id);
      case 'delete':
        if (await confirm(context, 'Delete chat?',
            'Yeh chat hamesha ke liye delete ho jayegi.')) {
          c.delete(s.id);
        }
    }
  }

  Widget _projectTile(Project p, int i) {
    final open = _open.contains(p.id);
    final chats = c.chatsIn(p.id);
    final col = _pal[i % _pal.length];
    return Column(children: [
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => open ? _open.remove(p.id) : _open.add(p.id)),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: col.withOpacity(0.18),
                border: Border.all(color: col.withOpacity(0.4)),
              ),
              child: Icon(open ? Icons.folder_open_rounded : Icons.folder_rounded,
                  size: 17, color: col),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, size: 18),
              onSelected: (v) => _projectMenu(v, p),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'new', child: Text('New chat here')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
        ),
      ),
      if (open)
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Column(children: [
            for (final s in chats) _chatTile(s),
            if (chats.isEmpty) _hint('Is project mein abhi koi chat nahi'),
          ]),
        ),
    ]);
  }

  Future<void> _projectMenu(String v, Project p) async {
    switch (v) {
      case 'new':
        c.startNew(projectId: p.id);
        widget.onAction();
      case 'edit':
        final r = await projectDialog(context,
            name: p.name, instructions: p.instructions, edit: true);
        if (r != null && r.$1.isNotEmpty) c.editProject(p.id, r.$1, r.$2);
      case 'delete':
        if (await confirm(context, 'Delete project?',
            'Project delete hoga, lekin uski chats safe rahengi.')) {
          c.deleteProject(p.id);
        }
    }
  }

  Future<void> _newProject() async {
    final r = await projectDialog(context);
    if (r != null && r.$1.isNotEmpty) c.addProject(r.$1, r.$2);
  }

  Widget _footer() {
    final u = widget.auth.user!;
    return GlassContainer(
      radius: 22,
      padding: const EdgeInsets.all(10),
      onTap: widget.onSettings,
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, gradient: AppColors.brand),
          child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(u.email.isEmpty ? 'Guest' : u.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const Icon(Icons.settings_rounded, size: 20),
      ]),
    );
  }
}