import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/flash_card.dart';
import '../models/chat_conversation.dart';
import '../services/hive_service.dart';
import 'chat_provider.dart';

const _uuid = Uuid();

class FlashCardProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final ChatProvider _chatProvider;

  List<FlashCard> _cards = [];
  bool _initialized = false;
  bool _isGenerating = false;
  String _searchQuery = '';
  String? _activeTag;
  String? _difficultyFilter;

  List<FlashCard> get cards => _cards;
  bool get initialized => _initialized;
  bool get isGenerating => _isGenerating;
  String get searchQuery => _searchQuery;
  String? get activeTag => _activeTag;
  String? get difficultyFilter => _difficultyFilter;

  List<FlashCard> get filteredCards {
    var result = _cards;
    if (_activeTag != null) {
      result = result.where((c) => c.tags.contains(_activeTag)).toList();
    }
    if (_difficultyFilter != null) {
      result = result.where((c) => c.difficulty == _difficultyFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
        c.question.toLowerCase().contains(q) ||
        c.answer.toLowerCase().contains(q)
      ).toList();
    }
    return result..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<String> get allTags {
    final tagSet = <String>{};
    for (final c in _cards) {
      tagSet.addAll(c.tags);
    }
    return tagSet.toList()..sort();
  }

  int get totalReviews =>
      _cards.fold(0, (sum, c) => sum + c.reviewCount);
  double get averageSuccessRate {
    final reviewed = _cards.where((c) => c.reviewCount > 0).toList();
    if (reviewed.isEmpty) return 0;
    return reviewed.fold(0.0, (sum, c) => sum + c.successRate) / reviewed.length;
  }

  FlashCardProvider(this._hiveService, this._chatProvider);

  Future<void> load() async {
    _cards = _hiveService.loadFlashCards();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addCard({
    required String question,
    required String answer,
    List<String> tags = const [],
    String? sourceConversationId,
    String? sourceConversationTitle,
    String difficulty = 'medium',
  }) async {
    final card = FlashCard(
      id: _uuid.v4(),
      question: question,
      answer: answer,
      tags: tags,
      sourceConversationId: sourceConversationId,
      sourceConversationTitle: sourceConversationTitle,
      difficulty: difficulty,
    );
    _cards.add(card);
    await _save();
    notifyListeners();
  }

  Future<void> updateCard(FlashCard updated) async {
    final idx = _cards.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _cards[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> deleteCards(List<String> ids) async {
    _cards.removeWhere((c) => ids.contains(c.id));
    await _save();
    notifyListeners();
  }

  Future<void> markReviewed(String id, bool correct) async {
    final idx = _cards.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _cards[idx] = _cards[idx].copyWith(
        reviewCount: _cards[idx].reviewCount + 1,
        correctCount: correct
            ? _cards[idx].correctCount + 1
            : _cards[idx].correctCount,
        lastReviewedAt: DateTime.now(),
      );
      await _save();
      notifyListeners();
    }
  }

  Future<void> generateFromConversation(ChatConversation conv) async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final messages = conv.messages
          .where((m) => m.role == 'assistant' && m.content.isNotEmpty)
          .map((m) => m.content)
          .join('\n\n');

      if (messages.length > 8000) {
        messages.substring(0, 8000);
      }

      final service = _chatProvider.createAIService();
      final systemPrompt = 'You are a flashcard generator. Extract key concepts '
          'from the conversation and create flashcards. Output only a JSON array '
          'of objects with fields: "question", "answer", "tags" (array of strings), '
          '"difficulty" ("easy"/"medium"/"hard"). Generate 3-8 flashcards.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message:
            'Generate flashcards from this conversation:\n"""\n$messages\n"""',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
      }

      final raw = response.toString().trim();
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) return;

      final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> parsed = jsonDecode(jsonStr);
      for (final entry in parsed) {
        final e = entry as Map<String, dynamic>;
        final tags = List<String>.from(e['tags'] as List? ?? []);
        if (conv.title != 'New Chat') {
          tags.add(conv.title);
        }
        _cards.add(FlashCard(
          id: _uuid.v4(),
          question: e['question'] as String? ?? '',
          answer: e['answer'] as String? ?? '',
          tags: tags,
          sourceConversationId: conv.id,
          sourceConversationTitle: conv.title,
          difficulty: e['difficulty'] as String? ?? 'medium',
        ));
      }

      await _save();
      notifyListeners();
    } catch (_) {}

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> generateFromAllConversations() async {
    for (final conv in _chatProvider.conversations) {
      await generateFromConversation(conv);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveTag(String? tag) {
    _activeTag = tag;
    notifyListeners();
  }

  void setDifficultyFilter(String? difficulty) {
    _difficultyFilter = difficulty;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveFlashCards(_cards);
  }
}
