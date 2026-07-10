import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../services/hive_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class JournalProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;

  List<JournalEntry> _entries = [];
  bool _initialized = false;
  bool _isAnalyzing = false;
  String _searchQuery = '';

  List<JournalEntry> get entries => _entries;
  bool get initialized => _initialized;
  bool get isAnalyzing => _isAnalyzing;
  String get searchQuery => _searchQuery;

  List<JournalEntry> get filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final q = _searchQuery.toLowerCase();
    return _entries.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.content.toLowerCase().contains(q) ||
        e.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  List<JournalEntry> get recentEntries => _entries.take(5).toList();

  Map<String, int> get moodDistribution {
    final dist = <String, int>{};
    for (final e in _entries) {
      if (e.mood != null) {
        dist[e.mood!] = (dist[e.mood!] ?? 0) + 1;
      }
    }
    return dist;
  }

  JournalProvider(this._hiveService, this._settingsProvider);

  Future<void> load() async {
    _entries = _hiveService.loadJournalEntries();
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _initialized = true;
    notifyListeners();
  }

  Future<void> addEntry({
    required String title,
    required String content,
    bool isVoiceInput = false,
    List<String> tags = const [],
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      title: title,
      content: content,
      tags: tags,
      isVoiceInput: isVoiceInput,
    );
    _entries.insert(0, entry);
    await _save();
    notifyListeners();
  }

  Future<void> updateEntry(JournalEntry updated) async {
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _entries[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> analyzeEntry(String id) async {
    if (_isAnalyzing) return;
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      final entry = _entries[idx];
      final service = _createAIService();
      final systemPrompt =
          'You are a journal analyst. Analyze this journal entry and return a JSON object with:\n'
          '- "mood": one word (happy, sad, anxious, peaceful, excited, frustrated, grateful, reflective)\n'
          '- "moodScore": number 1-10\n'
          '- "summary": 1-2 sentence summary\n'
          '- "tags": array of 2-4 relevant tags\n'
          'Return ONLY valid JSON.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Title: ${entry.title}\n\nContent: ${entry.content}',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
      }

      final raw = response.toString().trim();
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return;

      final json = jsonDecode(raw.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

      _entries[idx] = JournalEntry(
        id: entry.id,
        title: entry.title,
        content: entry.content,
        aiSummary: json['summary'] as String?,
        mood: json['mood'] as String?,
        moodScore: (json['moodScore'] as num?)?.toDouble(),
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? entry.tags,
        isVoiceInput: entry.isVoiceInput,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );

      await _save();
    } catch (_) {}

    _isAnalyzing = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
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
    await _hiveService.saveJournalEntries(_entries);
  }
}
