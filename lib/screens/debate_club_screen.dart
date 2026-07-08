import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class DebateClubScreen extends StatefulWidget {
  const DebateClubScreen({super.key});

  @override
  State<DebateClubScreen> createState() => _DebateClubScreenState();
}

class _DebateClubScreenState extends State<DebateClubScreen> {
  final _topicController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initDebate();
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleStart() {
    final topic = _topicController.text;
    if (topic.trim().isEmpty) return;
    _topicController.clear();
    _focusNode.unfocus();
    context.read<ChatProvider>().runDebate(topic);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<ChatProvider>();

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
                    colors: [accent, const Color(0xFFFF6B35)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.balance, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Debate Club',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildInputSection(accent, provider),
            Expanded(
              child: provider.debateResult == null && !provider.debateProcessing
                  ? _buildIdleState(accent)
                  : _buildDebate(accent, provider),
            ),
            if (provider.debateResult != null && !provider.debateProcessing)
              _buildActionBar(accent, provider),
          ],
        ),
      ),
    );
  }

  // ── Input Section ────────────────────────────────────

  Widget _buildInputSection(Color accent, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: provider.debateProcessing
                    ? accent.withOpacity(0.25)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.02),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicController,
                          focusNode: _focusNode,
                          maxLines: 2,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: provider.debateProcessing
                                ? 'Debate in progress...'
                                : 'Enter a debate topic...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _handleStart(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStartButton(accent, provider),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildModelSelectors(accent, provider),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color accent, ChatProvider provider) {
    if (provider.debateProcessing) {
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
          colors: [accent, const Color(0xFFFF6B35)],
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
          onTap: _handleStart,
          child: const Center(
            child: Icon(Icons.balance, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelectors(Color accent, ChatProvider provider) {
    final options = provider.debateModelOptions;
    if (options.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildModelDropdown(
            label: 'FOR',
            labelColor: const Color(0xFF00E676),
            selectedId: provider.debateForModel.id,
            options: options,
            onChanged: provider.debateProcessing
                ? null
                : (id) => provider.setDebateForModel(id),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'VS',
            style: TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
        ),
        Expanded(
          child: _buildModelDropdown(
            label: 'AGAINST',
            labelColor: const Color(0xFFFF5252),
            selectedId: provider.debateAgainstModel.id,
            options: options,
            onChanged: provider.debateProcessing
                ? null
                : (id) => provider.setDebateAgainstModel(id),
          ),
        ),
      ],
    );
  }

  Widget _buildModelDropdown({
    required String label,
    required Color labelColor,
    required String selectedId,
    required List<DebateModelConfig> options,
    required void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isDense: true,
                dropdownColor: const Color(0xFF1A1A2E),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
                items: options.map((m) {
                  return DropdownMenuItem(
                    value: m.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _modelIcon(m.id, true, labelColor),
                        const SizedBox(width: 4),
                        Text(m.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged != null ? (id) => onChanged(id!) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Idle State ───────────────────────────────────────

  Widget _buildIdleState(Color accent) {
    return Center(
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
              Icons.balance,
              size: 40,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Debate Club',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Two AI models debate any topic — FOR vs AGAINST',
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

  // ── Debate View ──────────────────────────────────────

  Widget _buildDebate(Color accent, ChatProvider provider) {
    final result = provider.debateResult;
    if (result == null) return const SizedBox.shrink();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        _buildTopicHeader(result.topic, accent),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DebateArgumentCard(
                argument: result.forArg,
                sideLabel: 'FOR',
                sideColor: const Color(0xFF00E676),
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebateArgumentCard(
                argument: result.againstArg,
                sideLabel: 'AGAINST',
                sideColor: const Color(0xFFFF5252),
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicHeader(String topic, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.topic, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              topic,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(Color accent, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionChip(
            Icons.refresh_rounded,
            'New Debate',
            accent,
            () {
              provider.clearDebate();
              _focusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelIcon(String id, bool enabled, Color accent) {
    final color = enabled ? _modelColor(id) : Colors.white.withOpacity(0.2);
    switch (id) {
      case 'groq':
        return Icon(Icons.bolt_outlined, size: 14, color: color);
      case 'claude':
        return Icon(Icons.psychology_outlined, size: 14, color: color);
      case 'ollama':
        return Icon(Icons.computer_outlined, size: 14, color: color);
      default:
        return Icon(Icons.smart_toy_outlined, size: 14, color: color);
    }
  }

  Color _modelColor(String id) {
    switch (id) {
      case 'groq': return const Color(0xFF00E676);
      case 'claude': return const Color(0xFFE040FB);
      case 'ollama': return const Color(0xFF448AFF);
      default: return const Color(0xFF7C4DFF);
    }
  }
}

// ── Argument Card ─────────────────────────────────────

class _DebateArgumentCard extends StatelessWidget {
  final DebateArgument argument;
  final String sideLabel;
  final Color sideColor;
  final Color accent;

  const _DebateArgumentCard({
    required this.argument,
    required this.sideLabel,
    required this.sideColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isError = argument.error != null;
    final isComplete = argument.isComplete;
    final hasContent = argument.content.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.2)
              : isComplete && argument.error == null
                  ? sideColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (isError)
            _buildError()
          else if (!hasContent && !isComplete)
            _buildLoading()
          else
            _buildContent(),
          if (!isError && isComplete && hasContent)
            _buildStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sideColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sideLabel == 'FOR' ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
                  size: 12,
                  color: sideColor,
                ),
                const SizedBox(width: 4),
                Text(
                  sideLabel,
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            sideLabel == 'FOR' ? Icons.bolt_outlined : Icons.psychology_outlined,
            size: 13,
            color: _modelColor(argument.modelId),
          ),
          const SizedBox(width: 4),
          Text(
            argument.modelLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (argument.error != null) {
      return Text(
        'Error',
        style: TextStyle(
          color: Colors.red.shade300,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (!argument.isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10, height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: sideColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Speaking...',
            style: TextStyle(
              color: sideColor.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Icon(Icons.check_circle, size: 14, color: sideColor.withOpacity(0.6));
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF7C4DFF),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              argument.error!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MarkdownBody(
        data: argument.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 13,
            height: 1.5,
          ),
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h2: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h3: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          strong: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          code: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 11,
            fontFamily: 'monospace',
            backgroundColor: Color(0xFF1A1A2E),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: sideColor.withOpacity(0.5), width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 10),
          listBullet: TextStyle(color: sideColor),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
        ),
        builders: {
          'pre': CodeBlockBuilder(),
        },
      ),
    );
  }

  Widget _buildStats() {
    final elapsed = argument.elapsed;
    final cps = argument.charsPerSecond;
    if (elapsed == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 10, color: sideColor.withOpacity(0.5)),
          const SizedBox(width: 3),
          Text(
            _formatDuration(elapsed),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (cps != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.speed, size: 10, color: sideColor.withOpacity(0.5)),
            const SizedBox(width: 3),
            Text(
              '${cps.toStringAsFixed(0)} c/s',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${argument.content.length} chars',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Color _modelColor(String id) {
    switch (id) {
      case 'groq': return const Color(0xFF00E676);
      case 'claude': return const Color(0xFFE040FB);
      case 'ollama': return const Color(0xFF448AFF);
      default: return const Color(0xFF7C4DFF);
    }
  }
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '${d.inMilliseconds}ms';
  }
  if (d.inSeconds < 60) {
    final ms = d.inMilliseconds % 1000;
    return '${d.inSeconds}.${(ms ~/ 100)}s';
  }
  final secs = d.inSeconds % 60;
  final mins = d.inMinutes;
  return '${mins}m ${secs}s';
}
