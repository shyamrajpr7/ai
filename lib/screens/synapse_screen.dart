import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/persona.dart';
import '../models/synapse.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class SynapseScreen extends StatefulWidget {
  const SynapseScreen({super.key});

  @override
  State<SynapseScreen> createState() => _SynapseScreenState();
}

class _SynapseScreenState extends State<SynapseScreen> {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _steerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initSynapse();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _steerController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleStart() {
    final text = _promptController.text;
    if (text.trim().isEmpty) return;
    _promptController.clear();
    _focusNode.unfocus();
    context.read<ChatProvider>().startSynapse(text);
    _scrollToBottom();
  }

  void _showSteerDialog() {
    final accent = context.read<SettingsProvider>().accentColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Steer Conversation',
          style: TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk'),
        ),
        content: TextField(
          controller: _steerController,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'Give direction to the personas...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent),
            ),
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
              final text = _steerController.text.trim();
              if (text.isNotEmpty) {
                context.read<ChatProvider>().steerSynapse(text);
                _steerController.clear();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Send',
                style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<ChatProvider>();
    final session = provider.synapseSession;
    final personas = context.watch<SettingsProvider>().personas;

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
                    colors: [accent, const Color(0xFFFF9100)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.hub_outlined, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Synapse',
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
            _buildPersonaSelector(accent, provider, personas),
            Expanded(
              child: session == null
                  ? _buildIdleState(accent)
                  : _buildSynapseView(accent, provider, session),
            ),
            if (session == null || session.status == SynapseStatus.idle)
              _buildStartBar(accent, provider)
            else
              _buildControlBar(accent, provider, session),
          ],
        ),
      ),
    );
  }

  // ── Persona Selector ───────────────────────────────────

  Widget _buildPersonaSelector(
      Color accent, ChatProvider provider, List<Persona> personas) {
    final selected = provider.synapsePersonaIds;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Personas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${selected.length}/3 selected',
                style: TextStyle(
                  color: selected.length >= 2 ? accent : Colors.white.withOpacity(0.2),
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: personas.map((p) {
                final isSelected = selected.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => provider.toggleSynapsePersona(p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? p.color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: isSelected
                              ? p.color.withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 5),
                          Text(
                            p.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              fontSize: 12,
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
        ],
      ),
    );
  }

  // ── Idle State ─────────────────────────────────────────

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
              Icons.hub_outlined,
              size: 40,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Synapse Collaboration',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select 2-3 personas and enter a prompt',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Watch them brainstorm, debate, and collaborate',
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Synapse View ───────────────────────────────────────

  Widget _buildSynapseView(
      Color accent, ChatProvider provider, SynapseSession session) {
    return Column(
      children: [
        if (session.status == SynapseStatus.paused)
          _buildPausedBanner(accent),
        if (session.errorMessage != null)
          _buildErrorBanner(accent, session.errorMessage!),
        Expanded(child: _buildMessages(accent, provider, session)),
      ],
    );
  }

  Widget _buildPausedBanner(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: accent.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.pause_circle_outline, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            'Paused — tap resume to continue',
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(Color accent, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
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

  Widget _buildMessages(
      Color accent, ChatProvider provider, SynapseSession session) {
    final msgs = session.messages;
    if (msgs.isEmpty && session.status == SynapseStatus.running) {
      return const Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF7C4DFF),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: msgs.length + (provider.synapseProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < msgs.length) {
          return _SynapseMessageBubble(message: msgs[index], accent: accent);
        }
        return _buildTypingIndicator(accent);
      },
    );
  }

  Widget _buildTypingIndicator(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  // ── Control Bar ────────────────────────────────────────

  Widget _buildControlBar(
      Color accent, ChatProvider provider, SynapseSession session) {
    final isRunning = session.status == SynapseStatus.running;
    final isPaused = session.status == SynapseStatus.paused;
    final isCompleted = session.status == SynapseStatus.completed ||
        session.status == SynapseStatus.error;
    final hasContent = session.messages.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isRunning
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (isRunning || isPaused) ...[
                  _controlButton(
                    icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: accent,
                    onTap: () {
                      if (isPaused) {
                        provider.resumeSynapse();
                      } else {
                        provider.pauseSynapse();
                      }
                    },
                  ),
                  _controlButton(
                    icon: Icons.north_east_rounded,
                    color: accent,
                    onTap: _showSteerDialog,
                  ),
                ],
                if (isCompleted && hasContent) ...[
                  _controlButton(
                    icon: Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.4),
                    onTap: () {
                      provider.initSynapse();
                    },
                  ),
                ],
                const Spacer(),
                if (isRunning || isPaused)
                  _controlButton(
                    icon: Icons.stop_rounded,
                    color: Colors.red.shade300,
                    onTap: () => provider.stopSynapse(),
                  ),
                if (!isRunning && !isPaused && hasContent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      session.status == SynapseStatus.completed
                          ? 'Complete'
                          : 'Error',
                      style: TextStyle(
                        color: session.status == SynapseStatus.completed
                            ? const Color(0xFF00E676)
                            : Colors.red.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  // ── Start Bar ──────────────────────────────────────────

  Widget _buildStartBar(Color accent, ChatProvider provider) {
    final canStart = provider.synapsePersonaIds.length >= 2;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: canStart
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
                    controller: _promptController,
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
                      hintText: !canStart
                          ? 'Select 2-3 personas above...'
                          : 'Enter a topic for debate...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) => canStart ? _handleStart() : null,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStartButton(accent, canStart),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(Color accent, bool canStart) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, const Color(0xFFFF9100)],
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
          onTap: canStart ? _handleStart : null,
          child: const Center(
            child: Icon(
              Icons.hub_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message Bubble ───────────────────────────────────────

class _SynapseMessageBubble extends StatelessWidget {
  final SynapseMessage message;
  final Color accent;

  const _SynapseMessageBubble({
    required this.message,
    required this.accent,
  });

  Color get _personaColor => Color(message.personaColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _personaColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _personaColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _personaColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(message.personaEmoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message.personaName,
            style: TextStyle(
              color: _personaColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _personaColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Turn ${message.turnNumber + 1}',
              style: TextStyle(
                color: _personaColor.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: MarkdownBody(
        data: message.content,
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
          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              left: BorderSide(color: _personaColor.withOpacity(0.5), width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 12),
          listBullet: TextStyle(color: _personaColor),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        builders: {
          'pre': CodeBlockBuilder(),
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 10, color: Colors.white.withOpacity(0.15)),
          const SizedBox(width: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
