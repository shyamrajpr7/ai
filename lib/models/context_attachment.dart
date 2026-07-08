class ContextAttachment {
  final String id;
  final String type;
  String title;
  String content;
  String source;
  bool enabled;
  final DateTime addedAt;
  DateTime updatedAt;

  ContextAttachment({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    required this.source,
    this.enabled = true,
    DateTime? addedAt,
    DateTime? updatedAt,
  })  : addedAt = addedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'content': content,
    'source': source,
    'enabled': enabled,
    'addedAt': addedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ContextAttachment.fromJson(Map<String, dynamic> json) =>
      ContextAttachment(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        source: json['source'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'] as String)
            : null,
        updatedAt: DateTime.now(),
      );

  ContextAttachment copyWith({
    String? title,
    String? content,
    bool? enabled,
  }) {
    return ContextAttachment(
      id: id,
      type: type,
      title: title ?? this.title,
      content: content ?? this.content,
      source: source,
      enabled: enabled ?? this.enabled,
      addedAt: addedAt,
      updatedAt: DateTime.now(),
    );
  }
}
