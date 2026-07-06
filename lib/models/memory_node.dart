class MemoryNode {
  final String id;
  String content;
  String category;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  double importance;

  MemoryNode({
    required this.id,
    required this.content,
    this.category = 'general',
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.importance = 0.5,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'category': category,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'importance': importance,
  };

  factory MemoryNode.fromJson(Map<String, dynamic> json) => MemoryNode(
    id: json['id'] as String,
    content: json['content'] as String,
    category: json['category'] as String? ?? 'general',
    tags: List<String>.from(json['tags'] as List? ?? []),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
  );
}

const memoryCategories = [
  'general',
  'fact',
  'preference',
  'personal',
  'interest',
  'project',
];
