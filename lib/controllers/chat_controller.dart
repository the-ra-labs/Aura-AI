import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/store.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/project.dart';
import '../services/ai_service.dart';
import 'settings_controller.dart';
import '../models/attachment.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._settings, this.userId) {
    _load();
  }

  final SettingsController _settings;
  final String userId;

  final List<ChatSession> sessions = [];
  final List<Project> projects = [];
  String? currentId;
  String? draftProjectId;
  bool isGenerating = false;
  String? error;

  StreamSubscription<String>? _sub;
  Completer<void>? _done;

  String get _ck => 'chats_$userId';
  String get _pk => 'projects_$userId';
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------- load / save ----------
  void _load() {
    try {
      final c = Store.read(_ck);
      if (c != null) {
        sessions.addAll((jsonDecode(c) as List)
            .map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e))));
      }
      final p = Store.read(_pk);
      if (p != null) {
        projects.addAll((jsonDecode(p) as List)
            .map((e) => Project.fromJson(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    await Store.write(_ck, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await Store.write(_pk, jsonEncode(projects.map((p) => p.toJson()).toList()));
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  // ---------- getters ----------
  ChatSession? get current {
    for (final s in sessions) {
      if (s.id == currentId) return s;
    }
    return null;
  }

  Project? projectOf(String? id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ChatSession> chatsIn(String? projectId) {
    final l = sessions.where((s) => s.projectId == projectId).toList();
    l.sort((a, b) => b.updated.compareTo(a.updated));
    return l;
  }

  List<ChatSession> search(String q) => sessions
      .where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.messages.any((m) => m.text.toLowerCase().contains(q)))
      .toList();

  // ---------- navigation ----------
  void startNew({String? projectId}) {
    stop();
    currentId = null;
    draftProjectId = projectId;
    error = null;
    notifyListeners();
  }

  void select(String id) {
    stop();
    currentId = id;
    error = null;
    notifyListeners();
  }

  // ---------- chat actions ----------
  void rename(String id, String title) {
    final s = _find(id);
    if (s == null || title.isEmpty) return;
    s.title = title;
    _commit();
  }

  void togglePin(String id) {
    final s = _find(id);
    if (s == null) return;
    s.pinned = !s.pinned;
    _commit();
  }

  void moveToProject(String id, String? projectId) {
    final s = _find(id);
    if (s == null) return;
    s.projectId = projectId;
    _commit();
  }

  void delete(String id) {
    if (currentId == id) {
      stop();
      currentId = null;
    }
    sessions.removeWhere((s) => s.id == id);
    _commit();
  }

  void deleteAll() {
    stop();
    sessions.clear();
    currentId = null;
    _commit();
  }

  ChatSession? _find(String id) {
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ---------- projects ----------
  void addProject(String name, String instructions) {
    projects.add(Project(id: _id(), name: name, instructions: instructions));
    _commit();
  }

  void editProject(String id, String name, String instructions) {
    final p = projectOf(id);
    if (p == null) return;
    p.name = name;
    p.instructions = instructions;
    _commit();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    for (final s in sessions) {
      if (s.projectId == id) s.projectId = null;
    }
    _commit();
  }

  // ---------- messaging ----------
  Future<void> send(String text,
      {List<Attachment> attachments = const []}) async {
    final t = text.trim();
    if ((t.isEmpty && attachments.isEmpty) || isGenerating) return;

    var s = current;
    if (s == null) {
      s = ChatSession(id: _id(), projectId: draftProjectId);
      sessions.insert(0, s);
      currentId = s.id;
      draftProjectId = null;
    }
    s.messages.add(ChatMessage(
        id: _id(), text: t, isUser: true, attachments: List.of(attachments)));
    if (s.messages.length == 1) {
      final base = t.isNotEmpty ? t : attachments.first.name;
      s.title = base.length > 32 ? '${base.substring(0, 32)}…' : base;
    }
    await _generate(s);
  }

  Future<void> regenerate() async {
    final s = current;
    if (s == null || isGenerating) return;
    if (s.messages.isNotEmpty && !s.messages.last.isUser) s.messages.removeLast();
    if (s.messages.isEmpty) return;
    await _generate(s);
  }

  String _system(ChatSession s) {
    final p = projectOf(s.projectId);
    return [
      _settings.effectiveSystem,
      if (p != null && p.instructions.trim().isNotEmpty)
        'Project "${p.name}" instructions:\n${p.instructions}',
    ].join('\n\n');
  }

  Future<void> _generate(ChatSession s) async {
    final reply = ChatMessage(id: _id(), text: '', isUser: false);
    final history = List<ChatMessage>.from(s.messages);
    s.messages.add(reply);
    isGenerating = true;
    error = null;
    s.updated = DateTime.now();
    notifyListeners();

    final AiService svc = _settings.buildService();

    _done = Completer<void>();
    _sub = svc.stream(history: history, system: _system(s)).listen(
          (d) {
            reply.text += d;
            notifyListeners();
          },
          onError: (Object e) {
            error = e.toString().replaceFirst('Exception: ', '');
            _finish();
          },
          onDone: _finish,
          cancelOnError: true,
        );
    await _done!.future;
    _sub = null;

    if (reply.text.isEmpty) s.messages.remove(reply);
    isGenerating = false;
    s.updated = DateTime.now();
    await _save();
    notifyListeners();
  }

  void _finish() {
    if (_done != null && !_done!.isCompleted) _done!.complete();
  }

  void stop() {
    _sub?.cancel();
    _finish();
  }

  String exportMarkdown(ChatSession s) {
    final b = StringBuffer('# ${s.title}\n\n');
    for (final m in s.messages) {
      b.writeln(m.isUser ? '**You:**' : '**Aura:**');
      b.writeln(m.text);
      for (final a in m.attachments) {
        b.writeln('_📎 ${a.name}_');
      }
      b.writeln();
    }
    return b.toString();
  }
}