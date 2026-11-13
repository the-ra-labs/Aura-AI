import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

abstract class AiService {
  Stream<String> stream({required List<ChatMessage> history, String? system});
}

String messageText(ChatMessage m) {
  final b = StringBuffer(m.text);
  for (final a in m.attachments) {
    if (a.text != null) b.write('\n\n[File: ${a.name}]\n${a.text}');
  }
  return b.toString();
}

String apiErrorMessage(int code, String body) {
  var detail = '';
  try {
    final e = jsonDecode(body)['error'];
    detail = e is Map ? (e['message'] ?? '').toString() : (e ?? '').toString();
  } catch (_) {
    detail = body;
  }
  if (detail.length > 200) detail = '${detail.substring(0, 200)}…';
  final hint = switch (code) {
    400 => 'Request galat (model is input ko support nahi karta?)',
    401 => 'API key galat hai. Settings → API Key check karein',
    403 => 'Is key ko permission nahi (ya region block)',
    404 => 'Model nahi mila. secrets.dart mein model name check karein',
    413 => 'Message bohat lamba hai, chhota karke try karein',
    429 => 'Free limit abhi khatam, thori der baad try karein',
    >= 500 => 'Provider ka server masla, thori der baad try karein',
    _ => 'Error',
  };
  return '$hint ($code)${detail.isEmpty ? '' : '\n$detail'}';
}

Stream<Map<String, dynamic>> _sseJson(http.Request req) async* {
  final client = http.Client();
  try {
    final res = await client.send(req);
    if (res.statusCode != 200) {
      throw Exception(
          apiErrorMessage(res.statusCode, await res.stream.bytesToString()));
    }
    await for (final line in res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final d = line.substring(5).trim();
      if (d.isEmpty || d == '[DONE]') continue;
      yield Map<String, dynamic>.from(jsonDecode(d));
    }
  } finally {
    client.close();
  }
}

class MockAiService implements AiService {
  @override
  Stream<String> stream(
      {required List<ChatMessage> history, String? system}) async* {
    const text = '👋 Demo mode: abhi koi API key set nahi hai.\n\n'
        '`lib/core/secrets.dart` mein free **Groq key** paste karein, '
        'ya **Settings → API Key** mein daalein.\n\n'
        '```dart\nprint("Hello from Aura");\n```';
    await Future.delayed(const Duration(milliseconds: 500));
    for (final w in text.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield '$w ';
    }
  }
}

/// Groq, Cerebras, GitHub Models: sab OpenAI-style hain.
class ChatApiService implements AiService {
  ChatApiService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.visionModel,
  });
  final String baseUrl, apiKey, model;
  final String? visionModel;

  // Free plan mein tokens/minute kam hote hain, isliye sirf recent messages bhejte hain
  static const _maxHistory = 14;

  Object _content(ChatMessage m) {
    final imgs = m.attachments.where((a) => a.isImage).toList();
    if (imgs.isEmpty) return messageText(m);
    return [
      {'type': 'text', 'text': messageText(m)},
      for (final a in imgs)
        {
          'type': 'image_url',
          'image_url': {'url': 'data:${a.mime};base64,${base64Encode(a.bytes!)}'}
        },
    ];
  }

  @override
  Stream<String> stream(
      {required List<ChatMessage> history, String? system}) async* {
    var h = history.length > _maxHistory
        ? history.sublist(history.length - _maxHistory)
        : history;
    while (h.length > 1 && !h.first.isUser) {
      h = h.sublist(1);
    }

    final hasImg = h.any((m) => m.attachments.any((a) => a.isImage));
    final useModel = hasImg ? visionModel : model;
    if (useModel == null) throw Exception('Is provider par image support nahi');

    final body = {
      'model': useModel,
      'stream': true,
      'messages': [
        if (system != null && system.trim().isNotEmpty)
          {'role': 'system', 'content': system},
        for (final m in h)
          {'role': m.isUser ? 'user' : 'assistant', 'content': _content(m)},
      ],
    };
    final req = http.Request(
        'POST', Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..body = jsonEncode(body);

    await for (final j in _sseJson(req)) {
      final c = j['choices'];
      if (c is List && c.isNotEmpty) {
        final t = c[0]['delta']?['content'];
        if (t is String) yield t;
      }
    }
  }

  /// null = key theek, warna error message.
  static Future<String?> testKey(String baseUrl, String key) async {
    try {
      final res = await http
          .get(Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/models'),
              headers: {'Authorization': 'Bearer ${key.trim()}'})
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200
          ? null
          : apiErrorMessage(res.statusCode, res.body);
    } catch (e) {
      return 'Internet ya connection masla: $e';
    }
  }
}

/// Pehla provider fail ho (limit waghera) to agla try karta hai.
class FallbackAiService implements AiService {
  FallbackAiService(this.services);
  final List<(String, AiService)> services;

  @override
  Stream<String> stream(
      {required List<ChatMessage> history, String? system}) async* {
    final errors = <String>[];
    for (final (name, s) in services) {
      var got = false;
      try {
        await for (final d in s.stream(history: history, system: system)) {
          got = true;
          yield d;
        }
        return;
      } catch (e) {
        if (got) rethrow; // jawab beech mein fail ho to dobara try nahi
        errors.add('$name: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
    throw Exception(
        errors.isEmpty ? 'Koi provider available nahi' : errors.join('\n\n'));
  }
}