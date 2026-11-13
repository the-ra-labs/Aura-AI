import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../models/attachment.dart';
import '../services/voice_service.dart';
import 'buttons.dart';
import 'glass_container.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onStop,
    this.generating = false,
  });
  final void Function(String text, List<Attachment> files) onSend;
  final VoidCallback onStop;
  final bool generating;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final List<Attachment> _files = [];
  bool _listening = false;
  String _base = '';

  bool get _canSend => _ctrl.text.trim().isNotEmpty || _files.isNotEmpty;
  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_r);
    _focus.addListener(_r);
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _submit([String? _]) {
    final t = _ctrl.text.trim();
    if (!_canSend || widget.generating) return;
    VoiceService.instance.cancelListening();
    widget.onSend(t, List.of(_files));
    _ctrl.clear();
    setState(() {
      _files.clear();
      _listening = false;
    });
  }

  Future<void> _dictate() async {
    final v = VoiceService.instance;
    if (_listening) {
      await v.stopListening();
      setState(() => _listening = false);
      return;
    }
    if (!await v.init()) {
      _snack('Voice input yahan available nahi (ya mic permission do)');
      return;
    }
    _base = _ctrl.text.isEmpty ? '' : '${_ctrl.text} ';
    setState(() => _listening = true);
    await v.listen(
      onText: (t, fin) {
        if (!mounted) return;
        _ctrl.text = '$_base$t';
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      },
      onEnd: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final ext = x.name.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      setState(() => _files.add(Attachment(name: x.name, mime: mime, bytes: bytes)));
    } catch (_) {
      _snack('Image select nahi ho saki');
    }
  }

  Future<void> _pickFile() async {
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'txt', 'md', 'json', 'csv', 'dart', 'py', 'js', 'ts', 'html',
          'css', 'xml', 'yaml', 'yml', 'java', 'c', 'cpp', 'log'
        ],
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      var text = utf8.decode(bytes, allowMalformed: true);
      if (text.length > 100000) {
        text = '${text.substring(0, 100000)}\n…(truncated)';
      }
      setState(() =>
          _files.add(Attachment(name: f.name, mime: 'text/plain', text: text)));
    } catch (_) {
      _snack('File select nahi ho saki');
    }
  }

  Widget _thumb(Attachment a) {
    final child = a.isImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(a.bytes!, width: 58, height: 58, fit: BoxFit.cover),
          )
        : Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.description_rounded, size: 18, color: AppColors.cyan),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          );
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(clipBehavior: Clip.none, children: [
        child,
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => setState(() => _files.remove(a)),
            child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black87,
                child: Icon(Icons.close, size: 12)),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final active = _canSend || widget.generating;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: GlassContainer(
        radius: 32,
        padding: const EdgeInsets.all(6),
        tint: focused ? AppColors.violet : null,
        glow: focused ? AppColors.violet : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: SizedBox(
                height: 66,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [for (final a in _files) _thumb(a)],
                ),
              ),
            ),
          Row(children: [
            PopupMenuButton<int>(
              onSelected: (v) {
                if (v == 0) _pickImage(ImageSource.gallery);
                if (v == 1) _pickImage(ImageSource.camera);
                if (v == 2) _pickFile();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 0, child: Text('Image (gallery)')),
                if (_mobile) const PopupMenuItem(value: 1, child: Text('Camera')),
                const PopupMenuItem(value: 2, child: Text('Text / code file')),
              ],
              child: const GlassIconButton(icon: Icons.add_rounded),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onSubmitted: _submit,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration.collapsed(
                    hintText: _listening ? 'Listening…' : 'Message Aura…',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            GlassIconButton(
                icon: _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                filled: _listening,
                onTap: _dictate),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.generating ? widget.onStop : _submit,
              child: AnimatedOpacity(
                opacity: active ? 1 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.generating
                        ? AppColors.brandWarm
                        : AppColors.brand,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.violet.withOpacity(active ? 0.55 : 0),
                          blurRadius: 16,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Icon(
                      widget.generating
                          ? Icons.stop_rounded
                          : Icons.arrow_upward_rounded,
                      color: Colors.white),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}