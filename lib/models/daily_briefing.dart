class DailyBriefing {
  final String id;
  final DateTime date;
  final List<HabitSummary> habits;
  final List<RitualSummary> rituals;
  final MoodTrend? moodTrend;
  final List<FlashCardDue> flashCardsDue;
  final String? aiInsight;
  final int totalConversationsToday;
  final DateTime? createdAt;

  DailyBriefing({
    required this.id,
    required this.date,
    this.habits = const [],
    this.rituals = const [],
    this.moodTrend,
    this.flashCardsDue = const [],
    this.aiInsight,
    this.totalConversationsToday = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get completedHabits => habits.where((h) => h.completed).length;
  int get completedRituals => rituals.where((r) => r.completed).length;
  int get totalHabits => habits.length;
  int get totalRituals => rituals.length;
  double get completionRate {
    final total = totalHabits + totalRituals;
    if (total == 0) return 0;
    return (completedHabits + completedRituals) / total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'rituals': rituals.map((r) => r.toJson()).toList(),
        'moodTrend': moodTrend?.toJson(),
        'flashCardsDue': flashCardsDue.map((f) => f.toJson()).toList(),
        'aiInsight': aiInsight,
        'totalConversationsToday': totalConversationsToday,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory DailyBriefing.fromJson(Map<String, dynamic> json) => DailyBriefing(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        habits: (json['habits'] as List?)
                ?.map((e) => HabitSummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        rituals: (json['rituals'] as List?)
                ?.map((e) => RitualSummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        moodTrend: json['moodTrend'] != null
            ? MoodTrend.fromJson(json['moodTrend'] as Map<String, dynamic>)
            : null,
        flashCardsDue: (json['flashCardsDue'] as List?)
                ?.map((e) => FlashCardDue.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        aiInsight: json['aiInsight'] as String?,
        totalConversationsToday: json['totalConversationsToday'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class HabitSummary {
  final String id;
  final String title;
  final String emoji;
  final int currentStreak;
  final bool completed;

  HabitSummary({
    required this.id,
    required this.title,
    required this.emoji,
    required this.currentStreak,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'currentStreak': currentStreak,
        'completed': completed,
      };

  factory HabitSummary.fromJson(Map<String, dynamic> json) => HabitSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String? ?? '🎯',
        currentStreak: json['currentStreak'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}

class RitualSummary {
  final String id;
  final String type;
  final String title;
  final bool completed;

  RitualSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'completed': completed,
      };

  factory RitualSummary.fromJson(Map<String, dynamic> json) => RitualSummary(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
      );
}

class MoodTrend {
  final String dominantMood;
  final double avgSentiment;
  final double avgEnergy;
  final int entryCount;
  final List<String> topTopics;

  MoodTrend({
    required this.dominantMood,
    required this.avgSentiment,
    required this.avgEnergy,
    required this.entryCount,
    required this.topTopics,
  });

  Map<String, dynamic> toJson() => {
        'dominantMood': dominantMood,
        'avgSentiment': avgSentiment,
        'avgEnergy': avgEnergy,
        'entryCount': entryCount,
        'topTopics': topTopics,
      };

  factory MoodTrend.fromJson(Map<String, dynamic> json) => MoodTrend(
        dominantMood: json['dominantMood'] as String? ?? 'curious',
        avgSentiment: (json['avgSentiment'] as num?)?.toDouble() ?? 5.0,
        avgEnergy: (json['avgEnergy'] as num?)?.toDouble() ?? 5.0,
        entryCount: json['entryCount'] as int? ?? 0,
        topTopics: (json['topTopics'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class FlashCardDue {
  final String id;
  final String question;
  final String difficulty;
  final int reviewCount;
  final double successRate;

  FlashCardDue({
    required this.id,
    required this.question,
    required this.difficulty,
    required this.reviewCount,
    required this.successRate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'difficulty': difficulty,
        'reviewCount': reviewCount,
        'successRate': successRate,
      };

  factory FlashCardDue.fromJson(Map<String, dynamic> json) => FlashCardDue(
        id: json['id'] as String,
        question: json['question'] as String,
        difficulty: json['difficulty'] as String? ?? 'medium',
        reviewCount: json['reviewCount'] as int? ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble() ?? 0,
      );
}
