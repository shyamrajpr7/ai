import 'package:flutter/material.dart';
import 'chat_provider.dart';

class CodeStudioProvider extends ChangeNotifier {
  final ChatProvider _chatProvider;

  String _code = '// Write your code here\nvoid main() {\n  print("Hello, World!");\n}';
  String _language = 'dart';
  String _aiResponse = '';
  bool _isProcessing = false;
  String? _lastAction;

  List<Map<String, String>> _sessions = [];

  String get code => _code;
  String get language => _language;
  String get aiResponse => _aiResponse;
  bool get isProcessing => _isProcessing;
  String? get lastAction => _lastAction;
  int get sessionCount => _sessions.length;

  CodeStudioProvider(this._chatProvider);

  void setCode(String code) {
    _code = code;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void clearResponse() {
    _aiResponse = '';
    _lastAction = null;
    notifyListeners();
  }

  void _addSession(String action, String response) {
    _sessions.add({
      'action': action,
      'code': _code,
      'language': _language,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> explainCode() async {
    await _streamAiResponse(
      action: 'explain',
      systemPrompt: 'You are an expert code explainer. '
          'Explain the following code in detail: what it does, how it works, '
          'key concepts, and any notable patterns. Be concise but thorough.',
    );
  }

  Future<void> fixBugs() async {
    await _streamAiResponse(
      action: 'fix',
      systemPrompt: 'You are an expert debugger. Analyze the following code '
          'for bugs, errors, and potential issues. Provide the corrected code '
          'and explain what was wrong. Be concise.',
    );
  }

  Future<void> generateCode(String prompt) async {
    await _streamAiResponse(
      action: 'generate',
      systemPrompt: 'You are an expert programmer. Generate code based on the '
          'following request. Output only the code with brief comments. '
          'Language: $_language.',
      userMessage: prompt,
    );
  }

  Future<void> runCode() async {
    await _streamAiResponse(
      action: 'run',
      systemPrompt: 'You are a code interpreter. Analyze the following code '
          'and simulate its execution. Show the expected output, trace the '
          'execution flow, and highlight any side effects or errors. '
          'If the code has a main function or entry point, describe what '
          'would happen when it runs.',
    );
  }

  Future<void> _streamAiResponse({
    required String action,
    required String systemPrompt,
    String? userMessage,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _lastAction = action;
    _aiResponse = '';
    notifyListeners();

    try {
      final service = _chatProvider.createAIService();
      final message = userMessage ?? _code;
      final history = <Map<String, String>>[
        {'role': 'user', 'content': '```$_language\n$_code\n```'},
      ];

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: message,
        history: history,
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
        _aiResponse = response.toString();
        notifyListeners();
      }

      _addSession(action, _aiResponse);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _aiResponse = 'Error: ${e.toString().replaceAll("Exception: ", "")}';
      _isProcessing = false;
      notifyListeners();
    }
  }
}
