class DiaryEntry {
  final String id;
  final DateTime date;
  final String summary;
  final List<String> keyInsights;
  final List<String> conversationPreviews;
  final String? dreamscapePrompt;
  final String? imageBase64;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.summary,
    this.keyInsights = const [],
    this.conversationPreviews = const [],
    this.dreamscapePrompt,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'summary': summary,
    'keyInsights': keyInsights,
    'conversationPreviews': conversationPreviews,
    if (dreamscapePrompt != null) 'dreamscapePrompt': dreamscapePrompt,
    if (imageBase64 != null) 'imageBase64': imageBase64,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    summary: json['summary'] as String,
    keyInsights: List<String>.from(json['keyInsights'] as List),
    conversationPreviews: List<String>.from(json['conversationPreviews'] as List),
    dreamscapePrompt: json['dreamscapePrompt'] as String?,
    imageBase64: json['imageBase64'] as String?,
  );
}
