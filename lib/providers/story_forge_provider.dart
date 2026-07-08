import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

enum AuthorType { user, ai }

class Chapter {
  final String id;
  final String content;
  final AuthorType author;
  final DateTime timestamp;
  final String? choiceLabel;

  Chapter({
    String? id,
    required this.content,
    required this.author,
    DateTime? timestamp,
    this.choiceLabel,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class BranchingChoice {
  final String label;
  final String prompt;

  BranchingChoice({required this.label, required this.prompt});
}

class Story {
  final String id;
  String title;
  String genre;
  String premise;
  List<Chapter> chapters;
  DateTime createdAt;
  DateTime updatedAt;

  Story({
    String? id,
    required this.title,
    required this.genre,
    required this.premise,
    List<Chapter>? chapters,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        chapters = chapters ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

class StoryForgeProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  List<Story> _stories = [];
  Story? _currentStory;
  bool _isGenerating = false;
  String _currentResponse = '';
  List<BranchingChoice> _branchingChoices = [];
  bool _isAITurn = false;
  String? _error;

  StoryForgeProvider(this._settingsProvider);

  List<Story> get stories => _stories;
  Story? get currentStory => _currentStory;
  bool get isGenerating => _isGenerating;
  String get currentResponse => _currentResponse;
  List<BranchingChoice> get branchingChoices => _branchingChoices;
  bool get isAITurn => _isAITurn;
  String? get error => _error;

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

  void createStory(String title, String genre, String premise) {
    _currentStory = Story(title: title, genre: genre, premise: premise);
    _stories.add(_currentStory!);
    notifyListeners();
    _generateInitialChapter();
  }

  void selectStory(Story story) {
    _currentStory = story;
    _branchingChoices = [];
    _currentResponse = '';
    _isAITurn = false;
    notifyListeners();
  }

  void _generateInitialChapter() async {
    if (_currentStory == null) return;
    _isGenerating = true;
    _isAITurn = true;
    _error = null;
    _currentResponse = '';
    _branchingChoices = [];
    notifyListeners();

    try {
      final service = _createAIService();
      final buffer = StringBuffer();
      final systemPrompt = 'You are a creative storyteller. Write the opening chapter of a ${_currentStory!.genre} story based on this premise:\n\n${_currentStory!.premise}\n\nWrite a vivid, engaging first chapter (2-3 paragraphs). End with a natural hook that sets up where the story could go next.';

      await for (final chunk in service.streamResponse(
        message: 'Write the opening chapter for a ${_currentStory!.genre} story titled "${_currentStory!.title}" with premise: ${_currentStory!.premise}',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentResponse = buffer.toString();
        notifyListeners();
      }

      final content = buffer.toString();
      if (content.isNotEmpty) {
        _currentStory!.chapters.add(Chapter(content: content, author: AuthorType.ai));
        _currentStory!.updatedAt = DateTime.now();
        _generateBranchingChoices(content);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isGenerating = false;
      _isAITurn = false;
      notifyListeners();
    }
  }

  void _generateBranchingChoices(String lastChapter) async {
    if (_currentStory == null) return;
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final service = _createAIService();
      final fullStory = _currentStory!.chapters.map((c) => '[${c.author == AuthorType.user ? "You" : "Narrator"}]\n${c.content}').join('\n\n');
      final prompt = 'Based on the story so far, suggest 3 distinct branching narrative paths for what happens next. '
          'Return your response as a JSON array of objects with "label" (short choice name, 2-5 words) and "prompt" (2-3 sentence description of that path). '
          'Format: [{"label": "...", "prompt": "..."}]';

      final buffer = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: prompt,
        history: [{'role': 'user', 'content': fullStory}],
        systemPrompt: 'You suggest creative narrative branches. Always respond with valid JSON only.',
      )) {
        buffer.write(chunk);
        notifyListeners();
      }

      final raw = buffer.toString().trim();
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1) {
        final json = raw.substring(jsonStart, jsonEnd + 1);
        try {
          final list = _JsonDecoder().convert(json) as List;
          _branchingChoices = list.map((e) {
            final map = e as Map<String, dynamic>;
            return BranchingChoice(
              label: map['label']?.toString() ?? 'Continue',
              prompt: map['prompt']?.toString() ?? '',
            );
          }).toList();
        } catch (_) {
          _branchingChoices = [
            BranchingChoice(label: 'Continue Forward', prompt: 'The story continues along its current path.'),
            BranchingChoice(label: 'Twist Ahead', prompt: 'An unexpected revelation changes everything.'),
            BranchingChoice(label: 'New Perspective', prompt: 'We see events from another character\'s point of view.'),
          ];
        }
      }
    } catch (e) {
      _branchingChoices = [
        BranchingChoice(label: 'Continue Forward', prompt: 'The story continues along its current path.'),
        BranchingChoice(label: 'Twist Ahead', prompt: 'An unexpected revelation changes everything.'),
        BranchingChoice(label: 'New Perspective', prompt: 'We see events from another character\'s point of view.'),
      ];
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void selectBranch(BranchingChoice choice) {
    if (_currentStory == null) return;
    _isAITurn = true;
    _branchingChoices = [];
    notifyListeners();
    _generateAIChapter(choice.prompt, choice.label);
  }

  void skipBranches() {
    _branchingChoices = [];
    _isAITurn = false;
    notifyListeners();
  }

  void submitUserChapter(String content) {
    if (_currentStory == null || content.trim().isEmpty) return;
    _currentStory!.chapters.add(Chapter(content: content.trim(), author: AuthorType.user));
    _currentStory!.updatedAt = DateTime.now();
    _isAITurn = true;
    _branchingChoices = [];
    notifyListeners();
    _generateAIChapter('Continue the story from where the user left off.', null);
  }

  void _generateAIChapter(String direction, String? choiceLabel) async {
    if (_currentStory == null) return;
    _isGenerating = true;
    _error = null;
    _currentResponse = '';
    notifyListeners();

    try {
      final service = _createAIService();
      final buffer = StringBuffer();
      final fullStory = _currentStory!.chapters.map((c) => '[${c.author == AuthorType.user ? "You" : "Narrator"}]\n${c.content}').join('\n\n');
      final systemPrompt = 'You are a creative storyteller. Write the next chapter (2-3 paragraphs) continuing this story. '
          'Maintain consistent tone, characters, and pacing. End with a hook. Direction: $direction';

      await for (final chunk in service.streamResponse(
        message: 'Write the next chapter following this direction: $direction',
        history: [{'role': 'user', 'content': fullStory}],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentResponse = buffer.toString();
        notifyListeners();
      }

      final content = buffer.toString();
      if (content.isNotEmpty) {
        _currentStory!.chapters.add(Chapter(content: content, author: AuthorType.ai, choiceLabel: choiceLabel));
        _currentStory!.updatedAt = DateTime.now();
        _generateBranchingChoices(content);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      _isAITurn = false;
      notifyListeners();
    }
  }

  void clearCurrentStory() {
    _currentStory = null;
    _currentResponse = '';
    _branchingChoices = [];
    _isAITurn = false;
    _isGenerating = false;
    _error = null;
    notifyListeners();
  }
}

class _JsonDecoder {
  int _pos = 0;

  dynamic convert(String source) {
    _pos = 0;
    _skipWhitespace(source);
    final result = _parseValue(source);
    return result;
  }

  dynamic _parseValue(String source) {
    _skipWhitespace(source);
    if (_pos >= source.length) throw FormatException('Unexpected end');
    final c = source[_pos];
    if (c == '{') return _parseObject(source);
    if (c == '[') return _parseArray(source);
    if (c == '"') return _parseString(source);
    if (c == 't' || c == 'f') return _parseBool(source);
    if (c == 'n') return _parseNull(source);
    return _parseNumber(source);
  }

  Map<String, dynamic> _parseObject(String source) {
    _pos++;
    final map = <String, dynamic>{};
    _skipWhitespace(source);
    if (_pos < source.length && source[_pos] == '}') {
      _pos++;
      return map;
    }
    while (_pos < source.length) {
      _skipWhitespace(source);
      if (_pos >= source.length) throw FormatException('Unexpected end');
      if (source[_pos] == '}') {
        _pos++;
        return map;
      }
      final key = _parseString(source);
      _skipWhitespace(source);
      if (_pos >= source.length || source[_pos] != ':') throw FormatException('Expected :');
      _pos++;
      final value = _parseValue(source);
      map[key] = value;
      _skipWhitespace(source);
      if (_pos < source.length && source[_pos] == ',') _pos++;
      else if (_pos < source.length && source[_pos] == '}') {
        _pos++;
        return map;
      }
    }
    throw FormatException('Unterminated object');
  }

  List<dynamic> _parseArray(String source) {
    _pos++;
    final list = <dynamic>[];
    _skipWhitespace(source);
    if (_pos < source.length && source[_pos] == ']') {
      _pos++;
      return list;
    }
    while (_pos < source.length) {
      _skipWhitespace(source);
      if (_pos >= source.length) throw FormatException('Unexpected end');
      if (source[_pos] == ']') {
        _pos++;
        return list;
      }
      list.add(_parseValue(source));
      _skipWhitespace(source);
      if (_pos < source.length && source[_pos] == ',') _pos++;
      else if (_pos < source.length && source[_pos] == ']') {
        _pos++;
        return list;
      }
    }
    throw FormatException('Unterminated array');
  }

  String _parseString(String source) {
    _pos++;
    final sb = StringBuffer();
    while (_pos < source.length) {
      final c = source[_pos];
      if (c == '"') {
        _pos++;
        return sb.toString();
      }
      if (c == '\\') {
        _pos++;
        if (_pos >= source.length) throw FormatException('Unexpected end');
        final esc = source[_pos];
        if (esc == '"' || esc == '\\' || esc == '/') sb.write(esc);
        else if (esc == 'b') sb.write('\b');
        else if (esc == 'f') sb.write('\f');
        else if (esc == 'n') sb.write('\n');
        else if (esc == 'r') sb.write('\r');
        else if (esc == 't') sb.write('\t');
        else if (esc == 'u') {
          if (_pos + 4 >= source.length) throw FormatException('Invalid unicode');
          final hex = source.substring(_pos + 1, _pos + 5);
          sb.writeCharCode(int.parse(hex, radix: 16));
          _pos += 4;
        }
        _pos++;
      } else {
        sb.write(c);
        _pos++;
      }
    }
    throw FormatException('Unterminated string');
  }

  num _parseNumber(String source) {
    final start = _pos;
    if (_pos < source.length && source[_pos] == '-') _pos++;
    while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++;
    if (_pos < source.length && source[_pos] == '.') {
      _pos++;
      while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++;
    }
    if (_pos < source.length && (source[_pos] == 'e' || source[_pos] == 'E')) {
      _pos++;
      if (_pos < source.length && (source[_pos] == '+' || source[_pos] == '-')) _pos++;
      while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++;
    }
    final numStr = source.substring(start, _pos);
    if (numStr.contains('.') || numStr.contains('e') || numStr.contains('E')) {
      return double.parse(numStr);
    }
    return int.parse(numStr);
  }

  bool _parseBool(String source) {
    if (source.startsWith('true', _pos)) {
      _pos += 4;
      return true;
    }
    if (source.startsWith('false', _pos)) {
      _pos += 5;
      return false;
    }
    throw FormatException('Expected bool');
  }

  dynamic _parseNull(String source) {
    if (source.startsWith('null', _pos)) {
      _pos += 4;
      return null;
    }
    throw FormatException('Expected null');
  }

  void _skipWhitespace(String source) {
    while (_pos < source.length && source.codeUnitAt(_pos) <= 32) _pos++;
  }
}
