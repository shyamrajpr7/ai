import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceResult = '';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _voiceResult = '';
      });

      _speech.listen(
        onResult: (result) {
          setState(() => _voiceResult = result.recognizedWords);
          _contentController.text = _voiceResult;
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Voice Journal',
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, accent),
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildSearchBar(accent),
            const SizedBox(height: 8),
            _buildMoodOverview(accent),
            Expanded(
              child: Consumer<JournalProvider>(
                builder: (context, provider, _) {
                  final entries = provider.filteredEntries;
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 64, color: accent.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            provider.searchQuery.isEmpty
                                ? 'No journal entries yet'
                                : 'No matching entries',
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to write or speak your first entry',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white30),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildEntryCard(entries[index], accent);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          onChanged: (v) => context.read<JournalProvider>().setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search entries...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodOverview(Color accent) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final dist = provider.moodDistribution;
        if (dist.isEmpty) return const SizedBox.shrink();

        final sorted = dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: sorted.take(5).map((e) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _moodEmoji(e.key),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key} (${e.value})',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(JournalEntry entry, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.mood != null) ...[
                Text(_moodEmoji(entry.mood!), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(entry.createdAt),
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              if (entry.isVoiceInput)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.mic, size: 12, color: accent),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.white.withOpacity(0.4)),
                onSelected: (v) {
                  if (v == 'analyze') context.read<JournalProvider>().analyzeEntry(entry.id);
                  if (v == 'edit') _showEditDialog(context, accent, entry);
                  if (v == 'delete') _confirmDelete(context, entry);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'analyze', child: Text('AI Analyze')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                color: const Color(0xFF1A1A2E),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          if (entry.aiSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: accent.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.aiSummary!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, Color accent) {
    _titleController.clear();
    _contentController.clear();
    _voiceResult = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('New Entry', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _saveEntry(context);
                        Navigator.pop(ctx);
                      },
                      child: Text('Save', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Title...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (_isListening) {
                                _stopListening();
                              } else {
                                _startListening();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? Colors.redAccent.withOpacity(0.2)
                                  : accent.withOpacity(0.1),
                              border: Border.all(
                                color: _isListening ? Colors.redAccent : accent.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: _isListening ? Colors.redAccent : accent,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isListening ? 'Listening... Tap to stop' : 'Tap to speak',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _isListening ? Colors.redAccent : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      maxLines: 15,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        border: InputBorder.none,
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

  void _showEditDialog(BuildContext context, Color accent, JournalEntry entry) {
    _titleController.text = entry.title;
    _contentController.text = entry.content;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Edit Entry', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.read<JournalProvider>().updateEntry(JournalEntry(
                        id: entry.id,
                        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Untitled',
                        content: _contentController.text,
                        aiSummary: entry.aiSummary,
                        mood: entry.mood,
                        moodScore: entry.moodScore,
                        tags: entry.tags,
                        isVoiceInput: entry.isVoiceInput,
                        createdAt: entry.createdAt,
                      ));
                      Navigator.pop(ctx);
                    },
                    child: Text('Save', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Title...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: 15,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.6),
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry(BuildContext context) {
    final provider = context.read<JournalProvider>();
    provider.addEntry(
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Untitled Entry',
      content: _contentController.text,
      isVoiceInput: _voiceResult.isNotEmpty,
    );
  }

  void _confirmDelete(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Entry?'),
        content: Text(
          'This will permanently delete "${entry.title}".',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().deleteEntry(entry.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '\u{1F60A}';
      case 'sad': return '\u{1F622}';
      case 'anxious': return '\u{1F61F}';
      case 'peaceful': return '\u{1F54A}';
      case 'excited': return '\u{1F929}';
      case 'frustrated': return '\u{1F624}';
      case 'grateful': return '\u{1F64F}';
      case 'reflective': return '\u{1F9D8}';
      default: return '\u{1F4DD}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
