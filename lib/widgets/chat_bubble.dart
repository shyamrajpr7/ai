import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import 'glow_text.dart';
import 'code_block.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final bool isError;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final accent = const Color(0xFF7C4DFF);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 12,
        right: isUser ? 12 : 60,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            _buildAvatar(accent, isUser),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft:
                          Radius.circular(isUser ? 20 : 4),
                      topRight:
                          Radius.circular(isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    color: isUser
                        ? accent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: isUser
                          ? accent.withOpacity(0.3)
                          : Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? accent.withOpacity(0.08)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildContent(context, isUser, accent),
                )
                    .animate()
                    .fadeIn(
                        duration: 300.ms,
                        curve: Curves.easeOutCubic)
                    .slideX(
                        begin: isUser ? 0.15 : -0.15,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 2),
                if (!isStreaming && !isError)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isUser ? 0 : 4,
                      right: isUser ? 4 : 0,
                    ),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser)
            _buildAvatar(accent, isUser),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final min = timestamp.minute.toString().padLeft(2, '0');
    if (diff.inDays < 1) return '$hour:$min $ampm';
    return '${timestamp.month}/${timestamp.day} $hour:$min $ampm';
  }

  Widget _buildAvatar(Color accent, bool isUser) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? LinearGradient(
                colors: [accent, accent.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [const Color(0xFF7C4DFF), const Color(0xFF448AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: (isUser ? accent : const Color(0xFF7C4DFF)).withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.auto_awesome,
          size: 15,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser, Color accent) {
    if (isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRetry!();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.5)),
                  color: accent.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isStreaming) {
      if (message.content.isEmpty) {
        return const SizedBox(
          width: 40,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF7C4DFF),
              ),
            ),
          ),
        );
      }
      return GlowText(
        message.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.6,
        ),
      );
    }

    if (isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.imageBase64 != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () => _showImagePreview(context, message.imageBase64!),
                child: Image.memory(
                  base64Decode(message.imageBase64!),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (message.content.isNotEmpty) const SizedBox(height: 8),
          ],
          if (message.content.isNotEmpty)
            MarkdownBody(
              data: message.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 15,
                  height: 1.6,
                ),
                code: const TextStyle(
                  color: Color(0xFFE0E0FF),
                  fontSize: 13,
                  backgroundColor: Color(0xFF1A1A2E),
                ),
                codeblockDecoration: const BoxDecoration(),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.imageBase64 != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showImagePreview(context, message.imageBase64!),
                child: Image.memory(
                  base64Decode(message.imageBase64!),
                  width: 240,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (message.content.isNotEmpty) const SizedBox(height: 10),
        ],
        if (message.content.isNotEmpty)
          MarkdownBody(
            data: message.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 15,
                height: 1.6,
              ),
              h1: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
              h2: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
              h3: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
              strong: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              em: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontStyle: FontStyle.italic,
              ),
              code: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 13,
                fontFamily: 'monospace',
                backgroundColor: Color(0xFF1A1A2E),
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF7C4DFF).withOpacity(0.5),
                    width: 3,
                  ),
                ),
              ),
              blockquotePadding: const EdgeInsets.only(left: 12),
              listBullet: const TextStyle(
                color: Color(0xFF7C4DFF),
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
            builders: {
              'pre': CodeBlockBuilder(),
            },
          ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, String base64) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(base64),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
