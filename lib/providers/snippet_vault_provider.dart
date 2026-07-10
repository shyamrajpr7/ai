import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/code_snippet.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class SnippetVaultProvider extends ChangeNotifier {
  final HiveService _hiveService;

  List<CodeSnippet> _snippets = [];
  bool _initialized = false;
  String _searchQuery = '';
  String? _activeLanguage;
  String? _activeTag;

  List<CodeSnippet> get snippets => _snippets;
  bool get initialized => _initialized;
  String get searchQuery => _searchQuery;
  String? get activeLanguage => _activeLanguage;
  String? get activeTag => _activeTag;

  List<CodeSnippet> get filteredSnippets {
    var result = _snippets;
    if (_activeLanguage != null) {
      result = result.where((s) => s.language == _activeLanguage).toList();
    }
    if (_activeTag != null) {
      result = result.where((s) => s.tags.contains(_activeTag)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
          s.title.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          (s.description?.toLowerCase().contains(q) ?? false) ||
          s.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return result..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<String> get allLanguages {
    final langs = _snippets.map((s) => s.language).toSet().toList();
    return langs..sort();
  }

  List<String> get allTags {
    final tags = <String>{};
    for (final s in _snippets) {
      tags.addAll(s.tags);
    }
    return tags.toList()..sort();
  }

  int get totalCopies => _snippets.fold(0, (sum, s) => sum + s.copyCount);

  SnippetVaultProvider(this._hiveService);

  Future<void> load() async {
    _snippets = _hiveService.loadCodeSnippets();
    _initialized = true;
    notifyListeners();
  }

  Future<void> addSnippet({
    required String title,
    required String code,
    String language = 'dart',
    String? description,
    List<String> tags = const [],
    String? sourceConversationId,
  }) async {
    final snippet = CodeSnippet(
      id: _uuid.v4(),
      title: title,
      code: code,
      language: language,
      description: description,
      tags: tags,
      sourceConversationId: sourceConversationId,
    );
    _snippets.add(snippet);
    await _save();
    notifyListeners();
  }

  Future<void> updateSnippet(CodeSnippet updated) async {
    final idx = _snippets.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _snippets[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteSnippet(String id) async {
    _snippets.removeWhere((s) => s.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> incrementCopyCount(String id) async {
    final idx = _snippets.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _snippets[idx].copyCount++;
      _snippets[idx].updatedAt = DateTime.now();
      await _save();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveLanguage(String? language) {
    _activeLanguage = language;
    notifyListeners();
  }

  void setActiveTag(String? tag) {
    _activeTag = tag;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveCodeSnippets(_snippets);
  }
}
