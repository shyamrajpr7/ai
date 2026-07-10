class JournalEntry {
  final String id;
  String title;
  String content;
  String? aiSummary;
  String? mood;
  double? moodScore;
  List<String> tags;
  bool isVoiceInput;
  final DateTime createdAt;
  DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    this.aiSummary,
    this.mood,
    this.moodScore,
    this.tags = const [],
    this.isVoiceInput = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'aiSummary': aiSummary,
        'mood': mood,
        'moodScore': moodScore,
        'tags': tags,
        'isVoiceInput': isVoiceInput,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        aiSummary: json['aiSummary'] as String?,
        mood: json['mood'] as String?,
        moodScore: (json['moodScore'] as num?)?.toDouble(),
        tags: List<String>.from(json['tags'] as List? ?? []),
        isVoiceInput: json['isVoiceInput'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
