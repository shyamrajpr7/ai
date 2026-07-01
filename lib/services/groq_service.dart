import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class GroqService implements AIService {
  final String apiKey;
  final String model;

  GroqService({required this.apiKey, this.model = 'llama3-70b-8192'});

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
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

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
        'temperature': 0.7,
        'max_tokens': 8192,
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Groq API error (${response.statusCode}): $errorBody');
    }

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final idx = buffer.indexOf('\n');
        final line = buffer.substring(0, idx).trim();
        buffer = buffer.substring(idx + 1);

        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]' || data.isEmpty) continue;
          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map?;
              if (delta != null) {
                final content = delta['content'] as String? ?? '';
                if (content.isNotEmpty) yield content;
              }
            }
          } catch (_) {}
        }
      }
    }
  }
}
