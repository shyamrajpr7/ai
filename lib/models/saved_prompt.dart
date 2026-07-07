class SavedPrompt {
  final String id;
  String title;
  String content;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;
  int usageCount;

  SavedPrompt({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.usageCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'usageCount': usageCount,
  };

  factory SavedPrompt.fromJson(Map<String, dynamic> json) => SavedPrompt(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    tags: List<String>.from(json['tags'] as List? ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    usageCount: json['usageCount'] as int? ?? 0,
  );

  SavedPrompt copyWith({
    String? title,
    String? content,
    List<String>? tags,
    int? usageCount,
  }) {
    return SavedPrompt(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
