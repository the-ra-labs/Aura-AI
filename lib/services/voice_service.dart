import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  VoiceService._();
  static final instance = VoiceService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _ttsInit = false;
  void Function(String)? _onStatus;

  /// Settings se set hota hai (en-US, ur-PK, ...)
  String locale = 'en-US';

  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(onStatus: (s) => _onStatus?.call(s));
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    void Function()? onEnd,
  }) async {
    if (!await init()) return;
    _onStatus = (s) {
      if (s == 'done' || s == 'notListening') onEnd?.call();
    };
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: locale.replaceAll('-', '_'),
      ),
    );
  }

  Future<void> stopListening() async {
    if (_ready) await _stt.stop();
  }

  Future<void> cancelListening() async {
    if (_ready) await _stt.cancel();
  }

  Future<void> speak(String text) async {
    try {
      if (!_ttsInit) {
        await _tts.awaitSpeakCompletion(true);
        _ttsInit = true;
      }
      final clean = _clean(text);
      if (clean.isEmpty) return;
      await _tts.setLanguage(locale);
      await _tts.stop();
      await _tts.speak(clean);
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static String _clean(String t) => t
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' code block ')
      .replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m[1] ?? '')
      .replaceAll(RegExp(r'[*_`#>~|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}