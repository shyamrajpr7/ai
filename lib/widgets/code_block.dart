import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'pre') return null;

    final language = _extractLanguage(element);
    final code = _extractText(element);

    if (code.isEmpty) return null;

    return _CodeBlockWidget(code: code, language: language);
  }

  String _extractLanguage(md.Element element) {
    for (final child in element.children ?? []) {
      if (child is md.Element && child.tag == 'code') {
        return child.attributes['class']?.replaceAll('language-', '') ?? '';
      }
    }
    return '';
  }

  String _extractText(md.Node node) {
    final buffer = StringBuffer();
    _extractRecursive(node, buffer);
    return buffer.toString().trim();
  }

  void _extractRecursive(md.Node node, StringBuffer buffer) {
    if (node is md.Text) {
      buffer.write(node.text);
    } else if (node is md.Element) {
      for (final child in node.children ?? []) {
        _extractRecursive(child, buffer);
      }
    }
  }
}

class _CodeBlockWidget extends StatelessWidget {
  final String code;
  final String language;

  const _CodeBlockWidget({required this.code, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (language.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied!'),
                          duration: const Duration(seconds: 1),
                          backgroundColor:
                              const Color(0xFF7C4DFF).withOpacity(0.8),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 14, color: Colors.white60),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
