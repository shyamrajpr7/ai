import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;

  GeminiService(this.apiKey);

  @override
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash:streamGenerateContent?alt=sse&key=$apiKey',
    );

    final contents = history.map((h) => {
      'role': h['role'] == 'assistant' ? 'model' : h['role'],
      'parts': [{'text': h['content']}],
    }).toList();
    contents.add({
      'role': 'user',
      'parts': [{'text': message}],
    });

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 8192,
        },
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Gemini API error (${response.statusCode}): $errorBody');
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
            final candidates = json['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]?['text'] as String? ?? '';
                if (text.isNotEmpty) yield text;
              }
            }
          } catch (_) {}
        }
      }
    }
  }
}
