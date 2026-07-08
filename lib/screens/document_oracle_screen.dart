import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/document_oracle_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class DocumentOracleScreen extends StatefulWidget {
  const DocumentOracleScreen({super.key});

  @override
  State<DocumentOracleScreen> createState() => _DocumentOracleScreenState();
}

class _DocumentOracleScreenState extends State<DocumentOracleScreen> {
  final _questionController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend() {
    final text = _questionController.text;
    if (text.trim().isEmpty) return;
    _questionController.clear();
    _focusNode.requestFocus();
    context.read<DocumentOracleProvider>().askQuestion(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<DocumentOracleProvider>();

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
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF448AFF)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                provider.document != null
                    ? provider.document!.name.length > 20
                        ? '${provider.document!.name.substring(0, 17)}...'
                        : provider.document!.name
                    : 'Document Oracle',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: provider.document != null
              ? [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                    onPressed: () {
                      provider.clearDocument();
                      _questionController.clear();
                    },
                    tooltip: 'Remove document',
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            Expanded(
              child: provider.document == null
                  ? _buildEmptyState(accent, provider)
                  : _buildChat(accent, provider),
            ),
            if (provider.document != null)
              _buildInputBar(accent, provider),
          ],
        ),
      ),
    );
  }

  // ── Empty / Upload State ──────────────────────────────

  Widget _buildEmptyState(Color accent, DocumentOracleProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
                ),
              ),
              child: Icon(
                Icons.menu_book,
                size: 40,
                color: accent.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Document Oracle',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a document and ask questions about it',
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 32),
            _buildUploadButton(accent, provider),
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(provider.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(Color accent, DocumentOracleProvider provider) {
    return GestureDetector(
      onTap: provider.isLoading ? null : () => provider.pickDocument(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, const Color(0xFF448AFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: provider.isLoading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Upload PDF or Text File',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 13,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Document Info Bar ─────────────────────────────────

  Widget _buildDocInfoBar(Color accent, DocumentOracleProvider provider) {
    final doc = provider.document;
    if (doc == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.pageCount} page${doc.pageCount != 1 ? 's' : ''} · ${_formatCharCount(doc.content.length)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => provider.pickDocument(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    'Change',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat View ─────────────────────────────────────────

  Widget _buildChat(Color accent, DocumentOracleProvider provider) {
    return Column(
      children: [
        _buildDocInfoBar(accent, provider),
        Expanded(
          child: provider.messages.isEmpty && !provider.isProcessing
              ? _buildChatIdle(accent)
              : _buildMessageList(accent, provider),
        ),
      ],
    );
  }

  Widget _buildChatIdle(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.08),
            ),
            child: Icon(Icons.chat_outlined, size: 28, color: accent.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask about this document',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 15,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 240,
            child: Text(
              'Questions will be answered based on the document content',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(Color accent, DocumentOracleProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: provider.messages.length + (provider.isProcessing ? 1 : 0) + (provider.error != null ? 1 : 0),
      itemBuilder: (context, index) {
        int offset = 0;

        if (provider.error != null && index == 0) {
          offset = 1;
          return _buildErrorBanner(provider.error!);
        }

        final msgIndex = index - offset;
        if (msgIndex < provider.messages.length) {
          final msg = provider.messages[msgIndex];
          return _buildMessageBubble(msg, accent);
        }

        if (provider.isProcessing && provider.currentResponse.isNotEmpty) {
          return _buildStreamingBubble(accent, provider);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(OracleMessage msg, Color accent) {
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
              child: Icon(Icons.auto_awesome, size: 14, color: accent),
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
                  ? Text(
                      msg.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Color(0xFFE0E0FF),
                          fontSize: 14,
                          height: 1.6,
                        ),
                        strong: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        code: const TextStyle(
                          color: Color(0xFFE0E0FF),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          backgroundColor: Color(0xFF1A1A2E),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(10),
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

  Widget _buildStreamingBubble(Color accent, DocumentOracleProvider provider) {
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
            child: Icon(Icons.auto_awesome, size: 14, color: accent),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: accent.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Analyzing...',
                        style: TextStyle(
                          color: accent.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: provider.currentResponse,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Color(0xFFE0E0FF),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    builders: {'pre': CodeBlockBuilder()},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────

  Widget _buildInputBar(Color accent, DocumentOracleProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: provider.isProcessing
              ? accent.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
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
                    controller: _questionController,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: provider.isProcessing
                          ? 'Thinking...'
                          : 'Ask about this document...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 4),
                _buildSendButton(accent, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(Color accent, DocumentOracleProvider provider) {
    if (provider.isProcessing) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.15),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF448AFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleSend,
          child: const Center(
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  String _formatCharCount(int count) {
    if (count < 1000) return '$count chars';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K chars';
    return '${(count / 1000000).toStringAsFixed(1)}M chars';
  }
}
