import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class GroqService implements AIService {
  final String apiKey;
  final String model;
  final double temperature;

  GroqService({required this.apiKey, this.model = 'llama-3.1-8b-instant', this.temperature = 0.6});

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
    String webSearchContext = '',
    String? imageBase64,
    String systemPrompt = '',
  }) async* {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
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

    final effectiveModel = imageBase64 != null && !model.contains('vision')
        ? 'llama-3.2-11b-vision-preview'
        : model;

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

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': effectiveModel,
        'messages': apiMessages,
        'temperature': temperature,
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {}
          }
        }
      } else {
        final body = await response.stream.bytesToString();
        throw Exception('Groq API error (${response.statusCode}): $body');
      }
    } finally {
      client.close();
    }
  }
}
