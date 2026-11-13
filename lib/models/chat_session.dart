import 'chat_message.dart';

class ChatSession {
  ChatSession({
    required this.id,
    this.title = 'New chat',
    this.pinned = false,
    this.projectId,
    List<ChatMessage>? messages,
    DateTime? updated,
  })  : messages = messages ?? [],
        updated = updated ?? DateTime.now();

  final String id;
  String title;
  bool pinned;
  String? projectId;
  final List<ChatMessage> messages;
  DateTime updated;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'pinned': pinned,
    'projectId': projectId,
    'updated': updated.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id: j['id'],
    title: j['title'],
    pinned: j['pinned'] ?? false,
    projectId: j['projectId'],
    updated: DateTime.parse(j['updated']),
    messages: (j['messages'] as List)
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}