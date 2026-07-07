import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/flash_card.dart';
import '../providers/flash_card_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class FlashCardFactoryScreen extends StatefulWidget {
  const FlashCardFactoryScreen({super.key});

  @override
  State<FlashCardFactoryScreen> createState() =>
      _FlashCardFactoryScreenState();
}

class _FlashCardFactoryScreenState extends State<FlashCardFactoryScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String? _filterTag;
  String? _filterDifficulty;

  bool _studyMode = false;
  int _studyIndex = 0;
  List<FlashCard> _studyDeck = [];
  final Map<String, bool> _studyResults = {};

  String _editingQuestion = '';
  String _editingAnswer = '';
  String _editingTags = '';
  String _editingDifficulty = 'medium';

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent),
              _buildToolbar(accent),
              Expanded(
                child: Consumer<FlashCardProvider>(
                  builder: (context, provider, _) {
                    if (!provider.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (_studyMode && _studyDeck.isNotEmpty) {
                      return _buildStudyView(accent, provider);
                    }

                    if (provider.cards.isEmpty) {
                      return _buildEmptyState(accent, provider);
                    }

                    return _buildCardList(accent, provider);
                  },
                ),
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
          child: Consumer<FlashCardProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: Colors.white.withOpacity(0.6)),
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
                    child: const Icon(Icons.style_rounded,
                        size: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash Card Factory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      Text(
                        '${provider.cards.length} cards · '
                        '${provider.totalReviews} reviews',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (provider.cards.isNotEmpty && !_studyMode)
                    GestureDetector(
                      onTap: () => _startStudy(provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded,
                                size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              'Study',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_studyMode)
                    GestureDetector(
                      onTap: () => setState(() {
                        _studyMode = false;
                        _studyIndex = 0;
                        _studyDeck = [];
                        _studyResults.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Exit',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(Color accent) {
    return Consumer<FlashCardProvider>(
      builder: (context, provider, _) {
        final tags = provider.allTags;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onChanged: (v) {
                          _searchQuery = v;
                          provider.setSearchQuery(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 16, color: accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: provider.isGenerating
                        ? null
                        : () => _showGenerateDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: provider.isGenerating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent.withOpacity(0.4),
                              ),
                            )
                          : Icon(Icons.auto_awesome_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              if (tags.isNotEmpty || provider.cards.isNotEmpty) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _FilterChip2(
                        label: 'All',
                        selected: _filterTag == null &&
                            _filterDifficulty == null,
                        accent: accent,
                        onTap: () => setState(() {
                          _filterTag = null;
                          _filterDifficulty = null;
                          provider.setActiveTag(null);
                          provider.setDifficultyFilter(null);
                        }),
                      ),
                      ...['easy', 'medium', 'hard'].map((d) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _FilterChip2(
                          label: d,
                          selected: _filterDifficulty == d,
                          accent: accent,
                          onTap: () => setState(() {
                            _filterDifficulty = d;
                            _filterTag = null;
                            provider.setDifficultyFilter(d);
                            provider.setActiveTag(null);
                          }),
                        ),
                      )),
                      ...tags.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _FilterChip2(
                          label: t,
                          selected: _filterTag == t,
                          accent: accent,
                          onTap: () => setState(() {
                            _filterTag = t;
                            _filterDifficulty = null;
                            provider.setActiveTag(t);
                            provider.setDifficultyFilter(null);
                          }),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color accent, FlashCardProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
              ),
            ),
            child: Icon(Icons.style_rounded,
                size: 40, color: accent.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            'No flashcards yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate from conversations or create manually',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showGenerateDialog(context, provider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showAddDialog(context, provider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 18, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        'Manual',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(Color accent, FlashCardProvider provider) {
    final cards = provider.filteredCards;

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'No matching cards',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _FlashCardTile(
          card: card,
          accent: accent,
          onTap: () => _showCardDetail(context, provider, card),
          onDelete: () => provider.deleteCard(card.id),
        );
      },
    );
  }

  Widget _buildStudyView(Color accent, FlashCardProvider provider) {
    if (_studyIndex >= _studyDeck.length) {
      final correct = _studyResults.values.where((v) => v).length;
      final total = _studyResults.length;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      correct >= total / 2
                          ? Colors.green.withOpacity(0.3)
                          : accent.withOpacity(0.3),
                      accent.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  correct >= total / 2
                      ? Icons.celebration_rounded
                      : Icons.school_rounded,
                  size: 48,
                  color: correct >= total / 2 ? Colors.green : accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Session Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$correct / $total correct (${total > 0 ? (correct / total * 100).toInt() : 0}%)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => setState(() {
                  _studyMode = false;
                  _studyDeck = [];
                  _studyResults.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final card = _studyDeck[_studyIndex];
    return _StudyCardView(
      card: card,
      accent: accent,
      total: _studyDeck.length,
      current: _studyIndex + 1,
      onResult: (correct) {
        provider.markReviewed(card.id, correct);
        _studyResults[card.id] = correct;
        setState(() => _studyIndex++);
        HapticFeedback.lightImpact();
      },
    );
  }

  void _startStudy(FlashCardProvider provider) {
    final cards = provider.filteredCards.toList()..shuffle();
    if (cards.isEmpty) return;
    setState(() {
      _studyMode = true;
      _studyDeck = cards;
      _studyIndex = 0;
      _studyResults.clear();
    });
  }

  void _showGenerateDialog(
      BuildContext context, FlashCardProvider provider) {
    final accent = context.read<SettingsProvider>().accentColor;
    final chatProvider = context.read<ChatProvider>();
    final convs = chatProvider.conversations
        .where((c) => c.messages.any((m) => m.role == 'assistant'))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Generate Flashcards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose a conversation to extract flashcards from',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (convs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No conversations with AI responses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: convs.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          provider.generateFromAllConversations();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent,
                                accent.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Conversations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Batch generate from all chats',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final conv = convs[index - 1];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        provider.generateFromConversation(conv);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withOpacity(0.1),
                              ),
                              child: Icon(Icons.chat_bubble_outline,
                                  size: 16, color: accent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                conv.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16,
                                color: Colors.white.withOpacity(0.2)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, FlashCardProvider provider) {
    _editingQuestion = '';
    _editingAnswer = '';
    _editingTags = '';
    _editingDifficulty = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('New Flashcard'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => _editingQuestion = v,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Question',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => _editingAnswer = v,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => _editingTags = v,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated)',
                  labelStyle: const TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Difficulty: ',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(width: 8),
                  _DifficultyButton(
                    label: 'Easy',
                    selected: _editingDifficulty == 'easy',
                    color: Colors.green,
                    onTap: () =>
                        setState(() => _editingDifficulty = 'easy'),
                  ),
                  const SizedBox(width: 4),
                  _DifficultyButton(
                    label: 'Medium',
                    selected: _editingDifficulty == 'medium',
                    color: Colors.orange,
                    onTap: () =>
                        setState(() => _editingDifficulty = 'medium'),
                  ),
                  const SizedBox(width: 4),
                  _DifficultyButton(
                    label: 'Hard',
                    selected: _editingDifficulty == 'hard',
                    color: Colors.red,
                    onTap: () =>
                        setState(() => _editingDifficulty = 'hard'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              if (_editingQuestion.trim().isNotEmpty &&
                  _editingAnswer.trim().isNotEmpty) {
                final tags = _editingTags
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                provider.addCard(
                  question: _editingQuestion.trim(),
                  answer: _editingAnswer.trim(),
                  tags: tags,
                  difficulty: _editingDifficulty,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  void _showCardDetail(
      BuildContext context, FlashCardProvider provider, FlashCard card) {
    final accent = context.read<SettingsProvider>().accentColor;
    _editingQuestion = card.question;
    _editingAnswer = card.answer;
    _editingTags = card.tags.join(', ');
    _editingDifficulty = card.difficulty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          _editingQuestion = card.question;
          _editingAnswer = card.answer;
          _editingTags = card.tags.join(', ');
          _editingDifficulty = card.difficulty;
          return _CardDetailSheet(
            card: card,
            accent: accent,
            context: context,
            provider: provider,
            setSheetState: setSheetState,
          );
        },
      ),
    );
  }
}

class _FlashCardTile extends StatefulWidget {
  final FlashCard card;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FlashCardTile({
    required this.card,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_FlashCardTile> createState() => _FlashCardTileState();
}

class _FlashCardTileState extends State<_FlashCardTile> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final accent = widget.accent;
    final diffColor = card.difficulty == 'easy'
        ? Colors.green
        : card.difficulty == 'hard'
            ? Colors.red
            : Colors.orange;

    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      onLongPress: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _flipped
              ? const Color(0xFF0D0D15)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _flipped
                ? accent.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    card.difficulty,
                    style: TextStyle(
                      color: diffColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (card.sourceConversationTitle != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    card.sourceConversationTitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                if (card.reviewCount > 0)
                  Text(
                    '${card.successRate >= 0.7 ? "✓" : "△"} ${(card.successRate * 100).toInt()}%',
                    style: TextStyle(
                      color: card.successRate >= 0.7
                          ? Colors.green.withOpacity(0.6)
                          : Colors.orange.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.white.withOpacity(0.15)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _flipped ? card.answer : card.question,
              style: TextStyle(
                color: _flipped
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white,
                fontSize: 14,
                fontWeight: _flipped ? FontWeight.w400 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            if (_flipped && card.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: card.tags.map((t) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: accent.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudyCardView extends StatefulWidget {
  final FlashCard card;
  final Color accent;
  final int total;
  final int current;
  final ValueChanged<bool> onResult;

  const _StudyCardView({
    required this.card,
    required this.accent,
    required this.total,
    required this.current,
    required this.onResult,
  });

  @override
  State<_StudyCardView> createState() => _StudyCardViewState();
}

class _StudyCardViewState extends State<_StudyCardView>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(_StudyCardView old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _revealed = false;
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final accent = widget.accent;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(widget.total, (i) {
                final isActive = i == widget.current - 1;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: isActive ? 20 : 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.current} / ${widget.total}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_revealed) {
                  setState(() => _revealed = true);
                  _bounceCtrl.forward(from: 0);
                }
              },
              child: AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_revealed ? _bounceAnim.value * 0.02 : 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _revealed
                            ? const Color(0xFF0D0D15)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _revealed
                              ? accent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _revealed
                                ? Icons.lightbulb_outline
                                : Icons.help_outline,
                            size: 32,
                            color: _revealed
                                ? Colors.amber.withOpacity(0.6)
                                : Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _revealed ? card.answer : card.question,
                            style: TextStyle(
                              color: _revealed
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: _revealed
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (!_revealed)
                            Text(
                              'Tap to reveal',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onResult(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 20, color: Colors.red),
                            SizedBox(width: 6),
                            Text(
                              'Still Learning',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onResult(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green,
                            Colors.green.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 20, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Got It!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CardDetailSheet extends StatefulWidget {
  final FlashCard card;
  final Color accent;
  final BuildContext context;
  final FlashCardProvider provider;
  final StateSetter setSheetState;

  const _CardDetailSheet({
    required this.card,
    required this.accent,
    required this.context,
    required this.provider,
    required this.setSheetState,
  });

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  late TextEditingController _qCtrl;
  late TextEditingController _aCtrl;
  late TextEditingController _tCtrl;
  String _diff = 'medium';

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.card.question);
    _aCtrl = TextEditingController(text: widget.card.answer);
    _tCtrl = TextEditingController(text: widget.card.tags.join(', '));
    _diff = widget.card.difficulty;
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _aCtrl.dispose();
    _tCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final accent = widget.accent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Edit Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const Spacer(),
                Text(
                  '${card.reviewCount} reviews · '
                  '${(card.successRate * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _qCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Question',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _aCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Answer',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _tCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tags (comma separated)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...['easy', 'medium', 'hard'].map((d) {
                  final selected = _diff == d;
                  final c = d == 'easy'
                      ? Colors.green
                      : d == 'hard'
                          ? Colors.red
                          : Colors.orange;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _diff = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? c.withOpacity(0.2)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? c.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          d[0].toUpperCase() + d.substring(1),
                          style: TextStyle(
                            color: selected
                                ? c
                                : Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.provider.deleteCard(card.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      final tags = _tCtrl.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      widget.provider.updateCard(card.copyWith(
                        question: _qCtrl.text.trim(),
                        answer: _aCtrl.text.trim(),
                        tags: tags,
                        difficulty: _diff,
                      ));
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FilterChip2 extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChip2({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
