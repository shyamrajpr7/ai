import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/context_attachment.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class ContextWeaverProvider extends ChangeNotifier {
  final HiveService _hiveService;

  ContextWeaverProvider(this._hiveService);

  Map<String, List<ContextAttachment>> _attachments = {};
  bool _initialized = false;
  bool _isProcessing = false;

  bool get initialized => _initialized;
  bool get isProcessing => _isProcessing;

  List<ContextAttachment> getAttachments(String conversationId) {
    if (conversationId.isEmpty) return [];
    return _attachments[conversationId] ?? [];
  }

  List<ContextAttachment> getEnabledAttachments(String conversationId) {
    return getAttachments(conversationId).where((a) => a.enabled).toList();
  }

  String buildContextString(String conversationId) {
    final active = getEnabledAttachments(conversationId);
    if (active.isEmpty) return '';

    final parts = active.map((a) {
      final type = a.type == 'url'
          ? 'Web Page'
          : a.type == 'youtube'
              ? 'YouTube Video'
              : a.type == 'file'
                  ? 'File'
                  : 'Note';
      final header = '--- Attached $type: ${a.title} ---';
      final sourceLine = 'Source: ${a.source}';
      return '$header\n$sourceLine\n${a.content}';
    });

    return '\n\n--- Attached Context ---\n${parts.join('\n\n')}';
  }

  Future<void> load() async {
    final raw = _hiveService.loadContextAttachments();
    _attachments = raw.map((k, v) => MapEntry(
          k,
          (v as List)
              .map((e) =>
                  ContextAttachment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
    _initialized = true;
    notifyListeners();
  }

  Future<void> addAttachment(
      String conversationId, ContextAttachment attachment) async {
    _attachments.putIfAbsent(conversationId, () => []);
    _attachments[conversationId]!.insert(0, attachment);
    await _save();
    notifyListeners();
  }

  Future<void> removeAttachment(String conversationId, String id) async {
    final list = _attachments[conversationId];
    if (list == null) return;
    list.removeWhere((a) => a.id == id);
    if (list.isEmpty) _attachments.remove(conversationId);
    await _save();
    notifyListeners();
  }

  Future<void> toggleAttachment(String conversationId, String id) async {
    final list = _attachments[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    list[idx].enabled = !list[idx].enabled;
    list[idx].updatedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<void> updateContent(
      String conversationId, String id, String content) async {
    final list = _attachments[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    list[idx].content = content;
    list[idx].updatedAt = DateTime.now();
    await _save();
    notifyListeners();
  }

  Future<String> fetchUrlContent(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (compatible; NexusAI/1.0; +https://nexusai.app)',
      });
      if (response.statusCode == 200) {
        final body = response.body;
        final titleMatch =
            RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
                .firstMatch(body);
        final title = titleMatch?.group(1)?.trim() ?? url;

        final text = _stripHtml(body);
        final truncated = text.length > 8000 ? text.substring(0, 8000) : text;
        return '$title|||$truncated';
      }
    } catch (_) {}
    return '$url|||(Could not fetch content from this URL)';
  }

  Future<Map<String, String>> fetchYouTubeInfo(String url) async {
    try {
      final videoId = _extractYouTubeId(url);
      if (videoId == null) {
        return {'title': url, 'content': '(Could not identify YouTube video)'};
      }
      final oembedUri = Uri.parse(
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json');
      final response = await http.get(oembedUri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? url;
        final author = data['author_name'] as String? ?? 'Unknown';
        final content =
            'YouTube Video: "$title" by $author\n\nURL: https://youtube.com/watch?v=$videoId\n\n'
            'The AI can analyze this video based on its title and description context. '
            'For detailed transcript analysis, the video transcript would need to be provided separately.';
        return {'title': title, 'content': content};
      }
    } catch (_) {}
    return {'title': url, 'content': '(Could not fetch YouTube video info)'};
  }

  Future<void> addUrlAttachment(String conversationId, String url) async {
    _isProcessing = true;
    notifyListeners();

    String title;
    String content;

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final info = await fetchYouTubeInfo(url);
      title = info['title']!;
      content = info['content']!;
      await addAttachment(
        conversationId,
        ContextAttachment(
          id: _uuid.v4(),
          type: 'youtube',
          title: title,
          content: content,
          source: url,
        ),
      );
    } else {
      final result = await fetchUrlContent(url);
      final separator = result.indexOf('|||');
      title = result.substring(0, separator);
      content = result.substring(separator + 3);
      await addAttachment(
        conversationId,
        ContextAttachment(
          id: _uuid.v4(),
          type: 'url',
          title: title,
          content: content,
          source: url,
        ),
      );
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> addFileAttachment(String conversationId) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final filePath = file.path;

        String content;
        if (filePath != null) {
          final bytes = await File(filePath).readAsBytes();
          content = utf8.decode(bytes, allowMalformed: true);
          if (content.length > 10000) {
            content = content.substring(0, 10000);
          }
          final type = file.extension?.toLowerCase() ?? '';
          if (!['txt', 'md', 'csv', 'json', 'xml', 'html', 'yaml', 'yml', 'log']
              .contains(type)) {
            content =
                '(Binary file: $fileName, ${_formatSize(bytes.length)})\n'
                'The AI can reference this file by name but cannot read its raw content inline.\n'
                'File type: .$type\n'
                'File size: ${_formatSize(bytes.length)}';
          }
        } else {
          content = '(Could not access file: $fileName)';
        }

        await addAttachment(
          conversationId,
          ContextAttachment(
            id: _uuid.v4(),
            type: 'file',
            title: fileName,
            content: content,
            source: fileName,
          ),
        );
      }
    } catch (e) {
      debugPrint('File pick error: $e');
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> addTextAttachment(
      String conversationId, String title, String text) async {
    final truncated =
        text.length > 10000 ? text.substring(0, 10000) : text;
    await addAttachment(
      conversationId,
      ContextAttachment(
        id: _uuid.v4(),
        type: 'text',
        title: title,
        content: truncated,
        source: 'Manual entry',
      ),
    );
  }

  String _stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
        r'(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _save() async {
    await _hiveService.saveContextAttachments(_attachments);
  }
}
