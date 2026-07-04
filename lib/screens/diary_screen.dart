import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  bool _isGenerating = false;

  void _generateEntry() async {
    final provider = context.read<ChatProvider>();
    setState(() => _isGenerating = true);
    try {
      await provider.generateDiaryEntry();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;
    final provider = context.watch<ChatProvider>();
    final entries = provider.diaryEntries;

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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF448AFF)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chat Diary',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            if (!_isGenerating)
              IconButton(
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  color: provider.hasTodayEntry
                      ? Colors.white.withOpacity(0.3)
                      : accent,
                ),
                tooltip: provider.hasTodayEntry
                    ? 'Regenerate today\'s entry'
                    : 'Generate today\'s entry',
                onPressed: _generateEntry,
              ),
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
              ),
          ],
        ),
        body: entries.isEmpty
            ? _buildEmptyState(accent)
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: entries.length,
                itemBuilder: (context, index) =>
                    _DiaryCard(entry: entries[index], accent: accent),
              ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: accent.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No diary entries yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with AI and generate a daily summary',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isGenerating ? null : _generateEntry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.6)],
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Generate Today\'s Entry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final Color accent;

  const _DiaryCard({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(entry.date, DateTime.now());
    final dateStr = isToday
        ? 'Today'
        : '${_month(entry.date.month)} ${entry.date.day}, ${entry.date.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isToday ? accent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    color: isToday ? accent : Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              const Spacer(),
              if (entry.conversationPreviews.isNotEmpty)
                Text(
                  '${entry.conversationPreviews.length} chats',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.summary,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
          if (entry.keyInsights.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF1A1A2E), height: 1),
            const SizedBox(height: 12),
            ...entry.keyInsights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _month(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}
