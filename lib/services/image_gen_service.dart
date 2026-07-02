import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageGenService {
  Future<String> generateImage(String prompt) async {
    final url = Uri.parse(
      'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'NexusChat/1.0'},
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
        'Image generation failed (${response.statusCode})',
      );
    }

    return base64Encode(response.bodyBytes);
  }
}
