import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class ClaudeService implements AIService {
  final String apiKey;
  final String model;

  ClaudeService({required this.apiKey, this.model = 'claude-sonnet-4-20250514'});

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
    String webSearchContext = '',
    String? imageBase64,
    String systemPrompt = '',
  }) async* {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    String effectivePrompt = systemPrompt.isNotEmpty
        ? systemPrompt
        : 'You are the Nexus AI assistant. You provide helpful, concise, and accurate responses.';
    if (webSearchContext.isNotEmpty) {
      effectivePrompt += '\n\nHere are web search results to help answer the user:\n$webSearchContext\n\nUse these search results to provide an informed answer. Cite sources where appropriate.';
    }

    final List<Map<String, Object>> apiMessages = [];
    for (final h in history) {
      if (h['role'] == 'system') continue;
      apiMessages.add({'role': h['role']!, 'content': h['content']!});
    }

    if (imageBase64 != null) {
      apiMessages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message},
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/jpeg',
              'data': imageBase64,
            },
          },
        ],
      });
    } else {
      apiMessages.add({'role': 'user', 'content': message});
    }

    final body = <String, Object>{
      'model': model,
      'max_tokens': 4096,
      'messages': apiMessages,
    };
    if (effectivePrompt.isNotEmpty) {
      body['system'] = effectivePrompt;
    }

    final response = await http.post(
      url,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'] as List;
      if (content.isNotEmpty && content[0]['type'] == 'text') {
        yield content[0]['text'] as String;
      }
    } else {
      throw Exception('Claude API error (${response.statusCode}): ${response.body}');
    }
  }
}
