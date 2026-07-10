import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_briefing.dart';
import '../services/hive_service.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import 'habit_provider.dart';
import 'ritual_provider.dart';
import 'mood_provider.dart';
import 'flash_card_provider.dart';
import 'chat_provider.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class DailyBriefingProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;
  final HabitProvider _habitProvider;
  final RitualProvider _ritualProvider;
  final MoodProvider _moodProvider;
  final FlashCardProvider _flashCardProvider;
  final ChatProvider _chatProvider;

  DailyBriefing? _todayBriefing;
  List<DailyBriefing> _history = [];
  bool _initialized = false;
  bool _isGenerating = false;
  bool _isGeneratingInsight = false;

  DailyBriefing? get todayBriefing => _todayBriefing;
  List<DailyBriefing> get history => _history;
  bool get initialized => _initialized;
  bool get isGenerating => _isGenerating;
  bool get isGeneratingInsight => _isGeneratingInsight;

  DailyBriefingProvider(
    this._hiveService,
    this._settingsProvider,
    this._habitProvider,
    this._ritualProvider,
    this._moodProvider,
    this._flashCardProvider,
    this._chatProvider,
  );

  Future<void> load() async {
    _history = _hiveService.loadDailyBriefings();
    _todayBriefing = _history.where((b) => _isToday(b.date)).firstOrNull;
    _initialized = true;
    notifyListeners();
  }

  Future<void> generateBriefing() async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      final habits = _habitProvider.habits.map((h) {
        return HabitSummary(
          id: h.id,
          title: h.title,
          emoji: h.emoji,
          currentStreak: h.currentStreak,
          completed: h.isCompletedOn(now),
        );
      }).toList();

      final todayRituals = _ritualProvider.todayRituals.map((r) {
        return RitualSummary(
          id: r.id,
          type: r.type,
          title: r.title,
          completed: r.completed,
        );
      }).toList();

      MoodTrend? moodTrend;
      if (_moodProvider.weeklySummary != null) {
        final ws = _moodProvider.weeklySummary!;
        moodTrend = MoodTrend(
          dominantMood: ws.dominantMood,
          avgSentiment: ws.avgSentiment,
          avgEnergy: ws.avgEnergy,
          entryCount: ws.conversationCount,
          topTopics: ws.topTopics,
        );
      }

      final todayCards = _flashCardProvider.cards.where((c) {
        if (c.lastReviewedAt == null) return true;
        final lastReview = c.lastReviewedAt!;
        final daysSince = now.difference(lastReview).inDays;
        if (c.difficulty == 'hard' && daysSince >= 1) return true;
        if (c.difficulty == 'medium' && daysSince >= 3) return true;
        if (c.difficulty == 'easy' && daysSince >= 7) return true;
        return false;
      }).take(10).toList();

      final flashCardsDue = todayCards.map((c) {
        return FlashCardDue(
          id: c.id,
          question: c.question,
          difficulty: c.difficulty,
          reviewCount: c.reviewCount,
          successRate: c.successRate,
        );
      }).toList();

      final todayConversations = _chatProvider.conversations.where((c) {
        return _isToday(c.updatedAt);
      }).length;

      final briefing = DailyBriefing(
        id: _uuid.v4(),
        date: now,
        habits: habits,
        rituals: todayRituals,
        moodTrend: moodTrend,
        flashCardsDue: flashCardsDue,
        totalConversationsToday: todayConversations,
      );

      _todayBriefing = briefing;
      _history.removeWhere((b) => _isToday(b.date));
      _history.insert(0, briefing);
      await _save();
    } catch (_) {}

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> generateAiInsight() async {
    if (_isGeneratingInsight || _todayBriefing == null) return;
    _isGeneratingInsight = true;
    notifyListeners();

    try {
      final b = _todayBriefing!;
      final buffer = StringBuffer();
      buffer.writeln('User\'s Daily Data:');
      buffer.writeln(
          'Habits: ${b.completedHabits}/${b.totalHabits} completed');
      buffer.writeln(
          'Rituals: ${b.completedRituals}/${b.totalRituals} completed');
      if (b.moodTrend != null) {
        buffer.writeln('Mood: ${b.moodTrend!.dominantMood}');
        buffer.writeln(
            'Sentiment: ${b.moodTrend!.avgSentiment.toStringAsFixed(1)}/10');
        buffer.writeln(
            'Energy: ${b.moodTrend!.avgEnergy.toStringAsFixed(1)}/10');
        buffer.writeln('Topics: ${b.moodTrend!.topTopics.join(", ")}');
      }
      buffer.writeln('Flash cards due: ${b.flashCardsDue.length}');
      buffer.writeln('Conversations today: ${b.totalConversationsToday}');

      final service = _createAIService();
      final systemPrompt =
          'You are a supportive daily wellness coach. Based on the user\'s daily data, '
          'generate a brief, personalized insight (2-4 sentences). '
          'Be warm, specific, and actionable. Reference their actual data. '
          'Output ONLY the insight text, no labels or prefixes.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Generate a daily insight:\n${buffer.toString()}',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
      }

      final text = response.toString().trim();
      if (text.isNotEmpty) {
        _todayBriefing = DailyBriefing(
          id: _todayBriefing!.id,
          date: _todayBriefing!.date,
          habits: _todayBriefing!.habits,
          rituals: _todayBriefing!.rituals,
          moodTrend: _todayBriefing!.moodTrend,
          flashCardsDue: _todayBriefing!.flashCardsDue,
          aiInsight: text,
          totalConversationsToday: _todayBriefing!.totalConversationsToday,
          createdAt: _todayBriefing!.createdAt,
        );

        final idx = _history.indexWhere((b) => b.id == _todayBriefing!.id);
        if (idx != -1) _history[idx] = _todayBriefing!;
        await _save();
      }
    } catch (_) {}

    _isGeneratingInsight = false;
    notifyListeners();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
    await _hiveService.saveDailyBriefings(_history);
  }
}
