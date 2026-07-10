import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_conversation.dart';
import '../models/diary_entry.dart';
import '../models/memory_node.dart';
import '../models/canvas_project.dart';
import '../models/mood_analytics.dart';
import '../models/saved_prompt.dart';
import '../models/flash_card.dart';
import '../models/ritual.dart';
import '../models/context_attachment.dart';
import '../models/habit.dart';
import '../models/daily_briefing.dart';

class HiveService {
  static const _boxName = 'ai_chat_app';
  static const _convKey = 'conversations';
  static const _settingsKey = 'settings';
  static const _diaryKey = 'diary';
  static const _memoryKey = 'memories';
  static const _canvasKey = 'canvas_projects';
  static const _moodKey = 'mood_entries';
  static const _promptKey = 'saved_prompts';
  static const _graphKey = 'knowledge_graph';
  static const _flashCardKey = 'flash_cards';
  static const _ritualKey = 'rituals';
  static const _contextKey = 'context_attachments';
  static const _habitKey = 'habits';
  static const _dailyBriefingKey = 'daily_briefings';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveConversations(List<ChatConversation> conversations) async {
    final data = conversations.map((c) => c.toJson()).toList();
    await _box.put(_convKey, jsonEncode(data));
  }

  List<ChatConversation> loadConversations() {
    final raw = _box.get(_convKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _box.put(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic>? loadSettings() {
    final raw = _box.get(_settingsKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveDiaryEntries(List<DiaryEntry> entries) async {
    final data = entries.map((e) => e.toJson()).toList();
    await _box.put(_diaryKey, jsonEncode(data));
  }

  List<DiaryEntry> loadDiaryEntries() {
    final raw = _box.get(_diaryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMemories(List<MemoryNode> memories) async {
    final data = memories.map((m) => m.toJson()).toList();
    await _box.put(_memoryKey, jsonEncode(data));
  }

  List<MemoryNode> loadMemories() {
    final raw = _box.get(_memoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => MemoryNode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePrompts(List<SavedPrompt> prompts) async {
    final data = prompts.map((p) => p.toJson()).toList();
    await _box.put(_promptKey, jsonEncode(data));
  }

  List<SavedPrompt> loadPrompts() {
    final raw = _box.get(_promptKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SavedPrompt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveKnowledgeGraph(Map<String, dynamic> data) async {
    await _box.put(_graphKey, jsonEncode(data));
  }

  Map<String, dynamic>? loadKnowledgeGraph() {
    final raw = _box.get(_graphKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveFlashCards(List<FlashCard> cards) async {
    final data = cards.map((c) => c.toJson()).toList();
    await _box.put(_flashCardKey, jsonEncode(data));
  }

  List<FlashCard> loadFlashCards() {
    final raw = _box.get(_flashCardKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FlashCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRituals(List<Ritual> rituals) async {
    final data = rituals.map((r) => r.toJson()).toList();
    await _box.put(_ritualKey, jsonEncode(data));
  }

  List<Ritual> loadRituals() {
    final raw = _box.get(_ritualKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Ritual.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final data = habits.map((h) => h.toJson()).toList();
    await _box.put(_habitKey, jsonEncode(data));
  }

  List<Habit> loadHabits() {
    final raw = _box.get(_habitKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Habit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDailyBriefings(List<DailyBriefing> briefings) async {
    final data = briefings.map((b) => b.toJson()).toList();
    await _box.put(_dailyBriefingKey, jsonEncode(data));
  }

  List<DailyBriefing> loadDailyBriefings() {
    final raw = _box.get(_dailyBriefingKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => DailyBriefing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> saveCanvasProjects(List<CanvasProject> projects) async {
    final data = projects.map((p) => p.toJson()).toList();
    await _box.put(_canvasKey, jsonEncode(data));
  }

  List<CanvasProject> loadCanvasProjects() {
    final raw = _box.get(_canvasKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CanvasProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMoodEntries(List<MoodEntry> entries) async {
    final data = entries.map((e) => e.toJson()).toList();
    await _box.put(_moodKey, jsonEncode(data));
  }

  List<MoodEntry> loadMoodEntries() {
    final raw = _box.get(_moodKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveContextAttachments(
      Map<String, List<ContextAttachment>> data) async {
    final raw = data.map((k, v) => MapEntry(
          k,
          v.map((a) => a.toJson()).toList(),
        ));
    await _box.put(_contextKey, jsonEncode(raw));
  }

  Map<String, List<ContextAttachment>> loadContextAttachments() {
    final raw = _box.get(_contextKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(
          k,
          (v as List)
              .map((e) =>
                  ContextAttachment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
  }
}
