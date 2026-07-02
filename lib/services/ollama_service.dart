import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class OllamaService implements AIService {
  final String endpoint;
  final String model;

  OllamaService({required this.endpoint, this.model = 'llama3.2'});

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
    String webSearchContext = '',
  }) async* {
    final url = Uri.parse('$endpoint/chat/completions');

    final messages = history.map((h) => {
      'role': h['role'],
      'content': h['content'],
    }).toList();
    messages.add({
      'role': 'user',
      'content': message,
    });

    String systemPrompt = 'You are the Nexus AI assistant. You provide helpful, concise, and accurate responses.';
    if (webSearchContext.isNotEmpty) {
      systemPrompt += '\n\nHere are web search results to help answer the user:\n$webSearchContext\n\nUse these search results to provide an informed answer. Cite sources where appropriate.';
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          ...messages,
        ],
        'stream': false,
        'temperature': 0.6,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      yield content;
    } else {
      final errorBody = response.body;
      throw Exception('Ollama error (${response.statusCode}): $errorBody');
    }
  }
}
