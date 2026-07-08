import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/hive_service.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class HabitProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;

  List<Habit> _habits = [];
  List<CoachMessage> _coachMessages = [];
  bool _initialized = false;
  bool _isGeneratingCoach = false;

  HabitProvider(this._hiveService, this._settingsProvider);

  List<Habit> get habits => _habits;
  List<CoachMessage> get coachMessages => _coachMessages;
  bool get initialized => _initialized;
  bool get isGeneratingCoach => _isGeneratingCoach;

  int get globalStreak {
    if (_habits.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      final allDone = _habits.every((h) => h.isCompletedOn(day));
      if (allDone) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  double get globalCompletionRate {
    if (_habits.isEmpty) return 0;
    final today = DateTime.now();
    int completed = 0;
    int total = 0;
    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final dayHabits = _habits.where((h) => h.logs.any((l) {
        final lDate = DateTime(l.date.year, l.date.month, l.date.day);
        return lDate == DateTime(day.year, day.month, day.day);
      }));
      for (final h in _habits) {
        if (h.isCompletedOn(day)) completed++;
        total++;
      }
    }
    return total > 0 ? completed / total : 0;
  }

  Future<void> load() async {
    _habits = _hiveService.loadHabits();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    await _save();
    notifyListeners();
  }

  Future<void> updateHabit(Habit updated) async {
    final idx = _habits.indexWhere((h) => h.id == updated.id);
    if (idx != -1) {
      _habits[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> toggleLog(String habitId, {DateTime? date}) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    final habit = _habits[idx];
    final day = date ?? DateTime.now();
    final dayStart = DateTime(day.year, day.month, day.day);

    final existingIdx = habit.logs.indexWhere((l) {
      final lDate = DateTime(l.date.year, l.date.month, l.date.day);
      return lDate == dayStart;
    });

    if (existingIdx != -1) {
      if (habit.logs[existingIdx].completed) {
        habit.logs.removeAt(existingIdx);
      } else {
        habit.logs[existingIdx].completed = true;
      }
    } else {
      habit.logs.add(HabitLog(date: dayStart, completed: true));
    }

    await _save();
    notifyListeners();
  }

  Future<void> generateCoachMessage() async {
    if (_isGeneratingCoach || _habits.isEmpty) return;
    _isGeneratingCoach = true;
    notifyListeners();

    try {
      final context = _buildCoachContext();
      final service = _createAIService();
      final systemPrompt = 'You are a supportive habit coach. Based on the user\'s habit data, '
          'generate a brief, personalized motivational message (1-3 sentences). '
          'Be encouraging and specific. Reference their actual habits and streaks. '
          'Output ONLY the message text, no labels or prefixes.';

      final buffer = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Generate a coaching message:\n$context',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
      }

      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        _coachMessages.insert(0, CoachMessage(
          id: _uuid.v4(),
          content: text,
          type: CoachMessageType.encouragement,
        ));
      }
    } catch (_) {}

    _isGeneratingCoach = false;
    notifyListeners();
  }

  String _buildCoachContext() {
    final buffer = StringBuffer();
    buffer.writeln('Habit Data:');
    for (final habit in _habits) {
      buffer.writeln('- ${habit.emoji} ${habit.title} (${habit.category})');
      buffer.writeln('  Current streak: ${habit.currentStreak} days');
      buffer.writeln('  Longest streak: ${habit.longestStreak} days');
      buffer.writeln('  30-day rate: ${(habit.completionRate(30) * 100).toStringAsFixed(0)}%');
    }
    buffer.writeln('Global streak: $globalStreak days');
    buffer.writeln('Global 30-day rate: ${(globalCompletionRate * 100).toStringAsFixed(0)}%');
    return buffer.toString();
  }

  AIService _createAIService() {
    final temp = min(_settingsProvider.temperature, 0.7);
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

  List<Map<String, dynamic>> getWeeklyData(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => _habits.first);
    if (habit == _habits.first && habit.id != habitId) return [];
    final today = DateTime.now();
    final data = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final done = habit.isCompletedOn(day);
      data.add({
        'date': day,
        'completed': done,
        'label': _dayLabel(day),
      });
    }
    return data;
  }

  String _dayLabel(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Future<void> _save() async {
    await _hiveService.saveHabits(_habits);
  }
}
