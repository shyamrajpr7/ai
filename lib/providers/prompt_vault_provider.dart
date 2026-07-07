import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_prompt.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class PromptVaultProvider extends ChangeNotifier {
  final HiveService _hiveService;
  List<SavedPrompt> _prompts = [];
  String _searchQuery = '';
  String? _activeTag;

  List<SavedPrompt> get prompts => _prompts;

  List<SavedPrompt> get filteredPrompts {
    var result = _prompts;
    if (_activeTag != null) {
      result = result.where((p) => p.tags.contains(_activeTag)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.content.toLowerCase().contains(q)
      ).toList();
    }
    return result..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<String> get allTags {
    final tagSet = <String>{};
    for (final p in _prompts) {
      tagSet.addAll(p.tags);
    }
    return tagSet.toList()..sort();
  }

  String get searchQuery => _searchQuery;
  String? get activeTag => _activeTag;

  PromptVaultProvider(this._hiveService);

  Future<void> load() async {
    _prompts = _hiveService.loadPrompts();
    notifyListeners();
  }

  Future<void> addPrompt({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final prompt = SavedPrompt(
      id: _uuid.v4(),
      title: title,
      content: content,
      tags: tags,
    );
    _prompts.add(prompt);
    await _save();
    notifyListeners();
  }

  Future<void> updatePrompt(SavedPrompt updated) async {
    final idx = _prompts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _prompts[idx] = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deletePrompt(String id) async {
    _prompts.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> incrementUsage(String id) async {
    final idx = _prompts.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _prompts[idx] = _prompts[idx].copyWith(
        usageCount: _prompts[idx].usageCount + 1,
      );
      await _save();
      notifyListeners();
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

  Future<void> addTagToPrompt(String promptId, String tag) async {
    final idx = _prompts.indexWhere((p) => p.id == promptId);
    if (idx != -1 && !_prompts[idx].tags.contains(tag)) {
      final updatedTags = [..._prompts[idx].tags, tag];
      _prompts[idx] = _prompts[idx].copyWith(tags: updatedTags);
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeTagFromPrompt(String promptId, String tag) async {
    final idx = _prompts.indexWhere((p) => p.id == promptId);
    if (idx != -1) {
      final updatedTags = _prompts[idx].tags.where((t) => t != tag).toList();
      _prompts[idx] = _prompts[idx].copyWith(tags: updatedTags);
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    await _hiveService.savePrompts(_prompts);
  }
}
