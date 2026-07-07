class KnowledgeNode {
  String id;
  String label;
  String type; // 'topic', 'concept', 'person', 'place', 'technology', 'hashtag'
  int frequency;
  double importance;
  double x;
  double y;
  List<String> messageIds;
  int colorValue;

  KnowledgeNode({
    required this.id,
    required this.label,
    this.type = 'topic',
    this.frequency = 1,
    this.importance = 0.5,
    this.x = 0,
    this.y = 0,
    List<String>? messageIds,
    this.colorValue = 0xFF7C4DFF,
  }) : messageIds = messageIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type,
    'frequency': frequency,
    'importance': importance,
    'x': x,
    'y': y,
    'messageIds': messageIds,
    'colorValue': colorValue,
  };

  factory KnowledgeNode.fromJson(Map<String, dynamic> json) => KnowledgeNode(
    id: json['id'] as String,
    label: json['label'] as String,
    type: json['type'] as String? ?? 'topic',
    frequency: json['frequency'] as int? ?? 1,
    importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
    x: (json['x'] as num?)?.toDouble() ?? 0,
    y: (json['y'] as num?)?.toDouble() ?? 0,
    messageIds: List<String>.from(json['messageIds'] as List? ?? []),
    colorValue: json['colorValue'] as int? ?? 0xFF7C4DFF,
  );

  KnowledgeNode copyWith({
    String? label,
    String? type,
    int? frequency,
    double? importance,
    double? x,
    double? y,
    List<String>? messageIds,
    int? colorValue,
  }) {
    return KnowledgeNode(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      importance: importance ?? this.importance,
      x: x ?? this.x,
      y: y ?? this.y,
      messageIds: messageIds ?? this.messageIds,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class KnowledgeEdge {
  final String id;
  final String sourceId;
  final String targetId;
  double weight;
  String? label;

  KnowledgeEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.weight = 1.0,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'targetId': targetId,
    'weight': weight,
    if (label != null) 'label': label,
  };

  factory KnowledgeEdge.fromJson(Map<String, dynamic> json) => KnowledgeEdge(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    targetId: json['targetId'] as String,
    weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    label: json['label'] as String?,
  );
}
