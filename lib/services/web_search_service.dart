import 'dart:convert';
import 'package:http/http.dart' as http;

class WebSearchService {
  final String apiKey;

  WebSearchService({required this.apiKey});

  Future<String> search(String query) async {
    final response = await http.post(
      Uri.parse('https://api.tavily.com/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': apiKey,
        'query': query,
        'search_depth': 'basic',
        'include_answer': true,
        'max_results': 5,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Search failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List;
    final answer = data['answer'] as String?;

    final buffer = StringBuffer();
    if (answer != null && answer.isNotEmpty) {
      buffer.writeln('Summary: $answer\n');
    }
    buffer.writeln('Search results for: $query\n');
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln('${i + 1}. ${r['title']}');
      buffer.writeln('   ${r['content']}');
      buffer.writeln('   Source: ${r['url']}\n');
    }
    return buffer.toString();
  }
}
