import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class VocabWord {
  final String id;
  final String word;
  final String translation;
  final String exampleSentence;
  final String? pronunciationHint;
  bool mastered;

  VocabWord({
    required this.id,
    required this.word,
    required this.translation,
    this.exampleSentence = '',
    this.pronunciationHint,
    this.mastered = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'word': word, 'translation': translation,
    'exampleSentence': exampleSentence, 'pronunciationHint': pronunciationHint,
    'mastered': mastered,
  };
}

class DojoMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;

  DojoMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class LanguageDojoProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  stt.SpeechToText? _speech;
  bool _speechAvailable = false;

  String _targetLanguage = 'Spanish';
  String _nativeLanguage = 'English';
  List<VocabWord> _vocabulary = [];
  int _currentVocabIndex = 0;
  bool _showTranslation = false;
  bool _isGeneratingVocab = false;

  bool _isListening = false;
  String _spokenText = '';
  bool _isAssessing = false;
  double _lastScore = 0.0;
  String? _lastAssessment;

  bool _isConversationProcessing = false;
  List<DojoMessage> _conversationMessages = [];
  String _currentResponse = '';

  bool get speechAvailable => _speechAvailable;
  String get targetLanguage => _targetLanguage;
  String get nativeLanguage => _nativeLanguage;
  List<VocabWord> get vocabulary => _vocabulary;
  int get currentVocabIndex => _currentVocabIndex;
  bool get showTranslation => _showTranslation;
  bool get isGeneratingVocab => _isGeneratingVocab;
  bool get isListening => _isListening;
  String get spokenText => _spokenText;
  bool get isAssessing => _isAssessing;
  double get lastScore => _lastScore;
  String? get lastAssessment => _lastAssessment;
  bool get isConversationProcessing => _isConversationProcessing;
  List<DojoMessage> get conversationMessages => _conversationMessages;
  String get currentResponse => _currentResponse;

  VocabWord? get currentWord {
    if (_vocabulary.isEmpty) return null;
    if (_currentVocabIndex >= _vocabulary.length) _currentVocabIndex = 0;
    return _vocabulary[_currentVocabIndex];
  }

  LanguageDojoProvider(this._settingsProvider);

  Future<void> initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech!.initialize(onError: (_) {});
      notifyListeners();
    } catch (_) {}
  }

  void setLanguage(String lang) {
    _targetLanguage = lang;
    _vocabulary = [];
    _conversationMessages = [];
    _currentVocabIndex = 0;
    _showTranslation = false;
    notifyListeners();
  }

  void setNativeLanguage(String lang) {
    _nativeLanguage = lang;
    notifyListeners();
  }

  Future<void> generateVocabulary({int count = 10}) async {
    if (_isGeneratingVocab) return;
    _isGeneratingVocab = true;
    _vocabulary = [];
    _currentVocabIndex = 0;
    _showTranslation = false;
    notifyListeners();

    try {
      final service = _createAIService();
      final systemPrompt = 'You are a language tutor. Generate exactly $count vocabulary words for $_targetLanguage learners. '
          'Respond ONLY with a JSON array of objects. Each object must have: '
          '"word" (the word in $_targetLanguage), '
          '"translation" (in $_nativeLanguage), '
          '"exampleSentence" (a simple example sentence in $_targetLanguage), '
          '"pronunciationHint" (a brief phonetic hint). '
          'No markdown, no explanation, just the JSON array.';

      final buffer = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Generate $count vocabulary words for $_targetLanguage.',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
      }

      final raw = buffer.toString().trim();
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
        final parsed = _parseJsonList(jsonStr);
        for (final entry in parsed) {
          _vocabulary.add(VocabWord(
            id: _uuid.v4(),
            word: entry['word'] as String? ?? '?',
            translation: entry['translation'] as String? ?? '?',
            exampleSentence: entry['exampleSentence'] as String? ?? '',
            pronunciationHint: entry['pronunciationHint'] as String?,
          ));
        }
      }

      if (_vocabulary.isEmpty) {
        _vocabulary.add(VocabWord(
          id: _uuid.v4(),
          word: 'Hola',
          translation: 'Hello',
          exampleSentence: 'Hola, ¿cómo estás?',
          pronunciationHint: 'OH-lah',
        ));
      }
    } catch (_) {
      _vocabulary.add(VocabWord(
        id: _uuid.v4(),
        word: 'Hola',
        translation: 'Hello',
        exampleSentence: 'Hola, ¿cómo estás?',
        pronunciationHint: 'OH-lah',
      ));
    }

    _isGeneratingVocab = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _parseJsonList(String json) {
    try {
      // ignore: depend_on_referenced_packages
      return ( _JsonDecoder().convert(json) as List)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      final items = <Map<String, dynamic>>[];
      final regex = RegExp(r'\{[^}]+\}');
      for (final match in regex.allMatches(json)) {
        try {
          final map = <String, dynamic>{};
          final pairs = RegExp(r'"(\w+)":\s*"((?:[^"\\]|\\.)*)"');
          for (final p in pairs.allMatches(match.group(0)!)) {
            map[p.group(1)!] = p.group(2)!;
          }
          if (map.isNotEmpty) items.add(map);
        } catch (_) {}
      }
      return items;
    }
  }

  void nextWord() {
    if (_vocabulary.isEmpty) return;
    _currentVocabIndex = (_currentVocabIndex + 1) % _vocabulary.length;
    _showTranslation = false;
    _spokenText = '';
    _lastScore = 0;
    _lastAssessment = null;
    notifyListeners();
  }

  void previousWord() {
    if (_vocabulary.isEmpty) return;
    _currentVocabIndex = (_currentVocabIndex - 1 + _vocabulary.length) % _vocabulary.length;
    _showTranslation = false;
    _spokenText = '';
    _lastScore = 0;
    _lastAssessment = null;
    notifyListeners();
  }

  void toggleTranslation() {
    _showTranslation = !_showTranslation;
    notifyListeners();
  }

  void markMastered() {
    if (currentWord != null) {
      final idx = _vocabulary.indexWhere((w) => w.id == currentWord!.id);
      if (idx != -1) {
        _vocabulary[idx].mastered = !_vocabulary[idx].mastered;
        nextWord();
        notifyListeners();
      }
    }
  }

  Future<void> startListening() async {
    if (_speech == null || !_speechAvailable) return;
    _spokenText = '';
    _lastScore = 0;
    _lastAssessment = null;
    _isListening = true;
    notifyListeners();

    String? localeId;
    final langCode = _languageCode(_targetLanguage);
    if (langCode != null) {
      try {
        final locales = await _speech!.locales();
        final match = locales.firstWhere(
          (l) => l.localeId.startsWith(langCode),
          orElse: () => locales.first,
        );
        localeId = match.localeId;
      } catch (_) {}
    }

    await _speech!.listen(
      onResult: (result) {
        _spokenText = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          _isListening = false;
          _assessPronunciation();
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  void stopListening() {
    _speech?.stop();
    _isListening = false;
    if (_spokenText.isNotEmpty && !_isAssessing) {
      _assessPronunciation();
    }
    notifyListeners();
  }

  Future<void> _assessPronunciation() async {
    final word = currentWord;
    if (word == null || _spokenText.isEmpty) return;
    _isAssessing = true;
    notifyListeners();

    final expected = word.word.toLowerCase().trim();
    final spoken = _spokenText.toLowerCase().trim();

    final wordSim = _wordSimilarity(expected, spoken);
    _lastScore = wordSim * 100;

    if (_lastScore > 80) {
      _lastAssessment = 'Great pronunciation! 🎯';
    } else if (_lastScore > 50) {
      _lastAssessment = 'Getting closer! Try saying "${word.pronunciationHint ?? word.word}"';
    } else {
      _lastAssessment = 'Listen and repeat: ${word.pronunciationHint ?? word.word}';
    }

    _isAssessing = false;
    notifyListeners();
  }

  double _wordSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final len = max(a.length, b.length);
    int matches = 0;
    for (int i = 0; i < len; i++) {
      if (i < a.length && i < b.length && a[i] == b[i]) matches++;
    }
    final baseSim = matches / len;
    final containsSim = a.contains(b) || b.contains(a) ? 0.5 : 0.0;
    return min(1.0, baseSim + containsSim * 0.3);
  }

  Future<void> sendConversationMessage(String text) async {
    if (text.trim().isEmpty || _isConversationProcessing) return;

    _conversationMessages.add(DojoMessage(id: _uuid.v4(), role: 'user', content: text));
    _isConversationProcessing = true;
    _currentResponse = '';
    notifyListeners();

    try {
      final service = _createAIService();
      final systemPrompt = 'You are a language tutor. Have a natural conversation in $_targetLanguage. '
          'The user is learning $_targetLanguage (their native language is $_nativeLanguage). '
          'Respond in $_targetLanguage, keeping sentences simple and clear. '
          'If the user seems confused, you may provide a brief translation in $_nativeLanguage in parentheses. '
          'Correct any mistakes gently. Be encouraging and supportive.';

      final history = _conversationMessages
          .where((m) => m.role == 'user')
          .map((m) => {'role': 'user', 'content': m.content})
          .toList();

      final buffer = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: text,
        history: history,
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentResponse = buffer.toString();
        notifyListeners();
      }

      final response = buffer.toString();
      if (response.isNotEmpty) {
        _conversationMessages.add(DojoMessage(
          id: _uuid.v4(), role: 'assistant', content: response,
        ));
      }

      _isConversationProcessing = false;
      _currentResponse = '';
      notifyListeners();
    } catch (e) {
      _isConversationProcessing = false;
      notifyListeners();
    }
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

  String? _languageCode(String language) {
    const codes = {
      'Spanish': 'es', 'French': 'fr', 'German': 'de', 'Italian': 'it',
      'Portuguese': 'pt', 'Japanese': 'ja', 'Korean': 'ko', 'Chinese': 'zh',
      'Russian': 'ru', 'Arabic': 'ar', 'Hindi': 'hi', 'Dutch': 'nl',
      'Polish': 'pl', 'Turkish': 'tr', 'Swedish': 'sv', 'Danish': 'da',
      'Norwegian': 'no', 'Finnish': 'fi', 'Czech': 'cs', 'Romanian': 'ro',
      'English': 'en',
    };
    return codes[language];
  }

  void clearConversation() {
    _conversationMessages = [];
    _currentResponse = '';
    notifyListeners();
  }
}

class _JsonDecoder {
  dynamic convert(String source) {
    final result = _parseValue(source, 0);
    return result.value;
  }

  _ParseResult _parseValue(String source, int pos) {
    pos = _skipWhitespace(source, pos);
    if (pos >= source.length) throw FormatException('Unexpected end');
    final c = source[pos];
    if (c == '[') return _parseArray(source, pos);
    if (c == '{') return _parseObject(source, pos);
    if (c == '"') return _parseString(source, pos);
    if (c == 't' || c == 'f') return _parseBool(source, pos);
    if (c == 'n') return _parseNull(source, pos);
    return _parseNumber(source, pos);
  }

  _ParseResult _parseArray(String source, int pos) {
    pos++;
    final list = <dynamic>[];
    while (pos < source.length) {
      pos = _skipWhitespace(source, pos);
      if (source[pos] == ']') { pos++; return _ParseResult(list, pos); }
      if (list.isNotEmpty) {
        if (source[pos] != ',') throw FormatException('Expected comma');
        pos++;
      }
      final result = _parseValue(source, pos);
      list.add(result.value);
      pos = result.nextPos;
    }
    throw FormatException('Unterminated array');
  }

  _ParseResult _parseObject(String source, int pos) {
    pos++;
    final map = <String, dynamic>{};
    while (pos < source.length) {
      pos = _skipWhitespace(source, pos);
      if (source[pos] == '}') { pos++; return _ParseResult(map, pos); }
      if (map.isNotEmpty) {
        if (source[pos] != ',') throw FormatException('Expected comma');
        pos++;
      }
      final keyResult = _parseString(source, _skipWhitespace(source, pos));
      pos = _skipWhitespace(source, keyResult.nextPos);
      if (source[pos] != ':') throw FormatException('Expected colon');
      pos++;
      final valueResult = _parseValue(source, pos);
      map[keyResult.value as String] = valueResult.value;
      pos = valueResult.nextPos;
    }
    throw FormatException('Unterminated object');
  }

  _ParseResult _parseString(String source, int pos) {
    if (source[pos] != '"') throw FormatException('Expected string');
    pos++;
    final buffer = StringBuffer();
    while (pos < source.length) {
      final c = source[pos];
      if (c == '"') { pos++; return _ParseResult(buffer.toString(), pos); }
      if (c == '\\') {
        pos++;
        if (pos >= source.length) throw FormatException('Unexpected end');
        buffer.write(source[pos]);
      } else {
        buffer.write(c);
      }
      pos++;
    }
    throw FormatException('Unterminated string');
  }

  _ParseResult _parseNumber(String source, int pos) {
    final start = pos;
    if (source[pos] == '-') pos++;
    while (pos < source.length && _isDigit(source[pos])) pos++;
    if (pos < source.length && source[pos] == '.') {
      pos++;
      while (pos < source.length && _isDigit(source[pos])) pos++;
    }
    return _ParseResult(double.tryParse(source.substring(start, pos)) ?? 0, pos);
  }

  _ParseResult _parseBool(String source, int pos) {
    if (source.startsWith('true', pos)) return _ParseResult(true, pos + 4);
    if (source.startsWith('false', pos)) return _ParseResult(false, pos + 5);
    throw FormatException('Expected bool');
  }

  _ParseResult _parseNull(String source, int pos) {
    if (source.startsWith('null', pos)) return _ParseResult(null, pos + 4);
    throw FormatException('Expected null');
  }

  int _skipWhitespace(String source, int pos) {
    while (pos < source.length && source.codeUnitAt(pos) <= 32) pos++;
    return pos;
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class _ParseResult {
  final dynamic value;
  final int nextPos;
  _ParseResult(this.value, this.nextPos);
}
