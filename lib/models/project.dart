class Project {
  Project({required this.id, required this.name, this.instructions = ''});
  final String id;
  String name;
  String instructions;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'instructions': instructions};

  factory Project.fromJson(Map<String, dynamic> j) => Project(
      id: j['id'], name: j['name'], instructions: j['instructions'] ?? '');
}