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
    String? imageBase64,
    String systemPrompt = '',
  }) async* {
    final url = Uri.parse('$endpoint/chat/completions');

    final List<Map<String, Object>> apiMessages = [];

    String effectivePrompt = systemPrompt.isNotEmpty
        ? systemPrompt
        : 'You are the Nexus AI assistant. You provide helpful, concise, and accurate responses.';
    if (webSearchContext.isNotEmpty) {
      effectivePrompt += '\n\nHere are web search results to help answer the user:\n$webSearchContext\n\nUse these search results to provide an informed answer. Cite sources where appropriate.';
    }
    apiMessages.add({'role': 'system', 'content': effectivePrompt});

    for (final h in history) {
      apiMessages.add({'role': h['role']!, 'content': h['content']!});
    }

    if (imageBase64 != null) {
      apiMessages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
          },
        ],
      });
    } else {
      apiMessages.add({'role': 'user', 'content': message});
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': apiMessages,
        'stream': false,
        'temperature': 0.6,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      yield content;
    } else {
      throw Exception('Ollama error (${response.statusCode}): ${response.body}');
    }
  }
}
