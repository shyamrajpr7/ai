import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class GroqService implements AIService {
  final String apiKey;
  final String model;

  GroqService({required this.apiKey, this.model = 'llama-3.1-8b-instant'});

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
    String webSearchContext = '',
  }) async* {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

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
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          ...messages,
        ],
        'temperature': 0.6,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      yield content;
    } else {
      final errorBody = response.body;
      throw Exception('Groq API error (${response.statusCode}): $errorBody');
    }
  }
}
