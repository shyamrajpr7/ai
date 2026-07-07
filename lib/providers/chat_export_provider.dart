import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_conversation.dart';
import 'chat_provider.dart';

class ExportTheme {
  final String name;
  final Color primary;
  final Color surface;
  final Color userBubble;
  final Color aiBubble;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const ExportTheme({
    required this.name,
    required this.primary,
    required this.surface,
    required this.userBubble,
    required this.aiBubble,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });
}

const exportThemes = [
  ExportTheme(
    name: 'Midnight',
    primary: Color(0xFF0A0A0F),
    surface: Color(0xFF12121A),
    userBubble: Color(0xFF1A1A2E),
    aiBubble: Color(0xFF0D0D15),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAAAAAA),
    accent: Color(0xFF7C4DFF),
  ),
  ExportTheme(
    name: 'Aurora',
    primary: Color(0xFF0A1A0F),
    surface: Color(0xFF0F1F14),
    userBubble: Color(0xFF1A2E1A),
    aiBubble: Color(0xFF0D1F0F),
    textPrimary: Color(0xFFE0FFE0),
    textSecondary: Color(0xFF88AA88),
    accent: Color(0xFF4DFF7C),
  ),
  ExportTheme(
    name: 'Sunset',
    primary: Color(0xFF1A0F0A),
    surface: Color(0xFF221712),
    userBubble: Color(0xFF2E1A1A),
    aiBubble: Color(0xFF1F0F0D),
    textPrimary: Color(0xFFFFE8D0),
    textSecondary: Color(0xFFAA8877),
    accent: Color(0xFFFF7C4D),
  ),
  ExportTheme(
    name: 'Ocean',
    primary: Color(0xFF0A0F1A),
    surface: Color(0xFF121722),
    userBubble: Color(0xFF1A1A2E),
    aiBubble: Color(0xFF0D0F1F),
    textPrimary: Color(0xFFD0E0FF),
    textSecondary: Color(0xFF7788AA),
    accent: Color(0xFF4D7CFF),
  ),
  ExportTheme(
    name: 'Minimal',
    primary: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    userBubble: Color(0xFFE8E8E8),
    aiBubble: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF666666),
    accent: Color(0xFF333333),
  ),
];

class ChatExportProvider extends ChangeNotifier {
  final ChatProvider _chatProvider;

  ChatExportProvider(this._chatProvider);

  ChatConversation? _selectedConversation;
  String _format = 'markdown';
  int _themeIndex = 0;
  String _previewContent = '';
  bool _isGenerating = false;

  ChatConversation? get selectedConversation => _selectedConversation;
  String get format => _format;
  int get themeIndex => _themeIndex;
  String get previewContent => _previewContent;
  bool get isGenerating => _isGenerating;
  ExportTheme get theme => exportThemes[_themeIndex];

  List<ChatConversation> get conversations => _chatProvider.conversations;

  void selectConversation(ChatConversation? conv) {
    _selectedConversation = conv;
    _previewContent = '';
    notifyListeners();
  }

  void setFormat(String format) {
    _format = format;
    _previewContent = '';
    notifyListeners();
  }

  void setTheme(int index) {
    _themeIndex = index;
    notifyListeners();
  }

  void generatePreview() {
    if (_selectedConversation == null) return;
    _isGenerating = true;
    notifyListeners();

    switch (_format) {
      case 'markdown':
        _previewContent = _generateMarkdown(_selectedConversation!);
      case 'html':
        _previewContent = _generateHtml(_selectedConversation!);
      case 'text':
        _previewContent = _generateText(_selectedConversation!);
    }

    _isGenerating = false;
    notifyListeners();
  }

  String _colorToHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}'
      '${c.green.toRadixString(16).padLeft(2, '0')}'
      '${c.blue.toRadixString(16).padLeft(2, '0')}';

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _generateMarkdown(ChatConversation conv) {
    final buf = StringBuffer();
    buf.writeln('# ${conv.title}');
    buf.writeln();
    buf.writeln('> Exported on ${_formatDate(DateTime.now())}');
    buf.writeln('---');
    buf.writeln();

    for (final msg in conv.messages) {
      if (msg.content.isEmpty) continue;
      final time = _formatTimestamp(msg.timestamp);
      if (msg.role == 'user') {
        buf.writeln('### 👤 You ($time)');
        buf.writeln();
        buf.writeln('> ${msg.content}');
      } else {
        buf.writeln('### 🤖 Nexus AI ($time)');
        buf.writeln();
        buf.writeln(msg.content);
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    return buf.toString().trim();
  }

  String _generateHtml(ChatConversation conv) {
    final t = theme;
    final bg = _colorToHex(t.primary);
    final surface = _colorToHex(t.surface);
    final userBg = _colorToHex(t.userBubble);
    final aiBg = _colorToHex(t.aiBubble);
    final text = _colorToHex(t.textPrimary);
    final muted = _colorToHex(t.textSecondary);
    final accent = _colorToHex(t.accent);

    final messages = conv.messages.map((msg) {
      if (msg.content.isEmpty) return '';
      final time = _formatTimestamp(msg.timestamp);
      final roleLabel = msg.role == 'user' ? 'You' : 'Nexus AI';
      final icon = msg.role == 'user' ? '👤' : '🤖';
      final align = msg.role == 'user' ? 'flex-end' : 'flex-start';
      final bubbleBg = msg.role == 'user' ? userBg : aiBg;

      final escaped = msg.content
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;');

      final withCode = escaped.replaceAllMapped(
        RegExp(r'```(\w*)\n([\s\S]*?)```'),
        (m) => '<pre><code>${m.group(2)!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</code></pre>',
      );
      final withInline = withCode.replaceAllMapped(
        RegExp(r'`([^`]+)`'),
        (m) => '<code>${m.group(1)}</code>',
      );
      final withBold = withInline.replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'),
        (m) => '<strong>${m.group(1)}</strong>',
      );
      final withNewlines = withBold.replaceAll('\n', '<br>');

      return '''
        <div style="display:flex;justify-content:$align;margin-bottom:16px">
          <div style="max-width:80%;background:$bubbleBg;border-radius:16px;padding:12px 16px;border:1px solid rgba(255,255,255,0.06)">
            <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
              <span>$icon</span>
              <span style="color:$accent;font-weight:600;font-size:13px">$roleLabel</span>
              <span style="color:$muted;font-size:11px">$time</span>
            </div>
            <div style="color:$text;font-size:14px;line-height:1.6">$withNewlines</div>
          </div>
        </div>
      ''';
    }).join('\n');

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${conv.title} - Chat Export</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:$bg;color:$text;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;padding:0;margin:0}
  .header{background:$surface;padding:24px 32px;border-bottom:1px solid rgba(255,255,255,0.06)}
  .header h1{font-size:22px;font-weight:700;margin-bottom:4px;color:$text}
  .header p{font-size:13px;color:$muted}
  .content{max-width:720px;margin:0 auto;padding:24px 16px}
  pre{background:rgba(0,0,0,0.3);border-radius:8px;padding:12px;overflow-x:auto;margin:8px 0;font-size:13px}
  code{font-family:'SF Mono','Fira Code','Consolas',monospace;background:rgba(0,0,0,0.2);padding:2px 6px;border-radius:4px;font-size:13px}
  pre code{background:none;padding:0}
  .footer{text-align:center;padding:32px;color:$muted;font-size:12px}
</style>
</head>
<body>
<div class="header">
  <h1>${conv.title}</h1>
  <p>Exported on ${_formatDate(DateTime.now())} · ${conv.messages.length} messages</p>
</div>
<div class="content">
$messages
</div>
<div class="footer">Generated by Nexus AI · Chat Export Studio</div>
</body>
</html>''';
  }

  String _generateText(ChatConversation conv) {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════');
    buf.writeln('  ${conv.title}');
    buf.writeln('  Exported on ${_formatDate(DateTime.now())}');
    buf.writeln('═══════════════════════════════════════');
    buf.writeln();

    for (final msg in conv.messages) {
      if (msg.content.isEmpty) continue;
      final time = _formatTimestamp(msg.timestamp);
      final prefix = msg.role == 'user' ? '👤 You' : '🤖 Nexus';
      buf.writeln('[$time] $prefix');
      buf.writeln('─────────────────────────────────────');
      buf.writeln(msg.content);
      buf.writeln();
    }

    return buf.toString().trim();
  }

  Future<void> copyToClipboard() async {
    if (_previewContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _previewContent));
  }
}
