import 'dart:convert';
import 'package:http/http.dart' as http;

class WebFetchService {
  Future<String> fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return 'Invalid URL: $url';
    }

    final response = await http
        .get(uri, headers: {
          'User-Agent': 'NexusAgent/1.0',
          'Accept': 'text/html,text/plain,application/json,*/*',
        })
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      return 'Fetch failed (${response.statusCode}): ${response.reasonPhrase}';
    }

    final ct = response.headers['content-type'] ?? '';
    if (ct.contains('application/json')) {
      final obj = jsonDecode(response.body);
      return const JsonEncoder.withIndent('  ').convert(obj);
    }

    final body = response.body;
    if (body.length > 5000) {
      return '${body.substring(0, 5000)}\n\n[... truncated, full length: ${body.length} chars]';
    }
    return body;
  }
}
