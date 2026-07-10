import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../models/persona.dart';
import '../models/search_result.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/glass_input_bar.dart';
import '../widgets/chat_history_drawer.dart';
import '../models/chat_message.dart';
import 'settings_screen.dart';
import 'time_machine_screen.dart';
import 'prompt_vault_screen.dart';
import 'persona_forge_screen.dart';
import 'arena_screen.dart';
import 'cognitive_lab_screen.dart';
import 'code_studio_screen.dart';
import 'debate_club_screen.dart';
import 'document_oracle_screen.dart';
import 'habit_tracker_screen.dart';
import 'language_dojo_screen.dart';
import 'story_forge_screen.dart';
import 'emotion_mirror_screen.dart';
import 'meeting_scribe_screen.dart';
import 'daily_briefing_screen.dart';
import 'snippet_vault_screen.dart';
import 'quote_screen.dart';
import 'journal_screen.dart';
import 'reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  String? _pendingImageBase64;
  bool _isImageGen = false;
  bool _isVideoGen = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<ConversationSearchGroup> _searchResults = [];
  final _searchScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchScrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleImagePicked(String base64) {
    setState(() => _pendingImageBase64 = base64);
  }

  void _clearImage() {
    setState(() => _pendingImageBase64 = null);
  }

  void _handleToggleImageGen() {
    setState(() {
      _isImageGen = !_isImageGen;
      _isVideoGen = false;
      if (!_isImageGen) _clearImage();
    });
  }

  void _handleToggleVideoGen() {
    setState(() {
      _isVideoGen = !_isVideoGen;
      _isImageGen = false;
      if (!_isVideoGen) _clearImage();
    });
  }

  void _handleGenerateImage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _isImageGen = false);
    _focusNode.requestFocus();
    context.read<ChatProvider>().generateImage(text);
    _scrollToBottom();
  }

  void _handleGenerateVideo() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _isVideoGen = false);
    _focusNode.requestFocus();
    context.read<ChatProvider>().generateVideo(text);
    _scrollToBottom();
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    _searchFocusNode.unfocus();
  }

  void _showPersonaPicker(BuildContext buildContext) {
    final settings = context.read<SettingsProvider>();
    final accent = settings.accentColor;

    showModalBottomSheet(
      context: buildContext,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Choose Persona',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonaForgeScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'Forge',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune, size: 12,
                              color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            'Manage',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFF1A1A2E)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.4,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: settings.personas.map((p) {
                  final isActive = p.id == settings.activePersona.id;
                  return GestureDetector(
                    onTap: () {
                      settings.setActivePersona(p.id);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? p.color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isActive
                            ? Border.all(color: p.color.withOpacity(0.25))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? p.color.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.04),
                            ),
                            child: Center(
                              child: Text(p.emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.7),
                                    fontSize: 15,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.systemPrompt.length > 50
                                      ? '${p.systemPrompt.substring(0, 47)}...'
                                      : p.systemPrompt,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.color,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
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

  void _onSearchChanged(String value) {
    final provider = context.read<ChatProvider>();
    setState(() {
      _searchResults = value.trim().isEmpty ? [] : provider.searchMessages(value);
    });
  }

  void _onSearchResultTap(String conversationId, String? messageId) {
    final provider = context.read<ChatProvider>();
    provider.selectConversation(conversationId);
    _closeSearch();
  }

  void _handleSend() {
    final text = _textController.text;
    final image = _pendingImageBase64;
    if (text.trim().isEmpty && image == null) return;
    _textController.clear();
    _clearImage();
    setState(() {
      _isImageGen = false;
      _isVideoGen = false;
    });
    _focusNode.requestFocus();
    context.read<ChatProvider>().sendMessage(text, imageBase64: image);
    _scrollToBottom();
  }

  String _getActiveBranchName(ChatProvider provider) {
    final conv = provider.currentConversation;
    if (conv == null) return '';
    final branch = conv.branches.where((b) => b.id == conv.activeBranchId).firstOrNull;
    return branch?.name ?? 'Original';
  }

  void _showBranchIndicator(BuildContext buildContext, ChatProvider provider) {
    final accent = context.read<SettingsProvider>().accentColor;
    final conv = provider.currentConversation;
    if (conv == null) return;

    showModalBottomSheet(
      context: buildContext,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: accent.withOpacity(0.2)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Branches',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...conv.branches.map((b) => ListTile(
              leading: Icon(
                b.id == conv.activeBranchId
                    ? Icons.call_split_rounded
                    : Icons.subdirectory_arrow_right_rounded,
                color: b.id == conv.activeBranchId
                    ? accent
                    : Colors.white.withOpacity(0.4),
                size: 20,
              ),
              title: Text(
                b.name,
                style: TextStyle(
                  color: b.id == conv.activeBranchId
                      ? accent
                      : Colors.white.withOpacity(0.7),
                  fontWeight:
                      b.id == conv.activeBranchId ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              subtitle: b.id == conv.activeBranchId
                  ? Text(
                      'Active',
                      style: TextStyle(
                        color: accent.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                provider.switchBranch(b.id);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _openTimeMachine(BuildContext buildContext, ChatProvider provider) {
    final conv = provider.currentConversation;
    if (conv == null) return;
    Navigator.push(
      buildContext,
      MaterialPageRoute(
        builder: (_) => TimeMachineScreen(
          conversation: conv,
          provider: provider,
        ),
      ),
    );
  }

  void _showPromptVault(BuildContext buildContext) {
    HapticFeedback.lightImpact();
    Navigator.push(
      buildContext,
      MaterialPageRoute(
        builder: (_) => PromptVaultScreen(
          pickerMode: true,
          onPromptPicked: (content) {
            _textController.text = content;
            _focusNode.requestFocus();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          drawer: ChatHistoryDrawer(provider: provider),
          body: Builder(
            builder: (scaffoldCtx) => GradientMeshBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(scaffoldCtx, accent, provider),
                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults(accent, provider)
                          : _buildMessages(provider, accent),
                    ),
                    if (_pendingImageBase64 != null)
                      _buildImagePreview(accent),
                    GlassInputBar(
                      isProcessing: provider.isProcessing,
                      isImageGen: _isImageGen,
                      isVideoGen: _isVideoGen,
                      onImagePicked: _handleImagePicked,
                      onSend: _handleSend,
                      onGenerateImage: _handleGenerateImage,
                      onGenerateVideo: _handleGenerateVideo,
                      onToggleImageGen: _handleToggleImageGen,
                      onToggleVideoGen: _handleToggleVideoGen,
                      controller: _textController,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_pendingImageBase64!),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Image attached',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext buildContext, Color accent, ChatProvider provider) {
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
          child: _isSearching
              ? _buildSearchBar(accent)
              : Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () => Scaffold.of(buildContext).openDrawer(),
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => _showPersonaPicker(buildContext),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [accent, const Color(0xFF448AFF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    context.watch<SettingsProvider>().activePersona.emoji,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.watch<SettingsProvider>().activePersona.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (provider.currentConversation != null &&
                          provider.currentConversation!.branches.length > 1)
                        GestureDetector(
                          onTap: () {
                            _showBranchIndicator(context, provider);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.call_split_rounded,
                                    size: 12, color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  _getActiveBranchName(provider),
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      _buildModelBadge(accent),
                      const Spacer(),
                      _NavIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'Search messages',
                        onPressed: _openSearch,
                      ),
                      _NavIconButton(
                        icon: Icons.add_rounded,
                        tooltip: 'New Chat',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          provider.createConversation();
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.account_tree_outlined,
                        tooltip: 'Chat Time Machine',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _openTimeMachine(context, provider);
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.bookmark_outline_rounded,
                        tooltip: 'Prompt Vault',
                        onPressed: () => _showPromptVault(context),
                      ),
                      _NavIconButton(
                        icon: Icons.auto_awesome,
                        tooltip: 'Code Studio',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CodeStudioScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.sports_kabaddi,
                        tooltip: 'Model Arena',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ArenaScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.science_outlined,
                        tooltip: 'Cognitive Lab',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CognitiveLabScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.balance,
                        tooltip: 'Debate Club',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DebateClubScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.menu_book,
                        tooltip: 'Document Oracle',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DocumentOracleScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.repeat,
                        tooltip: 'Habit Tracker',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HabitTrackerScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.translate,
                        tooltip: 'Language Dojo',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LanguageDojoScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.auto_stories,
                        tooltip: 'Story Forge',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoryForgeScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.mood,
                        tooltip: 'Emotion Mirror',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmotionMirrorScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.record_voice_over,
                        tooltip: 'Meeting Scribe',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MeetingScribeScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.wb_sunny_outlined,
                        tooltip: 'Daily Briefing',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyBriefingScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.code,
                        tooltip: 'Snippet Vault',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SnippetVaultScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.format_quote,
                        tooltip: 'Daily Quotes',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuoteScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.mic,
                        tooltip: 'Voice Journal',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JournalScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.alarm,
                        tooltip: 'Smart Reminders',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReminderScreen(),
                            ),
                          );
                        },
                      ),
                      _NavIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const SettingsScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildModelBadge(Color accent) {
    final settings = context.watch<SettingsProvider>();
    String modelName;
    switch (settings.backend) {
      case BackendType.groq:
        modelName = settings.groqModel;
      case BackendType.claude:
        modelName = settings.claudeModel;
      case BackendType.ollama:
        modelName = settings.ollamaModel;
    }
    return Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, size: 11, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              modelName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: _closeSearch,
        ),
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Search all messages...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 15,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMessages(ChatProvider provider, Color accent) {
    final conv = provider.currentConversation;

    if (conv == null) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Start a conversation',
        subtitle: 'Tap + to create a new chat',
        accent: accent,
      );
    }

    final messages = conv.messages.toList();

    if (messages.isEmpty && !provider.isProcessing) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'Ask me anything',
        subtitle: 'I\'m here to help with anything you need',
        accent: accent,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemCount: messages.length + (provider.isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          final isError = msg.status == MessageStatus.error;
          return ChatBubble(
            key: ValueKey(msg.id),
            message: msg,
            isError: isError,
            onRetry: isError ? () => provider.retryMessage() : null,
            onEdit: msg.role == 'user'
                ? () {
                    provider.editMessageAndBranch(msg.id).then((m) {
                      if (m != null) {
                        _textController.text = m.content;
                        if (m.imageBase64 != null) {
                          setState(() => _pendingImageBase64 = m.imageBase64);
                        }
                      }
                    });
                  }
                : null,
            onDelete: () => provider.deleteMessage(msg.id),
          );
        } else {
          return ChatBubble(
            key: const ValueKey('streaming'),
            message: ChatMessage(
              id: 'streaming',
              content: provider.currentResponse,
              role: 'assistant',
              timestamp: DateTime.now(),
            ),
            isStreaming: true,
          );
        }
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
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
                colors: [
                  accent.withOpacity(0.15),
                  accent.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              icon,
              size: 40,
              color: accent.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Color accent, ChatProvider provider) {
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Search all messages',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find messages across all conversations',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
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
      controller: _searchScrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        final query = _searchController.text;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(accent, group),
              ...group.results.map((r) => _buildResultItem(accent, r, query)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(Color accent, ConversationSearchGroup group) {
    return GestureDetector(
      onTap: () => _onSearchResultTap(group.conversationId, null),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_rounded, size: 16, color: accent.withOpacity(0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.conversationTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${group.matchCount} ${group.matchCount == 1 ? 'match' : 'matches'}',
                style: TextStyle(
                  color: accent.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(Color accent, SearchResult result, String query) {
    final msg = result.message;
    final isUser = msg.role == 'user';
    final timeStr = _formatTime(msg.timestamp);

    return GestureDetector(
      onTap: () => _onSearchResultTap(result.conversationId, msg.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUser
                    ? accent.withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                isUser ? Icons.person : Icons.auto_awesome,
                size: 14,
                color: isUser ? accent : Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isUser ? 'You' : 'Nexus',
                        style: TextStyle(
                          color: isUser
                              ? accent.withOpacity(0.7)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildHighlightedText(msg.content, query, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, Color accent) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
          fontFamily: 'Inter',
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(qLower, start);
      if (idx == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ));
        break;
      }

      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          color: accent,
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 1.4,
          backgroundColor: accent.withOpacity(0.15),
        ),
      ));

      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(0.6)),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
