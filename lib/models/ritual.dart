class Ritual {
  final String id;
  final String type;
  String title;
  String description;
  final DateTime date;
  bool completed;
  String? journalResponse;
  int streak;
  final DateTime createdAt;
  DateTime updatedAt;

  Ritual({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    this.completed = false,
    this.journalResponse,
    this.streak = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'completed': completed,
    'journalResponse': journalResponse,
    'streak': streak,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Ritual.fromJson(Map<String, dynamic> json) => Ritual(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
    completed: json['completed'] as bool? ?? false,
    journalResponse: json['journalResponse'] as String?,
    streak: json['streak'] as int? ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: DateTime.now(),
  );

  Ritual copyWith({
    String? title,
    String? description,
    bool? completed,
    String? journalResponse,
    int? streak,
  }) {
    return Ritual(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date,
      completed: completed ?? this.completed,
      journalResponse: journalResponse ?? this.journalResponse,
      streak: streak ?? this.streak,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
