class CodeSnippet {
  final String id;
  String title;
  String code;
  String language;
  String? description;
  List<String> tags;
  String? sourceConversationId;
  final DateTime createdAt;
  DateTime updatedAt;
  int copyCount;

  CodeSnippet({
    required this.id,
    required this.title,
    required this.code,
    this.language = 'dart',
    this.description,
    this.tags = const [],
    this.sourceConversationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.copyCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'code': code,
        'language': language,
        'description': description,
        'tags': tags,
        'sourceConversationId': sourceConversationId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'copyCount': copyCount,
      };

  factory CodeSnippet.fromJson(Map<String, dynamic> json) => CodeSnippet(
        id: json['id'] as String,
        title: json['title'] as String,
        code: json['code'] as String,
        language: json['language'] as String? ?? 'dart',
        description: json['description'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        sourceConversationId: json['sourceConversationId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        copyCount: json['copyCount'] as int? ?? 0,
      );

  CodeSnippet copyWith({
    String? title,
    String? code,
    String? language,
    String? description,
    List<String>? tags,
    int? copyCount,
  }) {
    return CodeSnippet(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      language: language ?? this.language,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      sourceConversationId: sourceConversationId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      copyCount: copyCount ?? this.copyCount,
    );
  }
}
