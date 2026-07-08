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

enum EmotionType { joy, sadness, anger, fear, surprise, disgust, neutral }

class EmotionScore {
  final EmotionType type;
  final double score;

  EmotionScore({required this.type, required this.score});
}

class EmotionResult {
  final EmotionType primaryEmotion;
  final List<EmotionScore> scores;
  final double intensity;
  final String? explanation;

  EmotionResult({
    required this.primaryEmotion,
    required this.scores,
    required this.intensity,
    this.explanation,
  });
}

class EmotionSnapshot {
  final String id;
  final EmotionResult result;
  final String sourceText;
  final DateTime timestamp;

  EmotionSnapshot({
    String? id,
    required this.result,
    required this.sourceText,
    DateTime? timestamp,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class EmotionMirrorProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  EmotionResult? _currentEmotion;
  final List<EmotionSnapshot> _timeline = [];
  bool _isAnalyzing = false;
  String _currentAnalysis = '';
  String? _error;
  String _dominantEmotionOverTime = '';

  EmotionMirrorProvider(this._settingsProvider);

  EmotionResult? get currentEmotion => _currentEmotion;
  List<EmotionSnapshot> get timeline => _timeline;
  bool get isAnalyzing => _isAnalyzing;
  String get currentAnalysis => _currentAnalysis;
  String? get error => _error;
  String get dominantEmotionOverTime => _dominantEmotionOverTime;

  AIService _createAIService() {
    final temp = min(_settingsProvider.temperature, 0.3);
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

  static const _emotionKeywords = <EmotionType, List<String>>{
    EmotionType.joy: ['happy', 'glad', 'wonderful', 'amazing', 'love', 'great', 'fantastic', 'excited', 'thrilled', 'delighted', 'joyful', 'grateful', 'blessed', 'beautiful', 'awesome', 'yay', 'woohoo', 'hurray', 'celebrate', 'fun'],
    EmotionType.sadness: ['sad', 'unhappy', 'depressed', 'miserable', 'heartbroken', 'lonely', 'grief', 'sorrow', 'disappointed', 'upset', 'crying', 'tears', 'gloomy', 'melancholy', 'hopeless', 'sorry', 'regret', 'miss'],
    EmotionType.anger: ['angry', 'furious', 'outraged', 'frustrated', 'irritated', 'annoyed', 'livid', 'enraged', 'hate', 'mad', 'fuming', 'infuriated', 'hostile', 'aggressive', 'rage'],
    EmotionType.fear: ['afraid', 'scared', 'terrified', 'anxious', 'worried', 'nervous', 'frightened', 'panicked', 'horrified', 'dread', 'fearful', 'uneasy', 'alarmed', 'petrified', 'paranoid'],
    EmotionType.surprise: ['surprised', 'shocked', 'amazed', 'astonished', 'stunned', 'speechless', 'unexpected', 'wow', 'incredible', 'unbelievable', 'startled', 'floored'],
    EmotionType.disgust: ['disgusted', 'gross', 'revolted', 'disgusting', 'nasty', 'appalled', 'horrible', 'terrible', 'awful', 'vile', 'repulsed', 'sickened', 'disturbed'],
  };

  EmotionResult _keywordAnalyze(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    final scores = <EmotionType, double>{};
    for (final type in EmotionType.values) {
      if (type == EmotionType.neutral) continue;
      var count = 0;
      final keywords = _emotionKeywords[type]!;
      for (final word in words) {
        if (keywords.any((k) => word.contains(k))) count++;
      }
      scores[type] = count / max(words.length, 1) * 4;
    }

    var maxScore = 0.0;
    var primary = EmotionType.neutral;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        primary = entry.key;
      }
    }

    final allScores = EmotionType.values.map((t) {
      final s = t == EmotionType.neutral ? (max(0, 1 - maxScore)).toDouble() : (scores[t] ?? 0).toDouble();
      return EmotionScore(type: t, score: s.clamp(0.0, 1.0).toDouble());
    }).toList();

    final intensity = scores.values.fold(0.0, (a, b) => a + b) / max(scores.length, 1);

    return EmotionResult(
      primaryEmotion: primary,
      scores: allScores,
      intensity: intensity.clamp(0, 1),
      explanation: 'Keyword-based analysis',
    );
  }

  void analyzeText(String text) {
    if (text.trim().isEmpty) return;
    _isAnalyzing = true;
    _error = null;
    _currentAnalysis = '';
    notifyListeners();

    final quickResult = _keywordAnalyze(text);
    _currentEmotion = quickResult;
    _timeline.add(EmotionSnapshot(result: quickResult, sourceText: text));
    _updateDominant();

    _analyzeWithAI(text);
  }

  Future<void> _analyzeWithAI(String text) async {
    try {
      final service = _createAIService();
      final buffer = StringBuffer();
      const systemPrompt = 'You are an emotion analysis AI. Analyze the emotional tone of the given text. '
          'Return a JSON object with: "primary" (one of: joy, sadness, anger, fear, surprise, disgust, neutral), '
          '"scores" (object with 0-1 scores for each emotion), "intensity" (0-1 overall emotional intensity), '
          '"explanation" (1 sentence). Example: {"primary":"joy","scores":{"joy":0.8,"sadness":0.1,"anger":0.0,"fear":0.0,"surprise":0.1,"disgust":0.0,"neutral":0.0},"intensity":0.7,"explanation":"The text expresses happiness and gratitude."}';

      await for (final chunk in service.streamResponse(
        message: text,
        history: _timeline.takeLast(5).map((s) => {
          'role': 'user',
          'content': 'Text: "${s.sourceText}" → Emotion: ${s.result.primaryEmotion.name}',
        }).toList(),
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentAnalysis = buffer.toString();
        notifyListeners();
      }

      final raw = buffer.toString().trim();
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final json = raw.substring(jsonStart, jsonEnd + 1);
        try {
          final map = _EmotionJsonDecoder().convert(json) as Map<String, dynamic>;
          final primaryStr = map['primary']?.toString() ?? 'neutral';
          final primary = EmotionType.values.firstWhere(
            (e) => e.name == primaryStr,
            orElse: () => EmotionType.neutral,
          );
          final scoresMap = map['scores'] as Map<String, dynamic>? ?? {};
          final scores = EmotionType.values.map((e) {
            final val = scoresMap[e.name];
            return EmotionScore(type: e, score: (val is num ? val.toDouble() : 0.0).clamp(0.0, 1.0).toDouble());
          }).toList();
          final intensity = (map['intensity'] is num ? (map['intensity'] as num).toDouble() : 0.5).clamp(0.0, 1.0).toDouble();
          final explanation = map['explanation']?.toString();

          final aiResult = EmotionResult(primaryEmotion: primary, scores: scores, intensity: intensity, explanation: explanation);
          _currentEmotion = aiResult;
          _timeline.last = EmotionSnapshot(result: aiResult, sourceText: text);
          _updateDominant();
        } catch (_) {}
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void _updateDominant() {
    if (_timeline.isEmpty) {
      _dominantEmotionOverTime = '';
      return;
    }
    final counts = <EmotionType, int>{};
    for (final s in _timeline) {
      counts[s.result.primaryEmotion] = (counts[s.result.primaryEmotion] ?? 0) + 1;
    }
    final dominant = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    _dominantEmotionOverTime = dominant.key.name;
  }

  void clear() {
    _currentEmotion = null;
    _timeline.clear();
    _currentAnalysis = '';
    _error = null;
    _dominantEmotionOverTime = '';
    notifyListeners();
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => sublist(max(0, length - n));
}

class _EmotionJsonDecoder {
  int _pos = 0;

  dynamic convert(String source) {
    _pos = 0;
    _skipWhitespace(source);
    return _parseValue(source);
  }

  dynamic _parseValue(String source) {
    _skipWhitespace(source);
    if (_pos >= source.length) throw FormatException('Unexpected end');
    final c = source[_pos];
    if (c == '{') return _parseObject(source);
    if (c == '[') return _parseArray(source);
    if (c == '"') return _parseString(source);
    if (c == 't' || c == 'f') return _parseBool(source);
    if (c == 'n') return null;
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

  void _skipWhitespace(String source) {
    while (_pos < source.length && source.codeUnitAt(_pos) <= 32) _pos++;
  }
}
