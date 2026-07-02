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
    String? imageBase64,
  }) async* {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final List<Map<String, Object>> apiMessages = [];

    String systemPrompt = 'You are the Nexus AI assistant. You provide helpful, concise, and accurate responses.';
    if (webSearchContext.isNotEmpty) {
      systemPrompt += '\n\nHere are web search results to help answer the user:\n$webSearchContext\n\nUse these search results to provide an informed answer. Cite sources where appropriate.';
    }
    apiMessages.add({'role': 'system', 'content': systemPrompt});

    for (final h in history) {
      apiMessages.add({'role': h['role']!, 'content': h['content']!});
    }

    if (imageBase64 != null) {
      final visionModel = model.contains('vision')
          ? model
          : 'llama-3.2-11b-vision-preview';
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

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': visionModel,
          'messages': apiMessages,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        yield content;
      } else {
        throw Exception('Groq API error (${response.statusCode}): ${response.body}');
      }
    } else {
      apiMessages.add({'role': 'user', 'content': message});

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': apiMessages,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        yield content;
      } else {
        throw Exception('Groq API error (${response.statusCode}): ${response.body}');
      }
    }
  }
}
