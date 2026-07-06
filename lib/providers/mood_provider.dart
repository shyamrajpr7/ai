import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_analytics.dart';
import '../models/chat_conversation.dart';
import '../services/hive_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class MoodProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;

  List<MoodEntry> _entries = [];
  bool _isAnalyzing = false;
  bool _initialized = false;

  List<MoodEntry> get entries => _entries;
  bool get isAnalyzing => _isAnalyzing;
  bool get initialized => _initialized;

  MoodProvider(this._hiveService, this._settingsProvider);

  Future<void> load() async {
    _entries = _hiveService.loadMoodEntries();
    _initialized = true;
    notifyListeners();
  }

  MoodSummary? get weeklySummary {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekEntries = _entries.where((e) =>
        e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(weekEnd)).toList();

    if (weekEntries.isEmpty) return null;

    final moodCounts = <String, int>{};
    final topicCounts = <String, int>{};
    double totalSentiment = 0;
    double totalEnergy = 0;

    for (final e in weekEntries) {
      moodCounts[e.dominantMood] = (moodCounts[e.dominantMood] ?? 0) + 1;
      totalSentiment += e.sentimentScore;
      totalEnergy += e.energyLevel;
      for (final t in e.topics) {
        topicCounts[t] = (topicCounts[t] ?? 0) + 1;
      }
    }

    final dominantMood = moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final topTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MoodSummary(
      weekStart: weekStart,
      dominantMood: dominantMood,
      avgSentiment: totalSentiment / weekEntries.length,
      avgEnergy: totalEnergy / weekEntries.length,
      topTopics: topTopics.take(10).map((e) => e.key).toList(),
      conversationCount: weekEntries.length,
    );
  }

  List<MoodSummary> get weeklyHistory {
    final byWeek = <int, List<MoodEntry>>{};
    for (final e in _entries) {
      final weekStart = e.date.subtract(Duration(days: e.date.weekday - 1));
      final key = weekStart.millisecondsSinceEpoch ~/ (Duration.millisecondsPerDay * 7);
      byWeek.putIfAbsent(key, () => []).add(e);
    }

    return byWeek.entries.map((e) {
      final entries = e.value;
      final moodCounts = <String, int>{};
      final topicCounts = <String, int>{};
      double totalSentiment = 0;
      double totalEnergy = 0;

      for (final entry in entries) {
        moodCounts[entry.dominantMood] = (moodCounts[entry.dominantMood] ?? 0) + 1;
        totalSentiment += entry.sentimentScore;
        totalEnergy += entry.energyLevel;
        for (final t in entry.topics) {
          topicCounts[t] = (topicCounts[t] ?? 0) + 1;
        }
      }

      final dominantMood = moodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final topTopics = topicCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return MoodSummary(
        weekStart: entries.first.date.subtract(
            Duration(days: entries.first.date.weekday - 1)),
        dominantMood: dominantMood,
        avgSentiment: totalSentiment / entries.length,
        avgEnergy: totalEnergy / entries.length,
        topTopics: topTopics.take(10).map((e) => e.key).toList(),
        conversationCount: entries.length,
      );
    }).toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
  }

  Future<void> analyzeConversations(List<ChatConversation> conversations) async {
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    notifyListeners();

    final existingIds = _entries.map((e) => e.conversationId).toSet();
    final toAnalyze = conversations
        .where((c) => !existingIds.contains(c.id) && c.messages.isNotEmpty)
        .toList();

    for (final conv in toAnalyze) {
      try {
        final entry = await _analyzeConversation(conv);
        if (entry != null) {
          _entries.add(entry);
        }
      } catch (_) {}
    }

    await _save();
    _isAnalyzing = false;
    notifyListeners();
  }

  Future<MoodEntry?> _analyzeConversation(ChatConversation conv) async {
    final transcript = conv.messages
        .map((m) => '${m.role == 'user' ? 'User' : 'AI'}: ${m.content.substring(0, m.content.length > 300 ? 300 : m.content.length)}')
        .join('\n');

    final prompt = 'Analyze this conversation and return a JSON object with:\n'
        '- "mood": one word from [analytical, creative, curious, stressed, joyful, anxious, focused, playful, reflective, energetic]\n'
        '- "sentiment": a number 1-10\n'
        '- "energy": a number 1-10\n'
        '- "topics": array of 2-4 key topic keywords\n'
        '- "summary": one short sentence describing the conversation\n\n'
        'Conversation:\n$transcript\n\n'
        'Return ONLY valid JSON with no markdown or explanation:\n'
        '{"mood":"...","sentiment":N,"energy":N,"topics":["...","..."],"summary":"..."}';

    try {
      final aiService = _createAIService();
      final response = StringBuffer();
      await for (final chunk in aiService.streamResponse(
        message: prompt,
        history: [],
        systemPrompt: 'You are a conversation analyst. Return only valid JSON.',
      )) {
        response.write(chunk);
      }

      final raw = response.toString().trim();
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;

      final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      // ignore: depend_on_referenced_packages
      final json = (jsonDecode(jsonStr) as Map<String, dynamic>);

      return MoodEntry(
        id: _uuid.v4(),
        conversationId: conv.id,
        conversationTitle: conv.title,
        date: conv.updatedAt,
        dominantMood: (json['mood'] as String?)?.toLowerCase() ?? 'curious',
        sentimentScore: ((json['sentiment'] as num?)?.toDouble() ?? 5.0)
            .clamp(1, 10),
        energyLevel: ((json['energy'] as num?)?.toDouble() ?? 5.0)
            .clamp(1, 10),
        topics: (json['topics'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ?? ['general'],
        summary: json['summary'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  AIService _createAIService() {
    final temp = _settingsProvider.temperature;
    if (_settingsProvider.backend == BackendType.groq) {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel, temperature: temp);
    } else if (_settingsProvider.backend == BackendType.claude) {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      return ClaudeService(apiKey: apiKey, model: _settingsProvider.claudeModel, temperature: temp);
    } else {
      return OllamaService(
        endpoint: _settingsProvider.ollamaEndpoint,
        model: _settingsProvider.ollamaModel,
        temperature: temp,
      );
    }
  }

  Future<void> _save() async {
    await _hiveService.saveMoodEntries(_entries);
  }
}

// jsonDecode is in dart:convert