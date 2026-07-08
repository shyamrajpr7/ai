import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/story_forge_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class StoryForgeScreen extends StatefulWidget {
  const StoryForgeScreen({super.key});

  @override
  State<StoryForgeScreen> createState() => _StoryForgeScreenState();
}

class _StoryForgeScreenState extends State<StoryForgeScreen> {
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _premiseController = TextEditingController();
  final _chapterController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _premiseController.dispose();
    _chapterController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCreateDialog(Color accent) {
    _titleController.clear();
    _genreController.clear();
    _premiseController.clear();
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                    ),
                    child: const Center(child: Icon(Icons.auto_stories, size: 20, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Story',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField('Story Title', _titleController, 'e.g. The Crystal Nexus'),
              const SizedBox(height: 12),
              _buildField('Genre', _genreController, 'e.g. Fantasy, Sci-Fi, Mystery'),
              const SizedBox(height: 12),
              _buildField('Premise', _premiseController, 'A brief description of the story idea...', maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty || _premiseController.text.trim().isEmpty) return;
                      final genre = _genreController.text.trim().isEmpty ? 'Fantasy' : _genreController.text.trim();
                      context.read<StoryForgeProvider>().createStory(
                        _titleController.text.trim(),
                        genre,
                        _premiseController.text.trim(),
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Begin Story',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Inter'),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<StoryForgeProvider>();

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
              child: Icon(
                provider.currentStory != null ? Icons.arrow_back_rounded : Icons.close,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            onPressed: () {
              if (provider.currentStory != null) {
                provider.clearCurrentStory();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                provider.currentStory?.title ?? 'Story Forge',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        body: provider.currentStory == null
            ? _buildStoryList(accent, provider)
            : _buildStoryView(accent, provider),
        floatingActionButton: provider.currentStory == null
            ? FloatingActionButton(
                onPressed: () => _showCreateDialog(accent),
                backgroundColor: accent,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildStoryList(Color accent, StoryForgeProvider provider) {
    if (provider.stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 72, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(
              'No stories yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to forge your first tale',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'Inter',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: provider.stories.length,
      itemBuilder: (context, index) {
        final story = provider.stories[index];
        final chapterCount = story.chapters.length;
        final lastChapter = chapterCount > 0 ? story.chapters.last : null;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            provider.selectStory(story);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                  ),
                  child: Center(
                    child: Text(
                      story.title.isNotEmpty ? story.title[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.genre}  ·  $chapterCount chapter${chapterCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                      ),
                      if (lastChapter != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lastChapter.content.length > 80
                                ? '${lastChapter.content.substring(0, 80)}...'
                                : lastChapter.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryView(Color accent, StoryForgeProvider provider) {
    final story = provider.currentStory!;
    return Column(
      children: [
        Expanded(
          child: story.chapters.isEmpty && provider.isGenerating
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36, height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Weaving the opening chapter...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: story.chapters.length + (provider.branchingChoices.isNotEmpty ? 1 : 0) + (provider.isGenerating && provider.currentResponse.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < story.chapters.length) {
                      final chapter = story.chapters[index];
                      return _buildChapterCard(chapter, accent);
                    }
                    final choiceIdx = index - story.chapters.length;
                    if (provider.branchingChoices.isNotEmpty && choiceIdx == 0) {
                      return _buildBranchingChoices(accent, provider);
                    }
                    if (provider.isGenerating && provider.currentResponse.isNotEmpty) {
                      return _buildStreamingChapter(accent, provider);
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
        if (!provider.isAITurn && !provider.isGenerating && story.chapters.isNotEmpty)
          _buildUserInput(accent, provider),
      ],
    );
  }

  Widget _buildChapterCard(Chapter chapter, Color accent) {
    final isUser = chapter.author == AuthorType.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUser ? accent.withOpacity(0.2) : const Color(0xFF448AFF).withOpacity(0.2),
                ),
                child: Center(
                  child: Icon(
                    isUser ? Icons.person : Icons.auto_stories,
                    size: 14,
                    color: isUser ? accent : const Color(0xFF448AFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? 'You' : 'Narrator',
                style: TextStyle(
                  color: isUser ? accent : const Color(0xFF448AFF),
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (chapter.choiceLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chapter.choiceLabel!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? accent.withOpacity(0.05) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isUser ? accent : Colors.white).withOpacity(0.08),
              ),
            ),
            child: MarkdownBody(
              data: chapter.content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.6,
                ),
                h1: const TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold, fontSize: 18),
                h2: const TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold, fontSize: 16),
                h3: const TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold, fontSize: 14),
                strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                code: const TextStyle(color: Color(0xFF448AFF), fontFamily: 'monospace', fontSize: 13),
                codeblockDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              builders: {'code': CodeBlockBuilder()},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingChapter(Color accent, StoryForgeProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF448AFF).withOpacity(0.2),
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories, size: 14, color: Color(0xFF448AFF)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Narrator',
                style: TextStyle(
                  color: Color(0xFF448AFF),
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: MarkdownBody(
              data: provider.currentResponse,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.6,
                ),
                code: const TextStyle(color: Color(0xFF448AFF), fontFamily: 'monospace', fontSize: 13),
                codeblockDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              builders: {'code': CodeBlockBuilder()},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchingChoices(Color accent, StoryForgeProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.call_split, size: 16, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                'Choose the next path',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...provider.branchingChoices.map((choice) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                provider.selectBranch(choice);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choice.label,
                            style: TextStyle(
                              color: accent,
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            choice.prompt,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.skipBranches();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 10),
                    Text(
                      'Write your own chapter instead',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput(Color accent, StoryForgeProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1A1A2E).withOpacity(0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _chapterController,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Write the next chapter...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Inter'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = _chapterController.text.trim();
              if (text.isNotEmpty && !provider.isGenerating) {
                HapticFeedback.lightImpact();
                _chapterController.clear();
                _focusNode.unfocus();
                provider.submitUserChapter(text);
                _scrollToBottom();
              }
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
