class SmartReminder {
  final String id;
  String title;
  String? description;
  DateTime reminderTime;
  String repeatType; // none, daily, weekly, monthly
  bool isCompleted;
  bool isEnabled;
  String? category;
  String? sourceConversationId;
  final DateTime createdAt;

  SmartReminder({
    required this.id,
    required this.title,
    this.description,
    required this.reminderTime,
    this.repeatType = 'none',
    this.isCompleted = false,
    this.isEnabled = true,
    this.category,
    this.sourceConversationId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue => !isCompleted && reminderTime.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reminderTime': reminderTime.toIso8601String(),
        'repeatType': repeatType,
        'isCompleted': isCompleted,
        'isEnabled': isEnabled,
        'category': category,
        'sourceConversationId': sourceConversationId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SmartReminder.fromJson(Map<String, dynamic> json) => SmartReminder(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        reminderTime: DateTime.parse(json['reminderTime'] as String),
        repeatType: json['repeatType'] as String? ?? 'none',
        isCompleted: json['isCompleted'] as bool? ?? false,
        isEnabled: json['isEnabled'] as bool? ?? true,
        category: json['category'] as String?,
        sourceConversationId: json['sourceConversationId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
