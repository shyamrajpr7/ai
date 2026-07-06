import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_conversation.dart';
import '../models/diary_entry.dart';
import '../models/memory_node.dart';

class HiveService {
  static const _boxName = 'ai_chat_app';
  static const _convKey = 'conversations';
  static const _settingsKey = 'settings';
  static const _diaryKey = 'diary';
  static const _memoryKey = 'memories';

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

  Future<void> clearAll() async {
    await _box.clear();
  }
}
