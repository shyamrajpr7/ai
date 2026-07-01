import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_conversation.dart';
import '../providers/chat_provider.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final ChatProvider provider;

  const ChatHistoryDrawer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);

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
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.05),
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
            Expanded(
              child: provider.conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
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
                        ],
                      ),
                    )
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              child: Text(
                'Nexus AI v1.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatProvider provider,
      String id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Rename Chat',
          style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF7C4DFF)),
            ),
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

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);
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
        color: Colors.red.withOpacity(0.3),
        child: const Icon(Icons.delete, color: Colors.white70),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onRename,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: accent.withOpacity(0.2))
                : null,
          ),
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
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
            trailing: Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }
}
