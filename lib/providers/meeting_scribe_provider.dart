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

class ActionItem {
  final String id;
  String description;
  String? assignee;
  bool done;

  ActionItem({
    String? id,
    required this.description,
    this.assignee,
    this.done = false,
  }) : id = id ?? _uuid.v4();
}

class Meeting {
  final String id;
  String title;
  final DateTime date;
  Duration duration;
  String transcript;
  String summary;
  List<String> keyPoints;
  List<ActionItem> actionItems;

  Meeting({
    String? id,
    required this.title,
    DateTime? date,
    this.duration = Duration.zero,
    this.transcript = '',
    this.summary = '',
    List<String>? keyPoints,
    List<ActionItem>? actionItems,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now(),
        keyPoints = keyPoints ?? [],
        actionItems = actionItems ?? [];
}

class MeetingScribeProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  List<Meeting> _meetings = [];
  Meeting? _currentMeeting;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _liveTranscript = '';
  DateTime? _recordingStarted;
  String? _error;
  String _currentResponse = '';

  MeetingScribeProvider(this._settingsProvider);

  List<Meeting> get meetings => _meetings;
  Meeting? get currentMeeting => _currentMeeting;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String get liveTranscript => _liveTranscript;
  String? get error => _error;
  String get currentResponse => _currentResponse;
  Duration get recordingDuration => _recordingStarted != null ? DateTime.now().difference(_recordingStarted!) : Duration.zero;

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

  void startRecording() {
    _isRecording = true;
    _liveTranscript = '';
    _recordingStarted = DateTime.now();
    _currentMeeting = Meeting(title: 'Meeting ${_meetings.length + 1}');
    _error = null;
    notifyListeners();
  }

  void updateTranscript(String text) {
    _liveTranscript = text;
    notifyListeners();
  }

  void stopRecording() {
    if (!_isRecording) return;
    _isRecording = false;
    if (_currentMeeting != null) {
      _currentMeeting!.transcript = _liveTranscript;
      _currentMeeting!.duration = _recordingStarted != null
          ? DateTime.now().difference(_recordingStarted!)
          : Duration.zero;
    }
    notifyListeners();
  }

  void cancelRecording() {
    _isRecording = false;
    _liveTranscript = '';
    _recordingStarted = null;
    _currentMeeting = null;
    notifyListeners();
  }

  Future<void> processMeeting() async {
    if (_currentMeeting == null || _currentMeeting!.transcript.trim().isEmpty) return;
    _isProcessing = true;
    _error = null;
    _currentResponse = '';
    notifyListeners();

    try {
      final service = _createAIService();
      final transcript = _currentMeeting!.transcript;
      final buffer = StringBuffer();
      const systemPrompt = 'You are a meeting scribe. Analyze the transcript and return a JSON object with: '
          '"title" (concise meeting title), "summary" (2-3 paragraph summary), '
          '"keyPoints" (array of strings, 3-6 key points), '
          '"actionItems" (array of objects with "description" and optional "assignee"). '
          'Example: {"title":"Sprint Planning","summary":"...","keyPoints":["..."],"actionItems":[{"description":"...","assignee":"..."}]}';

      await for (final chunk in service.streamResponse(
        message: transcript,
        history: [],
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentResponse = buffer.toString();
        notifyListeners();
      }

      final raw = buffer.toString().trim();
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final json = raw.substring(jsonStart, jsonEnd + 1);
        try {
          final map = _MeetingJsonDecoder().convert(json) as Map<String, dynamic>;
          if (map['title'] != null) _currentMeeting!.title = map['title'].toString();
          if (map['summary'] != null) _currentMeeting!.summary = map['summary'].toString();
          if (map['keyPoints'] != null) {
            _currentMeeting!.keyPoints = (map['keyPoints'] as List).map((e) => e.toString()).toList();
          }
          if (map['actionItems'] != null) {
            _currentMeeting!.actionItems = (map['actionItems'] as List).map((e) {
              final item = e as Map<String, dynamic>;
              return ActionItem(
                description: item['description']?.toString() ?? '',
                assignee: item['assignee']?.toString(),
              );
            }).toList();
          }
        } catch (_) {}
      }

      _meetings.add(_currentMeeting!);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void selectMeeting(Meeting meeting) {
    _currentMeeting = meeting;
    notifyListeners();
  }

  void startNewMeeting() {
    _currentMeeting = null;
    _liveTranscript = '';
    _currentResponse = '';
    _error = null;
    notifyListeners();
  }

  void toggleActionItem(ActionItem item) {
    item.done = !item.done;
    notifyListeners();
  }
}

class _MeetingJsonDecoder {
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
    if (_pos < source.length && source[_pos] == '}') { _pos++; return map; }
    while (_pos < source.length) {
      _skipWhitespace(source);
      if (_pos >= source.length) throw FormatException('Unexpected end');
      if (source[_pos] == '}') { _pos++; return map; }
      final key = _parseString(source);
      _skipWhitespace(source);
      if (_pos >= source.length || source[_pos] != ':') throw FormatException('Expected :');
      _pos++;
      final value = _parseValue(source);
      map[key] = value;
      _skipWhitespace(source);
      if (_pos < source.length && source[_pos] == ',') _pos++;
      else if (_pos < source.length && source[_pos] == '}') { _pos++; return map; }
    }
    throw FormatException('Unterminated object');
  }

  List<dynamic> _parseArray(String source) {
    _pos++;
    final list = <dynamic>[];
    _skipWhitespace(source);
    if (_pos < source.length && source[_pos] == ']') { _pos++; return list; }
    while (_pos < source.length) {
      _skipWhitespace(source);
      if (_pos >= source.length) throw FormatException('Unexpected end');
      if (source[_pos] == ']') { _pos++; return list; }
      list.add(_parseValue(source));
      _skipWhitespace(source);
      if (_pos < source.length && source[_pos] == ',') _pos++;
      else if (_pos < source.length && source[_pos] == ']') { _pos++; return list; }
    }
    throw FormatException('Unterminated array');
  }

  String _parseString(String source) {
    _pos++;
    final sb = StringBuffer();
    while (_pos < source.length) {
      final c = source[_pos];
      if (c == '"') { _pos++; return sb.toString(); }
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
      } else { sb.write(c); _pos++; }
    }
    throw FormatException('Unterminated string');
  }

  num _parseNumber(String source) {
    final start = _pos;
    if (_pos < source.length && source[_pos] == '-') _pos++;
    while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++;
    if (_pos < source.length && source[_pos] == '.') { _pos++; while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++; }
    if (_pos < source.length && (source[_pos] == 'e' || source[_pos] == 'E')) { _pos++; if (_pos < source.length && (source[_pos] == '+' || source[_pos] == '-')) _pos++; while (_pos < source.length && source[_pos].codeUnitAt(0) >= 48 && source[_pos].codeUnitAt(0) <= 57) _pos++; }
    final numStr = source.substring(start, _pos);
    if (numStr.contains('.') || numStr.contains('e') || numStr.contains('E')) return double.parse(numStr);
    return int.parse(numStr);
  }

  bool _parseBool(String source) {
    if (source.startsWith('true', _pos)) { _pos += 4; return true; }
    if (source.startsWith('false', _pos)) { _pos += 5; return false; }
    throw FormatException('Expected bool');
  }

  void _skipWhitespace(String source) {
    while (_pos < source.length && source.codeUnitAt(_pos) <= 32) _pos++;
  }
}
