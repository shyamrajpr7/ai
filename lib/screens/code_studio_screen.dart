import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/code_studio_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/syntax_highlighter.dart';

class CodeStudioScreen extends StatefulWidget {
  const CodeStudioScreen({super.key});

  @override
  State<CodeStudioScreen> createState() => _CodeStudioScreenState();
}

class _CodeStudioScreenState extends State<CodeStudioScreen> {
  late TextEditingController _codeCtrl;
  late FocusNode _codeFocus;
  final _scrollCtrl = ScrollController();
  bool _showAiResponse = false;

  static const _languages = [
    'dart', 'python', 'javascript', 'typescript', 'java', 'kotlin',
    'swift', 'cpp', 'csharp', 'go', 'rust', 'ruby', 'php',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<CodeStudioProvider>();
    _codeCtrl = TextEditingController(text: provider.code);
    _codeFocus = FocusNode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _syncCode() {
    context.read<CodeStudioProvider>().setCode(_codeCtrl.text);
  }

  Widget _buildStatusBar(Color accent, CodeStudioProvider provider) {
    final lineCount = '\n'.allMatches(_codeCtrl.text).length + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$lineCount lines',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_codeCtrl.text.length} chars',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          if (provider.sessionCount > 0) ...[
            const Spacer(),
            Text(
              '${provider.sessionCount} runs',
              style: TextStyle(
                color: accent.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor(Color accent, CodeStudioProvider provider) {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.code, size: 14, color: accent.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Code',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _codeCtrl.text));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied!'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: accent.withOpacity(0.8),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded,
                        size: 14, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                focusNode: _codeFocus,
                onChanged: (_) => _syncCode(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Color(0xFFE0E0FF),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(Color accent, CodeStudioProvider provider) {
    final actions = [
      ('Explain', Icons.psychology_outlined, () => provider.explainCode()),
      ('Fix Bugs', Icons.bug_report_outlined, () => provider.fixBugs()),
      ('Run', Icons.play_arrow_rounded, () => provider.runCode()),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.language,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  items: _languages.map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) provider.setLanguage(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ...actions.map((a) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: provider.isProcessing ? null : () {
                _syncCode();
                setState(() => _showAiResponse = true);
                a.$3();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: a.$1 == 'Run'
                      ? LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)])
                      : null,
                  color: a.$1 == 'Run'
                      ? null
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.$2, size: 13, color: a.$1 == 'Run'
                        ? Colors.white
                        : Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      a.$1,
                      style: TextStyle(
                        color: a.$1 == 'Run'
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAiResponse(Color accent, CodeStudioProvider provider) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 14, color: accent.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    provider.lastAction?.toUpperCase() ?? 'OUTPUT',
                    style: TextStyle(
                      color: accent.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  if (provider.isProcessing)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: accent.withOpacity(0.4),
                      ),
                    ),
                  if (!provider.isProcessing && provider.aiResponse.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: provider.aiResponse));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: accent.withOpacity(0.8),
                          ),
                        );
                      },
                      child: Icon(Icons.copy_rounded,
                          size: 14, color: Colors.white.withOpacity(0.3)),
                    ),
                  if (!provider.isProcessing)
                    GestureDetector(
                      onTap: () {
                        provider.clearResponse();
                        setState(() => _showAiResponse = false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: provider.aiResponse.isEmpty && !provider.isProcessing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 28,
                              color: Colors.white.withOpacity(0.08)),
                          const SizedBox(height: 8),
                          Text(
                            'Select an action above',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 12,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      child: SelectableText.rich(
                        TextSpan(
                          children: _buildResponseSpans(
                              provider.aiResponse, provider.language),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildResponseSpans(String text, String language) {
    final spans = <TextSpan>[];
    final codeBlockRegExp = RegExp(
      r'```(\w*)\n([\s\S]*?)```',
    );

    int lastEnd = 0;
    for (final match in codeBlockRegExp.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ));
      }

      final codeLang = match.group(1)!.isNotEmpty ? match.group(1)! : language;
      final code = match.group(2)!;

      spans.add(TextSpan(
        text: '```$codeLang\n',
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
      ));
      spans.addAll(SyntaxHighlighter.highlight(code, codeLang));
      spans.add(TextSpan(
        text: '\n```',
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent),
              _buildStatusBar(accent, context.watch<CodeStudioProvider>()),
              Consumer<CodeStudioProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      _buildEditor(accent, provider),
                      _buildActionBar(accent, provider),
                      if (_showAiResponse || provider.isProcessing)
                        _buildAiResponse(accent, provider),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.7)],
                  ),
                ),
                child: const Icon(Icons.code_rounded,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Code Studio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _codeCtrl.text = '';
                  _syncCode();
                  context.read<CodeStudioProvider>().clearResponse();
                  setState(() => _showAiResponse = false);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.white.withOpacity(0.4)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
