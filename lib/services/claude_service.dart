import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class ClaudeService implements AIService {
  final String apiKey;
  final String model;
  final double temperature;

  ClaudeService({required this.apiKey, this.model = 'claude-sonnet-4-20250514', this.temperature = 0.6});

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

    final requestBody = <String, Object>{
      'model': model,
      'max_tokens': 4096,
      'temperature': temperature,
      'stream': true,
      'messages': apiMessages,
    };
    if (effectivePrompt.isNotEmpty) {
      requestBody['system'] = effectivePrompt;
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      });
      request.body = jsonEncode(requestBody);

      final response = await client.send(request);

      if (response.statusCode == 200) {
        String? currentEvent;
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7);
          } else if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (currentEvent == 'content_block_delta') {
              try {
                final json = jsonDecode(data);
                final text = json['delta']?['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              } catch (_) {}
            }
            currentEvent = null;
          }
        }
      } else {
        final body = await response.stream.bytesToString();
        throw Exception('Claude API error (${response.statusCode}): $body');
      }
    } finally {
      client.close();
    }
  }
}
