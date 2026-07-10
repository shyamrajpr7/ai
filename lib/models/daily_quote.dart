class DailyQuote {
  final String id;
  String text;
  String author;
  String category;
  bool isFavorite;
  final DateTime generatedAt;

  DailyQuote({
    required this.id,
    required this.text,
    this.author = 'Unknown',
    this.category = 'motivation',
    this.isFavorite = false,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        'category': category,
        'isFavorite': isFavorite,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
        id: json['id'] as String,
        text: json['text'] as String,
        author: json['author'] as String? ?? 'Unknown',
        category: json['category'] as String? ?? 'motivation',
        isFavorite: json['isFavorite'] as bool? ?? false,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
