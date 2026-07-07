class FlashCard {
  final String id;
  String question;
  String answer;
  List<String> tags;
  String? sourceConversationId;
  String? sourceConversationTitle;
  String difficulty;
  int reviewCount;
  int correctCount;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastReviewedAt;

  FlashCard({
    required this.id,
    required this.question,
    required this.answer,
    this.tags = const [],
    this.sourceConversationId,
    this.sourceConversationTitle,
    this.difficulty = 'medium',
    this.reviewCount = 0,
    this.correctCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastReviewedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get successRate =>
      reviewCount > 0 ? correctCount / reviewCount : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'tags': tags,
    'sourceConversationId': sourceConversationId,
    'sourceConversationTitle': sourceConversationTitle,
    'difficulty': difficulty,
    'reviewCount': reviewCount,
    'correctCount': correctCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
    tags: List<String>.from(json['tags'] as List? ?? []),
    sourceConversationId: json['sourceConversationId'] as String?,
    sourceConversationTitle: json['sourceConversationTitle'] as String?,
    difficulty: json['difficulty'] as String? ?? 'medium',
    reviewCount: json['reviewCount'] as int? ?? 0,
    correctCount: json['correctCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastReviewedAt: json['lastReviewedAt'] != null
        ? DateTime.parse(json['lastReviewedAt'] as String)
        : null,
  );

  FlashCard copyWith({
    String? question,
    String? answer,
    List<String>? tags,
    String? difficulty,
    int? reviewCount,
    int? correctCount,
    DateTime? lastReviewedAt,
  }) {
    return FlashCard(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      tags: tags ?? this.tags,
      sourceConversationId: sourceConversationId,
      sourceConversationTitle: sourceConversationTitle,
      difficulty: difficulty ?? this.difficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
