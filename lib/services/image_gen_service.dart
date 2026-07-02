import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageGenService {
  Future<String> generateImage(String prompt) async {
    final url = Uri.parse(
      'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Image generation failed (${response.statusCode})');
    }

    return base64Encode(response.bodyBytes);
  }
}
