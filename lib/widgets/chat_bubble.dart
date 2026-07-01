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
        left: isUser ? 48 : 8,
        right: isUser ? 8 : 48,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            _buildAvatar(accent),
          const SizedBox(width: 8),
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
                  ),
                  child: _buildContent(isUser, accent),
                )
                    .animate()
                    .fadeIn(
                        duration: 300.ms,
                        curve: Curves.easeOut)
                    .slideX(
                        begin: isUser ? 0.2 : -0.2,
                        end: 0,
                        duration: 300.ms),
              ],
            ),
          ),
          if (isUser)
            _buildAvatar(accent),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color accent) {
    final isUser = message.role == 'user';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? accent.withOpacity(0.3) : accent.withOpacity(0.15),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.auto_awesome,
          size: 14,
          color: accent.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildContent(bool isUser, Color accent) {
    if (isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 14,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRetry!();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          height: 16,
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
          height: 1.5,
        ),
      );
    }

    if (isUser) {
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          textScaleFactor: 1.0,
          p: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
          code: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 13,
            backgroundColor: Color(0xFF1A1A2E),
          ),
          codeblockDecoration: const BoxDecoration(),
        ),
      );
    }

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        textScaleFactor: 1.0,
        p: const TextStyle(
          color: Color(0xFFE0E0FF),
          fontSize: 15,
          height: 1.5,
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
    );
  }
}
