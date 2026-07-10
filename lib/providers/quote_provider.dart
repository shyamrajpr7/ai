import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_quote.dart';
import '../services/hive_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class QuoteProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;

  List<DailyQuote> _quotes = [];
  bool _initialized = false;
  bool _isGenerating = false;
  String _selectedCategory = 'all';

  List<DailyQuote> get quotes => _quotes;
  bool get initialized => _initialized;
  bool get isGenerating => _isGenerating;
  String get selectedCategory => _selectedCategory;

  List<DailyQuote> get favorites =>
      _quotes.where((q) => q.isFavorite).toList();

  List<DailyQuote> get filteredQuotes {
    if (_selectedCategory == 'all') return _quotes;
    return _quotes.where((q) => q.category == _selectedCategory).toList();
  }

  List<String> get allCategories {
    final cats = _quotes.map((q) => q.category).toSet().toList();
    return cats..sort();
  }

  DailyQuote? get todayQuote {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _quotes.where((q) {
      final qDate = DateTime(q.generatedAt.year, q.generatedAt.month, q.generatedAt.day);
      return qDate == todayStart;
    }).firstOrNull;
  }

  QuoteProvider(this._hiveService, this._settingsProvider);

  Future<void> load() async {
    _quotes = _hiveService.loadDailyQuotes();
    _initialized = true;
    notifyListeners();
  }

  Future<void> generateQuote({String category = 'motivation'}) async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final service = _createAIService();
      final systemPrompt =
          'You are a wise and thoughtful quote generator. Generate a single, '
          'original, and profound quote. Output ONLY a JSON object with:\n'
          '- "text": the quote text\n'
          '- "author": a plausible author name or "Nexus AI"\n\n'
          'Return ONLY valid JSON, no markdown or explanation.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Generate a $category quote.',
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

      final quote = DailyQuote(
        id: _uuid.v4(),
        text: json['text'] as String? ?? '',
        author: json['author'] as String? ?? 'Nexus AI',
        category: category,
      );

      _quotes.insert(0, quote);
      await _save();
    } catch (_) {}

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final idx = _quotes.indexWhere((q) => q.id == id);
    if (idx != -1) {
      _quotes[idx].isFavorite = !_quotes[idx].isFavorite;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteQuote(String id) async {
    _quotes.removeWhere((q) => q.id == id);
    await _save();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
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
    await _hiveService.saveDailyQuotes(_quotes);
  }
}
