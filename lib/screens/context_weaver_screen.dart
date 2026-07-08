import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/context_attachment.dart';
import '../providers/chat_provider.dart';
import '../providers/context_weaver_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ContextWeaverScreen extends StatefulWidget {
  const ContextWeaverScreen({super.key});

  @override
  State<ContextWeaverScreen> createState() => _ContextWeaverScreenState();
}

class _ContextWeaverScreenState extends State<ContextWeaverScreen> {
  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final chatProvider = context.watch<ChatProvider>();
    final conv = chatProvider.currentConversation;
    final convId = conv?.id ?? '';

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent, conv?.title ?? 'No Chat Selected'),
              Expanded(
                child: convId.isEmpty
                    ? _buildNoChat(accent)
                    : Consumer<ContextWeaverProvider>(
                        builder: (context, provider, _) {
                          final attachments =
                              provider.getAttachments(convId);
                          return _buildContent(accent, provider, convId,
                              attachments);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, String convTitle) {
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
          child: Column(
            children: [
              Row(
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
                    child: const Icon(Icons.link_rounded,
                        size: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Context Weaver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 52, bottom: 4),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        convTitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoChat(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'No Chat Selected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Open a conversation first,\nthen attach context here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color accent, ContextWeaverProvider provider,
      String convId, List<ContextAttachment> attachments) {
    return Column(
      children: [
        _buildActionBar(accent, provider, convId),
        Expanded(
          child: attachments.isEmpty
              ? _buildEmpty(accent)
              : _buildAttachmentsList(accent, provider, convId, attachments),
        ),
      ],
    );
  }

  Widget _buildActionBar(
      Color accent, ContextWeaverProvider provider, String convId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.language_rounded,
            label: 'URL',
            accent: accent,
            onTap: () => _showUrlDialog(context, provider, convId, accent),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.attach_file_rounded,
            label: 'File',
            accent: accent,
            onTap: () => provider.addFileAttachment(convId),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.edit_note_rounded,
            label: 'Note',
            accent: accent,
            onTap: () => _showTextDialog(context, provider, convId, accent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.08),
            ),
            child: Icon(Icons.link_rounded,
                size: 28, color: accent.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Context Attached',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add URLs, files, or notes to give the AI\nrelevant context for this conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(Color accent, ContextWeaverProvider provider,
      String convId, List<ContextAttachment> attachments) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final a = attachments[index];
        return _AttachmentCard(
          attachment: a,
          accent: accent,
          onToggle: () => provider.toggleAttachment(convId, a.id),
          onDelete: () {
            HapticFeedback.mediumImpact();
            provider.removeAttachment(convId, a.id);
          },
        );
      },
    );
  }

  void _showUrlDialog(BuildContext context, ContextWeaverProvider provider,
      String convId, Color accent) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Attach URL or YouTube Link'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
              Navigator.pop(ctx);
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                provider.addUrlAttachment(convId, url);
              }
            },
            child: const Text('Attach',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(BuildContext context, ContextWeaverProvider provider,
      String convId, Color accent) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste or type content...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();
              if (title.isNotEmpty && content.isNotEmpty) {
                provider.addTextAttachment(convId, title, content);
              }
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: accent.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accent.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final ContextAttachment attachment;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AttachmentCard({
    required this.attachment,
    required this.accent,
    required this.onToggle,
    required this.onDelete,
  });

  IconData _typeIcon(String type) {
    switch (type) {
      case 'url':
        return Icons.language_rounded;
      case 'youtube':
        return Icons.play_circle_rounded;
      case 'file':
        return Icons.insert_drive_file_rounded;
      case 'text':
        return Icons.edit_note_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'url':
        return const Color(0xFF64FFDA);
      case 'youtube':
        return const Color(0xFFFF5252);
      case 'file':
        return const Color(0xFF448AFF);
      case 'text':
        return const Color(0xFFFFD740);
      default:
        return accent;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'url':
        return 'Web Page';
      case 'youtube':
        return 'YouTube';
      case 'file':
        return 'File';
      case 'text':
        return 'Note';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(attachment.type);
    final preview = attachment.content.length > 120
        ? '${attachment.content.substring(0, 120)}...'
        : attachment.content;
    final sourcePreview = attachment.source.length > 50
        ? '${attachment.source.substring(0, 50)}...'
        : attachment.source;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: attachment.enabled
            ? const Color(0xFF12121A)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: attachment.enabled
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.03),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: attachment.enabled
                  ? Colors.white.withOpacity(0.03)
                  : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor.withOpacity(
                        attachment.enabled ? 0.15 : 0.05),
                  ),
                  child: Icon(_typeIcon(attachment.type),
                      size: 14,
                      color: typeColor
                          .withOpacity(attachment.enabled ? 0.8 : 0.3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.title,
                        style: TextStyle(
                          color: attachment.enabled
                              ? Colors.white.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SpaceGrotesk',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sourcePreview,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(
                        attachment.enabled ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _typeLabel(attachment.type),
                    style: TextStyle(
                      color: typeColor
                          .withOpacity(attachment.enabled ? 0.7 : 0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: attachment.enabled
                          ? accent
                          : Colors.transparent,
                      border: Border.all(
                        color: attachment.enabled
                            ? accent
                            : Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: attachment.enabled
                        ? const Icon(Icons.check,
                            size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white.withOpacity(0.2)),
                ),
              ],
            ),
          ),
          if (attachment.enabled && preview.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Text(
                preview,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  height: 1.4,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
