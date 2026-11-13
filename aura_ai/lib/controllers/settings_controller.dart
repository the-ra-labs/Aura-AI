import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/secrets.dart';
import '../core/store.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';

class SettingsController extends ChangeNotifier {
  static const groqUrl = 'https://api.groq.com/openai/v1';
  static const cerebrasUrl = 'https://api.cerebras.ai/v1';
  static const githubUrl = 'https://models.github.ai/inference';

  static const voiceLangs = {
    'en-US': 'English',
    'ur-PK': 'اردو',
    'hi-IN': 'हिन्दी',
    'ar-SA': 'العربية',
  };

  static const _base =
      'You are Aura, a smart, accurate and friendly AI assistant. Think carefully, '
      'give correct and well-structured answers, and say clearly when you are '
      'unsure instead of guessing. Use Markdown.';

  String apiKey = ''; // optional: secrets.dart wali Groq key ko override karti hai
  String voiceLang = 'en-US';
  String displayName = '';
  String aboutMe = '';
  String customInstructions = '';
  String replyLanguage = 'auto'; // auto | en | ur | roman
  String replyStyle = 'balanced'; // concise | balanced | detailed
  double textScale = 1.0;

  String _real(String v) {
    final s = v.replaceAll(RegExp(r'\s'), '');
    return s.startsWith('PASTE_') ? '' : s;
  }

  String get effectiveKey {
    final own = _real(apiKey);
    return own.isNotEmpty ? own : _real(Secrets.groqKey);
  }

  List<String> get activeProviders => [
        if (effectiveKey.isNotEmpty) 'Groq',
        if (_real(Secrets.cerebrasKey).isNotEmpty) 'Cerebras',
        if (_real(Secrets.githubKey).isNotEmpty) 'GitHub',
      ];

  bool get hasKey => activeProviders.isNotEmpty;

  AiService buildService() {
    final list = <(String, AiService)>[
      if (effectiveKey.isNotEmpty)
        ('Groq',
            ChatApiService(
                baseUrl: groqUrl,
                apiKey: effectiveKey,
                model: Secrets.model,
                visionModel: Secrets.visionModel)),
      if (_real(Secrets.cerebrasKey).isNotEmpty)
        ('Cerebras',
            ChatApiService(
                baseUrl: cerebrasUrl,
                apiKey: _real(Secrets.cerebrasKey),
                model: Secrets.backupModel)),
      if (_real(Secrets.githubKey).isNotEmpty)
        ('GitHub',
            ChatApiService(
                baseUrl: githubUrl,
                apiKey: _real(Secrets.githubKey),
                model: Secrets.githubModel,
                visionModel: Secrets.githubModel)),
    ];
    if (list.isEmpty) return MockAiService();
    if (list.length == 1) return list.first.$2;
    return FallbackAiService(list);
  }

  String get effectiveSystem {
    final b = StringBuffer(_base)..writeln();
    b.writeln(switch (replyStyle) {
      'concise' => 'Keep answers short and direct.',
      'detailed' => 'Give thorough, step-by-step answers.',
      _ => 'Give clear, balanced answers.',
    });
    b.writeln(switch (replyLanguage) {
      'en' => 'Always reply in English.',
      'ur' => 'Always reply in Urdu (Urdu script).',
      'roman' => 'Always reply in Roman Urdu (Urdu written in English letters).',
      _ => 'Reply in the same language the user writes in.',
    });
    if (displayName.trim().isNotEmpty) {
      b.writeln("The user's name is ${displayName.trim()}.");
    }
    if (aboutMe.trim().isNotEmpty) b.writeln('About the user: ${aboutMe.trim()}');
    if (customInstructions.trim().isNotEmpty) {
      b.writeln('User instructions: ${customInstructions.trim()}');
    }
    return b.toString();
  }

  String _s(dynamic v, String d) => v is String ? v : d;

  void load() {
    final r = Store.read('settings');
    if (r != null) {
      final j = jsonDecode(r);
      apiKey = _s(j['groqKey'], '');
      voiceLang = _s(j['voiceLang'], 'en-US');
      displayName = _s(j['displayName'], '');
      aboutMe = _s(j['aboutMe'], '');
      customInstructions = _s(j['customInstructions'], '');
      replyLanguage = _s(j['replyLanguage'], 'auto');
      replyStyle = _s(j['replyStyle'], 'balanced');
      textScale = (j['textScale'] is num) ? (j['textScale'] as num).toDouble() : 1.0;
    }
    VoiceService.instance.locale = voiceLang;
    notifyListeners();
  }

  Future<void> _save() => Store.write(
      'settings',
      jsonEncode({
        'groqKey': apiKey,
        'voiceLang': voiceLang,
        'displayName': displayName,
        'aboutMe': aboutMe,
        'customInstructions': customInstructions,
        'replyLanguage': replyLanguage,
        'replyStyle': replyStyle,
        'textScale': textScale,
      }));

  Future<void> update({
    String? apiKey,
    String? voiceLang,
    String? displayName,
    String? aboutMe,
    String? customInstructions,
    String? replyLanguage,
    String? replyStyle,
    double? textScale,
  }) async {
    if (apiKey != null) this.apiKey = apiKey;
    if (voiceLang != null) {
      this.voiceLang = voiceLang;
      VoiceService.instance.locale = voiceLang;
    }
    if (displayName != null) this.displayName = displayName;
    if (aboutMe != null) this.aboutMe = aboutMe;
    if (customInstructions != null) this.customInstructions = customInstructions;
    if (replyLanguage != null) this.replyLanguage = replyLanguage;
    if (replyStyle != null) this.replyStyle = replyStyle;
    if (textScale != null) this.textScale = textScale;
    await _save();
    notifyListeners();
  }
}