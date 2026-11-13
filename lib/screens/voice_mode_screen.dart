import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../core/theme/app_colors.dart';
import '../services/voice_service.dart';
import '../widgets/ai_orb.dart';

enum _V { idle, listening, thinking, speaking }

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key, required this.chat});
  final ChatController chat;

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen> {
  final _voice = VoiceService.instance;
  _V _s = _V.idle;
  String _heard = '', _reply = '', _note = '';
  bool _loop = true, _closed = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  @override
  void dispose() {
    _closed = true;
    _gen++;
    _voice.cancelListening();
    _voice.stopSpeaking();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_closed || _s != _V.idle) return;
    if (!await _voice.init()) {
      if (mounted) {
        setState(() => _note =
        'Voice input available nahi. Mic permission check karein (Windows par limited).');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _s = _V.listening;
      _heard = '';
      _note = '';
    });
    await _voice.listen(
      onText: (t, fin) {
        if (!mounted || _s != _V.listening) return;
        setState(() => _heard = t);
        if (fin && t.trim().isNotEmpty) _ask(t);
      },
      onEnd: () {
        if (!mounted || _s != _V.listening) return;
        if (_heard.trim().isEmpty) {
          setState(() => _s = _V.idle);
        } else {
          _ask(_heard);
        }
      },
    );
  }

  Future<void> _ask(String t) async {
    if (_s != _V.listening) return;
    final g = ++_gen;
    setState(() {
      _s = _V.thinking;
      _reply = '';
    });
    await _voice.stopListening();
    await widget.chat.send(t);
    if (!mounted || g != _gen) return;

    final msgs = widget.chat.current?.messages ?? [];
    final text = (msgs.isNotEmpty && !msgs.last.isUser) ? msgs.last.text : '';
    if (text.isEmpty) {
      setState(() {
        _s = _V.idle;
        _note = widget.chat.error ?? 'Jawab nahi aaya';
      });
      return;
    }
    setState(() {
      _s = _V.speaking;
      _reply = text;
    });
    await _voice.speak(text);
    if (!mounted || g != _gen) return;
    setState(() => _s = _V.idle);
    if (_loop) _listen();
  }

  void _stopAll() {
    _gen++;
    _loop = false;
    widget.chat.stop();
    _voice.cancelListening();
    _voice.stopSpeaking();
    setState(() => _s = _V.idle);
  }

  void _micTap() {
    if (_s == _V.idle) {
      _loop = true;
      _listen();
    } else if (_s == _V.listening) {
      _voice.stopListening(); // onEnd -> _ask
    } else {
      _stopAll();
    }
  }

  String get _status => switch (_s) {
    _V.idle => 'Tap mic to talk',
    _V.listening => 'Listening…',
    _V.thinking => 'Thinking…',
    _V.speaking => 'Speaking…',
  };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final caption = _s == _V.speaking ? _reply : _heard;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
              const Spacer(),
              const Text('Voice mode',
                  style: TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AiOrb(
                        size: w < 600 ? 230 : 290,
                        active: _s == _V.listening || _s == _V.speaking),
                    const SizedBox(height: 32),
                    Text(_status,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    if (caption.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: SingleChildScrollView(
                          child: Text(caption,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  height: 1.4)),
                        ),
                      ),
                    if (_note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_note,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.pink)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 8),
            child: GestureDetector(
              onTap: _micTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _s == _V.idle
                        ? const [Colors.white24, Colors.white12]
                        : const [AppColors.violet, AppColors.pink],
                  ),
                  boxShadow: _s == _V.idle
                      ? null
                      : [
                    BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.6),
                        blurRadius: 30)
                  ],
                ),
                child: Icon(
                    switch (_s) {
                      _V.idle => Icons.mic_none_rounded,
                      _V.listening => Icons.mic_rounded,
                      _ => Icons.stop_rounded,
                    },
                    size: 34),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}