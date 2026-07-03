import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoGenService {
  final String? apiKey;

  const VideoGenService({this.apiKey});

  Future<String> generateVideo(String prompt) async {
    final uri = Uri.parse(
      'https://gen.pollinations.ai/video/${Uri.encodeComponent(prompt)}',
    ).replace(queryParameters: {
      'model': 'wan-fast',
      'duration': '5',
      if (apiKey != null && apiKey!.isNotEmpty) 'key': apiKey,
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'NexusChat/1.0',
        if (apiKey != null && apiKey!.isNotEmpty)
          'Authorization': 'Bearer $apiKey',
      },
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
        'Video generation failed (${response.statusCode})',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/nexus_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await file.writeAsBytes(response.bodyBytes);

    return file.path;
  }
}
