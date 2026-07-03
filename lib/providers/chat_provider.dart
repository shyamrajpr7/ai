import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/ollama_service.dart';
import '../services/web_search_service.dart';
import '../services/image_gen_service.dart';
import '../services/video_gen_service.dart';
import '../services/hive_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

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

      final aiService = _createAIService();
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

  AIService _createAIService() {
    if (_settingsProvider.backend == BackendType.groq) {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
        throw Exception('Set your Groq API key in the .env file');
      }
      return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel);
    } else {
      return OllamaService(
        endpoint: _settingsProvider.ollamaEndpoint,
        model: _settingsProvider.ollamaModel,
      );
    }
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

  Future<void> _save() async {
    await _hiveService.saveConversations(_conversations);
  }
}
