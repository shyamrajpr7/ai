import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ritual.dart';
import '../services/hive_service.dart';
import 'chat_provider.dart';

const _uuid = Uuid();

class RitualProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final ChatProvider _chatProvider;

  List<Ritual> _rituals = [];
  bool _initialized = false;
  bool _isGenerating = false;

  RitualProvider(this._hiveService, this._chatProvider);

  List<Ritual> get rituals => _rituals;
  bool get initialized => _initialized;
  bool get isGenerating => _isGenerating;

  List<Ritual> get todayRituals {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return _rituals.where((r) {
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      return rDate == todayStart;
    }).toList();
  }

  int get currentStreak {
    if (_rituals.isEmpty) return 0;
    var streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayRituals = _rituals.where((r) {
        final rDate = DateTime(r.date.year, r.date.month, r.date.day);
        return rDate == dayStart;
      }).toList();
      if (dayRituals.isEmpty) break;
      final allComplete = dayRituals.where((r) => r.type != 'journal').every((r) => r.completed);
      if (allComplete) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool get hasTodayRituals => todayRituals.isNotEmpty;

  Future<void> load() async {
    _rituals = _hiveService.loadRituals();
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleComplete(String id) async {
    final index = _rituals.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _rituals[index].completed = !_rituals[index].completed;
    _rituals[index].updatedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> saveJournalResponse(String id, String response) async {
    final index = _rituals.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _rituals[index].journalResponse = response;
    _rituals[index].updatedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> updateRitual(Ritual updated) async {
    final index = _rituals.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;
    _rituals[index] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> deleteRitual(String id) async {
    _rituals.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> resetToday() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    _rituals.removeWhere((r) {
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      return rDate == todayStart;
    });
    await _save();
    notifyListeners();
  }

  Future<void> generateDailyRituals() async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final conversations = _chatProvider.conversations;
      final recentMessages = conversations
          .expand((c) => c.messages)
          .where((m) => m.role == 'assistant' && m.content.isNotEmpty)
          .map((m) => m.content)
          .join('\n\n');

      final context = recentMessages.length > 6000
          ? recentMessages.substring(0, 6000)
          : recentMessages;

      final service = _chatProvider.createAIService();
      final systemPrompt = 'You are a ritual and habit designer. Generate '
          'personalized daily rituals based on the user\'s conversation history. '
          'Output only a JSON array of exactly 3 objects with fields: '
          '"type" ("challenge", "journal", "habit"), '
          '"title" (short name), '
          '"description" (1-2 sentences). '
          'The challenge should be actionable for the day. '
          'The journal prompt should be reflective. '
          'The habit should be a small daily practice.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message:
            'Generate daily rituals based on these conversations:\n"""\n$context\n"""',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
      }

      final raw = response.toString().trim();
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) {
        _isGenerating = false;
        notifyListeners();
        return;
      }

      final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> parsed = jsonDecode(jsonStr);

      final today = DateTime.now();
      await resetToday();

      for (final entry in parsed) {
        final e = entry as Map<String, dynamic>;
        _rituals.add(Ritual(
          id: _uuid.v4(),
          type: e['type'] as String? ?? 'habit',
          title: e['title'] as String? ?? 'Untitled',
          description: e['description'] as String? ?? '',
          date: today,
        ));
      }

      await _save();
      notifyListeners();
    } catch (_) {}

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveRituals(_rituals);
  }
}
