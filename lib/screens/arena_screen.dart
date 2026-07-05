import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initArena();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
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
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    context.read<ChatProvider>().runArena(text);
    _scrollToBottom();
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
                    colors: [accent, const Color(0xFFE040FB)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.sports_kabaddi, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Arena',
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
            _buildModelToggles(accent, provider),
            Expanded(
              child: provider.arenaResults.isEmpty && !provider.arenaProcessing
                  ? _buildIdleState(accent)
                  : _buildResults(accent, provider),
            ),
            _buildInputBar(accent, provider),
          ],
        ),
      ),
    );
  }

  // ── Model Toggles ─────────────────────────────────────

  Widget _buildModelToggles(Color accent, ChatProvider provider) {
    final models = provider.arenaModels;
    if (models.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Compare',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: models.map((m) {
                  final enabled = m.enabled;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => provider.toggleArenaModel(m.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: enabled
                              ? _modelColor(m.id).withOpacity(0.2)
                              : Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: enabled
                                ? _modelColor(m.id).withOpacity(0.4)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _modelIcon(m.id, enabled, accent),
                            const SizedBox(width: 6),
                            Text(
                              m.label,
                              style: TextStyle(
                                color: enabled
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelIcon(String id, bool enabled, Color accent) {
    final color = enabled ? _modelColor(id) : Colors.white.withOpacity(0.2);
    switch (id) {
      case 'groq':
        return Icon(Icons.bolt_outlined, size: 16, color: color);
      case 'claude':
        return Icon(Icons.psychology_outlined, size: 16, color: color);
      case 'ollama':
        return Icon(Icons.computer_outlined, size: 16, color: color);
      default:
        return Icon(Icons.smart_toy_outlined, size: 16, color: color);
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

  // ── Idle State ────────────────────────────────────────

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
              Icons.sports_kabaddi,
              size: 40,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Model Arena',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send one prompt to every model at once',
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

  // ── Results ───────────────────────────────────────────

  Widget _buildResults(Color accent, ChatProvider provider) {
    final results = provider.arenaResults;
    final allDone = results.isNotEmpty && results.every((r) => r.isComplete);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: results.length + (allDone ? 1 : 0),
      itemBuilder: (context, index) {
        if (allDone && index == 0) {
          return _buildSpeedSummary(results, accent);
        }
        final resultIdx = allDone ? index - 1 : index;
        if (resultIdx < results.length) {
          return _ArenaResultCard(
            result: results[resultIdx],
            allResults: results,
            accent: accent,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSpeedSummary(List<ArenaResult> results, Color accent) {
    final completed = results.where((r) => r.elapsed != null).toList();
    if (completed.length < 2) return const SizedBox.shrink();

    completed.sort((a, b) => (a.elapsed!.inMilliseconds).compareTo(b.elapsed!.inMilliseconds));
    final fastest = completed.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                ),
                child: Icon(Icons.speed, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'Speed Rankings',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...completed.asMap().entries.map((entry) {
            final rank = entry.key;
            final r = entry.value;
            final isFastest = r.modelId == fastest.modelId;
            final pct = fastest.elapsed!.inMilliseconds > 0
                ? (fastest.elapsed!.inMilliseconds / r.elapsed!.inMilliseconds * 100)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      _rankEmoji(rank),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _modelIcon(r.modelId, true, accent),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      r.modelLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation(
                                isFastest
                                    ? _modelColor(r.modelId)
                                    : _modelColor(r.modelId).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(r.elapsed!),
                    style: TextStyle(
                      color: isFastest
                          ? _modelColor(r.modelId)
                          : Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: isFastest ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 0: return '🏆';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return '$rank.';
    }
  }

  // ── Input Bar ─────────────────────────────────────────

  Widget _buildInputBar(Color accent, ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: provider.arenaProcessing
              ? const Color(0xFFE040FB).withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.1),
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
                    controller: _textController,
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
                      hintText: provider.arenaProcessing
                          ? 'Running arena...'
                          : 'Type a prompt to test across models...',
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

  Widget _buildSendButton(Color accent, ChatProvider provider) {
    if (provider.arenaProcessing) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE040FB).withOpacity(0.15),
          border: Border.all(
            color: const Color(0xFFE040FB).withOpacity(0.3),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFFE040FB),
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
          colors: [accent, const Color(0xFFE040FB)],
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
            child: Icon(
              Icons.sports_kabaddi,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result Card ─────────────────────────────────────────

const _speedEmojis = ['🏆', '🥈', '🥉'];

class _ArenaResultCard extends StatelessWidget {
  final ArenaResult result;
  final List<ArenaResult> allResults;
  final Color accent;

  const _ArenaResultCard({
    required this.result,
    required this.allResults,
    required this.accent,
  });

  int get _speedRank {
    final withTime = allResults
        .where((r) => r.elapsed != null && r.error == null)
        .toList()
      ..sort((a, b) => a.elapsed!.inMilliseconds.compareTo(b.elapsed!.inMilliseconds));
    final idx = withTime.indexWhere((r) => r.modelId == result.modelId);
    return idx;
  }

  double get _relativeCps {
    if (result.charsPerSecond == null) return 0;
    final maxCps = allResults
        .where((r) => r.charsPerSecond != null && r.error == null)
        .fold<double>(0, (max, r) => r.charsPerSecond! > max ? r.charsPerSecond! : max);
    if (maxCps == 0) return 0;
    return result.charsPerSecond! / maxCps;
  }

  @override
  Widget build(BuildContext context) {
    final isError = result.error != null;
    final isComplete = result.isComplete;
    final hasContent = result.content.isNotEmpty;
    final rank = _speedRank;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.2)
              : isComplete && result.error == null
                  ? _modelColor(result.modelId).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(rank),
          _buildSpeedBar(rank),
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

  Widget _buildHeader(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _modelIcon(result.modelId, true, accent),
          const SizedBox(width: 8),
          Text(
            result.modelLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          if (result.isComplete && result.error == null && rank >= 0 && rank < 3) ...[
            const SizedBox(width: 6),
            Text(
              _speedEmojis[rank],
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const Spacer(),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (result.error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Error',
          style: TextStyle(
            color: Colors.red.shade300,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!result.isComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _modelColor(result.modelId).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _modelColor(result.modelId).withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Streaming',
              style: TextStyle(
                color: _modelColor(result.modelId).withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (result.elapsed != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _modelColor(result.modelId).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 11, color: _modelColor(result.modelId).withOpacity(0.7)),
            const SizedBox(width: 3),
            Text(
              _formatDuration(result.elapsed!),
              style: TextStyle(
                color: _modelColor(result.modelId).withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _modelColor(result.modelId).withOpacity(0.2),
      ),
      child: Icon(Icons.check, size: 12, color: _modelColor(result.modelId)),
    );
  }

  Widget _buildSpeedBar(int rank) {
    if (!result.isComplete || result.error != null) return const SizedBox.shrink();

    final cps = result.charsPerSecond;
    if (cps == null) return const SizedBox.shrink();

    final rel = _relativeCps;
    final isFastest = rank == 0;

    return Container(
      height: 3,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: rel > 0.01 ? rel : 0.01,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(3),
            ),
            gradient: LinearGradient(
              colors: [
                _modelColor(result.modelId).withOpacity(0.3),
                isFastest
                    ? _modelColor(result.modelId).withOpacity(0.9)
                    : _modelColor(result.modelId).withOpacity(0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 24, height: 24,
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
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.error!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 13,
                height: 1.5,
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
      padding: const EdgeInsets.all(14),
      child: MarkdownBody(
        data: result.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 14,
            height: 1.6,
          ),
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h2: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h3: const TextStyle(
            color: Colors.white,
            fontSize: 15,
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
            fontSize: 12,
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
                color: _modelColor(result.modelId).withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 12),
          listBullet: TextStyle(
            color: _modelColor(result.modelId),
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
    );
  }

  Widget _buildStats() {
    final cps = result.charsPerSecond;
    final latency = result.firstTokenLatency;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _statChip(
            Icons.timer_outlined,
            _formatDuration(result.elapsed!),
            'elapsed',
            _modelColor(result.modelId),
          ),
          const SizedBox(width: 12),
          if (cps != null)
            _statChip(
              Icons.speed,
              '${cps.toStringAsFixed(0)} c/s',
              'throughput',
              _modelColor(result.modelId),
            ),
          if (cps != null) const SizedBox(width: 12),
          if (latency != null)
            _statChip(
              Icons.flash_on_outlined,
              _formatDuration(latency),
              'first token',
              _modelColor(result.modelId),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 10,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _modelIcon(String id, bool enabled, Color accent) {
    final color = enabled ? _modelColor(id) : Colors.white.withOpacity(0.2);
    switch (id) {
      case 'groq':
        return Icon(Icons.bolt_outlined, size: 16, color: color);
      case 'claude':
        return Icon(Icons.psychology_outlined, size: 16, color: color);
      case 'ollama':
        return Icon(Icons.computer_outlined, size: 16, color: color);
      default:
        return Icon(Icons.smart_toy_outlined, size: 16, color: color);
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

// ── Helpers ─────────────────────────────────────────────

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
