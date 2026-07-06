import 'package:flutter/material.dart';

class MoodEntry {
  final String id;
  final String conversationId;
  final String conversationTitle;
  final DateTime date;
  final String dominantMood;
  final double sentimentScore;
  final double energyLevel;
  final List<String> topics;
  final String summary;

  MoodEntry({
    required this.id,
    required this.conversationId,
    required this.conversationTitle,
    required this.date,
    required this.dominantMood,
    required this.sentimentScore,
    required this.energyLevel,
    required this.topics,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'conversationTitle': conversationTitle,
    'date': date.toIso8601String(),
    'dominantMood': dominantMood,
    'sentimentScore': sentimentScore,
    'energyLevel': energyLevel,
    'topics': topics,
    'summary': summary,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    conversationTitle: json['conversationTitle'] as String? ?? 'Chat',
    date: DateTime.parse(json['date'] as String),
    dominantMood: json['dominantMood'] as String,
    sentimentScore: (json['sentimentScore'] as num).toDouble(),
    energyLevel: (json['energyLevel'] as num).toDouble(),
    topics: (json['topics'] as List<dynamic>).map((e) => e as String).toList(),
    summary: json['summary'] as String? ?? '',
  );
}

class MoodSummary {
  final DateTime weekStart;
  final String dominantMood;
  final double avgSentiment;
  final double avgEnergy;
  final List<String> topTopics;
  final int conversationCount;

  MoodSummary({
    required this.weekStart,
    required this.dominantMood,
    required this.avgSentiment,
    required this.avgEnergy,
    required this.topTopics,
    required this.conversationCount,
  });
}

class MoodColor {
  static Color forMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'analytical':
        return const Color(0xFF448AFF);
      case 'creative':
        return const Color(0xFF7C4DFF);
      case 'curious':
        return const Color(0xFF00BCD4);
      case 'stressed':
        return const Color(0xFFFF5252);
      case 'joyful':
        return const Color(0xFFFFD740);
      case 'anxious':
        return const Color(0xFFFF6D00);
      case 'focused':
        return const Color(0xFF00E676);
      case 'playful':
        return const Color(0xFFE040FB);
      case 'reflective':
        return const Color(0xFF78909C);
      case 'energetic':
        return const Color(0xFFFF4081);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  static String emojiForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'analytical': return '🔍';
      case 'creative': return '🎨';
      case 'curious': return '🤔';
      case 'stressed': return '😰';
      case 'joyful': return '😊';
      case 'anxious': return '😟';
      case 'focused': return '🎯';
      case 'playful': return '😜';
      case 'reflective': return '🧘';
      case 'energetic': return '⚡';
      default: return '💬';
    }
  }
}
