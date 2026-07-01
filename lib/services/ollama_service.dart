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

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Ollama error (${response.statusCode}): $errorBody');
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
