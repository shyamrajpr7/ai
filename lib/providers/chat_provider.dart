import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/ollama_service.dart';
import '../services/claude_service.dart';
import '../services/web_search_service.dart';
import '../services/image_gen_service.dart';
import '../services/video_gen_service.dart';
import '../services/hive_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class ArenaModelConfig {
  final String id;
  final String label;
  bool enabled;

  ArenaModelConfig({
    required this.id,
    required this.label,
    this.enabled = true,
  });
}

class ArenaResult {
  final String modelId;
  final String modelLabel;
  String content;
  bool isComplete;
  String? error;
  DateTime? startTime;
  DateTime? firstTokenTime;
  DateTime? endTime;

  ArenaResult({
    required this.modelId,
    required this.modelLabel,
    this.content = '',
    this.isComplete = false,
    this.error,
    this.startTime,
    this.firstTokenTime,
    this.endTime,
  });

  Duration? get elapsed {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  double? get charsPerSecond {
    if (elapsed == null || elapsed!.inSeconds == 0) return null;
    return content.length / elapsed!.inMilliseconds * 1000;
  }

  Duration? get firstTokenLatency {
    if (startTime == null || firstTokenTime == null) return null;
    return firstTokenTime!.difference(startTime!);
  }
}

class ChatProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SettingsProvider _settingsProvider;

  List<ChatConversation> _conversations = [];
  String? _currentConversationId;
  bool _isProcessing = false;
  String _currentResponse = '';
  String? _errorMessage;
  bool _initialized = false;

  List<ChatConversation> get conversations => _conversations;
  bool get isProcessing => _isProcessing;
  String get currentResponse => _currentResponse;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  ChatConversation? get currentConversation {
    final idx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    return idx != -1 ? _conversations[idx] : null;
  }

  ChatProvider(this._hiveService, this._settingsProvider);

  Future<void> load() async {
    _conversations = _hiveService.loadConversations();
    if (_conversations.isNotEmpty) {
      _currentConversationId = _conversations.first.id;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> createConversation() async {
    final conv = ChatConversation(id: _uuid.v4());
    _conversations.insert(0, conv);
    _currentConversationId = conv.id;
    _currentResponse = '';
    _errorMessage = null;
    await _save();
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    if (_currentConversationId == id) {
      _currentConversationId =
          _conversations.isNotEmpty ? _conversations.first.id : null;
    }
    await _save();
    notifyListeners();
  }

  Future<void> renameConversation(String id, String title) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _conversations[idx].title = title;
      await _save();
      notifyListeners();
    }
  }

  void selectConversation(String id) {
    _currentConversationId = id;
    _currentResponse = '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? imageBase64}) async {
    if (text.trim().isEmpty && imageBase64 == null) return;
    if (_isProcessing) return;

    if (_currentConversationId == null) {
      await createConversation();
    }

    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;

    final conv = _conversations[convIdx];

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      role: 'user',
      timestamp: DateTime.now(),
      imageBase64: imageBase64,
    );
    conv.messages.add(userMsg);
    conv.updatedAt = DateTime.now();

    _isProcessing = true;
    _currentResponse = '';
    _errorMessage = null;
    notifyListeners();

    try {
      String webSearchContext = '';
      if (_settingsProvider.webSearchEnabled) {
        try {
          final searchApiKey = dotenv.env['TAVILY_API_KEY'] ?? '';
          if (searchApiKey.isNotEmpty) {
            String searchQuery = text;
            if (imageBase64 != null && text.trim().isEmpty) {
              searchQuery = 'Identify this image and describe what is in it';
            }
            final searchService = WebSearchService(apiKey: searchApiKey);
            webSearchContext = await searchService.search(searchQuery);
          }
        } catch (e) {
          debugPrint('Web search failed: $e');
        }
      }

      final history = conv.messages
          .where((m) => m.status != MessageStatus.error)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final aiService = createAIService();
      final systemPrompt = _settingsProvider.activePersona.systemPrompt;
      final fullResponse = StringBuffer();

      await for (final chunk in aiService.streamResponse(
        message: text,
        history: history,
        webSearchContext: webSearchContext,
        imageBase64: imageBase64,
        systemPrompt: systemPrompt,
      )) {
        fullResponse.write(chunk);
        _currentResponse = fullResponse.toString();
        notifyListeners();
      }

      final result = fullResponse.toString();
      if (result.isNotEmpty) {
        final assistantMsg = ChatMessage(
          id: _uuid.v4(),
          content: result,
          role: 'assistant',
          timestamp: DateTime.now(),
        );
        conv.messages.add(assistantMsg);

        if (conv.title == 'New Chat' && conv.messages.length >= 2) {
          conv.title =
              text.length > 30 ? '${text.substring(0, 27)}...' : text;
        }
      }

      _isProcessing = false;
      _currentResponse = '';
      await _save();
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Failed to get response. Tap to retry.';
      notifyListeners();
    }
  }

  Future<void> generateImage(String prompt) async {
    if (prompt.trim().isEmpty || _isProcessing) return;

    if (_currentConversationId == null) {
      await createConversation();
    }

    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;

    final conv = _conversations[convIdx];

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: prompt,
      role: 'user',
      timestamp: DateTime.now(),
    );
    conv.messages.add(userMsg);
    conv.updatedAt = DateTime.now();

    _isProcessing = true;
    _currentResponse = '';
    _errorMessage = null;
    notifyListeners();

    try {
      final service = ImageGenService();
      final imageBase64 = await service.generateImage(prompt);

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: prompt,
        role: 'assistant',
        timestamp: DateTime.now(),
        imageBase64: imageBase64,
      );
      conv.messages.add(assistantMsg);

      if (conv.title == 'New Chat' && conv.messages.length >= 2) {
        conv.title =
            prompt.length > 30 ? '${prompt.substring(0, 27)}...' : prompt;
      }

      _isProcessing = false;
      _currentResponse = '';
      await _save();
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Image gen failed: ${e.toString().replaceAll("Exception: ", "")}';
      notifyListeners();
    }
  }

  Future<void> generateVideo(String prompt) async {
    if (prompt.trim().isEmpty || _isProcessing) return;

    if (_currentConversationId == null) {
      await createConversation();
    }

    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;

    final conv = _conversations[convIdx];

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: prompt,
      role: 'user',
      timestamp: DateTime.now(),
    );
    conv.messages.add(userMsg);
    conv.updatedAt = DateTime.now();

    _isProcessing = true;
    _currentResponse = '';
    _errorMessage = null;
    notifyListeners();

    try {
      final apiKey = dotenv.env['POLLINATIONS_API_KEY'] ?? '';
      final service = VideoGenService(apiKey: apiKey.isNotEmpty ? apiKey : null);
      final videoPath = await service.generateVideo(prompt);

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: prompt,
        role: 'assistant',
        timestamp: DateTime.now(),
        videoPath: videoPath,
      );
      conv.messages.add(assistantMsg);

      if (conv.title == 'New Chat' && conv.messages.length >= 2) {
        conv.title =
            prompt.length > 30 ? '${prompt.substring(0, 27)}...' : prompt;
      }

      _isProcessing = false;
      _currentResponse = '';
      await _save();
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Video gen failed: ${e.toString().replaceAll("Exception: ", "")}';
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_currentConversationId == null) return;
    final convIdx = _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;
    _conversations[convIdx].messages.removeWhere((m) => m.id == messageId);
    _conversations[convIdx].updatedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<ChatMessage?> deleteMessageAndSubsequent(String messageId) async {
    if (_currentConversationId == null) return null;
    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return null;
    final conv = _conversations[convIdx];
    final idx = conv.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return null;
    final target = conv.messages[idx];
    conv.messages.removeRange(idx, conv.messages.length);
    conv.updatedAt = DateTime.now();
    await _save();
    notifyListeners();
    return target;
  }

  Future<void> retryMessage() async {
    if (_currentConversationId == null) return;

    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;

    final conv = _conversations[convIdx];

    if (conv.messages.isNotEmpty && conv.messages.last.role == 'assistant') {
      conv.messages.removeLast();
    }

    String? lastUserText;
    String? lastImage;
    final lastUserIdx = conv.messages.lastIndexWhere((m) => m.role == 'user');
    if (lastUserIdx != -1) {
      lastUserText = conv.messages[lastUserIdx].content;
      lastImage = conv.messages[lastUserIdx].imageBase64;
      conv.messages.removeAt(lastUserIdx);
    }

    if (lastUserText == null && lastImage == null) return;

    _errorMessage = null;
    notifyListeners();

    await sendMessage(lastUserText ?? '', imageBase64: lastImage);
  }

  AIService createAIService() {
    final temp = _settingsProvider.temperature;
    if (_settingsProvider.backend == BackendType.groq) {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
        throw Exception('Set your Groq API key in the .env file');
      }
      return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel, temperature: temp);
    } else if (_settingsProvider.backend == BackendType.claude) {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('Set your Anthropic API key in the .env file');
      }
      return ClaudeService(apiKey: apiKey, model: _settingsProvider.claudeModel, temperature: temp);
    } else {
      return OllamaService(
        endpoint: _settingsProvider.ollamaEndpoint,
        model: _settingsProvider.ollamaModel,
        temperature: temp,
      );
    }
  }

  Future<DiaryEntry> generateDiaryEntry() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayConvs = _conversations.where((c) {
      return c.updatedAt.isAfter(todayStart) &&
          c.messages.any((m) => m.role == 'user');
    }).toList();

    if (todayConvs.isEmpty) {
      throw Exception('No conversations today to summarize');
    }

    final buffer = StringBuffer();
    for (final conv in todayConvs) {
      buffer.writeln('--- Conversation: ${conv.title} ---');
      for (final m in conv.messages) {
        final prefix = m.role == 'user' ? 'User' : 'AI';
        final text = m.content.length > 200
            ? '${m.content.substring(0, 197)}...'
            : m.content;
        buffer.writeln('$prefix: $text');
      }
      buffer.writeln();
    }

    final prompt = 'Summarize the following AI chat conversations from today. '
        'Extract the key topics discussed, insights gained, and any decisions or action items. '
        'Then list 2-5 key insights as a bullet list. '
        'Finally, generate a single vivid DREAMSCAPE_PROMPT — a detailed image generation prompt '
        'that visually represents the mood and themes of today\'s conversations.\n\n'
        'Format your response exactly like this:\n'
        'SUMMARY: <2-3 sentence summary>\n'
        'INSIGHTS:\n'
        '- <insight 1>\n'
        '- <insight 2>\n'
        '...\n'
        'DREAMSCAPE_PROMPT: <vivid image prompt>\n\n'
        'Conversations:\n${buffer.toString()}';

    final aiService = createAIService();
    final fullResponse = StringBuffer();
    await for (final chunk in aiService.streamResponse(
      message: prompt,
      history: [],
      systemPrompt: 'You are a thoughtful journal writer. Summarize conversations concisely and insightfully.',
    )) {
      fullResponse.write(chunk);
    }

    final response = fullResponse.toString();
    String summary = response;
    final insights = <String>[];
    String? dreamscapePrompt;

    if (response.contains('SUMMARY:')) {
      final withDreamscape = response.split('DREAMSCAPE_PROMPT:');
      final beforeDreamscape = withDreamscape.first;
      final parts = beforeDreamscape.split('INSIGHTS:');
      summary = parts.first.replaceAll('SUMMARY:', '').trim();
      if (parts.length > 1) {
        for (final line in parts[1].split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('-') || trimmed.startsWith('•')) {
            insights.add(trimmed.replaceFirst(RegExp(r'^[-•]\s*'), ''));
          }
        }
      }
      if (withDreamscape.length > 1) {
        dreamscapePrompt = withDreamscape.sublist(1).join('DREAMSCAPE_PROMPT:').trim();
      }
    }

    final entry = DiaryEntry(
      id: _uuid.v4(),
      date: today,
      summary: summary,
      keyInsights: insights,
      dreamscapePrompt: dreamscapePrompt,
      conversationPreviews: todayConvs.map((c) => c.title).toList(),
    );

    final entries = _hiveService.loadDiaryEntries();
    entries.removeWhere((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
    entries.insert(0, entry);
    await _hiveService.saveDiaryEntries(entries);

    return entry;
  }

  List<DiaryEntry> get diaryEntries => _hiveService.loadDiaryEntries();

  bool get hasTodayEntry {
    final today = DateTime.now();
    return diaryEntries.any((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day);
  }

  List<Map<String, dynamic>> searchMessages(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    for (final conv in _conversations) {
      for (final msg in conv.messages) {
        if (msg.content.toLowerCase().contains(lower)) {
          results.add({
            'conversationId': conv.id,
            'conversationTitle': conv.title,
            'message': msg,
          });
        }
      }
    }
    return results;
  }

  Map<DateTime, int> getMessageCountsByDay() {
    final counts = <DateTime, int>{};
    for (final conv in _conversations) {
      for (final msg in conv.messages) {
        final day = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<ChatConversation> getConversationsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _conversations.where((c) {
      return c.updatedAt.isAfter(start) && c.updatedAt.isBefore(end);
    }).toList();
  }

  // ── Arena ────────────────────────────────────────────

  bool _arenaProcessing = false;
  List<ArenaResult> _arenaResults = [];
  List<ArenaModelConfig> _arenaModels = [];
  String? _arenaPrompt;

  bool get arenaProcessing => _arenaProcessing;
  List<ArenaResult> get arenaResults => _arenaResults;
  List<ArenaModelConfig> get arenaModels => _arenaModels;
  String? get arenaPrompt => _arenaPrompt;

  void initArena() {
    _arenaModels = [
      ArenaModelConfig(id: 'groq', label: 'Groq Cloud'),
      ArenaModelConfig(id: 'claude', label: 'Claude'),
      ArenaModelConfig(id: 'ollama', label: 'Ollama'),
    ];
    _arenaResults = [];
    _arenaPrompt = null;
    _arenaProcessing = false;
    notifyListeners();
  }

  void toggleArenaModel(String id) {
    final idx = _arenaModels.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final enabledCount = _arenaModels.where((m) => m.enabled).length;
    if (_arenaModels[idx].enabled && enabledCount <= 2) return;
    _arenaModels[idx].enabled = !_arenaModels[idx].enabled;
    notifyListeners();
  }

  AIService _createServiceForModel(String modelId) {
    final temp = _settingsProvider.temperature;
    switch (modelId) {
      case 'groq':
        final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
        if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
          throw Exception('Set your Groq API key in the .env file');
        }
        return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel, temperature: temp);
      case 'claude':
        final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
        if (apiKey.isEmpty) {
          throw Exception('Set your Anthropic API key in the .env file');
        }
        return ClaudeService(apiKey: apiKey, model: _settingsProvider.claudeModel, temperature: temp);
      case 'ollama':
        return OllamaService(
          endpoint: _settingsProvider.ollamaEndpoint,
          model: _settingsProvider.ollamaModel,
          temperature: temp,
        );
      default:
        throw Exception('Unknown model: $modelId');
    }
  }

  Future<void> runArena(String prompt) async {
    if (prompt.trim().isEmpty || _arenaProcessing) return;

    _arenaPrompt = prompt;
    _arenaProcessing = true;
    final now = DateTime.now();
    _arenaResults = _arenaModels
        .where((m) => m.enabled)
        .map((m) => ArenaResult(
          modelId: m.id,
          modelLabel: m.label,
          startTime: now,
        ))
        .toList();
    notifyListeners();

    final systemPrompt = _settingsProvider.activePersona.systemPrompt;

    await Future.wait(_arenaResults.map((result) async {
      try {
        final service = _createServiceForModel(result.modelId);
        final buffer = StringBuffer();
        var isFirstChunk = true;
        await for (final chunk in service.streamResponse(
          message: prompt,
          history: [],
          systemPrompt: systemPrompt,
        )) {
          if (isFirstChunk) {
            isFirstChunk = false;
            result.firstTokenTime = DateTime.now();
          }
          buffer.write(chunk);
          result.content = buffer.toString();
          notifyListeners();
        }
        result.isComplete = true;
        result.endTime = DateTime.now();
        notifyListeners();
      } catch (e) {
        result.error = e.toString().replaceAll('Exception: ', '');
        result.isComplete = true;
        result.endTime = DateTime.now();
        notifyListeners();
      }
    }));

    _arenaProcessing = false;
    notifyListeners();
  }

  void clearArena() {
    _arenaResults = [];
    _arenaPrompt = null;
    _arenaProcessing = false;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveConversations(_conversations);
  }
}
