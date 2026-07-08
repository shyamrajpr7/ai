class HabitLog {
  DateTime date;
  bool completed;
  String? note;

  HabitLog({
    required this.date,
    this.completed = true,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'completed': completed,
    'note': note,
  };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    date: DateTime.parse(json['date'] as String),
    completed: json['completed'] as bool? ?? true,
    note: json['note'] as String?,
  );
}

class Habit {
  final String id;
  String title;
  String description;
  String emoji;
  int colorValue;
  String category;
  final DateTime createdAt;
  List<HabitLog> logs;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.emoji = '🎯',
    this.colorValue = 0xFF7C4DFF,
    this.category = 'other',
    DateTime? createdAt,
    List<HabitLog>? logs,
  })  : createdAt = createdAt ?? DateTime.now(),
        logs = logs ?? [];

  int get currentStreak {
    if (logs.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final log = logs.where((l) {
        final lDate = DateTime(l.date.year, l.date.month, l.date.day);
        return lDate == dayStart && l.completed;
      }).toList();
      if (log.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    if (logs.isEmpty) return 0;
    final allLogs = List<HabitLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));
    int maxStreak = 0;
    int current = 0;
    DateTime? prev;
    for (final log in allLogs) {
      if (!log.completed) {
        current = 0;
        prev = null;
        continue;
      }
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      if (prev != null) {
        final diff = day.difference(prev).inDays;
        if (diff == 1) {
          current++;
        } else {
          current = 1;
        }
      } else {
        current = 1;
      }
      prev = day;
      if (current > maxStreak) maxStreak = current;
    }
    return maxStreak;
  }

  double completionRate(int days) {
    if (days <= 0 || logs.isEmpty) return 0;
    final today = DateTime.now();
    int completed = 0;
    int total = 0;
    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayLogs = logs.where((l) {
        final lDate = DateTime(l.date.year, l.date.month, l.date.day);
        return lDate == dayStart;
      }).toList();
      if (dayLogs.isNotEmpty && dayLogs.any((l) => l.completed)) {
        completed++;
      }
      total++;
    }
    return total > 0 ? completed / total : 0;
  }

  bool isCompletedOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return logs.any((l) {
      final lDate = DateTime(l.date.year, l.date.month, l.date.day);
      return lDate == dayStart && l.completed;
    });
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'colorValue': colorValue,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    emoji: json['emoji'] as String? ?? '🎯',
    colorValue: json['colorValue'] as int? ?? 0xFF7C4DFF,
    category: json['category'] as String? ?? 'other',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    logs: json['logs'] != null
        ? (json['logs'] as List).map((e) => HabitLog.fromJson(e as Map<String, dynamic>)).toList()
        : [],
  );
}

class CoachMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final CoachMessageType type;

  CoachMessage({
    required this.id,
    required this.content,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum CoachMessageType {
  encouragement,
  insight,
  milestone,
  tip,
}
