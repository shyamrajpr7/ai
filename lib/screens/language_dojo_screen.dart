import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/language_dojo_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class LanguageDojoScreen extends StatefulWidget {
  const LanguageDojoScreen({super.key});

  @override
  State<LanguageDojoScreen> createState() => _LanguageDojoScreenState();
}

class _LanguageDojoScreenState extends State<LanguageDojoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _chatFocusNode = FocusNode();
  final _chatScrollController = ScrollController();
  final _vocabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanguageDojoProvider>().initSpeech();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    _vocabScrollController.dispose();
    super.dispose();
  }

  void _showLanguagePicker() {
    final accent = context.read<SettingsProvider>().accentColor;
    final dojo = context.read<LanguageDojoProvider>();

    final languages = [
      'Spanish', 'French', 'German', 'Italian', 'Portuguese',
      'Japanese', 'Korean', 'Chinese', 'Russian', 'Arabic',
      'Hindi', 'Dutch', 'Polish', 'Turkish', 'Swedish',
      'Danish', 'Norwegian', 'Finnish', 'Czech', 'Romanian',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: accent.withOpacity(0.2))),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('Choose Language', style: TextStyle(
                    color: Colors.white, fontSize: 17,
                    fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold,
                  )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: languages.map((lang) {
                  final selected = dojo.targetLanguage == lang;
                  return GestureDetector(
                    onTap: () {
                      dojo.setLanguage(lang);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? accent.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(_flagFor(lang), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(lang, style: TextStyle(
                            color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          )),
                          const Spacer(),
                          if (selected)
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: accent,
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _flagFor(String lang) {
    const flags = {
      'Spanish': '🇪🇸', 'French': '🇫🇷', 'German': '🇩🇪', 'Italian': '🇮🇹',
      'Portuguese': '🇵🇹', 'Japanese': '🇯🇵', 'Korean': '🇰🇷', 'Chinese': '🇨🇳',
      'Russian': '🇷🇺', 'Arabic': '🇸🇦', 'Hindi': '🇮🇳', 'Dutch': '🇳🇱',
      'Polish': '🇵🇱', 'Turkish': '🇹🇷', 'Swedish': '🇸🇪', 'Danish': '🇩🇰',
      'Norwegian': '🇳🇴', 'Finnish': '🇫🇮', 'Czech': '🇨🇿', 'Romanian': '🇷🇴',
    };
    return flags[lang] ?? '🌐';
  }

  void _handleChatSend() {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;
    _chatController.clear();
    context.read<LanguageDojoProvider>().sendConversationMessage(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final dojo = context.watch<LanguageDojoProvider>();

    return GradientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white.withOpacity(0.7)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                ),
                child: const Center(child: Icon(Icons.translate, size: 17, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showLanguagePicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_flagFor(dojo.targetLanguage), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(dojo.targetLanguage, style: const TextStyle(
                      color: Colors.white, fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.bold, fontSize: 18,
                    )),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white.withOpacity(0.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: accent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.4),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Vocabulary'),
                  Tab(icon: Icon(Icons.chat_outlined, size: 18), text: 'Conversation'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVocabTab(accent, dojo),
                  _buildConversationTab(accent, dojo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vocabulary Tab ────────────────────────────────────

  Widget _buildVocabTab(Color accent, LanguageDojoProvider dojo) {
    if (dojo.vocabulary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)]),
              ),
              child: Icon(Icons.menu_book, size: 34, color: accent.withOpacity(0.3)),
            ),
            const SizedBox(height: 20),
            Text('No vocabulary yet', style: TextStyle(
              color: Colors.white.withOpacity(0.5), fontSize: 16,
              fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 8),
            Text('Generate a word list to start practicing', style: TextStyle(
              color: Colors.white.withOpacity(0.25), fontSize: 13, fontFamily: 'Inter',
            )),
            const SizedBox(height: 28),
            _buildGenerateButton(accent, dojo),
          ],
        ),
      );
    }

    final word = dojo.currentWord;
    if (word == null) return const SizedBox.shrink();
    final progress = (dojo.currentVocabIndex + 1) / dojo.vocabulary.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text('${dojo.currentVocabIndex + 1} of ${dojo.vocabulary.length}', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'Inter',
              )),
              const Spacer(),
              _buildGenerateButton(accent, dojo),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildFlashCard(accent, dojo, word),
                const SizedBox(height: 20),
                _buildPronunciationSection(accent, dojo, word),
                const SizedBox(height: 16),
                if (dojo.lastAssessment != null)
                  _buildAssessmentResult(accent, dojo),
              ],
            ),
          ),
        ),
        _buildVocabActions(accent, dojo),
      ],
    );
  }

  Widget _buildGenerateButton(Color accent, LanguageDojoProvider dojo) {
    return GestureDetector(
      onTap: dojo.isGeneratingVocab ? null : () => dojo.generateVocabulary(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: dojo.isGeneratingVocab
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text('Generate', style: TextStyle(
                    color: accent, fontSize: 12, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
      ),
    );
  }

  Widget _buildFlashCard(Color accent, LanguageDojoProvider dojo, dynamic word) {
    return GestureDetector(
      onTap: () => dojo.toggleTranslation(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              dojo.showTranslation ? accent.withOpacity(0.12) : accent.withOpacity(0.06),
              dojo.showTranslation ? const Color(0xFF448AFF).withOpacity(0.06) : Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dojo.showTranslation
                ? accent.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(dojo.showTranslation),
            children: [
              if (!dojo.showTranslation) ...[
                Text(word.word, style: TextStyle(
                  color: Colors.white, fontSize: 32,
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Text(word.pronunciationHint ?? '', style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 14, fontFamily: 'Inter',
                )),
              ] else ...[
                Text(word.translation, style: TextStyle(
                  color: accent, fontSize: 28,
                  fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 12),
                Text(word.exampleSentence, style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 15, fontFamily: 'Inter',
                  height: 1.4,
                ), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dojo.showTranslation ? 'Tap to see word' : 'Tap to see translation',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPronunciationSection(Color accent, LanguageDojoProvider dojo, dynamic word) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.mic_outlined, size: 16, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text('Practice Pronunciation', style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12,
                fontWeight: FontWeight.w600, fontFamily: 'Inter',
              )),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: dojo.isListening ? () => dojo.stopListening() : () => dojo.startListening(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dojo.isListening
                    ? Colors.red.withOpacity(0.15)
                    : accent.withOpacity(0.1),
                border: Border.all(
                  color: dojo.isListening
                      ? Colors.red.withOpacity(0.4)
                      : accent.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: dojo.isListening
                    ? SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.red.shade300,
                        ),
                      )
                    : Icon(Icons.mic, size: 28, color: accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (dojo.isListening)
            Text('Listening...', style: TextStyle(
              color: Colors.red.shade300, fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
          if (dojo.spokenText.isNotEmpty && !dojo.isListening) ...[
            const SizedBox(height: 8),
            Text('You said: "${dojo.spokenText}"', style: TextStyle(
              color: Colors.white.withOpacity(0.6), fontSize: 13, fontFamily: 'Inter',
            ), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentResult(Color accent, LanguageDojoProvider dojo) {
    final score = dojo.lastScore;
    Color scoreColor;
    if (score > 80) {
      scoreColor = const Color(0xFF00E676);
    } else if (score > 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red.shade300;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scoreColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.12),
            ),
            child: Center(
              child: Text('${score.toStringAsFixed(0)}', style: TextStyle(
                color: scoreColor, fontSize: 16, fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(dojo.lastAssessment ?? '', style: TextStyle(
              color: Colors.white.withOpacity(0.8), fontSize: 13,
              fontFamily: 'Inter', height: 1.4,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabActions(Color accent, LanguageDojoProvider dojo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          _vocabButton(Icons.arrow_back_rounded, 'Previous', () => dojo.previousWord()),
          const SizedBox(width: 12),
          Expanded(
            child: _vocabButton(Icons.auto_awesome, 'Mastered', () => dojo.markMastered(),
              color: const Color(0xFF00E676)),
          ),
          const SizedBox(width: 12),
          _vocabButton(Icons.arrow_forward_rounded, 'Next', () => dojo.nextWord()),
        ],
      ),
    );
  }

  Widget _vocabButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (color ?? Colors.white).withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: (color ?? Colors.white).withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: (color ?? Colors.white).withOpacity(0.7),
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  // ── Conversation Tab ──────────────────────────────────

  Widget _buildConversationTab(Color accent, LanguageDojoProvider dojo) {
    if (dojo.conversationMessages.isEmpty && !dojo.isConversationProcessing) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)]),
                    ),
                    child: Icon(Icons.chat_outlined, size: 34, color: accent.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 20),
                  Text('Practice Conversation', style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 16,
                    fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text('Have a natural conversation in ${dojo.targetLanguage}. '
                        'The AI tutor will respond in ${dojo.targetLanguage} and help you learn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13, fontFamily: 'Inter'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => dojo.generateVocabulary(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Start with a phrase', style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildChatInput(accent, dojo),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: dojo.conversationMessages.length +
                (dojo.isConversationProcessing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < dojo.conversationMessages.length) {
                final msg = dojo.conversationMessages[index];
                return _buildChatBubble(msg, accent);
              }
              return _buildStreamingBubble(accent, dojo);
            },
          ),
        ),
        _buildChatInput(accent, dojo),
      ],
    );
  }

  Widget _buildChatBubble(dynamic msg, Color accent) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.15),
              ),
              child: Icon(Icons.translate, size: 14, color: accent),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? accent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isUser
                      ? accent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: isUser
                  ? Text(msg.content, style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontFamily: 'Inter', height: 1.4,
                    ))
                  : MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Color(0xFFE0E0FF), fontSize: 14, height: 1.6),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        code: const TextStyle(
                          color: Color(0xFFE0E0FF), fontSize: 12,
                          fontFamily: 'monospace', backgroundColor: Color(0xFF1A1A2E),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      builders: {'pre': CodeBlockBuilder()},
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.15),
              ),
              child: Icon(Icons.person, size: 14, color: accent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingBubble(Color accent, LanguageDojoProvider dojo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
            ),
            child: Icon(Icons.translate, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: accent.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 6),
                      Text('Thinking...', style: TextStyle(
                        color: accent.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                  if (dojo.currentResponse.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: dojo.currentResponse,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Color(0xFFE0E0FF), fontSize: 14, height: 1.6),
                      ),
                      builders: {'pre': CodeBlockBuilder()},
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(Color accent, LanguageDojoProvider dojo) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dojo.isConversationProcessing
              ? accent.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Inter', height: 1.4),
                    decoration: InputDecoration(
                      hintText: dojo.isConversationProcessing
                          ? 'Waiting...'
                          : 'Write in ${dojo.targetLanguage}...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) => _handleChatSend(),
                  ),
                ),
                const SizedBox(width: 4),
                _buildChatSendButton(accent, dojo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSendButton(Color accent, LanguageDojoProvider dojo) {
    if (dojo.isConversationProcessing) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.15),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Center(
          child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ),
      );
    }

    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleChatSend,
          child: const Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
        ),
      ),
    );
  }
}
