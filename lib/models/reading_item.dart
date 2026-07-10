class ReadingItem {
  final String id;
  String title;
  String? author;
  String? url;
  String type; // book, article, video, podcast
  String status; // to_read, reading, completed
  int progress; // 0-100
  int? rating; // 1-5
  String? notes;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;

  ReadingItem({
    required this.id,
    required this.title,
    this.author,
    this.url,
    this.type = 'book',
    this.status = 'to_read',
    this.progress = 0,
    this.rating,
    this.notes,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'url': url,
        'type': type,
        'status': status,
        'progress': progress,
        'rating': rating,
        'notes': notes,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        url: json['url'] as String?,
        type: json['type'] as String? ?? 'book',
        status: json['status'] as String? ?? 'to_read',
        progress: json['progress'] as int? ?? 0,
        rating: json['rating'] as int?,
        notes: json['notes'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
