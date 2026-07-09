import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/search_result.dart';
import '../models/conversation_branch.dart';
import '../models/diary_entry.dart';
import '../models/memory_node.dart';
import '../models/persona.dart';
import '../models/synapse.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/ollama_service.dart';
import '../services/claude_service.dart';
import '../services/web_search_service.dart';
import '../services/image_gen_service.dart';
import '../services/video_gen_service.dart';
import '../services/hive_service.dart';
import 'settings_provider.dart';
import 'knowledge_graph_provider.dart';
import 'context_weaver_provider.dart';

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
  final KnowledgeGraphProvider _knowledgeGraphProvider;
  ContextWeaverProvider? _contextWeaverProvider;

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

  ChatProvider(this._hiveService, this._settingsProvider, this._knowledgeGraphProvider, {ContextWeaverProvider? contextWeaverProvider})
      : _contextWeaverProvider = contextWeaverProvider;

  Future<void> load() async {
    _conversations = _hiveService.loadConversations();
    if (_conversations.isNotEmpty) {
      _currentConversationId = _conversations.first.id;
    }
    _memories = _hiveService.loadMemories();
    _initialized = true;
    notifyListeners();
  }

  Future<void> createConversation() async {
    final conv = ChatConversation(id: _uuid.v4());
    conv.branches = [ConversationBranch(id: 'main', name: 'Original')];
    conv.activeBranchId = 'main';
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
    _syncBranchMessages(conv);
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
      var systemPrompt = _settingsProvider.activePersona.systemPrompt;
      final memoryContext = _buildMemoryContext(text);
      if (memoryContext.isNotEmpty) {
        systemPrompt += '\n\n--- Memory Context ---\n$memoryContext';
      }
      final contextWeaver = _contextWeaverProvider;
      if (contextWeaver != null && _currentConversationId != null) {
        final attachmentContext =
            contextWeaver.buildContextString(_currentConversationId!);
        if (attachmentContext.isNotEmpty) {
          systemPrompt +=
              '\n\n$attachmentContext\n\nUse the attached context above to inform your responses.';
        }
      }
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
        _syncBranchMessages(conv);

        if (conv.title == 'New Chat' && conv.messages.length >= 2) {
          conv.title =
              text.length > 30 ? '${text.substring(0, 27)}...' : text;
        }

        _knowledgeGraphProvider.extractFromMessages([assistantMsg]);
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

  /// Branch the conversation from a historical message — replaces
  /// [deleteMessageAndSubsequent] with a version-preserving branch.
  Future<ChatMessage?> editMessageAndBranch(String messageId) async {
    if (_currentConversationId == null) return null;
    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return null;
    final conv = _conversations[convIdx];
    final idx = conv.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return null;
    final target = conv.messages[idx];

    final branchId = _uuid.v4();
    final branchName = 'Branch ${conv.branches.length + 1}';

    final branchMsgs = conv.messages.sublist(0, idx + 1);
    conv.branchMessages[branchId] = branchMsgs;
    conv.branches.add(ConversationBranch(id: branchId, name: branchName));
    conv.activeBranchId = branchId;
    conv.messages
      ..clear()
      ..addAll(branchMsgs);
    _syncBranchMessages(conv);
    conv.updatedAt = DateTime.now();
    await _save();
    notifyListeners();
    return target;
  }

  void switchBranch(String branchId) {
    if (_currentConversationId == null) return;
    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;
    final conv = _conversations[convIdx];
    final branchMsgs = conv.branchMessages[branchId];
    if (branchMsgs == null) return;

    conv.activeBranchId = branchId;
    conv.messages
      ..clear()
      ..addAll(branchMsgs);
    conv.updatedAt = DateTime.now();
    notifyListeners();
  }

  void renameBranch(String branchId, String name) {
    if (_currentConversationId == null) return;
    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;
    final conv = _conversations[convIdx];
    final branch = conv.branches.where((b) => b.id == branchId).firstOrNull;
    if (branch == null) return;
    branch.name = name;
    notifyListeners();
  }

  void deleteBranch(String branchId) {
    if (_currentConversationId == null) return;
    final convIdx =
        _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (convIdx == -1) return;
    final conv = _conversations[convIdx];
    if (conv.branches.length <= 1) return;

    conv.branches.removeWhere((b) => b.id == branchId);
    conv.branchMessages.remove(branchId);

    if (conv.activeBranchId == branchId) {
      final first = conv.branches.first;
      conv.activeBranchId = first.id;
      final msgs = conv.branchMessages[first.id];
      if (msgs != null) {
        conv.messages
          ..clear()
          ..addAll(msgs);
      }
    }
    conv.updatedAt = DateTime.now();
    notifyListeners();
  }

  void _syncBranchMessages(ChatConversation conv) {
    conv.branchMessages[conv.activeBranchId] = List.from(conv.messages);
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
    _syncBranchMessages(conv);
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
      _syncBranchMessages(conv);

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
    _syncBranchMessages(conv);
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
      _syncBranchMessages(conv);

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
    final conv = _conversations[convIdx];
    conv.messages.removeWhere((m) => m.id == messageId);
    _syncBranchMessages(conv);
    conv.updatedAt = DateTime.now();
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
    _syncBranchMessages(conv);
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

    _syncBranchMessages(conv);

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

  List<ConversationSearchGroup> searchMessages(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final groupMap = <String, List<SearchResult>>{};

    for (final conv in _conversations) {
      final allBranches = <ChatMessage>[];
      for (final branchMsgs in conv.branchMessages.values) {
        allBranches.addAll(branchMsgs);
      }
      if (allBranches.isEmpty) allBranches.addAll(conv.messages);

      final seen = <String>{};
      final titleMatch = conv.title.toLowerCase().contains(lower);
      final results = <SearchResult>[];

      if (titleMatch && allBranches.isNotEmpty) {
        results.add(SearchResult(
          conversationId: conv.id,
          conversationTitle: conv.title,
          message: allBranches.first,
          matches: const [MatchSpan(-1, -1)],
        ));
        seen.add(allBranches.first.id);
      }

      for (final msg in allBranches) {
        if (seen.contains(msg.id)) continue;
        seen.add(msg.id);

        final text = msg.content.toLowerCase();
        final matches = <MatchSpan>[];
        int start = 0;
        while (true) {
          final idx = text.indexOf(lower, start);
          if (idx == -1) break;
          matches.add(MatchSpan(idx, idx + query.length));
          start = idx + 1;
        }

        if (matches.isNotEmpty) {
          results.add(SearchResult(
            conversationId: conv.id,
            conversationTitle: conv.title,
            message: msg,
            matches: matches,
          ));
        }
      }

      if (results.isNotEmpty) {
        groupMap[conv.id] = results;
      }
    }

    final groups = <ConversationSearchGroup>[];
    for (final conv in _conversations) {
      final results = groupMap[conv.id];
      if (results != null && results.isNotEmpty) {
        groups.add(ConversationSearchGroup(
          conversationId: conv.id,
          conversationTitle: conv.title,
          results: results,
        ));
      }
    }
    return groups;
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

  // ── Cognitive Lab ─────────────────────────────────────

  bool _labProcessing = false;
  List<ArenaResult> _labResults = [];
  List<ArenaModelConfig> _labModels = [];

  bool get labProcessing => _labProcessing;
  List<ArenaResult> get labResults => _labResults;
  List<ArenaModelConfig> get labModels => _labModels;

  void initLab() {
    _labModels = [
      ArenaModelConfig(id: 'groq', label: 'Groq Cloud'),
      ArenaModelConfig(id: 'claude', label: 'Claude'),
      ArenaModelConfig(id: 'ollama', label: 'Ollama'),
    ];
    _labResults = [];
    _labProcessing = false;
    notifyListeners();
  }

  void toggleLabModel(String id) {
    final idx = _labModels.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final enabledCount = _labModels.where((m) => m.enabled).length;
    if (_labModels[idx].enabled && enabledCount <= 1) return;
    _labModels[idx].enabled = !_labModels[idx].enabled;
    notifyListeners();
  }

  Future<void> runLab({
    required String prompt,
    String systemPrompt = '',
    double temperature = 0.7,
  }) async {
    if (prompt.trim().isEmpty || _labProcessing) return;

    _labProcessing = true;
    final now = DateTime.now();
    _labResults = _labModels
        .where((m) => m.enabled)
        .map((m) => ArenaResult(
          modelId: m.id,
          modelLabel: m.label,
          startTime: now,
        ))
        .toList();
    notifyListeners();

    await Future.wait(_labResults.map((result) async {
      try {
        final service = _createLabService(result.modelId, temperature);
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

    _labProcessing = false;
    notifyListeners();
  }

  AIService _createLabService(String modelId, double temperature) {
    switch (modelId) {
      case 'groq':
        final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
        if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
          throw Exception('Set your Groq API key in the .env file');
        }
        return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel, temperature: temperature);
      case 'claude':
        final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
        if (apiKey.isEmpty) {
          throw Exception('Set your Anthropic API key in the .env file');
        }
        return ClaudeService(apiKey: apiKey, model: _settingsProvider.claudeModel, temperature: temperature);
      case 'ollama':
        return OllamaService(
          endpoint: _settingsProvider.ollamaEndpoint,
          model: _settingsProvider.ollamaModel,
          temperature: temperature,
        );
      default:
        throw Exception('Unknown model: $modelId');
    }
  }

  void clearLab() {
    _labResults = [];
    _labProcessing = false;
    notifyListeners();
  }

  // ── Memory Core ───────────────────────────────────────

  List<MemoryNode> _memories = [];

  List<MemoryNode> get memories => List.unmodifiable(_memories);

  Future<void> addMemory(MemoryNode memory) async {
    _memories.insert(0, memory);
    await _saveMemories();
    notifyListeners();
  }

  Future<void> updateMemory(MemoryNode memory) async {
    final idx = _memories.indexWhere((m) => m.id == memory.id);
    if (idx != -1) {
      memory.updatedAt = DateTime.now();
      _memories[idx] = memory;
      await _saveMemories();
      notifyListeners();
    }
  }

  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    await _saveMemories();
    notifyListeners();
  }

  String _buildMemoryContext(String userMessage) {
    if (_memories.isEmpty) return '';
    final relevant = _memories
        .where((m) => _isRelevant(m, userMessage))
        .take(5)
        .toList();
    if (relevant.isEmpty) return '';
    return relevant.map((m) =>
      '[${m.category}] ${m.content}'
    ).join('\n');
  }

  bool _isRelevant(MemoryNode memory, String message) {
    final msg = message.toLowerCase();
    final words = msg.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < 3) continue;
      if (memory.content.toLowerCase().contains(word)) return true;
      for (final tag in memory.tags) {
        if (tag.toLowerCase().contains(word)) return true;
      }
      if (memory.category.toLowerCase().contains(word)) return true;
    }
    return false;
  }

  Future<void> _saveMemories() async {
    await _hiveService.saveMemories(_memories);
  }

  // ── Synapse Collaboration ─────────────────────────────

  SynapseSession? _synapseSession;
  bool _synapseProcessing = false;
  List<String> _synapsePersonaIds = [];

  SynapseSession? get synapseSession => _synapseSession;
  bool get synapseProcessing => _synapseProcessing;
  List<String> get synapsePersonaIds => _synapsePersonaIds;

  void initSynapse() {
    _synapseSession = null;
    _synapseProcessing = false;
    _synapsePersonaIds = [];
    notifyListeners();
  }

  void toggleSynapsePersona(String personaId) {
    if (_synapsePersonaIds.contains(personaId)) {
      if (_synapsePersonaIds.length <= 2) return;
      _synapsePersonaIds.remove(personaId);
    } else {
      _synapsePersonaIds.add(personaId);
    }
    notifyListeners();
  }

  Future<void> startSynapse(String prompt) async {
    if (prompt.trim().isEmpty) return;
    if (_synapsePersonaIds.length < 2) return;
    if (_synapseProcessing) return;

    final personas = _settingsProvider.personas;
    final participants = _synapsePersonaIds
        .map((id) => personas.firstWhere((p) => p.id == id))
        .toList();

    _synapseSession = SynapseSession(
      id: _uuid.v4(),
      prompt: prompt,
      participantIds: List.from(_synapsePersonaIds),
      status: SynapseStatus.running,
      currentTurn: 0,
    );
    _synapseProcessing = true;
    notifyListeners();

    try {
      await _runSynapseTurn(prompt, participants, 0);
    } catch (e) {
      if (_synapseSession != null) {
        _synapseSession!.status = SynapseStatus.error;
        _synapseSession!.errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      _synapseProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _runSynapseTurn(
    String prompt,
    List<Persona> participants,
    int turn,
  ) async {
    if (_synapseSession == null) return;
    if (turn >= _synapseSession!.maxTurns) {
      _synapseSession!.status = SynapseStatus.completed;
      _synapseProcessing = false;
      notifyListeners();
      return;
    }

    for (var i = 0; i < participants.length; i++) {
      if (_synapseSession!.status == SynapseStatus.paused) return;
      if (_synapseSession!.status != SynapseStatus.running) return;

      final speaker = participants[i];
      final history = _buildSynapseHistory(_synapseSession!.messages);
      final instruction = _synapseSession!.userInstruction;
      var systemPrompt = speaker.systemPrompt;
      systemPrompt += '\n\nYou are participating in a multi-persona collaboration.';
      systemPrompt += '\nYour name: ${speaker.name}';
      systemPrompt += '\nRespond as ${speaker.name} would. Keep responses concise (2-4 paragraphs).';
      if (instruction != null && instruction.isNotEmpty) {
        systemPrompt += '\n\nUser instruction: $instruction';
      }

      final aiService = createAIService();
      final buffer = StringBuffer();
      final msgId = _uuid.v4();

      try {
        await for (final chunk in aiService.streamResponse(
          message: turn == 0 && i == 0
              ? prompt
              : 'Continue the discussion. Respond as $speaker.name.',
          history: history,
          systemPrompt: systemPrompt,
        )) {
          if (_synapseSession!.status == SynapseStatus.paused) return;
          if (_synapseSession!.status != SynapseStatus.running) return;
          buffer.write(chunk);

          _addOrUpdateSynapseMessage(msgId, speaker, buffer.toString(), turn);
          notifyListeners();
        }

        _finalizeSynapseMessage(msgId, speaker, buffer.toString(), turn);
        _synapseSession!.currentTurn = turn;
        notifyListeners();
      } catch (e) {
        final errMsg = '${speaker.name} encountered an error.';
        _addOrUpdateSynapseMessage(msgId, speaker, errMsg, turn);
        notifyListeners();
      }
    }

    if (_synapseSession!.status == SynapseStatus.running) {
      await _runSynapseTurn(prompt, participants, turn + 1);
    }
  }

  void _addOrUpdateSynapseMessage(
    String msgId,
    Persona speaker,
    String content,
    int turn,
  ) {
    if (_synapseSession == null) return;
    final existingIdx = _synapseSession!.messages.indexWhere((m) => m.id == msgId);
    final msg = SynapseMessage(
      id: msgId,
      personaId: speaker.id,
      personaName: speaker.name,
      personaEmoji: speaker.emoji,
      personaColor: speaker.color.value,
      content: content,
      turnNumber: turn,
    );
    if (existingIdx != -1) {
      final msgs = [..._synapseSession!.messages];
      msgs[existingIdx] = msg;
      _synapseSession!.messages = msgs;
    } else {
      _synapseSession!.messages = [..._synapseSession!.messages, msg];
    }
  }

  void _finalizeSynapseMessage(
    String msgId,
    Persona speaker,
    String content,
    int turn,
  ) {
    if (_synapseSession == null) return;
    final existingIdx = _synapseSession!.messages.indexWhere((m) => m.id == msgId);
    final msg = SynapseMessage(
      id: msgId,
      personaId: speaker.id,
      personaName: speaker.name,
      personaEmoji: speaker.emoji,
      personaColor: speaker.color.value,
      content: content,
      turnNumber: turn,
    );
    if (existingIdx != -1) {
      final msgs = [..._synapseSession!.messages];
      msgs[existingIdx] = msg;
      _synapseSession!.messages = msgs;
    }
  }

  List<Map<String, String>> _buildSynapseHistory(List<SynapseMessage> messages) {
    return messages.map((m) => {
      'role': 'assistant',
      'content': '${m.personaName}: ${m.content}',
    }).toList();
  }

  void pauseSynapse() {
    if (_synapseSession != null) {
      _synapseSession!.status = SynapseStatus.paused;
      notifyListeners();
    }
  }

  void resumeSynapse() {
    if (_synapseSession == null) return;
    _synapseSession!.status = SynapseStatus.running;
    _synapseProcessing = true;
    notifyListeners();

    final personas = _settingsProvider.personas;
    final participants = _synapsePersonaIds
        .map((id) => personas.firstWhere((p) => p.id == id))
        .toList();

    _runSynapseTurn(
      _synapseSession!.prompt,
      participants,
      _synapseSession!.currentTurn,
    );
  }

  void steerSynapse(String instruction) {
    if (_synapseSession != null) {
      _synapseSession!.userInstruction = instruction;
      notifyListeners();
    }
  }

  void stopSynapse() {
    _synapseSession?.status = SynapseStatus.completed;
    _synapseProcessing = false;
    notifyListeners();
  }

  // ── Debate Club ─────────────────────────────────────

  bool _debateProcessing = false;
  DebateResult? _debateResult;
  DebateModelConfig _debateForModel = DebateModelConfig(id: 'groq', label: 'Groq Cloud');
  DebateModelConfig _debateAgainstModel = DebateModelConfig(id: 'claude', label: 'Claude');

  bool get debateProcessing => _debateProcessing;
  DebateResult? get debateResult => _debateResult;
  DebateModelConfig get debateForModel => _debateForModel;
  DebateModelConfig get debateAgainstModel => _debateAgainstModel;

  List<DebateModelConfig> get debateModelOptions => const [
    DebateModelConfig(id: 'groq', label: 'Groq Cloud'),
    DebateModelConfig(id: 'claude', label: 'Claude'),
    DebateModelConfig(id: 'ollama', label: 'Ollama'),
  ];

  void initDebate() {
    _debateResult = null;
    _debateProcessing = false;
    notifyListeners();
  }

  void setDebateForModel(String id) {
    final opt = debateModelOptions.firstWhere((m) => m.id == id);
    _debateForModel = DebateModelConfig(id: opt.id, label: opt.label);
    if (_debateAgainstModel.id == _debateForModel.id) {
      final other = debateModelOptions.firstWhere((m) => m.id != id);
      _debateAgainstModel = DebateModelConfig(id: other.id, label: other.label);
    }
    notifyListeners();
  }

  void setDebateAgainstModel(String id) {
    final opt = debateModelOptions.firstWhere((m) => m.id == id);
    _debateAgainstModel = DebateModelConfig(id: opt.id, label: opt.label);
    if (_debateForModel.id == _debateAgainstModel.id) {
      final other = debateModelOptions.firstWhere((m) => m.id != id);
      _debateForModel = DebateModelConfig(id: other.id, label: other.label);
    }
    notifyListeners();
  }

  Future<void> runDebate(String topic) async {
    if (topic.trim().isEmpty || _debateProcessing) return;

    _debateProcessing = true;
    final now = DateTime.now();
    _debateResult = DebateResult(
      topic: topic,
      forArg: DebateArgument(
        side: 'for',
        modelId: _debateForModel.id,
        modelLabel: _debateForModel.label,
        startTime: now,
      ),
      againstArg: DebateArgument(
        side: 'against',
        modelId: _debateAgainstModel.id,
        modelLabel: _debateAgainstModel.label,
        startTime: now,
      ),
    );
    notifyListeners();

    await Future.wait([
      _streamDebateSide(topic, _debateResult!.forArg, true),
      _streamDebateSide(topic, _debateResult!.againstArg, false),
    ]);

    _debateProcessing = false;
    notifyListeners();
  }

  Future<void> _streamDebateSide(String topic, DebateArgument arg, bool isFor) async {
    try {
      final service = _createDebateService(arg.modelId);
      final systemPrompt = isFor
          ? 'You are a skilled debater arguing FOR the given topic. Present compelling, well-structured arguments with evidence and reasoning. Use a formal debate format with clear points.'
          : 'You are a skilled debater arguing AGAINST the given topic. Present compelling, well-structured counter-arguments with evidence and reasoning. Use a formal debate format with clear points.';
      final buffer = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Debate topic: $topic\n\nPresent your ${isFor ? "FOR" : "AGAINST"} arguments in a structured format.',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        arg.content = buffer.toString();
        notifyListeners();
      }
      arg.isComplete = true;
      arg.endTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      arg.error = e.toString().replaceAll('Exception: ', '');
      arg.isComplete = true;
      arg.endTime = DateTime.now();
      notifyListeners();
    }
  }

  AIService _createDebateService(String modelId) {
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

  void clearDebate() {
    _debateResult = null;
    _debateProcessing = false;
    notifyListeners();
  }

  Future<void> _save() async {
    await _hiveService.saveConversations(_conversations);
  }
}

// ── Debate Models ──────────────────────────────────────

class DebateModelConfig {
  final String id;
  final String label;
  const DebateModelConfig({required this.id, required this.label});
}

class DebateArgument {
  final String side;
  final String modelId;
  final String modelLabel;
  String content;
  bool isComplete;
  String? error;
  DateTime? startTime;
  DateTime? endTime;

  DebateArgument({
    required this.side,
    required this.modelId,
    required this.modelLabel,
    this.content = '',
    this.isComplete = false,
    this.error,
    this.startTime,
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
}

class DebateResult {
  final String topic;
  final DebateArgument forArg;
  final DebateArgument againstArg;

  DebateResult({
    required this.topic,
    required this.forArg,
    required this.againstArg,
  });
}
