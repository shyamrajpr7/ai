import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class ConversationSummaryScreen extends StatefulWidget {
  const ConversationSummaryScreen({super.key});

  @override
  State<ConversationSummaryScreen> createState() => _ConversationSummaryScreenState();
}

class _ConversationSummaryScreenState extends State<ConversationSummaryScreen> {
  bool _isGenerating = false;
  String _summary = '';
  String? _selectedConvId;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final conversations = context.watch<ChatProvider>().conversations;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Conversation Summary',
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: GradientMeshBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildConversationPicker(conversations, accent),
            const SizedBox(height: 12),
            if (_selectedConvId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _generateSummary(conversations, accent),
                    icon: _isGenerating
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                        : Icon(Icons.auto_awesome, size: 18, color: accent),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'Generate Summary',
                      style: GoogleFonts.inter(color: _isGenerating ? Colors.white30 : accent),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent.withOpacity(0.1),
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: accent.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _summary.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.summarize, size: 64, color: accent.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Select a conversation to summarize',
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : _buildSummaryContent(accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationPicker(List conversations, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: DropdownButton<String>(
          value: _selectedConvId,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF1A1A2E),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          hint: Text(
            'Select a conversation',
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
          items: conversations.map<DropdownMenuItem<String>>((conv) {
            final msgCount = conv.messages.length;
            return DropdownMenuItem(
              value: conv.id,
              child: Text(
                '${conv.title} ($msgCount msgs)',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() {
            _selectedConvId = v;
            _summary = '';
          }),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(Color accent) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.08), Colors.white.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Summary',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Summary copied!', style: GoogleFonts.inter(fontSize: 13)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(Icons.copy, size: 18, color: accent.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _summary,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withOpacity(0.85),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummary(List conversations, Color accent) async {
    if (_selectedConvId == null) return;

    final conv = conversations.firstWhere((c) => c.id == _selectedConvId);
    final messages = conv.messages;

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This conversation has no messages.', style: GoogleFonts.inter(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _summary = '';
    });

    try {
      final transcript = messages
          .map((m) => '${m.role == 'user' ? 'User' : 'AI'}: ${m.content.substring(0, m.content.length > 500 ? 500 : m.content.length)}')
          .join('\n\n');

      final truncated = transcript.length > 8000 ? transcript.substring(0, 8000) : transcript;

      final provider = context.read<SettingsProvider>();
      final chatProvider = context.read<ChatProvider>();
      final service = chatProvider.createAIService();
      final systemPrompt =
          'You are a conversation summarizer. Provide a clear, concise summary of the conversation. '
          'Include: 1) Main topic, 2) Key points discussed, 3) Any decisions or conclusions, 4) Action items if any. '
          'Use bullet points. Output ONLY the summary text, no labels or prefixes.';

      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: 'Summarize this conversation:\n\n$truncated',
        history: [],
        systemPrompt: systemPrompt,
      )) {
        response.write(chunk);
        setState(() => _summary = response.toString());
      }
    } catch (_) {
      setState(() => _summary = 'Failed to generate summary. Please try again.');
    }

    setState(() => _isGenerating = false);
  }
}
