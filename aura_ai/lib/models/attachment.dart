import 'dart:typed_data';

class Attachment {
  Attachment({required this.name, required this.mime, this.bytes, this.text});
  final String name;
  final String mime;
  final Uint8List? bytes; // images: sirf current session mein (save nahi hoti)
  final String? text; // text files: chat ke saath save hoti hain
  bool get isImage => bytes != null;

  Map<String, dynamic> toJson() => {'name': name, 'mime': mime, 'text': text};
  factory Attachment.fromJson(Map<String, dynamic> j) =>
      Attachment(name: j['name'], mime: j['mime'] ?? '', text: j['text']);
}