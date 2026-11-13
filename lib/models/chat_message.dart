import 'attachment.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? time,
    List<Attachment>? attachments,
  })  : time = time ?? DateTime.now(),
        attachments = attachments ?? [];

  final String id;
  String text;
  final bool isUser;
  final DateTime time;
  final List<Attachment> attachments;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'],
    text: j['text'],
    isUser: j['isUser'],
    time: DateTime.parse(j['time']),
    attachments: ((j['attachments'] as List?) ?? [])
        .map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}