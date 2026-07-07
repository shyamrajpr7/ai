import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chat_conversation.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/diary_screen.dart';
import '../screens/archaeology_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/arena_screen.dart';
import '../screens/cognitive_lab_screen.dart';
import '../screens/memory_constellation_screen.dart';
import '../screens/synapse_screen.dart';
import '../screens/voice_hub_screen.dart';
import '../screens/time_machine_screen.dart';
import '../screens/dream_canvas_screen.dart';
import '../screens/mood_dashboard_screen.dart';
import '../screens/agent_workspace_screen.dart';
import '../screens/prompt_vault_screen.dart';
import '../screens/knowledge_graph_screen.dart';
import '../screens/code_studio_screen.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final ChatProvider provider;

  const ChatHistoryDrawer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Drawer(
      backgroundColor: const Color(0xFF0A0A0F),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, accent),
            Expanded(
              child: provider.conversations.isEmpty
                  ? _buildEmptyConversations(accent)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: provider.conversations.length,
                      itemBuilder: (context, index) {
                        final conv = provider.conversations[index];
                        final isSelected =
                            conv.id == provider.currentConversation?.id;
                        return _ConversationTile(
                          conversation: conv,
                          isSelected: isSelected,
                          accent: accent,
                          onTap: () {
                            provider.selectConversation(conv.id);
                            Navigator.pop(context);
                          },
                          onDelete: () {
                            HapticFeedback.mediumImpact();
                            provider.deleteConversation(conv.id);
                          },
                          onRename: () => _showRenameDialog(
                              context, provider, conv.id, conv.title),
                        );
                      },
                    ),
            ),
            _buildNavSection(context, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nexus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: () {
                    provider.createConversation();
                    Navigator.pop(context);
                  },
                  tooltip: 'New Chat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConversations(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to start a new chat',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSection(BuildContext context, Color accent) {
    final navItems = [
      _NavItem('Chat Diary', Icons.menu_book_rounded, 'Reflections & journal',
          () => _navigate(context, const DiaryScreen())),
      _NavItem('Prompt Vault', Icons.bookmark_outline_rounded, 'Save & reuse prompts',
          () => _navigate(context, const PromptVaultScreen())),
      _NavItem('Archaeology', Icons.explore_outlined, 'Activity heatmap',
          () => _navigate(context, const ArchaeologyScreen())),
      _NavItem('Arena', Icons.sports_kabaddi, 'Compare models',
          () => _navigate(context, const ArenaScreen())),
      _NavItem('Synapse', Icons.hub_outlined, 'AI-to-AI debate',
          () => _navigate(context, const SynapseScreen())),
      _NavItem('Knowledge Graph', Icons.scatter_plot_rounded, 'Topics & concepts',
          () => _navigate(context, const KnowledgeGraphScreen())),
      _NavItem('Code Studio', Icons.code_rounded, 'AI code editor & fixer',
          () => _navigate(context, const CodeStudioScreen())),
      _NavItem('Voice Hub', Icons.waves, 'Hands-free assistant',
          () => _navigate(context, const VoiceHubScreen())),
      _NavItem('Dream Canvas', Icons.dashboard_customize_outlined, 'Vision board',
          () => _navigate(context, const DreamCanvasScreen())),
      _NavItem('Memory Core', Icons.auto_awesome, 'Constellation',
          () => _navigate(context, const MemoryConstellationScreen())),
      _NavItem('Dreamscape', Icons.auto_awesome, 'Art gallery',
          () => _navigate(context, const GalleryScreen())),
      _NavItem('Cognitive Lab', Icons.science_outlined, 'Prompt studio',
          () => _navigate(context, const CognitiveLabScreen())),
      _NavItem('Mood Analytics', Icons.insights, 'Sentiment & topics',
          () => _navigate(context, const MoodDashboardScreen())),
      _NavItem('Agent Workspace', Icons.auto_awesome, 'Autonomous tasks',
          () => _navigate(context, const AgentWorkspaceScreen())),
      _NavItem('Time Machine', Icons.account_tree_outlined, 'Branching & tree',
          () {
        final conv = provider.currentConversation;
        if (conv != null) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TimeMachineScreen(
                conversation: conv,
                provider: provider,
              ),
            ),
          );
        }
      }),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  'EXPLORE',
                  style: TextStyle(
                    color: accent.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 4),
              shrinkWrap: true,
              children: navItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final icons = [
                  Icons.menu_book_rounded,
                  Icons.bookmark_outline_rounded,
                  Icons.explore_outlined,
                  Icons.sports_kabaddi,
                  Icons.hub_outlined,
                  Icons.scatter_plot_rounded,
                  Icons.code_rounded,
                  Icons.waves,
                  Icons.dashboard_customize_outlined,
                  Icons.auto_awesome,
                  Icons.auto_awesome,
                  Icons.science_outlined,
                  Icons.insights,
                  Icons.auto_awesome,
                  Icons.account_tree_outlined,
                ];
                return _NavItemTile(
                  icon: icons[i],
                  label: item.label,
                  subtitle: item.subtitle,
                  accent: accent,
                  onTap: item.onTap,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'Nexus AI v1.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showRenameDialog(BuildContext context, ChatProvider provider,
      String id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Rename Chat',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameConversation(id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF7C4DFF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  _NavItem(this.label, this.icon, this.subtitle, this.onTap);
}

class _NavItemTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.12),
        ),
        child: Icon(
          icon,
          size: 16,
          color: accent.withOpacity(0.7),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 10,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.accent,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final preview = conversation.messages.isNotEmpty
        ? conversation.messages.last.content
        : 'Empty conversation';
    final previewText = preview.length > 60
        ? '${preview.substring(0, 57)}...'
        : preview;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: const Icon(Icons.delete, color: Colors.white70),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onRename,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: accent.withOpacity(0.25))
                : null,
          ),
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          accent.withOpacity(0.3),
                          accent.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: isSelected
                    ? accent
                    : Colors.white.withOpacity(0.4),
              ),
            ),
            title: Text(
              conversation.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              previewText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
